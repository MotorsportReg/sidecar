component {

	property any redis;
	property string prefix;
	property any redlock;

	function init (required any redis, string prefix = "redis-session-store_", string request_key = "$_express_redis_session_data_$") {
		variables.redis = extendCFRedis(arguments.redis);
		variables.prefix = arguments.prefix;
		variables.request_key = arguments.request_key;
		variables.TTL = 60*60; //same default as sidecar

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

	function setTTL( required numeric ttlSeconds ){
		variables.TTL = ttlSeconds;
		return this;
	}

	function destroy (required string sessionID) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.del(prefix & sessionID);
			structDelete( request, variables.request_key );
			lock.unlock();
		});
		return result;
	}

	//this function is used to make sure we only read from redis once per request
	private function ensureCachedInRequest(required string sessionID){
		if ( !structKeyExists(request, variables.request_key) ){
			request[variables.request_key] = getEntireSession(sessionID);
		}
	}

	function get (required string sessionID, required string key, any defaultValue) {
		ensureCachedInRequest(sessionID);
		if ( structKeyExists( request[variables.request_key], key ) ){
			return request[variables.request_key][key];
		}
		if (!isNull(defaultValue)) {
			return defaultValue;
		}
		return JavaCast("null", "");
	}

	function has (required string sessionID, required string key) {
		ensureCachedInRequest(sessionID);
		return structKeyExists( request[variables.request_key], key );
	}

	function clear (required string sessionID, required string key) {
		//clear it from the request cache
		ensureCachedInRequest(sessionID);
		structDelete( request[variables.request_key], key );
		//write session to redis
		return setEntireSession(sessionID);
	}

	function getEntireSession (required string sessionID) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			var data = redis.get(prefix & sessionID);
			if ( data == "" ){
				result = { 'cookie': getSessionCookie() };
			}else{
				result = deserializeJson( data );
			}
			lock.unlock();
		});
		return result;
	}

	private function setEntireSession (required string sessionID) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.set(prefix & sessionID, serializeJson( request[variables.request_key] ));
			//express-session uses Redis TTL instead of manually purging
			redis.expire(prefix & sessionID, variables.TTL);
			lock.unlock();
		});
		return result;
	}

	private function getSessionCookie () {
		//todo: where should cookie contents come from? what about SECURE option?
		return {
			"originalMaxAge": javaCast("null", 0)
			,"expires": javaCast("null", 0)
			,"httpOnly": true
			,"path": "/"
		};
	}

	function set (required string sessionID, required string key, required string value) {
		ensureCachedInRequest(sessionID);
		request[variables.request_key][key] = value;
		//write to redis
		return setEntireSession(sessionID);
	}

	// this function will set each key in the collection separately, but in the same action
	// use set() if you want to set the struct itself into one key
	function setCollection (required string sessionID, required struct collection) {
		ensureCachedInRequest(sessionID);

		for (var key in collection) {
			request[variables.request_key][key] = collection[key];
		}

		return setEntireSession(sessionID);
	}

	function touch (required any sessionID, required numeric expires) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.expireAt(prefix & sessionID, expires);
			lock.unlock();
		});
		return result;
	}

	function all () {
		return [];
	}

	function expired (numeric expiredBefore = unixTime()) {
		return [];
	}

	function length () {
		return arrayLen(all());
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
