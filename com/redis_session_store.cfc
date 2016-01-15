component {

	property any redis;
	property string prefix;
	property any redlock;

	function init (required any redis, string prefix = "redis-session-store_") {
		variables.redis = extendCFRedis(arguments.redis);
		variables.prefix = arguments.prefix;

		variables.redlock = new redlock([redis], {
				retryCount: 2,
				retryDelay: 150
			});

		return this;
	}

	private numeric function unixtimemillis () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}

	private numeric function unixtime () {
		return int(unixTimeMillis() / 1000);
	}

	private function getLockName (required string sessionID) {
		return prefix & sessionID & "_lock";
	}

	function destroy (required string sessionID) {

		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.del(prefix & sessionID);
			redis.zrem_fixed(prefix & "_session_expires", sessionID);
			lock.unlock();
		});
		return result;
	}

	function get (required string sessionID, required string key, any defaultValue) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hgetReturnsUndefined(prefix & sessionID, key);
			lock.unlock();
		});
		//ACF is such a piece of junk
		if (isNull(result)) {
			if (!isNull(defaultValue)) {
				return defaultValue;
			}
			return JavaCast("null", "");
		}
		return result;
	}

	function has (required string sessionID, required string key) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hExists(prefix & sessionID, key);
			lock.unlock();
		});
		return result;
	}

	function clear (required string sessionID, required string key) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hDel(prefix & sessionID, key);
			lock.unlock();
		});
		return result;
	}

	function getEntireSession (required string sessionID) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hGetAll(prefix & sessionID);
			lock.unlock();
		});
		return result;
	}

	function set (required string sessionID, required string key, required string value) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hSet(prefix & sessionID, key, value);
			lock.unlock();
		});
		return result;
	}

	// this function will set each key in the collection separately, but in the same action
	// use set() if you want to set the struct itself into one key
	function setCollection (required string sessionID, required struct collection) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			for (var key in collection) {
				result = redis.hSet(prefix & sessionID, key, collection[key]);
			}
			lock.unlock();
		});
		return result;
	}

	function touch (required any sessionID, required numeric expires) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			//result = redis.expire(prefix & sessionID, expires);
			redis.hSet(prefix & sessionID, "_session_expires", expires);
			redis.zadd(prefix & "_session_expires", expires, sessionID);
			lock.unlock();
		});
		return result;
	}

	function all () {
		return redis.zrangeByScore(prefix & "_session_expires", "-inf", "+inf");
	}

	function expired (numeric expiredBefore = unixTime()) {
		return redis.zrangeByScore(prefix & "_session_expires", "0", expiredBefore);
	}

	function length () {
		var keys = redis.hKeys(prefix & "_session_expires");
		return arrayLen(keys);
	}

	//cleanup routine that will delete everything from redis related to this session store, only necessary for testing!
	function _wipe_all () {
		var keys = redis.keys(prefix & "*");

		for (var key in keys) {
			redis.del(key);
		}

		return arrayLen(keys);
	}

	private function __zrem_fixed (key, member) {

		if (!isArray(member)) {
			member = [member];
		}

		var conn = getResource();
		var result = conn.zrem(JavaCast("string", key), JavaCast("string[]", member));

		returnResource(conn);

		if (isNull(result)) {
			result = 0;
		}

		return result;
	}

	private function __hgetReturnsUndefined (string key, string field) {
		var conn = getResource();
		var result = conn.hget(JavaCast("string", key), JavaCast("string", field));

		returnResource(conn);

		if (!isNull(result)) {
			return result;
		}

		return JavaCast("null", "");
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

		target.__inject("zrem_fixed", variables["__zrem_fixed"], true);
		target.__inject("hgetReturnsUndefined", variables["__hgetReturnsUndefined"], true);

		target.__cleanup();

		return target;
	}

}