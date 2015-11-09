component {

	property string loggingHeader;
	property numeric timeoutSeconds;
	property string oldSecret;
	property string newSecret;
	property any store;
	property any serializer;

	function init () {

		//defaults
		variables.loggingHeader = "";
		variables.timeoutSeconds = 60 * 60;
		variables.oldSecret = "old-super-secret-passphrase";
		variables.newSecret = "new-super-secret-passphrase";
		variables.serializer = function(input) {return serializeJSON(input);};

		return this;
	}

	//todo: come up with a better name for this
	function setLoggingHeader (required string header) {
		variables.loggingHeader = arguments.header;
		return this;
	}

	function setSessionTimeout (required numeric timeoutSeconds) {
		variables.timeoutSeconds = arguments.timeoutSeconds;
		return this;
	}

	function setSecrets (required string newSecret, string oldSecret = "") {
		variables.oldSecret = arguments.oldSecret;
		variables.newSecret = arguments.newSecret;
		return this;
	}

	function setSessionStorage (required any sessionStorage) {
		variables.store = arguments.sessionStorage;
		return this;
	}

	function setSerializer (required any f) {
		variables.serializer = arguments.f;
		return this;
	}



}