
#Sidecar - external session management and storage for ColdFusion

[![Build Status](https://travis-ci.org/MotorsportReg/sidecar.svg?branch=master)](https://travis-ci.org/MotorsportReg/sidecar)

## Version 1.0.0

Updating version to 1.0.0 as of 2017-02-03.  If you update from a previous version there were changes that will break backwards compat of existing sessions, so when you update all of your sessions will be restarted.  You also may want to clean up your store manually just to be sure there is no sessions that hang on longer than they should.

## Dependencies
This project depends on the following projects:

- [cfml-redlock](https://github.com/MotorsportReg/cfml-redlock)
- [cfredis](https://github.com/MWers/cfredis)
- [jedis](https://github.com/xetorthio/jedis)
- [Apache Commons Pool](https://commons.apache.org/proper/commons-pool/download_pool.cgi)


## Support
Adobe ColdFusion 10+, Lucee 4.5+


## Todo:

- [ ] `setCookieOptions()` testing, especially setting a custom cookie name
- [ ] `_getEntireRequestCache()` testing

## Configuring your application and using Sidecar

Coming soon

## Express-session compatibility

While Sidecar was heavily inspired by [express-session](https://github.com/expressjs/session), it was not originally written as a direct port and is not compatible using the default settings. In order to be able to read and write your CFML+Sidecar session data, on Redis, from a Node.js application using express-session, you need to use the included **express_redis_session_store.cfc** store adapter instead of the usual **redis_session_store.cfc**.

There is only one other change necessary from normal Sidecar usage: Your Sidecar (de)serializer functions need to be no-operation functions to prevent double serialization:

```js
sidecar.setSerializerFunction( function(d){ return d; } );
sidecar.setDeserializerFunction( function(d){ return d; } );
```

### Trade-offs for express-session compatibility

- Slightly less time-efficient
- Loss of `onSessionEnd()` callback support
- Loss of `_getAllSessions()` method

**Slightly less time-efficient**

The express-session compatible store adapter will store your data in the same way that express-session does. From CFML platforms, this approach is slightly less efficient than Sidecar's usual approach. The standard adapter will use a Redis hash for each session, with keys for each session variable; and the express-session approach is to use a Redis string key containing the session data as an object (CFML struct) stored serialized to JSON.

The express-session adapter will only read the session data from redis once per request, the first time it is requested, and caches it in the request scope. All writes update both Redis and the request scope cache. If you need to set multiple keys you can use `sidecar.setCollection()` to make this more efficient: 1 Redis write per collection, rather than per key.

This also means that unlike CFML sessions, data set during a request is not shared with other requests until the end of the request, not at the time it is being set instead of the way the redis_session_store sets and gets from redis when requested and so the updated value would be available to other requests immediately.  Also the redis_session_store only retrieves values in the session that you request specifically, the expression-session compatible version will retrieve all session values at the beginning of the request.  

While the express-session store adapter is slightly less efficient than standard Sidecar usage, this can be an acceptable trade-off if you need session data to be portable between Node.js and CFML.

**Loss of `onSessionEnd()` callback support**

Express-session typically relies on Redis TTL to expunge expired sessions; whereas the standard Sidecar approach expunges them manually. The express-session compatible store adapter does away with the session index and expiration keys in favor of a Redis TTL approach. However, since Sidecar is no longer evicting expired sessions manually, it can no longer call the `onSessionEnd()` callback.

**Loss of `_getAllSessions()` method**

As a result of removing the session expiration index, there is now no way to get a list of all active session id's. While part of Sidecar's public API, at present this method is only used for testing Sidecar.

Note: an alternative would be to use a different store with your express-session that matched sidecar semantics instead - doing so and researching the pros and cons of such a solution is currently left as an exercise for the reader.

## How to run the tests

1. Download testbox from: http://www.ortussolutions.com/products/testbox
2. Unzip the testbox/ folder into the root of the application (as a peer to tests)
3. The tests expect a redis instance to be running on localhost:6379, edit the top of /tests/basicTest.cfc if your instance is different
3. run /tests/index.cfm - will run the individual tests under basic remotely to be able to set the cookie headers

Or, if you use docker / docker-compose, you can use the included docker-compose file.

1. Clone the project.
2. `docker-compose up -d`
3. Hit the docker ip address on port 80.

You could swap out the `app` service with lucee or other coldfusion version if you would rather use that.

## License

This software is licensed under the Apache 2 license, quoted below.

Copyright 2016 MotorsportReg
Copyright 2016 Ryan Guill <ryanguill@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.
