component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {

	}

	function run () {

		describe("malformed cookie", function () {
			//this relies on the application.cfc having something that runs before the sidecar.requestStartHandler
			//to copy the original cookie into a request struct

			it("should have been a malformed cookie coming in, but a valid session cookie now", function() {
				expect(request).toHaveKey("originalCookieStruct");
				expect(request.originalCookieStruct).toHaveKey("sidecar_sid");
				expect(listLen(request.originalCookieStruct.sidecar_sid, ".")).notToBe(2);

				expect(request).toHaveKey("sidecar_sid");
				expect(request.sidecar_sid).notToBeEmpty();
				expect(listFirst(cookie.sidecar_sid, ".")).toBe(request.sidecar_sid);
				expect(request.sidecar_sid).toBe(application.sidecar.getSessionID());

			});

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});
		});


	}


}