component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {
		application.sess._wipe_all();
	}

	function run () {

		describe("session expiration", function () {


			//this relies on the session timeout being 5 seconds
			it("should cleanup all expired sessions", function() {
				application.sess.requestEndHandler();

				expect(application.sess._getAllSessions()).notToBeEmpty("should have some existing sessions");
				expect(application.sess._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(6 * 1000);

				expect(application.sess._getExpiredSessions()).notToBeEmpty("There should now be some session to clean up");

				application.sess.requestEndHandler();

				//all sessions should be gone
				expect(application.sess._getAllSessions()).toBeEmpty("all session should be gone at this point");
				expect(application.sess._getExpiredSessions()).toBeEmpty("no sessions means no expired sessions");

			});

		});


	}


}