<!---
The idea here is that the first request will not have any cookies, so call the tests that assume that,
any cookies returned will be passed to the subsequent requests.
--->

<cfparam name="url.format" default="html" />



<cfscript>

	if (!arrayFindNoCase(["html","travis"], url.format)) {
		url.format = "html";
	}

	reporter = "simple";

	switch (url.format) {
		case "travis" :
			reporter = "json";
			break;
		default :
			reporter = "simple";
			break;
	}

	steps = [
		{
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.newSessionTest&reinit=true",
			before:	function(index) {
				cookies = {};
				//writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.existingSessionTest",
			before: function(index) {
				//writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.malformedCookieTest",
			before: function(index) {
				//writeoutput("before step " & index);

				cookies.sidecar_sid["value"] = "foo";
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.sessionExpirationTests",
			before: function(index) {
				//writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.sessionDoesntExistTest",
			before: function(index) {
				//writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=#reporter#&target=tests.basic.cookieOptionsTest",
			before: function(index) {
				//writeoutput("before step " & index);
				//clear out existing cookies
				cookies = {};
				//writedump(cookies);
			},
			after: function (index) {
				//writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
	];

	function getResponseCookies (required struct response) {

		var cookies = {};

		if (!structKeyExists(response.ResponseHeader, "Set-Cookie")) {
			return cookies;
		}

		var rawCookies = response.ResponseHeader["Set-Cookie"];

		if (isSimpleValue(rawCookies)) {
			rawCookies = {"1": rawCookies};
		} else if (isArray(rawCookies)) {
			rawCookiesObject = {};
			for (var i = 1; i <= arrayLen(rawCookies); i++) {
				rawCookiesObject[i] = rawCookies[i];
			}
			rawCookies = rawCookiesObject;
		}

		for (var cookieIndex in rawCookies) {
			var parts = listToArray(rawCookies[cookieIndex], ";");
			var name = "";
			var attributes = {"raw": rawCookies[cookieIndex]};
			for (var i = 1; i <= arrayLen(parts); i++) {
				var partArray = listToArray(parts[i], "=");
				if (arrayLen(partArray) == 1) {
					partArray[2] = "";
				}
				if (i == 1) {
					name = partArray[1];
					attributes["value"] = partArray[2];
				} else {
					attributes[partArray[1]] = partArray[2];
				}
			}
			cookies[name] = attributes;
		}

		return cookies;
	}

	function getCookiesString(cookies) {
		var output = [];
		for (var key in cookies) {
			try {
				arrayAppend(output, key & "=" & cookies[key]["value"]);
			} catch ( any e ) {
				writedump(cookies);
				writedump(key);
				writedump(e);
				abort;
			}
		}
		return arrayToList(output, ";");
	}

	cookies = {};

	results = [];

	index = 0;

	for (step in steps) {
		index++;

		if (structKeyExists(step, "before")) {
			step.before(index);
		}

		cookieString = getCookiesString(cookies);

		httpService = new http(method="GET", charset="utf-8", url="http://" & cgi.server_name & step.url);
		if (len(cookieString)) {
			httpService.addParam(name="Cookie", type="header", value=cookieString);
		}

		httpResult = httpService.send().getPrefix();

		cookies = getResponseCookies(httpResult);

		arrayAppend(results, httpResult.fileContent);

		if (structKeyExists(step, "after")) {
			step.after(index);
		}

		break; //REMOVE ME AFTER TESTING

	}

	switch (url.format) {
		case "travis" :

			overall = {
				totalSpecs: 0,
				totalPass: 0,
				totalFail: 0,
				totalError: 0
			};

			//writedump(results);

			for (result in results) {
				result = deserializeJSON(result);
				overall.totalSpecs += result.totalSpecs;
				overall.totalPass += result.totalPass;
				overall.totalFail += result.totalFail;
				overall.totalError += result.totalError;
			}

			if (overall.totalSpecs != overall.totalPass) {
				pc = getpagecontext().getresponse();
				pc.getresponse().setstatus(500);
			}

			writeoutput(serializeJSON(overall));
			abort;

			break;
		default :

			for (result in results) {
				writeOutput(result);
				writeOutput("<hr />");
			}

			break;
	}





</cfscript>

