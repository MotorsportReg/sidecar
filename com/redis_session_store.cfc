component {

	property any redis;
	property string prefix;
	property numeric ttl;
	property any redlock;

	function init (required any redis, numeric ttl = 86400, string prefix = "redis-session-store_") {
		variables.redis = arguments.redis;
		variables.prefix = arguments.prefix;
		variables.ttl = arguments.ttl;
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

	function set (required string sessionID, required string key, required string value) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.hSet(prefix & sessionID, key, value);
			lock.unlock();
		});
		return result;
	}

	function touch (required any sessionID) {
		var result = false;
		redlock.lock(getLockName(sessionID), 200, function(err, lock) {
			if (len(err)) throw(err);
			result = redis.expire(prefix & sessionID, ttl);
			lock.unlock();
		});
		return result;
	}

	function all () {
		var hashes = redis.keys(prefix & "*");
		var output = [];
		for (var hash in hashes) {
			arrayAppend(output, replace(hash, prefix, ""));
		}
		return output;
	}

}