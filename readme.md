
#Sidecar - external session management and storage for ColdFusion

[ ![Codeship Status for MotorsportReg/sidecar](https://codeship.com/projects/e2f0a470-c060-0133-5fa9-0a9636267e9d/status?branch=master)](https://codeship.com/projects/137244)

## Dependencies
This project depends on the following projects:

- [cfml-redlock](https://github.com/MotorsportReg/cfml-redlock)
- [cfredis](https://github.com/MWers/cfredis)
- [jedis](https://github.com/xetorthio/jedis)
- [Apache Commons Pool](https://commons.apache.org/proper/commons-pool/download_pool.cgi)


##Support
Adobe ColdFusion 10+, Lucee 4.5+


##Todo:

- [ ] `setCookieOptions()` testing, especially setting a custom cookie name
- [ ] `_getEntireRequestCache()` testing

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
