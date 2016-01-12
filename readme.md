
##Todo:

[ ] `setCookieOptions()` testing, especially setting a custom cookie name
[ ] `ability to override session timeout on a per-session basis`



## How to run the tests

1. Download testbox from: http://www.ortussolutions.com/products/testbox
2. Unzip the testbox/ folder into the root of the application (as a peer to tests)
3. The tests expect a redis instance to be running on localhost:6379, edit the top of /tests/basicTest.cfc if your instance is different
3. run /tests/index.cfm - will run the individual tests under basic remotely to be able to set the cookie headers

