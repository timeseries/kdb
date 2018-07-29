/ cserve - Client server that stitches together various services
/ Various level of select queries are supported depending on how technical/advanced you want to query. 
/ In ascending user friendliness:
/ .cserve.smartSelect - Just write a select and have RDB/HDB data "nicely" stitched together for you
/ .cserve.runQueryFlatResult - Write a select and get a flattened table of the results, up to you to handle overlaps and RDB/HDB differences.
/ .cserve.runQuery - Send a query to multiple processes and get one row per proc/app. Very raw.

/ Decisions:
/ - Have defaultFilterDict with env already specified as apps should mostly point at only one environment.
/ - Allow setting of handleProvider so as to plug into existing framework, need to allow framework specified conn caching and password handling.
/ - App/Proc uniquely identify a data source and are interchangeable.
/   env.version should be rarely changed and cannot easily be mixed within one call to discourage such use.

/ @TODO multi-query formats
/ @TODO parse multi-statements to pull out selects
/ @TODO HDB/RDB stitching
/ @TODO test error handling on remote side.

.cserve.services:([] host:`$(); port:`int$(); app:`$(); proc:`$(); version:`$(); env:`$());
.cserve.defaultFilterDict:(::;`proc;`env)!(::;`rdb`hdb;`DEV);
.cserve.i.handleProvider:{hopen `$":" sv string x``host`port};
.cserve.i.lg:{1 string[.z.t],$[type[x]=98h; "\r\n"; "  "],$[type[x] in 10 -10h; x; .Q.s x],"\r\n"; x};

.cserve.setHandleProvider:{ .cserve.i.handleProvider:x; };
.cserve.setServices:{ .cserve.services:x; };

/ @param sFilter Filter services table using each item to filter one columns 
/            Dictionary = take key as column name and value as list of permitted values
/            List = Assume `app`proc filter in that order
/to atom/list of values that will be filtered to based on "in" clauses
.cserve.i.filterServices:{ [sFilter]
    / Convert list to dictionary
    if[99h<>type sFilter;
        c:count sFilter;
        sFilter:(c#`app`proc)!(),sFilter];
    fd:.cserve.defaultFilterDict,sFilter;
    wc:enlist {(in;x 0;enlist x 1)} each {flip (key x; value x)} fd;
    t:eval (?;.cserve.services;wc;0b;());
    () xkey t@exec first 1?i by app,proc,env from t };

/ Run a query over each of the services selected by sFilter.
/ @return a table with columns ([app; proc; env] r)
/         where r is the result of the query against that particular table
/ @param qry Query to run in either the query format usually supplied to a kdb handle 
/       or a function that requires no argument.
.cserve.runQuery:{ [sFilter; qry]
    s:.cserve.i.filterServices sFilter;
    s:update h:.cserve.i.handleProvider each s from s;
    q:$[type[qry] in 100 104h; (qry;`); qry];
	asyncSend:{[q;svc] neg[.cserve.i.lg[svc]`h] ({neg[.z.w] @[value;x;`ERROR]}; q)};
	asyncSend[q;] each s;
	//t:update r:r[;1],success:r[;0] from 
    t:update success:1b,r:{x[]} each h from s;
    2!select app,proc,env,version,success,host,port,r from t };

/ Run a query over all selected services, flatting the result to one table
/ @return One table showing all flattened results, with columns showing app/proc
/         Individual process results will be converted to table and if keyed, result will be keyed.
/ @param dropDataOnErrors If symbol=`dropDataOnErrors drop data from captures with errors else throw exception
.cserve.runQueryFlatResult:{ [sFilter; qry; dropDataOnErrors]
    t:.cserve.runQuery[sFilter; qry];
    mkTable:{ 
        t:.cserve.i.convertToTable x`r; 
        keyCols:$[count keys t; `app`proc,keys t; ()];
        keyCols xkey update app:x`app,proc:x`proc from t};
    if[0<count select from t where not success;
        $[dropDataOnErrors=`dropDataOnErrors; 
            t:select from t where success;
            'someCapturesGaveAnError];
        ];
    niceRes:(uj/) mkTable each 0!t;
    (niceRes;delete r from t) };
    
.cserve.i.queryWrap:{ [selectQry;emptyArg]
    q:$[10h=type selectQry; parse selectQry; selectQry];
    isSelect:(5=count q) and q[0]~value "?";
    pToVal:`date`int`long!(.z.d;0i;0j); / maps partition type to replacement value in RDB
    
    / If it's a select in the RDB and missing first query column, modify query to work
    if[$[isSelect; not 1b~.Q.qp q 1; 0b];
        wc1:q[2;0;0]; / where clause 1
        colNamePos:where {$[-11h=type x;x in `date`int`long;0b]} each wc1;
        / If we found a likely partition column in the query and it's not in the target table
        if[$[count colNamePos; not (q[2;0;0] first colNamePos) in cols q 1; 0b];
            wc1True:eval @[wc1; colNamePos; :; pToVal wc1 colNamePos];
            / If clause is true remove it
            $[wc1True; q[2;0]:1 _ q[2;0]; q[2;0;0]:0b]; 
            ];
        ];
    eval q };

/ Perform a select against the selected processes
/ flattening the results from them all and handling RDB/HDB differences
/ Assumes RDB holes data for .z.d according to RDB process itself.
/ @throws keysCollapsedUnsafely If the select query from each process returned data that had overlapping keys
.cserve.smartSelect:{ [sFilter; selectQry; optionsDict]
    d:(``showSrcCols!(::;0b)),$[99h=type optionsDict; optionsDict; ()!()];
    qry:(.cserve.i.queryWrap[selectQry;];`);
    r:.cserve.runQueryFlatResult[sFilter; qry; `];
    mt:t:r 0;
    if[not d `showSrcCols;
        mt:$[count keys t;
            ?[t;();{x!x} keys[t] except `app`proc; ()];
            delete app,proc from t];
        ];
    if[count[t]<>count mt; 'keysCollapsedUnsafely];
    mt};

.cserve.select:.cserve.smartSelect[;;()!()];
                
/ Convert any kdb object to a table
.cserve.i.convertToTable:{ [object]
	t:type object;
	/ dictionary = single row table, keys=headers, value=row
    dictToTbl:{ flip {k:key x; if[11h<>type k; k:`$string k]; k!value x} enlist each x};
	/ list = make table with val column
	$[.Q.qt object; 
        object;
		99h=t; dictToTbl object;
        {([] val:$[0h<=type x; x; enlist x])} object]
    };

.cserve.services:6#([] host:4#`localhost; port:6000+til 4; app:`a`a`b`b; proc:`rdb`hdb`rdb`hdb; version:4#0nf; env:4#`DEV);

