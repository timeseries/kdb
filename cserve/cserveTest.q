system "d .cserveTest";
        
rdbA:`app`proc!(`a;`rdb);
rdbAB:`app`proc!(`a`b;`rdb);

checkQuery:.qunit.assertKnownRun[.cserve.runQuery[;"select from t where a in 1 2"];];

/###  Testing that various levels of filter work    
testRunQueryDictionarySFilter:{ checkQuery `app`proc!(`a;`rdb)};
testRunQueryListSFilter:{ checkQuery `a`rdb };
/ Currently wont work as RDB/HDB stitching doesn't work
/ testRunQueryAtomSFilter:{ checkQuery[`a;"select from t where a in 1 2"] };

/###  Testing that various formats of query work
checkQueryRDBa:.qunit.assertKnownRun[.cserve.runQuery[rdbA;];];
testRunQueryQryString:{[] checkQueryRDBa "select from t where a in 1 2" };
/ Note the hack. Since tests are in a namespace, need to reference t this way to get the global
testRunQueryQryFunction:{[] checkQueryRDBa {select from @[`.;`t] where a in 1 2} };
testRunQueryQryProjection:{[] checkQueryRDBa {[l;x] select from @[`.;`t] where a in l}[1 2;] };
testRunQueryQryList:{[] checkQueryRDBa ({[l] select from @[`.;`t] where a in l};1 2) };

/###  Testing we get the results expected    
checkQueryResult:{ [sFilter; qry; expectedR]
    t:.cserve.runQuery[sFilter; qry];
    .qunit.assertEquals[exec r from t; expectedR; "result r as expected:",.Q.s t] }; 

testRunQueryAtomResult1Proc:{ checkQueryResult[rdbA; "2+2";enlist 4] };
testRunQueryTblResult1Proc:{ checkQueryResult[rdbA; "([] g:1 2)";enlist ([] g:1 2)] };
testRunQueryAtomResult2Proc:{ checkQueryResult[rdbAB; "2+2"; (4;4)] };
testRunQueryTblResult2Proc:{ checkQueryResult[rdbAB; "([] g:1 2)";2#enlist ([] g:1 2)] };
testRunQueryListResult1Proc:{ checkQueryResult[rdbA; "1 2 3";enlist 1 2 3] };
testRunQuerySingletonListResult1Proc:{ checkQueryResult[rdbA; "enlist 1";enlist enlist 1] };

testRunQueryDictResult1Proc:{ 
    t:.cserve.runQuery[rdbA; "`a`b!1 2"];
    .qunit.assertKnown[exec r from t; `:oddDictionary; "Weird dictionary matches stored val"] };

/### test .cserve.i.convertToTable    
checkConv:{ [object; expected];
    actual:.cserve.i.convertToTable object;
    .qunit.assertEquals[actual; expected; "conversion worked"] };
testConvertToTableTbl:{ checkConv[t;t:([]a:1 2)] };
testConvertToTableList:{ checkConv[1 2;t:([]val:1 2)] };
testConvertToTableAtom:{ checkConv[`h;t:([]val:enlist `h)] };
testConvertToTableDictionary:{ checkConv[`p`o!1 2;t:([] p:enlist 1; o:enlist 2)] };
testConvertToTableDictionarySameValLength:{ checkConv[(`p;"o")!(1 2;`l`k);t:([] p:enlist 1 2; o:enlist `l`k)] };

/###  Testing smartSelect
checkSmartSelect:{ [filter; query; optionsDict; description]
    actual:.cserve.smartSelect[filter; query; optionsDict];
    .qunit.assertKnown[actual; cleanName "smartSelect_",description; description] };
    
testSmartSelectMultiRdb:{ 
    f:.qunit.assertKnownRun[.cserve.smartSelect[rdbAB; ; ()!()];]; 
    f "select from t where a in 1 2"; / unkeyed result over multi RDB is razed
    f "select b by mport from t where a in 1 2"; / keyed query without overlap works
    };
    
testSelectMultiRdbKeyedOverlapError:{ 
    qry:"select b by a from t where a in 1 2";
    f:.cserve.smartSelect[rdbAB; ; ()!()];
    .qunit.assertError[f; qry; "key overlap between proc causes error"];
    / with source columns would work
    .cserve.smartSelect[rdbAB; qry; ``showSrcCols!11b] };

testSmartSelectRDBhdbWithDates:{
    wcs:("date=2011.01.01";"date in 2011.01.01 2016.01.03");
    wcs,:("date within 2011.01.01 2016.01.03";"date=.z.d";"date>2016.01.05");
    wcs,:wcs,\:",b<3";
    f:.qunit.assertKnownRun[.cserve.smartSelect[`a; ; ()!()];]; 
    f each "select from t where ",/:wcs };

testSmartSelectRDBhdbWithoutDates:{};

/ .cserve.runQuery[rdbAB; "select from t where a in 1 2"]
/ .cserve.runQueryFlatResult[rdbAB; "([a:1 2] b:3 4)"; 0b] 0
/ .cserve.smartSelect[rdbAB; "select b by a from t where a in 1 2"; ()!()]
/ .cserve.smartSelect[rdbAB; "select from t where a in 1 2"; ()!()]

/ .cserve.runQuery[`a`rdb; {select from t where a in 1 2}]
/ r:.qunit.runTests[]

