/ QUnit testing utility functions
system "d .utilTest";

testCall:{.qunit.assertEquals[.util.call[{x+1};1]; 2; "1 plus 1 equals two"]};
testCallFast:{.qunit.assertEquals[.util.callFast[{x+1};1]; 2; "1 plus 1 equals two"]};
testSys:{.qunit.assertEquals[.util.sys "echo 1"; enlist "1"; "1 plus 1 equals two"]};

/ we use assert error as a projection to check an error is thrown for `two+2
testCallError:{.qunit.assertError[.util.call[{x+1};]; `two; "cant add symbol to int"]};

testApply:{.qunit.assertEquals[.util.apply[{x+1};1]; 1b; "successfull apply returns 1b"]};
testApplyError:{.qunit.assertEquals[.util.apply[{x+1};`a]; 0b; "failed apply returns 0b"]};
