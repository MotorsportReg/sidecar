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


			it("should allow us to set a custom expiration on a session by session basis", function() {

				application.sess.requestEndHandler();

				application.sess.requestStartHandler();

				application.sess.setSessionTimeout(10); //10 seconds

				expect(arrayLen(application.sess._getAllSessions())).toBe(1, "Should have 1 session");
				expect(application.sess._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(6 * 1000);

				//this shouldnt be long enough to expire that session
				expect(arrayLen(application.sess._getAllSessions())).toBe(1, "Should have 1 session");
				expect(application.sess._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(5 * 1000);

				expect(application.sess._getExpiredSessions()).notToBeEmpty("There should now be some session to clean up");

				application.sess.requestEndHandler();

				//all sessions should be gone
				expect(application.sess._getAllSessions()).toBeEmpty("all session should be gone at this point");
				expect(application.sess._getExpiredSessions()).toBeEmpty("no sessions means no expired sessions");

			});

		});


	}


}