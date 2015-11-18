component {

	property numeric driftFactor;
	property numeric retryCount;
	property numeric retryDelay;
	property boolean debugEnabled;

	function init (required array clients, struct options = {}) {

		variables.unlockScript = 'if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("del", KEYS[1]) else return 0 end';
		variables.extendScript = 'if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("pexpire", KEYS[1], ARGV[2]) else return 0 end';

		//defaults
		variables.driftFactor = 0.01;
		variables.retryCount = 3;
		variables.retryDelay = 200;
		variables.debugEnabled = false;

		//todo: better validation ranges for these options?
		if (!isNull(options.driftFactor) && isNumeric(options.driftFactor) && options.driftFactor >= 0) {
			driftFactor = options.driftFactor;
		}

		if (!isNull(options.retryCount) && isNumeric(options.retryCount) && options.retryCount >= 0) {
			retryCount = options.retryCount;
		}

		if (!isNull(options.retryDelay) && isNumeric(options.retryDelay) && options.retryDelay >= 0) {
			retryDelay = options.retryDelay;
		}

		if (!isNull(options.debugEnabled) && isBoolean(options.debugEnabled)) {
			debugEnabled = options.debugEnabled;
		}

		if (!arrayLen(clients)) {
			throw("cfml-redlock must be instantiated with at least one client (redis server)");
		}

		variables.servers = clients;

		for (var srv in servers) {
			extendCFRedis(srv);
		}

		return this;
	}

	function getDriftFactor () {
		return driftFactor;
	}

	function getRetryCount () {
		return retryCount;
	}

	function getRetryDelay () {
		return retryDelay;
	}

	function lock (string resource, numeric ttl, any cb) {
		return _lock(resource, getNull(), ttl, arguments.cb);
	}

	function aquire (string resource, numeric ttl, any cb) {
		return lock(resource, ttl, arguments.cb);
	}

	function unlock (lock, cb) {
		_trace("unlock");


		if (lock.expiration < unixtime()) {
			//lock has expired
			_trace("expired");
			return arguments.cb('', '');
		}

		lock.expiration = 0;

		var waiting = arrayLen(servers);

		var loop = function (err, response) {
			_trace("unlock loop");
			if (len(err)) return cb(err, getNull());
			if (waiting-- > 1) return;
			return cb('', response);
		};


		for (var srv in servers) {
			srv.evalWithCallback(unlockScript, lock.resource, lock.value, loop);
		}
	}

	function release (lock, cb) {
		unlock(lock, arguments.cb);
	}

	function extend (lock, ttl, cb) {
		if (lock.expiration < unixtime()) {
			return cb("Cannot extend lock on resource " & lock.resource & " because the lock has already expired", getNull());
		}

		return _lock(lock.resource, lock.value, ttl, arguments.cb);

		//there was some extra stuff in the node library here that I think is unnecessary...
		//https://github.com/mike-marcacci/node-redlock/blob/master/redlock.js#L186
		//making note in case im wrong
	}

	function _lock (string resource, any value = getNull(), numeric ttl, any cb) {

		var request = "";
		var attempts = 0;

		if (isNull(value)) {
			//create a lock
			value = _random();
			request = function (srv, loop) {
				_trace("create lock request");
				return srv.setNxPx(resource, value, ttl, loop);
			};
		} else {
			//extend a lock
			request = function (srv, loop) {
				_trace("extend lock request");
				return srv.evalWithCallback(extendScript, [resource], [value, ttl], loop);
			};
		}

		var attempt = function() {
			attempts++;

			var start = unixtime();
			var votes = 0;
			var quorum = int(arrayLen(servers) / 2) + 1;
			var waiting = arrayLen(servers);

			var loop = function (err, response) {
				_trace("loop");
				if (len(err)) {
					return cb(err, getNull());
				}
				if (!isNull(response) && len(response)) {
					votes++;
				}
				if (waiting-- > 1) {
					return;
				}

				// Add 2 milliseconds to the drift to account for Redis expires precision, which is 1 ms,
				// plus the configured allowable drift factor
				var drift = round(driftFactor * ttl) + 2;

				var lock = _makeLock(this, resource, value, start + ttl - drift);

				// SUCCESS: there is consensus and the lock is not expired
				if(votes >= quorum && lock.expiration > unixtime()) {
					_trace("success");
					return cb('', lock);
				}

				// remove this lock from servers that voted for it
				return lock.unlock(function(){
					_trace("unlock cb");
					if(attempts <= retryCount) {
						_trace("retry");
						sleep(retryDelay);
						return attempt();
					}

					_trace("Failed");
					return cb("Exceeded " & retryCount & " attempts to lock the resource " & resource, getNull());
				});

			};

			for (var srv in servers) {
				request(srv, loop);
			}
		};

		attempt();

	}

	private function getNull () {
		return javaCast("null", 0);
	}

	private boolean function isCallback (fn) {
		return isCustomFunction(fn) || isClosure(fn);
	}

	private string function _random () {
		//we could use whatever we want here, we want it to be fast to generate but always unique
		//return hash(rand("SHA1PRNG"), "sha1");
		return createUUID();
	}

	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}

	private struct function _makeLock (redlock, resource, value, expiration) {

		var l = {
			redlock: redlock,
			resource: resource,
			value: value,
			expiration: expiration,
			unlock: function (callback) {
				_trace("lock.unlock");
				if (isNull(arguments.callback)) {
					arguments.callback = function(){};
				}
				l.redlock.unlock(l, arguments.callback);
			},
			extend: function (ttl, callback) {
				_trace("lock.extend");
				if (isNull(arguments.callback)) {
					arguments.callback = function(){};
				}
				l.redlock.extend(l, ttl, arguments.callback);
			}
		};

		return l;

	}

	private function __setNxPx (key, value, ttlms, cb) {

		var conn = getResource();
		var result = conn.set(JavaCast("String", key), JavaCast("String", value), JavaCast("String", "NX"), JavaCast("String", "PX"), JavaCast("long", ttlms));

		returnResource(conn);

		if (isNull(result)) {
			result = '';
		}

		if (!isnull(arguments.cb)) {
			return arguments.cb('', result);
		}

		return result;
	}

	private function __evalWithCallback (script, keys, args, cb) {

		if (!isArray(keys)) {
			keys = [keys];
		}

		var i = 0;

		for (i = 1; i <= arrayLen(keys); i++) {
			keys[i] = toString(keys[i]);
		}

		if (!isArray(args)) {
			args = [args];
		}

		for (i = 1; i <= arrayLen(args); i++) {
			args[i] = toString(args[i]);
		}

		var conn = getResource();
		var result = conn.eval(JavaCast("string", script), keys, args);

		returnResource(conn);

		if (isNull(result)) {
			result = '';
		}

		if (!isNull(arguments.cb)) {
			return arguments.cb('', result);
		}

		return result;
	}

	private function __inject (required string name, required any f, required boolean isPublic) {
		if (isPublic) {
			this[name] = f;
			variables[name] = f;
		} else {
			variables[name] = f;
		}
	}

	private function __cleanup () {
		structDelete(variables, "__inject");
		structDelete(this, "__inject");
		structDelete(variables, "__cleanup");
		structDelete(this, "__cleanup");
	}

	private function extendCFRedis (required target) {
		//write the injector first
		target["__inject"] = variables["__inject"];
		target["__cleanup"] = variables["__cleanup"];

		target.__inject("setNxPX", variables["__setNxPx"], true);
		target.__inject("evalWithCallback", variables["__evalWithCallback"], true);

		target.__cleanup();

		return target;
	}

	private function _trace (messages) {
		//could use this to dump or log
		if (debugEnabled) {
			if (!isArray(messages)) {
				messages = [messages];
			}

			for (var i = 1; i <= arrayLen(messages); i++) {
				messages[i] = toString(messages[i]);
			}

			for (var message in messages) {
				writedump(var=message);
				writeoutput("<br />");
			}
		}
	}

}