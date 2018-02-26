/ QUnit testing mathematical functions - Demonstrating parameters
system "d .mathParametersTest";

/ Each item in the list returned from parameters[] gets ran as separate tests
/ When the test is ran the .mathParametersTest.parameter will hold the single current value.
parameters:{((2 2;4);(1 5;6))};

testAdd:{
    p:.mathParametersTest.parameter;
    numpair:p 0;
    .qunit.assertEquals[.math.add[numpair 0;numpair 1]; p 1; "Adding gives expected res"]};
