t:update mport:system "p" from ([] a:til 6; b:`float$til 6);
`:hdba/2011.01.01/t/ set update a+10 from t;
`:hdba/2011.01.02/t/ set update a+20 from  t;
system "l hdba";

/ Same overrides in all processes
.z.pg:{ show (`.z.pg;x); PG::x; value x };
.z.ps:{ show (`.z.ps;x); PS::x; value x };
.z.po:{ show (`.z.po;x) };
