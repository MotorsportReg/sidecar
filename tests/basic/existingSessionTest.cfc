component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {

	}

	function run () {

		describe("existing Session", function () {
			it("should have request.sess_sid", function() {
				expect(request).toHaveKey("sess_sid");
				expect(request.sess_sid).notToBeEmpty();
			});

			it("should return the right value for a key thats been set", function() {
				var foo = application.sess.get("foo", "default");
				expect(foo).toBe("bar");
			});

			it("should return the right sessionID", function() {
				expect(application.sess.getSessionID()).toBe(request.sess_sid);
			});

			it("should have the same sessionID as in the cookie", function() {
				expect(application.sess.getSessionID()).toBe(listFirst(cookie.sess_sid, "."));
			});


		});


	}


}