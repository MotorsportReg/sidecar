<!---
The idea here is that the first request will not have any cookies, so call the tests that assume that,
any cookies returned will be passed to the subsequent requests.
--->

<cfscript>

	testURLS = [
		  "/tests/basic/index.cfm?opt_run=true&reporter=Doc&target=tests.basic.newSessionTest&reinit=true"
		, "/tests/basic/index.cfm?opt_run=true&reporter=Doc&target=tests.basic.existingSessionTest"
		];

	function getResponseCookies (required struct response) {

		var cookies = {};

		if (!structKeyExists(response.ResponseHeader, "Set-Cookie")) {
			return cookies;
		}

		var rawCookies = response.ResponseHeader["Set-Cookie"];

		if (!isStruct(rawCookies)) {
			rawCookies = {"1": rawCookies};
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
			arrayAppend(output, key & "=" & cookies[key]["value"]);
		}
		return arrayToList(output, ";");
	}

	cookies = {};

</cfscript>

<!---<cfdump var="#cgi#" abort="true"/>--->



<cfloop array="#testURLS#" index="testURL">

	<cfset cookieString = getCookiesString(cookies) />
	<cfhttp url="http://#cgi.server_name##testURL#" method="GET" result="httpResult">
		<cfif len(cookieString)>
			<cfhttpparam type="header" name="Cookie" value="#cookieString#" />
		</cfif>
	</cfhttp>

	<cfset cookies = getResponseCookies(httpResult) />

	<!---<cfdump var="#cookies#" />
	<cfdump var="#getCookiesString(cookies)#" />--->
	<cfoutput>
		#httpResult.fileContent#
		<hr />
	</cfoutput>

</cfloop>