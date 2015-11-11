component {

	property array clients;
	property string prefix;
	property numeric ttl;

	function init (required any client, numeric ttl = 86400, string prefix = "redis-session-store_") {
		variables.client = arguments.client;
		variables.prefix = arguments.prefix;
		variables.ttl = arguments.ttl;

		return this;
	}

	function destroy (required string sessionID) {

		return client.del(prefix & sessionID);
	}

	function get (required string sessionID, required string key) {
		return client.hGet(prefix & sessionID, key);
	}

	function set (required string sessionID, required string key, required string value) {
		return client.hSet(prefix & sessionID, key, value);
	}

	function touch (required any sessionID) {
		return client.expire(prefix & sessionID, ttl);
	}

}