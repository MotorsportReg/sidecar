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


			it("should NOT have started a new session", function() {
				expect(request).notToHaveKey("sessionStarted");
			});


			it("should have request.sess_sid", function() {
				expect(request).toHaveKey("sess_sid");
				expect(request.sess_sid).notToBeEmpty();
			});

			it("should return the right value for a key thats been set", function() {
				var foo = application.sess.get("foo", "default");
				expect(foo).toBe("bar");
			});


			it("should let us know if a key exists or not", function() {
				var hasFoo = application.sess.has("foo");
				expect(hasFoo).toBe(true);
				var hasBar = application.sess.has("bar");
				expect(hasBar).toBe(false);
			});


			it("should allow us to clear a specific key", function() {
				var hasFoo = application.sess.has("foo");
				expect(hasFoo).toBe(true);

				application.sess.clear("foo");

				hasFoo = application.sess.has("foo");
				expect(hasFoo).toBe(false);

				var foo = application.sess.get("foo", "defaultValue", true);
				expect(foo).toBe("defaultValue");
			});

			it("should return the right sessionID", function() {
				expect(application.sess.getSessionID()).toBe(request.sess_sid);
			});

			it("should have the same sessionID as in the cookie", function() {
				expect(application.sess.getSessionID()).toBe(listFirst(cookie.sess_sid, "."));
			});

			it("should allow you to retrieve items stored as a collection individually", function() {

				expect(application.sess.get("one", "defaultValue", true)).toBe(1);
				expect(application.sess.get("one", "defaultValue", false)).toBe(1);
				var two = application.sess.get("two", "defaultValue", true);
				expect(two).toBeArray().toBe([1,2]);

				expect(application.sess.get("three", "defaultValue", true)).toBeDate();
				expect(application.sess.get("three", "defaultValue", false)).toBeDate();

				expect(application.sess.get("FOUR", "defaultValue", true)).toBe(4);
				expect(application.sess.get("FOUR", "defaultValue", false)).toBe(4);

				expect(application.sess.get("five", "defaultValue", true)).toBe("defaultValue");
				expect(application.sess.get("five", "defaultValue", false)).toBe("defaultValue");
				expect(application.sess.get("FIVE", "defaultValue", true)).toBe("defaultValue");
				expect(application.sess.get("FIVE", "defaultValue", false)).toBe("defaultValue");

			});

			it("should allow you to retrieve the entire session", function() {

				var s = application.sess.getEntireSession();

				expect(s).toBeStruct();

				expect(structKeyExists(s, "one")).toBeTrue();
				expect(s["one"]).toBe(1);
				expect(s.one).toBe(1);
				expect(s.two).toBeArray().toBe([1,2]);
				expect(s.three).toBeDate();
				expect(s.four).toBe(4);
				expect(structKeyExists(s, "five")).toBeFalse();
			});

		});


	}


}