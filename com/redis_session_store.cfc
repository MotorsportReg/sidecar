component {

	property any redis;
	property string prefix;
	property any redlock;

	function init (required any redis, string prefix = "redis-session-store_") {
		variables.redis = arguments.redis;
		variables.prefix = arguments.prefix;

		variables.redlock = new redlock([redis], {
				retryCount: 2,
				retryDelay: 150
			});

		return this;
	}

	private function getLockName (required string sessionID) {
		return prefix & sessionID & "_lock";
	}

	function destroy (required string sessionID) {

		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.del(prefix & sessionID);
			redis.hDel(prefix & "_session_expires", sessionID);
			lock.unlock();
		});
		return result;
	}

	function get (required string sessionID, required string key) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hGet(prefix & sessionID, key);
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

	function touch (required any sessionID, required numeric expires) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			//result = redis.expire(prefix & sessionID, expires);
			redis.hset(prefix & "_session_expires", sessionID, expires);
			lock.unlock();
		});
		return result;
	}

	function all () {
		return redis.hGetAll(prefix & "_session_expires");
	}

	function length () {
		var keys = redis.hKeys(prefix & "_session_expires");
		return arrayLen(keys);
	}

}