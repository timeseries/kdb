t:update mport:system "p" from ([] a:til 6; b:`float$til 6);

/ Same overrides in all processes
.z.pg:{ show (`.z.pg;x); PG::x; value x };
.z.ps:{ show (`.z.ps;x); PS::x; value x };
.z.po:{ show (`.z.po;x) };
