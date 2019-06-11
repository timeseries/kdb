.cserveTest.testSmartSelectRDBhdbWithDates[]    

show -10 sublist rr:.qunit.runTests[]; system "rmdir expected /s /q && move actual expected"; @[hclose;;`] each key .z.W

.qunit.ignoreAllExceptions:not .qunit.ignoreAllExceptions
rr:.qunit.runTests[]; rr

f:.cserve.smartSelect[rdbAB; ; ()!()] 
    f "select from t where a in 1 2"
    ; / unkeyed result over multi RDB is razed
    f "select b by mport from t where a in 1 2"
    ; / keyed query without overlap works

(rr 19) `msg
(rr 19) `actual
(rr 19) `expected

(.cserve.smartSelect[`a; ; ()!()]) 0N! ("select from t where ",/:wcs) 10


(.cserve.smartSelect[`a; ; ()!()]) "select from t where date in (.z.d,2011.01.01)"
