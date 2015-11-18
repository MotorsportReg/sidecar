component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {

	}

	function run () {
		application.sess.set("foo", "bar2");

		dump(application.sess.get("foo"));

		//application.sess.destroy();
	}


}