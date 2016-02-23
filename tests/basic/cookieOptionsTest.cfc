component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis() / 1000;
	}


	function beforeAll () {
		application.sidecar._wipe_all();
		structDelete(request, application.sidecar.getCookieOptions().cookieName);

		application.sidecar.setCookieOptions(cookieName="someUniqueCookieName");

		application.sidecar.requestStartHandler();
	}

	function afterAll () {

	}

	function run () {

		describe("cookie tests", function () {

			it("should have a new cookie that is using our unique name", function() {

				expect(request).toHaveKey("someUniqueCookieName");
				expect(request.someUniqueCookieName).notToBeEmpty();
				expect(listFirst(cookie.someUniqueCookieName, ".")).toBe(request.someUniqueCookieName);
				expect(request.someUniqueCookieName).toBe(application.sidecar.getSessionID());

			});

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});
		});


	}


}