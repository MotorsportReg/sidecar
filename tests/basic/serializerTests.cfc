component extends="testbox.system.BaseSpec" {

	function beforeAll () {}
	function afterAll () {}

	function serializeWrapper( data ){
		return serializeJson( arguments.data );
	}
	function deserializeWrapper( data ){
		return deserializeJSON( arguments.data );
	}

	function run () {

		describe("(de)serializers", function () {


			it("should work together end-to-end", function() {
				application.sidecar.setSerializerFunction( serializeWrapper );
				application.sidecar.setDeserializerFunction( deserializeWrapper );
				application.sidecar.set("foo", { 'object': 'default' });
				var foo = application.sidecar.get("foo");
				expect(foo).toBe({ 'object': 'default' });
			});


		});


	}


}
