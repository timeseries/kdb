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
/ © TimeStored - Free for non-commercial use.

/ @TODO mocking projections are broken, add test and fix.

system "d .qunit";

EMPTYAR:`actual`expected`msg!```;
FAIL: "assertionFailed"; / exception thrown on assertion fail

/ Controls where known expected values are loaded from and new results are saved to
expectedPath:`:expected;
actualPath:`:actual;
currentNamespaceBeingTested:`;

debug:0b; / If true then do not run tests protected, i.e. break on assertion failures etc.
failFlag:0b;
r:1; / holder for result of \ts speed timing in runTests
ar:EMPTYAR; / holder for result of last assertion

mocks:{x!x}enlist (::); / dictionary from mock names to their original value etc.
unsetMocks:`$(); / list of variables that are mocked but were unset beforehand

lg:{a:string[.z.t],$[type[x]=98h; "\r\n"; "  "],$[type[x] in 10 -10h; x; .Q.s x],"\r\n"; l::l,enlist a; 1 a; x};

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
        lg "actual = ",-3!actual;];
    ar::`actual`expected`msg!(actual;expected;msg);
    if[failFlag; 'assertThatFAIL];
    actual};

// Make the test fail with given message. Useful for placing in 
// code areas that should never be ran or for marking incomplete test code.
fail:{ [msg] 
    failFlag::1b; 
    lg "FAILED -> ",msg;
    ar::`actual`expected`msg!(`fail;`;msg); 
    'fail};
            
// Assert that actual and expected value are equal
// @param actual An object representing the actual result value
// @param expected An object representing the expected value
// @param msg Description of this test or related message
// @return actual object
assertEquals:{ [actual; expected; msg]
    a:actual; e:expected; aTh:assertThat; / shortcuts
    ar::`actual`expected`msg!(actual;expected;msg);
    if[a~e; :a];
    if[.Q.qt e;
        if[failFlag::not .Q.qt actual; '"assertEquals expected an actual table"];
        if[failFlag::not (asc cols a)~asc cols e; '"assertEquals tables have same columns"];
        if[failFlag::not (count a)~count e; '"assertEquals tables have same number rows"];
        if[failFlag::not all/[a=e]; '"assertEquals tables have same data"];
        :a];
    assertThat[a;~;e;msg]};

/ Assert that the expectedFilename in the expectedPath contains a variable
/ that is equal to actual.
assertKnown:{ [expectedFilename; actual; msg]   
    makePath:.Q.dd[;currentNamespaceBeingTested,expectedFilename];
    e:@[get; makePath expectedPath; {`$"couldNotFindExpectedFilename ",x}];
    makePath[actualPath] set actual;
    assertEquals[actual; e; msg] };
    

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
    ar::`actual`expected`msg!(`noException;`ERR;msg);
    if[not (type func) within 100 104h; '"assertT first arg should be function type within 100 104h. ",msg];
    r:@[{(1b;x y)}[func;]; arg; {(0b; x)}];
    if[not failFlag;  
        if[failFlag::r 0; '"assertThrows Function never threw exception. ",msg];
        if[failFlag::not r[1] like (),exceptionLike; "exception like format expected: ",exceptionLike]];
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
    / no namespaces specified, find all ending with test
    nsl:$[11h~abs type nsList; nsList; `$".",/:string a where (lower a:key `) like "*test"]; 
    a:raze runNsTests each (),nsl;
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
    currentNamespaceBeingTested::ns;
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
    ar::EMPTYAR;
    // run setUp*
    ns:();
    if[2<=sum "."=a:string fn; 
        ns:`$(last ss[a;"."])#a;
        run each findFuncs[ns;"setUp*";0b]];
    // run actual test
/   r:@[{(1b; value[x] y)}[fn;]; ::; {(0b;x)}]; / safer non escaping version.
    r:value "{a:system \"ts .qunit.r:@[{(1b; value[`",string[fn],"] x)}; ::",$[debug;"";"; {(0b;x)}"],"];\"; `ran`result`time`mem!.qunit.r,a}[]";
    if[not r `ran; lg "test threw exception"];
    if[count ns; run each findFuncs[ns;"tearDown*";0b]];
    // cleanup dict format
    r[`status]: $[failFlag; `fail; $[not r `ran; `error; `pass]];
    r,:ar,`maxTime`maxMem#getConf fn; / show last assert on failure
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



//########## REPORTING FUNCTIONALITY ############ - Work in Progress

/ Generate an HTML report displaying the results of a test run
/ @param runTestsResult - Table returned from runTests
/ @param path - symbol - specifying locatin that HTML file is saved to
/ @param configDict - dictionary - to pass additional config at a later date (included now for backwards compatibility)
generateReport:{ [path; runTestsResult; configDict]
    f:hopen @[hdel; path; path];
    / body:toHtml each runTestsResult;
    f "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" > <head><meta http-equiv=\"content-type\" content=\"text/html; charset=iso-8859-1\" />";
    f "<style>tr.fail { background:red } td, th { padding:.1em; border:1px solid gray; }  table { border:1px solid gray; border-collapse:collapse; }</style>";
    f "<title>qUnit Tests</title></head><body><div id='inner'>";
    f "<h1><a href='http://www.timestored.com/kdb-guides/kdb-regression-unit-tests'>qUnit</a> Tests</h1>";
    f formatTable runTestsResult;
    testToHtml:{ [f; testDict]
        f "<hr /><h2>",string[testDict`name],"</h2><p>",testDict[`msg],"</p>";
        f "<h4>Actual</h4>",format[testDict`actual],"<h4>Expected</h4>",format[testDict`expected]; 
        };
    testToHtml[f;] each select from runTestsResult where status=`fail;
    f "</div> <div class='footer'><p><a href='http://www.timestored.com/kdb-guides/kdb-regression-unit-tests'>qUnit</a> | <a href='http://www.TimeStored.com/'>TimeStored.com</a> | <a href='http://www.timestored.com/kdb-training/'>kdb+ Training</a> </p></div></body></html>";
    hclose f;
    };

/ Display an HTML table
formatTable:{  [t]
    w:{ a:string[x],">"; l:y,"<",a; r:"</",a; l,((r,l) sv z),r};
    header:.h.htc[`tr;]  w[`th;"\t";string cols t];
    flatten:({"\t" sv x} each {.h.htc[`td;] .h.hc $[10h=type a:string x; a; .Q.s1 x]}'');
    content:"\r\n" sv {.h.htac[`tr; enlist[`class]!enlist `asads; x] } each flatten flip value flip t;
    .h.htc[`table;] (.h.htc[`thead;] header),content}; 

/ Display any kdb object as HTML
format:{ [o]  $[.Q.qt o; formatTable o; .Q.s o]};
