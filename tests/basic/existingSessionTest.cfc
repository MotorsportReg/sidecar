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


			it("should have request.sidecar_sid", function() {
				expect(request).toHaveKey("sidecar_sid");
				expect(request.sidecar_sid).notToBeEmpty();
			});

			it("should return the right value for a key thats been set", function() {
				var foo = application.sidecar.get("foo", "default");
				expect(foo).toBe("bar");
			});


			it("should let us know if a key exists or not", function() {
				var hasFoo = application.sidecar.has("foo");
				expect(hasFoo).toBe(true);
				var hasBar = application.sidecar.has("bar");
				expect(hasBar).toBe(false);
			});


			it("should allow us to clear a specific key", function() {
				var hasFoo = application.sidecar.has("foo");
				expect(hasFoo).toBe(true);

				application.sidecar.clear("foo");

				hasFoo = application.sidecar.has("foo");
				expect(hasFoo).toBe(false);

				var foo = application.sidecar.get("foo", "defaultValue", true);
				expect(foo).toBe("defaultValue");
			});

			it("should return the right sessionID", function() {
				expect(application.sidecar.getSessionID()).toBe(request.sidecar_sid);
			});

			it("should have the same sessionID as in the cookie", function() {
				expect(application.sidecar.getSessionID()).toBe(reReplace(listFirst(cookie.sidecar_sid, "."), "^s\:", ""));
			});

			it("should allow you to retrieve items stored as a collection individually", function() {

				expect(application.sidecar.get("one", "defaultValue", true)).toBe(1);
				expect(application.sidecar.get("one", "defaultValue", false)).toBe(1);
				var two = application.sidecar.get("two", "defaultValue", true);
				expect(two).toBeArray().toBe([1,2]);

				expect(application.sidecar.get("three", "defaultValue", true)).toBeDate();
				expect(application.sidecar.get("three", "defaultValue", false)).toBeDate();

				expect(application.sidecar.get("FOUR", "defaultValue", true)).toBe(4);
				expect(application.sidecar.get("FOUR", "defaultValue", false)).toBe(4);

				expect(application.sidecar.get("five", "defaultValue", true)).toBe("defaultValue");
				expect(application.sidecar.get("five", "defaultValue", false)).toBe("defaultValue");
				expect(application.sidecar.get("FIVE", "defaultValue", true)).toBe("defaultValue");
				expect(application.sidecar.get("FIVE", "defaultValue", false)).toBe("defaultValue");

			});

			it("should allow you to retrieve the entire session", function() {

				var s = application.sidecar.getEntireSession();

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
