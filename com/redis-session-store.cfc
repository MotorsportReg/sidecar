component {

	function init () {

	}

	function all (any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}

	}

	function destroy (required string sessionID, any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}

	}

	function clear (any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}

	}

	function length (any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}
	}

	function get (required string sessionID, required string key, any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}
	}

	function set (required string sessionID, required string key, required string value, any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}

	}

	function touch (required any sessionID, any cb) {
		if (isNull(cb)) {
			cb = function() {};
		}

	}

}