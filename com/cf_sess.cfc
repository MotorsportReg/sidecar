component {

	property string logName;
	property boolean debugEnabled;
	property numeric timeoutSeconds;
	property string oldSecret;
	property string newSecret;
	property any store;
	property any serializer;
	property any deserializer;
	property struct cookieOptions;
	property any sessionStartCallback;
	property any sessionEndCallback;

	function init () {

		//defaults
		variables.logName = "cf_sess";
		variables.debugEnabled = false;
		variables.timeoutSeconds = 60 * 60;
		variables.oldSecret = "old-super-secret-passphrase";
		variables.newSecret = "new-super-secret-passphrase";
		variables.serializer = function(input) { return serializeJSON(input); };
		variables.deserializer = function(input) { return deserializeJSON(input); };
		//todo: come up with a better default for the genSessionID function
		variables.genSessionID = function() { return createUUID(); };
		variables.cookieName = "sess_sid";
		variables.cookieOptions = {
			path: "/",
			httpOnly: true,
			secure: false,
			maxAge: 0
		};
		variables.sessionStartCallback = function() {};
		variables.sessionEndCallback = function() {};

		return this;
	}

	numeric function unixTimeMillis () {
		if (isNull(variables.system)) {
			variables.system = createObject("java", "java.lang.System");
		}
		return system.currentTimeMillis();
	}

	numeric function unixTime () {
		return int(unixTimeMillis() / 1000);
	}

	function enableDebugMode (string logName = variables.logName) {
		variables.logName = arguments.logName;
		variables.debugEnabled = true;
		return this;
	}

	function disableDebugMode () {
		variables.debugEnabled = false;
		return this;
	}

	function setLogName (string logName = variables.logName) {
		variables.logName = arguments.logName;
		return this;
	}

	private function doLog (string action = "", any data = "", string sessionID = getSessionID()) {
		if (debugEnabled) {
			if (!isSimpleValue(data)) {
				data = serializeJSON(data);
			}
			var output = [sessionID, action, data];
			writeLog(text=arrayToList(output, ";"), file=logName);
		}
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

	function setCookieOptions (
			string cookieName = "sess_sid",
			string path = "/",
			boolean httpOnly = true,
			boolean secure = false,
			numeric maxAge = 0) {

		variables.cookieName = cookieName;
		variables.cookieOptions.path = arguments.path;
		variables.cookieOptions.httpOnly = arguments.httpOnly;
		variables.cookieOptions.secure = arguments.secure;
		variables.cookieOptions.maxAge = arguments.maxAge;
		return this;
	}

	function onSessionStart (required any f) {
		variables.sessionStartCallback = arguments.f;
		return this;
	}

	//requestEndHandler will find any expired sessions and call this method for each (maybe in another thread?)
	function onSessionEnd (required any f) {
		variables.sessionEndCallback = arguments.f;
		return this;
	}

	//user is required to call this in Application.cfc:onRequestStart() for any request that sessions
	//should be enabled for
	function requestStartHandler () {
		if (!structKeyExists(cookie, variables.cookieName)) {
			//no existing session
			touch(genSessionID(), true);
			doLog("NoExistingSession");
		} else {
			var val = unsign(newSecret, cookie[variables.cookieName]);
			if (val == false) {
				val = unsign(oldSecret, cookie[variables.cookieName]);
				if (val == false) {
					//cookie exists, but is invalid session
					//delete existing cookie
					removeCookie();
					//start new session
					touch(genSessionID(), true);
					doLog("CookieExistsInvalidSession");
				} else {
					//cookie needs to be recreated using newSecret
					//get rid of old secret cookie
					removeCookie();
					//create new secret
					touch(listFirst(val, "|"), false);
					doLog("OldSecretCookie");
				}
			} else {
				//existing session was fine, just touch it
				touch(listFirst(val, "|"), false);
				doLog("ExistingSession");
			}

			//by this point we should have a session to work with

		}
	}

	private function touch (string sessionID = getSessionID(), boolean isNewSession = false) {
		request[variables.cookieName] = sessionID;

		var expires = dateAdd("s", timeoutSeconds, now());

		writeCookie(expires, newSecret);

		//not sure if this is really necessary, I think the touch() should do everything
		this.set('sess_expire', expires);

		store.touch(getSessionID(), unixtime() + (timeoutSeconds));

		if (isNewSession) {
			var startData = sessionStartCallback();
			if (!isNull(startData) && isStruct(startData)) {
				for (var key in startData) {
					this.set(key, startData[key]);
				}
			}
		}

		doLog("touch", {isNewSession: isNewSession, expires: expires});
	}

	private function writeCookie (expires, secret) {
		cookie[variables.cookieName] = {value: sign(secret, request[variables.cookieName])
				, path: cookieOptions.path
				, httpOnly: cookieOptions.httpOnly
				, secure: cookieOptions.secure
				, expires: expires};
	}

	private function removeCookie () {
		cookie[variables.cookieName] = {value: cookie[variables.cookieName]
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

		var expired = store.expired();

		//writedump(var=expired, label="expired");

		doLog("purgeSessions", {expired: expired}, "");

		for (var sessionID in expired) {
			var sessionData = store.getEntireSession(sessionID);
			sessionEndCallback(sessionData);
			store.destroy(sessionID);
		}
	}

	//included for testing
	function _getAllSessions () {
		return store.all();
	}

	//included for testing
	function _getExpiredSessions () {
		return store.expired();
	}

	private function ensureRequestSessionCache () {
		if (isNull(request.sess_cache) || !isStruct(request.sess_cache)) {
			request.sess_cache = structNew();
		}
	}

	function get (required string key, any defaultValue = -1) {
		ensureRequestSessionCache();
		var out = "";
		var fromCache = false;
		if (structKeyExists(request.sess_cache, key)) {
			fromCache = true;
			out = request.sess_cache[key];
		} else {
			out = store.get(getSessionID(), key);
		}
		request.sess_cache[key] = out;
		if (out == "") {
			return defaultValue;
		}
		doLog("get", {key: key, output: out, defaultValue: defaultValue, fromCache: fromCache});
		return variables.deserializer(out);
	}

	function set (required string key, required any value) {
		ensureRequestSessionCache();
		value = variables.serializer(value);

		request.sess_cache[key] = value;

		doLog("set", {key: key, value: value});
		return store.set(getSessionID(), key, value);
	}

	function setCollection (required struct collection) {
		ensureRequestSessionCache();

		for (var key in collection) {
			collection[key] = variables.serializer(collection[key]);
			request.sess_cache[key] = collection[key];
		}

		doLog("setCollection", {collection: collection});
		return store.setCollection(getSessionID(), collection);
	}

	function destroy () {
		doLog("destroy");
		return store.destroy(getSessionID());
	}

	function getSessionID () {
		if (isNull(request[variables.cookieName])) {
			throw("You need to wait until after you call requestStartHandler()");
		}
		return request[variables.cookieName];
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

	//cleanup routine that will delete everything from redis related to this session store, only necessary for testing!
	function _wipe_all () {
		doLog("_wipe_all");
		return store._wipe_all();
	}

}