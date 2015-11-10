component {

	property string loggingHeader;
	property numeric timeoutSeconds;
	property string oldSecret;
	property string newSecret;
	property any store;
	property any serializer;
	property struct cookieOptions;
	property any onSessionStart;
	property any onSessionEnd;

	function init () {

		//defaults
		variables.loggingHeader = "";
		variables.timeoutSeconds = 60 * 60;
		variables.oldSecret = "old-super-secret-passphrase";
		variables.newSecret = "new-super-secret-passphrase";
		variables.serializer = function(input) { return serializeJSON(input); };
		//todo: come up with a better default for the genSessionID function
		variables.genSessionID = function() { return createUUID(); };
		variables.cookieOptions = {
			path: "/",
			httpOnly: true,
			secure: false,
			maxAge: 0
		};
		variables.onSessionStart = function() {};
		variables.onSessionEnd = function() {};

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

	function setSerializerFunction (required any f) {
		variables.serializer = arguments.f;
		return this;
	}

	function setGenSessionIDFunction (required any f) {
		variables.genSessionID = arguments.f;
		return this;
	}

	function setCookieOptions (string path = "/", boolean httpOnly = true, boolean secure = false, numeric maxAge = 0) {
		variables.cookieOptions.path = arguments.path;
		variables.cookieOptions.httpOnly = arguments.httpOnly;
		variables.cookieOptions.secure = arguments.secure;
		variables.cookieOptions.maxAge = arguments.maxAge;
		return this;
	}

	function onSessionStart (required any f) {
		variables.onSessionStart = arguments.f;
		return this;
	}

	//requestEndHandler will find any expired sessions and call this method for each (maybe in another thread?)
	function onSessionEnd (required any f) {
		variables.onSessionEnd = arguments.f;
		return this;
	}

	//user is required to call this in Application.cfc:onRequestStart() for any request that sessions
	//should be enabled for
	function requestStartHandler () {
		if (isNull(cookie.sess_sid)) {
			//no existing session
		} else {
			var val = unsign(newSecret, cookie.sess_sid);
			if (val == false) {
				val = unsign(oldSecret, cookie.sess_sid);
				if (val == false) {
					//cookie exists, but is invalid session
					request.sess_sid = listFirst(val, "|");
				} else {
					//cookie needs to be recreated using newSecret

				}

			}

			//by this point we should have a session to work with


		}
	}

	//user should call this in Application.cfc:onRequestEnd() for any request that they called the
	//requestStartHandler for at least
	function requestEndHandler () {

	}

	function get (required string key, any defaultValue) {

	}

	function set (required string key, required any value) {

	}

	function destroy () {

	}

	function touch () {

	}

	function getSessionID () {

	}

	private string function sign (required string secret, required any input) output="false" {
		if (isArray(input)) {
			input = join(input);
		}

		return input & "." & toBase64(binaryDecode(hmac(replace(input, "\n", chr(10), "all"), secret, "HmacSHA1"), "hex"));
	}

	private string function unsign (required string secret, required string val) {
		var input = listFirst(val, ".");
		if (sign(secret, input) == val) {
			return input;
		}
		return false;
	}

	private string function join (required array input, string delim = "\n") {

		var sb = [];
		var i = 0;
		for (var item in input) {
			if (++i != 1) {
				arrayAppend(sb, delim);
			}
			if (isNumeric(item) && int(item) == item) {
				arrayAppend(sb, int(item).longValue().toString());
			} else {
				arrayAppend(sb, item);
			}

		}
		return arrayToList(sb, "");
	}



}