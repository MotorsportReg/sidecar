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

	private numeric function unixtimemillis () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}

	private numeric function unixtime () {
		return int(unixTimeMillis() / 1000);
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
			touchSession(genSessionID());
		} else {
			var val = unsign(newSecret, cookie.sess_sid);
			if (val == false) {
				val = unsign(oldSecret, cookie.sess_sid);
				if (val == false) {
					//cookie exists, but is invalid session
					//delete existing cookie
					removeCookie();
					//start new session
					touchSession(genSessionID());
				} else {
					//cookie needs to be recreated using newSecret
					//get rid of old secret cookie
					removeCookie();
					//create new secret
					touchSession(listFirst(val, "|"));
				}
			} else {
				//existing session was fine, just touch it
				touchSession(listFirst(val, "|"));
			}

			//by this point we should have a session to work with

		}
	}

	private function touchSession (string sessionID) {
		request.sess_sid = sessionID;

		var expires = dateAdd("s", timeoutSeconds, now());

		writeCookie(expires, newSecret);

		this.set('sess_expire', expires);

		this.touch();

		var startData = onSessionStart();
		if (!isNull(startData) && isStruct(startData)) {
			for (var key in startData) {
				this.set(key, startData[key]);
			}
		}

	}

	private function writeCookie (expires, secret) {
		cookie.sess_sid = {value: sign(secret, request.sess_sid)
				, path: cookieOptions.path
				, httpOnly: cookieOptions.httpOnly
				, secure: cookieOptions.secure
				, expires: expires};
	}

	private function removeCookie () {
		cookie.sess_sid = {value: cookie.sess_sid
				, path: cookieOptions.path
				, httpOnly: cookieOptions.httpOnly
				, secure: cookieOptions.secure
				, expires: "NOW"};
	}

	//user should call this in Application.cfc:onRequestEnd() for any request that they called the
	//requestStartHandler for at least
	function requestEndHandler () {
		purgeSessions();
	}

	function purgeSessions () {
		var allSessions = store.all();

		//todo: this is naive and will check all sessions every time for expired sessions, probably need to do this a different way
		//todo: also consider doing this in a different thread
		for (var sessionID in allSessions) {
			if (allSessions[sessionID] < unixTime()) {
				var sessionData = store.getEntireSession(sessionID);
				onSessionEnd(sessionData);
				store.destroy(sessionID);
			}
		}
	}

	function get (required string key, any defaultValue) {
		var out = store.get(getSessionID(), key);
		if (out == "") {
			return defaultValue;
		}
		return out;
	}

	function set (required string key, required any value) {
		return store.set(getSessionID(), key, value);
	}

	function destroy () {
		return store.destroy(getSessionID());
	}

	function touch () {
		return store.touch(getSessionID(), unixtime() + (timeoutSeconds));
	}

	function getSessionID () {
		if (isNull(request.sess_sid)) {
			throw("You need to wait until after you call requestStartHandler()");
		}
		return request.sess_sid;
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