/ Unit testing for q similar to junit, cunit etc.       <br/>
/ Tests should be specified in their own file/namespace       <br/>
/ Actual test functions should then be named test* and contain assertions.       <br/>
/ <br/>
/ Tests can either pass/fail/exception. Failure is caused by an assert failing.
/ You have the option of configuring qunit to halt on failed assertions allowing
/ you to step into the code at that point.
/ .
/ @author TimeStored.com
/ @website http://www.timestored.com/kdb-guides/kdb-regression-unit-tests

system "d .qunit";

EMPTYAR:`actual`expected`msg!```;
FAIL: "assertionFailed"; / exception thrown on assertion fail

breakOnExceptions:0b;
failFlag:0b;
r:1; / holder for result of \ts speed timing in runTests
ar:EMPTYAR; / holder for result of last assertion

mocks:{x!x}enlist (::); / dictionary from mock names to their original value etc.
unsetMocks:`$(); / list of variables that are mocked but were unset beforehand

lg:{a:string[.z.t],"  ",$[type[x] in 10 -10h; x; .Q.s x],"\r\n"; l::l,enlist a; 1 a; x};

// Assert that the relation between expected and actual value holds
// @param actual An object representing the actual result value
// @param expected An object representing the expected value
// @param msg Description of this test or related message
// @return actual object
assertThat:{ [actual; relation; expected; msg]
    failFlag::not .[relation; (actual; expected); 0b];
    lg $[failFlag; "FAILED"; "passed"]," -> ",msg;
    if[failFlag;
        lg "expected = ",-3!expected;
        lg "actual = ",-3!actual;
        ar::`actual`expected`msg!(actual;expected;msg);];
    if[breakOnExceptions and failFlag; 'FAIL];
    actual};

// Make the test fail with given message. Useful for placing in 
// code areas that should never be ran or for marking incomplete test code.
fail:{ [msg] failFlag::1b; 
    lg "FAILED -> ",msg;
    ar::`actual`expected`msg!(`fail;`;msg); 
    `fail};
            
// Assert that actual and expected value are equal
// @param actual An object representing the actual result value
// @param expected An object representing the expected value
// @param msg Description of this test or related message
// @return actual object
assertEquals:{ [actual; expected; msg]
    a:actual; e:expected; aTh:assertThat; / shortcuts
    if[.Q.qt e;
        aTh[1b;~; .Q.qt actual;"expected an actual table"];
        if[not failFlag; aTh[asc cols a; ~; asc cols e;"tables have same columns"]];
        if[not failFlag; aTh[count a; ~; count e;"tables have same number rows"]];
        if[not failFlag; assertTrue[all/[a=e];"tables have same data"]];
        :a];
    assertThat[a;~;e;msg]};

// Assert that executing a given function causes an error to be thrown
// @param func A function that takes a single argument
// @param arg The argument for the function
// @param msg Description of this test or related message
// @return result of running function.
assertError:{ [func; arg; msg]   
    assertThrows[func; arg; "*"; msg] };

// Assert that executing a given function causes specific exception to be thrown
// @param exceptionLike A value that is used to check the likeness of an exception e.g. "type*"
assertThrows:{ [func; arg; exceptionLike; msg] 
    assertThat[type func; within; 100 104h; "assertError first arg should be function type within 100 104h. ",msg];
    r:@[{(1b;x y)}[func;]; arg; {(0b; x)}];
    if[not failFlag;  
        assertTrue[not r 0; "Function failed.",msg];
        assertTrue[r[1] like (),exceptionLike; "exception like format expected: ",exceptionLike]];
    ar::`actual`expected`msg!(r 1;`ERR;msg); 
    r 1};
    
// assert that actual is true
// @param msg Description of this test or related message
// @return actual object
assertTrue:{ [actual; msg]  assertThat[actual;=;1b; msg]};

/ Run all tests in selected namespaces, return table of pass/fails/timings.
/ @param nsList symbol list of namespaces that contains test e.g. `.mytests`yourtests
/ @return a table containing one row for each test, detailing if it passed/failed.
/ @throws nsNoExist If the namespace you selected does not exist.
runTests:{ [nsList] 
    l::("  ";"   ");
    lg "\r\n"; lg "########## .qunit.runTests `",("`" sv string (),nsList)," ##########";
    a:raze runNsTests each (),nsList;
    lg $[count a; update namespace:nsList from a; 'noTestsFound]};

/ find functions with a certain name pattern within the selected namespace
/ @logEmpty If set to true write to log that no funcs found otherwise stay silent
findFuncs:{ [ns; pattern; logEmpty]
        fl:{x where x like y}[system "f ",string ns; pattern];
        if[logEmpty or 0<count fl; lg pattern," found: `","`" sv string fl];
        $[ns~`.; fl; `${"." sv x} each string ns,/:fl]};

/ attempt to run 0-arg function or throw an error
run:{@[value lg x;::;{'lg "setUpError",x}]};        
        

/ Run all tests for a single namespace, return table of pass/fails/timings.
/ @return table of results, or empty list if no tests found
/ @param ns symbol specifying a single namespace to test e.g. `.mytests
runNsTests:{ [ns]
    if[not (ns~`.) or (`$1_string ns) in key `; 'nsNoExist]; // can't find namespace
    ff:findFuncs[ns;;1b];
    run each ff "beforeNamespace*";
    testList: ff "test*";
    c: runTest each  testList;
    run each ff "afterNamespace*";
    $[count c; `status`name`result`actual`expected`msg`time`mem xcols update name:testList from c; ()] };
    
/ for fully specified test function in namespace get its config dictionary.
getConf:{ [fn]     
    d:`maxTime`maxMem!(0Wj;0Wj); / default
    conf: @[{{ .[`$".",string x 1;`qunitConfig,x 2] }` vs x}; fn; ``!``];
    $[99h~type conf; d,conf; d]};
    
/ protectively evaluate a single test. 
/ @return dictionary of test success/failure, name, result etc.
runTest:{ [fn]
    lg "#### .qunit.runTest `",string fn;
    // check single arg function
    validTest:$[100h~type vFn:value fn; $[1~count (value vFn) 1; 1b; 0b]; 0b];
    if[not validTest; :(0b;0b;"test should be single arg function")];
    failFlag:: 0b;
    // run setUp*
    ns:();
    if[2<=sum "."=a:string fn; 
        ns:`$(last ss[a;"."])#a;
        run each findFuncs[ns;"setUp*";0b]];
    // run actual test
/   r:@[{(1b; value[x] y)}[fn;]; ::; {(0b;x)}]; / safer non escaping version.
    r:value "{a:system \"ts .qunit.r:@[{(1b; value[`",string[fn],"] x)}; ::; {(0b;x)}];\"; `ran`result`time`mem!.qunit.r,a}[]";
    if[not r `ran; lg "test threw exception"];
    if[count ns; run each findFuncs[ns;"tearDown*";0b]];
    // cleanup dict format
    r[`status]: $[not r `ran; `error; $[failFlag; `fail; `pass]];
    r,:$[failFlag; ar; EMPTYAR],`maxTime`maxMem#getConf fn; / show last assert on failure
    if[not[failFlag] and any r[`time`mem]>r`maxTime`maxMem;
        r[`status`msg]:(`fail;"exceeeded max config time/mem")];
    `ran _ r};    
    
mock:{ [name; val]
    r:@[{(1b;value x)}; name;00b];
    / if variable has an existing value
    $[(not name in unsetMocks) and first r;
        [if[not name in key mocks; mocks[name]:r 1]]; / store original value 
        unsetMocks,:name];
    / make sure func declared in same ns as any existing function        
    if[100h~type fn:mocks name;
        lg "isFunc";
        ns:string first (value fn) 3;
        lg "ns = ",ns;
        v:string $[ns~"";name;last ` vs name];
        lg "v = ",v;
        runInNs[ns; v,":",string val];
        :name];
    / else
    name set val}; 

/ Run a string of code in a given namespace. 
runInNs:{ [ns; code]
    cd:system "d";
    system "d .",ns;
    value code;
    system "d ",string cd;};
    
/ delete a variable of format `.ns.name whether it's defnined in ns or not
removeVar:{ [name]
    // two cases to cover if defined in ns or not
    @[ {![`.;();0b;enlist x]}; name; `]; 
    @[ {n:` vs x; ![`$".",string n 1;();0b;enlist n 2]}; name; `]; };

/ Reset any variables that were mocked
/ @return the list of variables unmocked.
reset:{ [names]
    / if no arg, then remove all variables
    n:$[names~(::); unsetMocks union key 1 _ mocks; (),names];
    / remove those that were unset
    removeVar each n inter unsetMocks;
    unsetMocks::unsetMocks except n;
    / remove cached original values
    k:n inter key mocks;
    k set' mocks k;
    emptyDict:{x!x}enlist (::);
    mocks::emptyDict,k _ 1 _ mocks; / the sentinal causes remove problems
    n };
