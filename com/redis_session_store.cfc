component {

	property any srv;
	property string prefix;
	property numeric ttl;

	function init (required any srv, numeric ttl = 86400, string prefix = "redis-session-store_") {
		variables.srv = arguments.srv;
		variables.prefix = arguments.prefix;
		variables.ttl = arguments.ttl;

		return this;
	}

	function destroy (required string sessionID) {

		return srv.del(prefix & sessionID);
	}

	function get (required string sessionID, required string key) {
		return srv.hGet(prefix & sessionID, key);
	}

	function set (required string sessionID, required string key, required string value) {
		return srv.hSet(prefix & sessionID, key, value);
	}

	function touch (required any sessionID) {
		return srv.expire(prefix & sessionID, ttl);
	}

}