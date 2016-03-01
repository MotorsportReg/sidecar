component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {

	}

	function run () {

		describe("baseline environment", function () {

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});

			it("should have request.sidecar_sid", function() {
				expect(request).toHaveKey("sidecar_sid");
				expect(request.sidecar_sid).notToBeEmpty();
			});

			it("should give a default value for a non-existant key", function() {
				var foo = application.sidecar.get("foo", "default");
				expect(foo).toBe("default");
			});

			it("should return the right value for a key thats been set", function() {
				application.sidecar.set("foo", "bar");
				var foo = application.sidecar.get("foo", "default");
				expect(foo).toBe("bar");
			});

			it("should let us know if a key exists or not", function() {
				application.sidecar.set("foo", "bar");
				var hasFoo = application.sidecar.has("foo");
				expect(hasFoo).toBe(true);
				var hasBar = application.sidecar.has("bar");
				expect(hasBar).toBe(false);
			});

			it("should return the right sessionID", function() {
				expect(application.sidecar.getSessionID()).toBe(request.sidecar_sid);
			});

			it("should have the same sessionID as in the cookie", function() {
				expect(application.sidecar.getSessionID()).toBe(listFirst(cookie.sidecar_sid, "."));
			});

			it("should allow you to store a collection at once", function() {

				//you have to use quotes for the collection or the keys will be stored in redis as UPPERCASE
				var coll = {
					"one": 1,
					"two": [1,2],
					"three": now(),
					four: 4
				};

				application.sidecar.setCollection(coll);

				expect(application.sidecar.get("one", "defaultValue", true)).toBe(1);

				var two = application.sidecar.get("two", "defaultValue", true);
				expect(two).toBeArray().toBe([1,2]);

				expect(application.sidecar.get("three", "defaultValue", true)).toBeDate();

				expect(application.sidecar.get("FOUR", "defaultValue", true)).toBe(4);

				expect(application.sidecar.get("five", "defaultValue", true)).toBe("defaultValue");
				expect(application.sidecar.get("FIVE", "defaultValue", true)).toBe("defaultValue");

			});

			it("should store and retrieve a struct properly", function() {
				var structTest = {
					one: 1,
					two: 2,
					three: [1,2,3]
				};

				application.sidecar.set("structTest", structTest);

				var output = application.sidecar.get("structTest", "default", true);

				expect(output).toBeStruct();
				expect(output).toBe(structTest);
			});


		});


	}


}