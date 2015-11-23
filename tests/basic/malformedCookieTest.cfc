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
			//this relies on the application.cfc having something that runs before the sess.requestStartHandler
			//to copy the original cookie into a request struct

			it("should have been a malformed cookie coming in, but a valid session cookie now", function() {
				expect(request).toHaveKey("originalCookieStruct");
				expect(request.originalCookieStruct).toHaveKey("sess_sid");
				expect(listLen(request.originalCookieStruct.sess_sid, ".")).notToBe(2);

				expect(request).toHaveKey("sess_sid");
				expect(request.sess_sid).notToBeEmpty();
				expect(listFirst(cookie.sess_sid, ".")).toBe(request.sess_sid);
				expect(request.sess_sid).toBe(application.sess.getSessionID());

			});

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});

		});


	}


}