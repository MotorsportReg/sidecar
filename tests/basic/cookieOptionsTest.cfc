component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis() / 1000;
	}


	function beforeAll () {
		application.sidecar._wipe_all();
		structDelete(request, application.sidecar.getCookieOptions().cookieName);

		application.sidecar.setCookieOptions(cookieName="someUniqueCookieName");

		application.sidecar.requestStartHandler();
	}

	function afterAll () {

	}

	function run () {

		describe("cookie tests", function () {

			it("should have a new cookie that is using our unique name", function() {

				expect(request).toHaveKey("someUniqueCookieName");
				expect(request.someUniqueCookieName).notToBeEmpty();
				expect(reReplace(listFirst(cookie.someUniqueCookieName, "."), "^s\:", "")).toBe(request.someUniqueCookieName);
				expect(request.someUniqueCookieName).toBe(application.sidecar.getSessionID());

			});

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});
		});

		describe("signatures", function () {

			it("should produce the same signature as node's cookie-signature module for compat", function() {

				makePublic(application.sidecar, "sign", "publicSign");

				//these inputs and outputs are values that were run through node-cookie-signature to obtain reference values
				expect( application.sidecar.publicSign( "b42527", "a" ) ).toBe("a.GgASGmQ1e95bMuS1woXgCTrIq3cVwALSUhIc0pzyz/Y");
				expect( application.sidecar.publicSign( "b42527", "adam" ) ).toBe("adam.Jrqs4C8bgqgd5J0MBNPPGE6YFNSD9uhYFz6cY74kz1g");
				expect( application.sidecar.publicSign( "b42527", "this is a test" ) ).toBe("this is a test.Az8Q+c+kASA7GroDGLUlzfvgMHHusWkyDgJnK1GTNIY");
				expect( application.sidecar.publicSign( "b42527", "ryan guill is the man" ) ).toBe("ryan guill is the man.AXdjwH9BGe6qUYkN/YZTiLn6EPm3r/F+KqHPdpuBCgY");

			});

		});

	}


}
