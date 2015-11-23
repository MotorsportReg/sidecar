<!---
The idea here is that the first request will not have any cookies, so call the tests that assume that,
any cookies returned will be passed to the subsequent requests.
--->

<cfscript>

	steps = [
		{
			url:"/tests/basic/index.cfm?opt_run=true&reporter=Doc&target=tests.basic.newSessionTest&reinit=true",
			before:	function(index) {
				cookies = {};
				writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=Doc&target=tests.basic.existingSessionTest",
			before: function(index) {
				writeoutput("before step " & index);
				//writedump(cookies);
			},
			after: function (index) {
				writeoutput("after step " & index);
				//writedump(cookies);
			}
		}
		, {
			url:"/tests/basic/index.cfm?opt_run=true&reporter=Doc&target=tests.basic.malformedCookieTest",
			before: function(index) {
				writeoutput("before step " & index);

				cookies.sess_sid["value"] = "foo";
				//writedump(cookies);
			},
			after: function (index) {
				writeoutput("after step " & index);
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

</cfscript>

<!---<cfdump var="#cgi#" abort="true"/>--->


<cfset index = 0 />

<cfloop array="#steps#" index="step">
	<cfset index++ />

	<cfif structKeyExists(step, "before")>
		<cfset step.before(index) />
	</cfif>

	<cfset cookieString = getCookiesString(cookies) />

	<!---<cfdump var="#cookieString#" abort="false"/>--->
	<cfhttp url="http://#cgi.server_name##step.url#" method="GET" result="httpResult">
		<cfif len(cookieString)>
			<cfhttpparam type="header" name="Cookie" value="#cookieString#" />
		</cfif>
	</cfhttp>

	<cfset cookies = getResponseCookies(httpResult) />

	<!---<cfdump var="#cookies#" />
	<cfdump var="#getCookiesString(cookies)#" />--->
	<cfoutput>
		#httpResult.fileContent#

	</cfoutput>

	<cfif structKeyExists(step, "after")>
		<cfset step.after(index) />
	</cfif>


	<hr />
</cfloop>