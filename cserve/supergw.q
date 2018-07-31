/ supergw that:
/ 1. Uses cserve to provide an interface that takes fully specified selects
/    e.g. "select from .nyse.quotes" and to send it to the correct cserve "service"
/ 2. Presents a facade that allows:
/        Calling .kdb.XXX calls, and sending those calls to underlying services
/        Running queries, that appear to hit local RDBs but is automatically sent remote.

/ filter used to check that this function should be ran locally rather than sent elsewhere
.supergw.runLocalFilter:{0<count x ss ".kdb."};
.supergw.isQry:{ [parsedQ] $[5=count parsedQ;$[value["?"]~parsedQ 0;-11h~type parsedQ 1;0b];0b]};
.supergw.tblList:`symbol$();

.supergw.select:{ [qry] 
    p:parse qry;
    if[not .supergw.isQry p; 'notQry];
    nsTblPair:$[3~count a:` vs p 1;a 1 2;'tblNotFullyDefined];
    sFilter:enlist[`app]!enlist nsTblPair 0;
    qry:@[p;1;:;nsTblPair 1];
    .cserve.smartSelect[sFilter; qry; ()!()] };

/ For all proc RDBS, recreate an empty version of their RDB table in this process under .{proc}.{tableName}
/ Populate .supergw.tblList with a list of all names.
.supergw.refreshMetaData:{[]
    / Fetch empty versions of all RDB tables and set them locally
    qry:"update t:{0#t} each tbl from ([] tbl:tables[])";
    t:.cserve.smartSelect[enlist[`proc]!enlist `rdb; qry; ``showSrcCols!11b];
    .supergw.tblList:{(` sv `,x`app`tbl) set x`t} each t};

/ Given a string of qCode, decide whether to run it on remote agents or locally and return the result.
.supergw.smartEval:{ [qCode]
    / In order:
    / 1. Try evaling as a select
    / 2. Try running against capture as guessed by finding .xxx.yyy table format
    / 3. Try running on supergateway itself
    if[.supergw.runLocalFilter qCode;
        show "pass runLocal filter";
        reval (value;qCode)];
    pq:$[10h~abs type qCode; parse qCode; qCode];
    if[.supergw.isQry pq;
        show "super select";
        :.supergw.select qCode];
    tblNames:.supergw.tblList where .supergw.tblList in\: raze pq;
    tblNames,:where 0<count each qCode ss/: string {x!x} .supergw.tblList;
    if[0<count tblNames;
        tName:tblNames 0;
        nsTblPair:1 _ ` vs tName;
        sFilter:`app`proc!(nsTblPair 0;`rdb);
        myCode:ssr[qCode;string tName;string nsTblPair 1];
        show "run Query:",myCode;
        t:.cserve.runQuery[sFilter; myCode];
        if[1<>count t; 'badConfig];
        :exec first r from t];
    show "reval";
    reval (value;qCode)};

sys:{system 0N!"l ",x};
sys each ("html.q";"doth.k";"cserve.q");
.h.RUNNER:.supergw.smartEval;
X:(::;::);
.z.pg:{X::X,enlist x; .supergw.smartEval x};
.supergw.refreshMetaData[];
.kdb.run:.cserve.smartSelect[;;()!()];
-1 ".kdb.run[`a;\"select from t\"]";