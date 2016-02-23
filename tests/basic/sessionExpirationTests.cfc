component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis() / 1000;
	}


	function beforeAll () {
	}

	function afterAll () {
		application.sidecar._wipe_all();
	}

	function run () {

		describe("session expiration", function () {


			//this relies on the session timeout being 5 seconds
			it("should cleanup all expired sessions", function() {
				application.sidecar.requestEndHandler();

				expect(application.sidecar._getAllSessions()).notToBeEmpty("should have some existing sessions");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(6 * 1000);

				expect(application.sidecar._getExpiredSessions()).notToBeEmpty("There should now be some session to clean up");

				application.sidecar.requestEndHandler();

				//all sessions should be gone
				expect(application.sidecar._getAllSessions()).toBeEmpty("all session should be gone at this point");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("no sessions means no expired sessions");

			});


			it("should allow us to set a custom expiration on a session by session basis", function() {

				application.sidecar.requestEndHandler();

				application.sidecar.requestStartHandler();

				application.sidecar.setSessionTimeout(10); //10 seconds

				expect(arrayLen(application.sidecar._getAllSessions())).toBe(1, "Should have 1 session");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(6 * 1000);

				//this shouldnt be long enough to expire that session
				expect(arrayLen(application.sidecar._getAllSessions())).toBe(1, "Should have 1 session");
				var expiredSessions = application.sidecar._getExpiredSessions();
				if (arrayLen(expiredSessions) != 0) {
					writedump(unixTime());
					writedump(application.sidecar.getEntireSession());
					writedump(request);
					writedump(expiredSessions);abort;
				}
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				sleep(5 * 1000);

				expect(application.sidecar._getExpiredSessions()).notToBeEmpty("There should now be some session to clean up");

				application.sidecar.requestEndHandler();

				//all sessions should be gone
				expect(application.sidecar._getAllSessions()).toBeEmpty("all session should be gone at this point");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("no sessions means no expired sessions");

			});

			it("should allow us to call destroy on a single session", function() {
				application.sidecar.requestEndHandler();

				application.sidecar.requestStartHandler();

				expect(arrayLen(application.sidecar._getAllSessions())).toBe(1, "Should have 1 session");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There shouldn't be any sessions yet to clean up");

				var sessionID = application.sidecar._getAllSessions()[1];

				application.sidecar.destroy();

				expect(arrayLen(application.sidecar._getAllSessions())).toBe(1, "should be a new session started");

				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There still shouldn't be any sessions yet to clean up");
			});


			it("should allow us to still use a session after it has been destroyed", function() {
				application.sidecar.requestEndHandler();

				application.sidecar.requestStartHandler();

				application.sidecar.set("foo", "bar");
				expect(application.sidecar.get("foo", "default", true)).toBe("bar");

				application.sidecar.destroy();

				expect(application.sidecar.get("foo", "default", true)).toBe("default");

				expect(arrayLen(application.sidecar._getAllSessions())).toBe(1, "should be a new session started");
				expect(application.sidecar._getExpiredSessions()).toBeEmpty("There still shouldn't be any sessions yet to clean up");

				application.sidecar.set("foo", "bar");

				expect(application.sidecar.get("foo", "default", true)).toBe("bar");
			});

		});




	}


}