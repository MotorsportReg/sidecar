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
	property numeric purgeFrequencySeconds;
	property numeric lastPurge;

	function init () {

		//defaults
		variables.logName = "sidecar";
		variables.debugEnabled = false;
		variables.debugLogLevel = "FULL";
		variables.defaultTimeoutSeconds = 60 * 60;
		variables.oldSecret = "old-super-secret-passphrase";
		variables.newSecret = "new-super-secret-passphrase";
		variables.serializer = function(input) { return binaryEncode(objectSave(input), "Base64"); };
		variables.deserializer = function(input) {
			try {
				return objectLoad(binaryDecode(input, "Base64"));
			} catch (any e) {
				return input;
			}
		};
		//todo: come up with a better default for the genSessionID function
		variables.genSessionID = function() { return createUUID(); };
		variables.cookieName = "sidecar_sid";
		variables.cookieOptions = {
			path: "/",
			httpOnly: true,
			secure: false,
			maxAge: 0
		};
		variables.sessionStartCallback = function() {};
		variables.sessionEndCallback = function() {};
		variables.lastPurge = 0;
		setPurgeFrequencySeconds(60);

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

	function enableDebugMode (string logName = variables.logName, string logLevel = "FULL") {
		variables.logName = arguments.logName;
		variables.debugEnabled = true;

		if (arrayFindNoCase(["FULL","BASIC"], arguments.logLevel)) {
			variables.debugLogLevel = ucase(arguments.logLevel);
			doLog("debugLogLevel set to " & variables.debugLogLevel);
		}
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

	private function doLog (string action = "", any data = "", string sessionID = getSessionID(false)) {
		if (debugEnabled) {
			if (debugLogLevel == "FULL") {
				if (!isSimpleValue(data)) {
					if (isBinary(data)) {
						data = "{{binary data}}";
					} else if (isStruct(data) && structKeyExists(data, "value") && isbinary(data.value)) {
						data.value = "{{binary data}}";
						data = serializeJSON(data);
					} else {
						data = serializeJSON(data);
					}
				}
				var output = [sessionID, action, data];
			} else {
				var key = "";
				if (isStruct(data) && structKeyExists(data, "key")) {
					key = data.key;
				}

				var output = [left(sessionID, 5), action, key];
			}

			writeLog(text=arrayToList(output, ";"), file=logName);
		}
	}

	function setDefaultSessionTimeout (required numeric timeoutSeconds) {
		variables.defaultTimeoutSeconds = arguments.timeoutSeconds;
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
			string cookieName = "sidecar_sid",
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

	function getCookieOptions () {
		var output = duplicate(cookieOptions);
		output.cookieName = variables.cookieName;
		return output;
	}

	function setPurgeFrequencySeconds (required numeric value) {
		if (value >= 0) {
			doLog("setting purgeFrequencySeconds to #value#");
			variables.purgeFrequencySeconds = value;
		}
	}

	function async (required any f) {
		var listener = f;
		structDelete(arguments, "f");

		thread action="run" name="thread_#createUUID()#" listener=listener args=arguments emit=this {
			try {
				listener(argumentCollection=arguments);
			} catch (any e) {
				arguments.exception = e;
				emit.dispatchError(argumentCollection=arguments);
			}
		}
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

		var timeoutSeconds = defaultTimeoutSeconds;

		if (!isNewSession) {
			timeoutSeconds = get("SIDECAR_TIMEOUT", 0);
			doLog("getting session timeout", timeoutSeconds);
		}

		if (!isNumeric(timeoutSeconds) || timeoutSeconds < 1) {
			timeoutSeconds = defaultTimeoutSeconds;
		}

		var expires = dateAdd("s", timeoutSeconds, now());

		writeCookie(expires, newSecret);

		set('SIDECAR_TIMEOUT', timeoutSeconds);

		store.touch(getSessionID(), unixtime() + (timeoutSeconds));

		if (isNewSession) {
			doLog("sessionStartCallback");
			var startData = sessionStartCallback();
			if (!isNull(startData) && isStruct(startData)) {
				for (var key in startData) {
					key = ucase(key);
					set(key, startData[key]);
				}
			}
		}

		doLog("touch", {isNewSession: isNewSession, expires: expires, timeoutSeconds: timeoutSeconds});
	}

	function setSessionTimeout (required numeric timeoutSeconds) {
		doLog("setSessionTimeout", timeoutSeconds);
		set('SIDECAR_TIMEOUT', timeoutSeconds);
		touch();
		return this;
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
		doLog("requestEndHandler");
		if (unixTime() - lastPurge > purgeFrequencySeconds) {
			purgeSessions();
			lastPurge = unixTime();
		}
	}

	function purgeSessions () {

		async(function() {
			var expired = store.expired();
			doLog("purgeSessions", {expired: expired}, "");

			for (var sessionID in expired) {
				var sessionData = store.getEntireSession(sessionID);
				sessionEndCallback(sessionData);
				store.destroy(sessionID);
			}
		});
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
		if (isNull(request.sidecar_cache) || !isStruct(request.sidecar_cache)) {
			clearRequestSessionCache();
		}
	}

	private function clearRequestSessionCache () {
		request.sidecar_cache = structNew();
	}

	function get (required string key, any defaultValue = -1, boolean bypassRequestCache = false) {
		if (!bypassRequestCache) {
			ensureRequestSessionCache();
		}

		key = ucase(key);
		var out = "";
		var fromCache = false;
		if (!bypassRequestCache && structKeyExists(request.sidecar_cache, key)) {
			fromCache = true;
			out = request.sidecar_cache[key];
		} else {
			out = store.get(getSessionID(), key);
		}
		if (!isDefined("out")) {
			doLog("get", {key: key, output: defaultValue, defaultValue: defaultValue, fromCache: fromCache});
			return defaultValue;
		}
		request.sidecar_cache[key] = out;

		out = variables.deserializer(out);
		doLog("get", {key: key, output: out, defaultValue: defaultValue, fromCache: fromCache});
		return out;
	}

	function getEntireSession() {
		var data = store.getEntireSession(getSessionID());
		var output = structNew();
		for (var key in data) {
			output[ucase(key)] = variables.deserializer(data[key]);
		}
		return output;
	}

	function _getEntireRequestCache() {
		var data = request.sidecar_cache;
		var output = structNew();
		for (var key in data) {
			output[key] = variables.deserializer(data[key]);
		}
		return output;
	}

	function has (required string key) {
		ensureRequestSessionCache();
		key = ucase(key);
		var out = false;
		if (structKeyExists(request.sidecar_cache, key)) {
			doLog("has", {key: key, output: true, fromCache: true});
			return true;
		}
		out = store.has(getSessionID(), key);
		doLog("has", {key: key, output: out, fromCache: false});
		return out;
	}

	function clear (required string key) {
		ensureRequestSessionCache();
		key = ucase(key);
		var out = false;
		var inCache = false;
		if (structKeyExists(request.sidecar_cache, key)) {
			inCache = true;
			structDelete(request.sidecar_cache, key);
		}
		out = store.clear(getSessionID(), key);
		doLog("clear", {key: key, output: out, inCache: inCache});
		return out;
	}

	function set (required string key, required any value) {
		ensureRequestSessionCache();
		key = ucase(key);
		var serializedValue = variables.serializer(value);

		request.sidecar_cache[key] = serializedValue;

		doLog("set", {key: key, value: value});
		return store.set(getSessionID(), key, serializedValue);
	}

	function setCollection (required struct collection) {
		ensureRequestSessionCache();
		var coll = structNew();
		for (var key in collection) {
			key = ucase(key);
			coll[key] = variables.serializer(collection[key]);
			request.sidecar_cache[key] = coll[key];
		}

		doLog("setCollection", {collection: coll});
		return store.setCollection(getSessionID(), coll);
	}

	//allowed to run destroy before the session has started
	function destroy () {
		doLog("destroy");
		clearRequestSessionCache();
		var sessionID = getSessionID(throwIfInvalid = false);
		if (!len(sessionID)) return false;
		var result = store.destroy(sessionID);
		touch(isNewSession=true);
		return result;
	}

	function getSessionID (boolean throwIfInvalid = true) {
		if (!structKeyExists(request, variables.cookieName)) {
			if (throwIfInvalid) {
				throw("You need to wait until after you call requestStartHandler()");
			}
			return "";
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