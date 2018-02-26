[QUnit - Kdb Unit Testing Framework](http://www.timestored.com/kdb-guides/kdb-regression-unit-tests)
======================================

For an HTML version with images see the timestored page on [kdb+ Unit Testing](http://www.timestored.com/kdb-guides/kdb-regression-unit-tests)

Intro to Unit Testing
-----------------------------------------------

QUnit is a framework for implementing testing in kdb. Unit tests target specific areas of a q program e.g. a single method. Once a test has been written, we can be sure that area of code works and in future if we change that area of code we can be sure that it still works.

The framework enforces a specific structure for tests, this encourages best practices and helps other team members quickly understand the code. Tests should be declared in a separate file within the source code directory and within the file, the functions should be in a namespace. QUnit relies on certain naming conventions detailed below to identify tests and setup routines.


Special Methods - QUnit Naming of functions
-----------------------------------------------

QUnit uses special naming conventions to denote tests, all test functions begin with test in their name. The framework will run these tests (order is not guaranteed) and provide a table of successes and failures. An example is shown test for checking that adding works as expected is shown below:

testAdd:{ .qunit.assertEquals[2+2; 4; "two plus two makes four"]};		

```
\d .mathTests
testAdd:{ .qunit.assertEquals[2+2; 4; "two plus two makes four"]};		
\d .
```

The table below details all of the prefixes which have a special purpose in qunit.

| Name Prefix      |	        Description                    |
|------------------|-------------------------------------------|
| test*	           | Identifies that this method is a test.    |
| setUp*	       | Code that should be ran before each test. |
| tearDown*	       | Code that should be ran before after test.|
| beforeNamespace* | Code that will be ran once, before any tests. |
| afterNamespace*  | Code that will be ran once, after all tests have been ran. |

The prefixes other than test are for setting up state before the tests. For example beforeNamespace could be used to open a handle to a remote database that provides test data, rather than reconnecting within each test. All functions should accept no arguments, any results returned from tests will be shown in the result table. Any errors within these setup/teardown functions will cause no tests to run.


Assert Statements
-----------------------------------------------

Qunit provides methods for asserting that the output of a function was valid. If one of these assertions fail, their message will be shown and the test will fail. The following assertions are currently provided:

| Name       |	        Description                    |
|------------------|-------------------------------------------|
assertEquals[actual; expected; msg] |	Assert that actual and expected value are equal. |
assertKnown:[actual; expectedFilename; msg] | Assert that actual matches the binary data in the expectedFilename. |
assertThat[actual; relation; expected; msg]	| Assert that the relation between expected and actual value holds |
assertTrue[actual; msg]	| Assert that actual is true |
assertError[func; arg; msg]	| Assert that executing a given function causes an error to be thrown |
fail[msg] |	Make the test fail with given message. |

AssertThat is likely to be most useful as it allows performing any comparison between expected and actual result. The resultEquals tries to be smarter and compare table column names and rows if it expects a table, so as to provide more meaningful output. Each assertion accepts a msg parameter that is there to allow the developer to give information if the test fails to allow others to debug the problem.

Example Test .q file
-----------------------------------------------

As seen in [q language style guidelines](http://www.timestored.com/kdb-guides/q-coding-standards) we recommended placing all related functions in one file/namespace. We recommend placing tests in a similarly named file and namespace. e.g. If you have functions for mathematical calculations in a file math.q, they would be placed in the namespace .math, .math.add[], .math.sub[] etc. The tests would then go in a file mathTest.q and the namespace .mathTest. As shown below:

### Example math.q file

```
/ Mathematical functions
system "d .math";

add:{x+y};
sub:{x-y};

/ given a circles radius, return it's area.
getAreaofCircle:{[r] -4*atan[-1]*r*r};

/ @return list of prime numbers less than it's argument
getPrimesLessThan:{$[x<4;enlist 2;r,1_where not any x#'not til each r:.z.s ceiling sqrt x]};

/ @return the product of all positive integers less than or equal to n only 
getFactorial:{$[x<2;1;x*.z.s x-1]};
```

### Example mathTest.q file

```
/ QUnit testing mathematical functions
system "d .mathTest";

testAdd:{.qunit.assertEquals[.math.add[2;2]; 4; "2 plus 2 equals four"]};

/ we use assert error as a projection to check an error is thrown for `two+2
testAddSymbol:{.qunit.assertError[.math.add[2;]; `two; "cant add symbol to int"]};

testSub:{ .qunit.assertTrue[.math.sub[2;2]~0; "2 minus 2 equals zero"] };

/ assert that allows using any relational operator for 
/ comparing actual and expected values.
testGetAreaofCircle:{ 
    r:.math.getAreaofCircle[1];
    .qunit.assertThat[r;<;3.1417; "nearly pi <"];
    .qunit.assertThat[r;>;3.1415; "nearly pi >"]};

testGetPrimesLessThanTen:{ 
    r:.math.getPrimesLessThan[10];
    .qunit.assertEquals[r; 2 3 5 7; "primes < 10 match"]};
    
testGetPrimesLessThanMinusOne:{ 
    r:.math.getPrimesLessThan[-1];
    .qunit.assertEquals[r; (); "no negative primes"]};
    
testGetFactorial:{ 
    r:.math.getFactorial 20; 
    .qunit.assertEquals[r; 2432902008176640000; "known factorial matches"]};
           
/ to set a max time we use the qunitconfig
/ a dictionary from test names to test parameters to their values
testGetFactorialSpeed:{ max .math.getFactorial each 10+100000?10 };
qunitConfig:``!();
qunitConfig[`testGetFactorialSpeed]:`maxTime`maxMem!(100;20000000);  
```

Running Tests
-----------------------------------------------

### From Command Line

Make sure you have your actual code loaded, qunit and our tests then call .qunit.runTests on the test namespace. The framework will then automatically find all tests and log the output of each test and assertion. Finally returning a table with one row per test. Where the sucess or failure together with time and memory required. (Tests assertions can be set on max time/memory). Notice below that our testGetPrimesLessThanMinusOne function failed and that we can see where we expected an empty list, it returned 2. 

```
q)\l math.q
q)\l qunit.q
q)\l mathTest.q
q).qunit.runTests `.mathTest
14:04:18.296  ########## .qunit.runTests `.mathTest ##########
14:04:18.296  test* found: `testAdd`testAddSymbol`testGetAreaofCircle`testGetPrimesLessThanMinusOne`testGetPrimesLessThanTen`testSub
14:04:18.297  #### .qunit.runTest `.mathTest.testAdd
14:04:18.298  passed -> 2 plus 2 equals four
14:04:18.300  .....

status name                                      result   actual expected msg                  time mem     ..
------------------------------------------------------------------------------------------------------------..
pass   .mathTest.testAdd                       4        `      `        `                    1    4195824 ..
pass   .mathTest.testAddSymbol                 "type"   `      `        `                    2    4196096 ..
pass   .mathTest.testGetAreaofCircle           3.141593 `      `        `                    1    4195824 ..
fail   .mathTest.testGetPrimesLessThanMinusOne ,2       ,2     ()       "no negative primes" 2    4196000 ..
pass   .mathTest.testGetPrimesLessThanTen      2 3 5 7  `      `        `                    1    4195936 ..
pass   .mathTest.testSub                       1b       `      `        `                    1    4195760 ..	
```

### qStudio Support

[qStudio kdb+ IDE](http://www.timestored.com/qstudio) has builtin support for [qunit](http://www.timestored.com/qstudio/help/qunit). Once your functions have been loaded onto your server you can press Ctrl + T to load qunit, load the tests and run them. Or you can also go "File Menu"->Query->"Unit Test Current Script". After a period the result panel should return a result atble with a row for each test and a pass or fail as shown in the screenshot above.

### Test Results

The result of running tests is a table with one row for each test. The table will contain the following columns:

    status - Whether the test passed or failed.
    name - The fully qualified name of the test.
    result - The return value of the test
    actual - If the test failed, this will contain the actual value for the failing assertion.
    expected - If the test failed, this will contain the expected value for the failing assertion.
    msg - Reason why the test assertion failed
    time - The time in milliseconds that the test took to run.
    mem - The memory in bytes that the test took to run.
    maxTime - The maximium time in milliseconds that the test is allowed to run, else it would fail.
    maxMem - The maximium memory in bytes that the test is allowed to run, else it would fail.


Parameters
-----------------------------------------------

Have you ever wanted to run the same tests but with a variety of configurations. In junit you use [parameterized tests](https://github.com/junit-team/junit4/wiki/parameterized-tests).  qUnit allows for a similar concept using .ns.parameters[] function to provide a list of the various configurations permitted.

Within your test namespace you can define a function e.g. ``.mathTest.parameters`` that returns a list for example with the values:(1 2;3 4). The test framework will then do 2 full runs of the tests. Once with ``.mathTest.parameter:1 2;`` and once with ``.mathTest.parameter:3 4;``. From each test you should access that parameter. The qunit result will contain a row for each test run and an additional column called parameter, saying what the configuration was when ran.

Special Methods:

| Name Prefix      |	        Description                    |
|------------------|-------------------------------------------|
| parameters | Function that returns a list of the various parameters to use. |
| beforeParameters* | Code that will be ran once, before any tests. |
| afterParameters*  | Code that will be ran once, after all tests have been ran. |

Note: The before/afterNamespace calls will now be ran before/after each parameterised run.

### Example Run
```
22:20:42.619  ########## .qunit.runTests `:: ##########
22:20:42.619  `.mathParametersTest.parameters
22:20:42.619  parameters = ((2 2;4);(1 5;6))
22:20:42.619  parameter = (2 2;4)
22:20:42.620  beforeNamespace* found: `
22:20:42.620  test* found: `testAdd
22:20:42.620  #### .qunit.runTest `.mathParametersTest.testAdd
22:20:42.620  afterNamespace* found: `
22:20:42.620  parameter = (1 5;6)
22:20:42.620  beforeNamespace* found: `
22:20:42.620  test* found: `testAdd
22:20:42.620  #### .qunit.runTest `.mathParametersTest.testAdd
22:20:42.620  afterNamespace* found: `
22:20:42.620
status name                        result actual expected msg                ..
-----------------------------------------------------------------------------..
pass   .mathParametersTest.testAdd 4      4      4        "Adding gives expec..
pass   .mathParametersTest.testAdd 6      6      6        "Adding gives expec..

```
