component skip="true" {
	this.name = "cf-sess-tests-" & "basic-" & hash(getCurrentTemplatePath());

	this.mappings["/lib"] = expandPath("../../lib");
	this.mappings["/com"] = expandPath("../../com");

	this.javasettings = {
		loadPaths = ["../../lib"],
		loadColdFusionClassPath = true,
		reloadOnChange = false,
		watchInterval = 60,
		watchExtensions = "jar,class"
	};

	this.sessionmanagement = false;

	private function getRedisClient () {
		local.redisHost = "localhost";  // redis server hostname or ip address
		local.redisPort = 6379;         // redis server ip address

		// Configure connection pool
		local.jedisPoolConfig = CreateObject("java", "redis.clients.jedis.JedisPoolConfig");

		//writedump(local.jedisPoolConfig.getFields());
		//writedump(getMetaData(local));abort;

		local.jedisPoolConfig.init();
		local.jedisPoolConfig.testOnBorrow = false;
		local.jedisPoolConfig.testOnReturn = false;
		local.jedisPoolConfig.testWhileIdle = true;
		//local.jedisPoolConfig.maxActive = 100;
		local.jedisPoolConfig.maxIdle = 5;
		local.jedisPoolConfig.numTestsPerEvictionRun = 10;
		local.jedisPoolConfig.timeBetweenEvictionRunsMillis = 10000;
		local.jedisPoolConfig.maxWaitMillis = 30000;

		local.jedisPool = CreateObject("java", "redis.clients.jedis.JedisPool");
		local.jedisPool.init(local.jedisPoolConfig, local.redisHost, local.redisPort);

		// The "cfc.cfredis" component name will change depending on where you put cfredis
		local.redis = CreateObject("component", "lib.cfredis").init();
		local.redis.connectionPool = local.jedisPool;

		return local.redis;
	}

	function appInit () {

		var redis = getRedisClient();
		var redlock = new lib.redlock([redis], {
				retryCount: 2,
				retryDelay: 150
			});

		var store = new com.redis_session_store(redis);
		var sess = new com.cf_sess();
			sess.setSessionStorage(store);
			sess.setSecrets("3", "4");


		lock scope="application" type="exclusive" timeout="1" throwOnTimeout=true {
			application.sess = sess;
		}

	}

	boolean function onApplicationStart () {
		//you do not have to lock the application scope
		//you CANNOT access the variables scope
		//uncaught exceptions or returning false will keep the application from starting
			//and CF will not process any pages, onApplicationStart() will be called on next request

		appInit();

		return true;
	}

/*
	void function onError (any exception, string eventName) {
		//You CAN display a message to the user if an error occurs during an
			//onApplicationStart, onSessionStart, onRequestStart, onRequest,
			//or onRequestEnd event method, or while processing a request.
		//You CANNOT display output to the user if the error occurs during an
			//onApplicationEnd or onSessionEnd event method, because there is
			//no available page context; however, it can log an error message.

		writedump(arguments);
		abort;
	}
*/

	boolean function onRequestStart (targetPage) {
		//you cannot access the variables scope
		//you CAN access the request scope

		//include "globalFunctions.cfm";

		if (!isNull(url.reinit) && url.reinit == true) {
			appInit();
		}

		application.sess.requestStartHandler();

		//returning false would stop processing the request
		return true;
	}

	void function onRequestEnd (targetPage) {
		//you can access page context
		//you can generate output
		//you cannot access the variables scope
		//you CAN access the request scope

		application.sess.requestEndHandler();
	}




}