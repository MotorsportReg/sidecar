component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();

	}


	function beforeAll () {
		application.sess._wipe_all();
		structDelete(request, application.sess.getCookieOptions().cookieName);
	}

	function afterAll () {
		application.sess._wipe_all();
	}

	function run () {

		describe("session doesnt yet exist", function () {


			it("should not allow you to set anything", function() {
				expect(function() {
					application.sess.set("foo", "bar");
				}).toThrow();

			});
			it("should allow destroy() without a session", function() {
				expect(function() {
					application.sess.destroy();
				}).notToThrow();
			});



		});


	}


}