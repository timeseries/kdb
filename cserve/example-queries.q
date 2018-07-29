2+2
select from .a.t
last .a.t
meta .a.t

tables `.a
tables `.b
.a.t

.kdb.run[`a;"select from t"]
.kdb.run[`b;"select from t"]
.kdb.run[`b`rdb;"select from t"]
.kdb.run[`b`hdb;"select from t"]

.kdb.run[`b`hdb;"select a,date from t"]
.kdb.run[`app`proc!("*";`rdb);"tables[]"]

.cserve.defaultFilterDict
.cserve.services


.supergw.smartEval "select from .a.t"
.cserve.smartSelect[rdbAB; "(uj/) {() xkey update t:x from meta x} each tables[]"; ()!()]
.cserve.runQuery[rdbAB; "select from t where a in 1 2"]
.cserve.runQuery[rdbAB; parse "select from t where a in 1 2"]

(uj/) {update app:x`app from x`r} each () xkey .cserve.runQuery[enlist[`proc]!enlist `rdb`hdb; "(uj/) {() xkey update tbl:x from meta x} each tables[]"]
.cserve.smartSelect[rdbAB; "(uj/) {() xkey update t:x from meta x} each tables[]"; ()!()]
.cserve.runQuery[{x}; "([] a:tables[])"]

.cserve.services
.cserve.i.filterServices
.cserve.defaultFilterDict

{[qry] 
    p:parse qry;
    isQry:$[5=count p;$[value["?"]~p 0;-11h~type p 1;0b];0b];
    if[not isQry; 'notQry];
    nsTblPair:$[3~count a:` vs p 1;a 1 2;'tblNotFullyDefined];
    sFilter:enlist[`app]!enlist nsTblPair 0;
    qry:@[p;1;:;nsTblPair 1];
    .cserve.smartSelect[sFilter; qry; ()!()]
    
     } "select from .a.t where a in 1 2"
     
     