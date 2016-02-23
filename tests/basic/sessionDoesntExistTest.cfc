component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();

	}


	function beforeAll () {
		application.sidecar._wipe_all();
		structDelete(request, application.sidecar.getCookieOptions().cookieName);
	}

	function afterAll () {
		application.sidecar._wipe_all();
	}

	function run () {

		describe("session doesnt yet exist", function () {


			it("should not allow you to set anything", function() {
				expect(function() {
					application.sidecar.set("foo", "bar");
				}).toThrow();

			});
			it("should allow destroy() without a session", function() {
				expect(function() {
					application.sidecar.destroy();
				}).notToThrow();
			});



		});


	}


}