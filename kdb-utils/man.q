
\d .man


/#########################   Help

help:([name:`$()] description:(); eg:());
upsert[`help; (`slash; "listing of all builtin \\ commands"; "\\p to get the port")];
upsert[`help; (`dotz; "listing of all builtin .z.xxx commands"; "  ")];
upsert[`help; (`dotQ; "listing of all builtin .Q.xxx commands"; "   ")];
upsert[`help; (`bang; "listing of all builtin ! commands"; "0! to print to console")];
upsert[`help; (`error; "listing of all builtin errors q can throw"; "'limit")];
upsert[`help; (`types; "listing of all builtin KDB data types"; "100f is a float")];
upsert[`help; (`cmdline; "listing of all KDB command line arguments"; "-p to set the port")];
upsert[`help; (`funcs; "listing of all builtin q functions"; "  ")];
upsert[`help; (`dotQ; "listing of all builtin .Q.xxx commands"; "  ")];
upsert[`help; (`typr; "type command with english explaination"; ".man.typr 100 returns integer")];
description:"Help library that provides builtin KDB type/error/function lookups and a number of utility functions";



/#########################   PUBLIC FUNCTIONS - Only functions that should be called

man:{ x:(),x;
	$[0h=type x; namespaces; 
		1=count x; @[{(value ".",(string x 0)) `help}; x; "help not found"]; `oops]};

/ manual packages on each package
buildMan:{ .man.namespaces:([name:`$()] description:());
	upsert[`.man.namespaces; (`Q; "KDB provided private API though many of these are commonly used")];
	upsert[`.man.namespaces; (`q; "KDB provided public API that contains all q functions")];
	upsert[`.man.namespaces; (`o; "KDB provided ODBC related functionality")];
	upsert[`.man.namespaces; (`h; "KDB provided functions used for handling webserver calls")];
	upsert[`.man.namespaces; (`z; "Not strictly a namespace but contains functions for accessing dates/times")];
	upsert[`.man.namespaces; a,'{enlist x@`description} each {`$".",x}@/: string a:(key `) except `q`Q`h`o] };

/ breakdown of memory usage by variable,table etc. Warning this can cause a wsfull error
mem:{a:enlist[key`.],` sv/:/:n,/:'key each n:` sv/:`,/:key[`]except`q`Q`o`h;
	useTS:{{{$[(0=.Q.qp value x) and ((value "type ",x) in 99 98 14 11h); (system "ts 1 _ ",x)[1]; 0Nj]} each x} each string x};
	b:([]namespace:`,n; variable:a; typ:{type value x}''[a]; space:{count -8!value x}''[a]; ram:useTS[a]%1024.0*1024.0);
	rename:{[tab;frm;to] @[cols tab;cols[tab]?frm;:;to] xcol tab};
	rename[`ram xdesc ungroup b; `ram; `$"Ram (KB)"]};


/ an imporved version of the builtin type command that returns an english language description
typr:{[vari] tt:type vari; 
	out:(string tt)," "; 
	if[(tt>0) and (tt<20); out,:"list "]; 
	if[(tt>=20) and (tt<=77); out,:"enumeration "]; 
	if[(tt>=78) and (tt<=96); [out,:"nested "; tt:tt-77]]; 
	tableNum:`int$(abs tt); / number in type table for this object
	$[98=tableNum; :out,(string ((0b;1b;0)!(`splayed;`partitioned;`memory))[.Q.qp vari])," table"; ::];
	$[(99=tableNum); $[(all 98h=type each (key a;value a:vari)); :out," keyed table"; ::]; ::];
	
	out,:string ((`nr xkey update  nr:"I"$num from types)@tableNum)[`typee] ; 
	:out};

/ allows querying what a Q command does, this includes:
/ .man.whatis[".z.z"] , .man.whatis "\\p", .man.whatis "-1!", .man.whatis "xasc"
whatis:{[arg] x:`$arg; 
	r:select from (update Type:`$"dotz" from dotz) where sym=x; 
	$[(count r)>0;; r:select from (update Type:`$"dotQ" from dotQ) where sym=x ]; 
	$[(count r)>0;; r:select from (update Type:`$"Slash command" from (update sym:`$("\\",'string sym) from slash)) where sym=x ]; 
	$[(count r)>0;; r:select from (update Type:`$"Bang command" from bang) where sym=x ]; 
	$[(count r)>0;; r:update Type:`$"Error Types" from (select from error where sym=x) ]; 
	$[(count r)>0;; r:update Type:`$"Command Line Arguement" from (select from (update sym:("-",'string sym) from cmdline) where sym like arg)]; 
	$[(count r)>0;; [r:update Type:`$"Function" from (select from func where sym=x);
				rr:update Type:`$"Related" from (select from func where sym in ((flip select seeAlso from r)[`seeAlso][0]));
				r,:rr]]; 
	$[(count r)>0; `Type`sym xcols 0!r; r:"no result"] };

/ get a table of system information

sysReport:([] query:(".z.K";".z.k";".z.o";".z.u";".z.f";".z.x";".z.a";".z.h";"\\c";"\\C";"\\d";"\\p";"\\P";"\\S";"\\t";"\\T";"\\w";"\\W";"\\o"))


/ clean the output a little
cl:{[tbl] update val:{"." sv string `int$0x00 vs x} each val from tbl where query like ".z.a"};
/ from a list of string items like (".z.u";"\\p") return a report on their values
getReport:{[vars] cl flip (`query`description`val)!(vars;({(.man.whatis x)[`description]} each vars);value each vars)};
getReportFor:{[vars;remoteHandle] cl flip (`query`description`val)!(vars;({(.man.whatis x)[`description]} each vars);remoteHandle ({value each x};vars))};
/ get a precanned report
getSystemReport:{getReport .man.sysReport[`query]};
/ get a precanned report from a remote machine
getSystemReportFor:getReportFor[.man.sysReport[`query];];

/ return true if the first character of a symbol is uppercase, false otherwise											
k)isUpperCase:{(`int$"a") > `int$ *: $: x};

/ the size of the different column types
m:"bxhijefcsmdzuvt"!1 1 2 4 8 4 8 1 8 4 4 8 4 4 4j;

/ mb table - returns estimated space in bytes a table takes up
mb:{ count[x]*sum m exec t from meta x}

/ an extended version of .q.meta that also returns attributes and keys
metax:{ 
	fullTypeName:{raze (string x)," - ",(string (`charType xkey types) [lower string x;`typee]),$[isUpperCase[x];" list";""]};
	attribut:(`s`p`u`g)!("s - sorted"; "p - parted"; "u - unique"; "g - grouped");
	(`column`type,`$("foreign key";"attribute";"key")) xcol a:update k:(c in keys x),(fullTypeName'[t]),attribut[a],size:.man.m[t] from meta x};

/ table showing event handlers and whether they have been overridden
getEventHandlers:{ update overridden:{{100h=type each @[value; x; {0b}]} each string x} sym from a:eventHandlers lj `dotzLink xcol dotz};
	
/#########################   Tables used by the functions

eventHandlers:([sym:`$()] dotzLink:());
insert[`eventHandlers; (`.z.pc; `$".z.pc[h]")];
insert[`eventHandlers; (`.z.pg; `$".z.pg[x]")];
insert[`eventHandlers; (`.z.ph; `$".z.ph[x]")];
insert[`eventHandlers; (`.z.pi; `$".z.pi[x]")];
insert[`eventHandlers; (`.z.po; `$".z.po[h]")];
insert[`eventHandlers; (`.z.pp; `$".z.pp[x]")];
insert[`eventHandlers; (`.z.ps; `$".z.ps[x]")];
insert[`eventHandlers; (`.z.vs; `$".z.vs[v;i]")];
insert[`eventHandlers; (`.z.ts; `$".z.ts[x]")];
insert[`eventHandlers; (`.z.pw; `$".z.pw[u;p]")];



dotz:([sym:`$()] description:());
insert[`dotz; (`$".z.a";enlist "ip-address ie. \".\" sv string `int$0x00 vs .z.a")];
insert[`dotz; (`$".z.ac";enlist "Http authenticate from cookie")];
insert[`dotz; (`$".z.b";enlist "dependencies (more information than \\b)")];
insert[`dotz; (`$".z.d";enlist "gmt date")];
insert[`dotz; (`$".z.D";enlist "local date")];
insert[`dotz; (`$".z.f";enlist "startup file")];
insert[`dotz; (`$".z.h";enlist "hostname")];
insert[`dotz; (`$".z.i";enlist "pid")];
insert[`dotz; (`$".z.k";enlist "kdb+ releasedate ")];
insert[`dotz; (`$".z.K";enlist "kdb+ major version")];
insert[`dotz; (`$".z.l";enlist "license information (;expirydate;updatedate;;;)")];
insert[`dotz; (`$".z.o";enlist "OS ")];
insert[`dotz; (`$".z.pc[h]";enlist "close, h handle (already closed)")];
insert[`dotz; (`$".z.pg[x]";enlist "get")];
insert[`dotz; (`$".z.ph[x]";enlist "http get")];
insert[`dotz; (`$".z.pi[x]";enlist "input (qcon)")];
insert[`dotz; (`$".z.po[h]";enlist "open, h handle ")];
insert[`dotz; (`$".z.pp[x]";enlist "http post")];
insert[`dotz; (`$".z.ps[x]";enlist "set")];
insert[`dotz; (`$".z.pw[u;p]";enlist "validate user and password")];
insert[`dotz; (`$".z.1";enlist "quiet mode")];
insert[`dotz; (`$".z.s";enlist "self, current function definition")];
insert[`dotz; (`$".z.t";enlist "gmt time")];
insert[`dotz; (`$".z.T";enlist "local time")];
insert[`dotz; (`$".z.ts[x]";enlist "timer expression (called every \\t)")];
insert[`dotz; (`$".z.u";enlist "userid ")];
insert[`dotz; (`$".z.vs[v;i]";enlist "value set")];
insert[`dotz; (`$".z.w";enlist "handle (0 for console, handle to remote for KIPC)")];
insert[`dotz; (`$".z.x";enlist "command line parameters (argc..)")];
insert[`dotz; (`$".z.z";enlist "gmt timestamp. e.g. 2013.11.06T15:49:26.559")];
insert[`dotz; (`$".z.Z";enlist "local timestamp. e.g. 2013.11.06T15:49:26.559")];
insert[`dotz; (`$".z.n";enlist "Get gmt timespan (nanoseconds). e.g. 0D15:49:07.295301000")];
insert[`dotz; (`$".z.N";enlist "Get local timespan (nanoseconds). e.g. 0D15:49:07.295301000")];
insert[`dotz; (`$".z.p";enlist "Get gmt timestamp (nanoseconds). e.g. 2011.11.06D15:48:38.446651000")];
insert[`dotz; (`$".z.P";enlist "Get local timestamp (nanoseconds). e.g. 2011.11.06D15:48:38.446651000")];

dotQ:([sym:`$()] description:());
insert[`dotQ; (`$".Q.addmonths";enlist "Adds y months to x")];
insert[`dotQ; (`$".Q.addr";enlist "ip-address as an integer  from a hostname symbol")];
insert[`dotQ; (`$".Q.host";enlist "hostname as a symbol for an integer ip-address")];
insert[`dotQ; (`$".Q.chk";enlist "fills missing tables")];
insert[`dotQ; (`$".Q.cn";enlist "number of rows for partitioned table passed by value")];
insert[`dotQ; (`$".Q.pn";enlist "Partition counts cached since the last time .Q.cn was called")];
insert[`dotQ; (`$".Q.D";enlist "In segmented dbs, partition vector with each element enlisted")];
insert[`dotQ; (`$".Q.dd";enlist "Shorthand for ` sv x,`$string y")];
insert[`dotQ; (`$".Q.dpft[directory;partition;`p#field;tablename] ";enlist "Saves a table splayed to a specific partition of a database sorted (`p#) on a specified field")];
insert[`dotQ; (`$".Q.dsftg";enlist "(loop M&1000000 rows at a time - load/process/save) ")];
insert[`dotQ; (`$".Q.en";enlist "Enumerates any character columns in a table to the list sym and appends any new entries to a file in the db directory.")];
insert[`dotQ; (`$".Q.fc";enlist "parallel on cut")];
insert[`dotQ; (`$".Q.fk";enlist "return ` if the column is not an fkey or `tab if the column is a fkey into tab")];
insert[`dotQ; (`$".Q.fmt";enlist "Formats a number")];
insert[`dotQ; (`$".Q.fs";enlist "Loops over file (in chunks) applying function")];
insert[`dotQ; (`$".Q.ft";enlist "creates a new function that also works on keyed")];
insert[`dotQ; (`$".Q.gc";enlist "Invokes the garbage collector.")];
insert[`dotQ; (`$".Q.hdpf[historicalport;directory;partition;`p#field] ";enlist "save all tables and notify host ")];
insert[`dotQ; (`$".Q.ind";enlist "it takes a partitioned table and (long!) indices into the table ")];
insert[`dotQ; (`$".Q.P";enlist "In segmented dbs, contains the list of segments that have been loaded ")];
insert[`dotQ; (`$".Q.par[dir;part;table] ";enlist "locate a table (sensitive to par.txt) ")];
insert[`dotQ; (`$".Q.PD";enlist "In partitioned dbs, contains a list of partition locations ")];
insert[`dotQ; (`$".Q.pd";enlist ".Q.PD as modified by .Q.view. ")];
insert[`dotQ; (`$".Q.pf";enlist "contains the partition type of a partitioned hdb (only)")];
insert[`dotQ; (`$".Q.PV";enlist "In partitioned dbs, contains a list of partition values - conformant to date")];
insert[`dotQ; (`$".Q.pv";enlist ".Q.PV as modified by .Q.view. ")];
insert[`dotQ; (`$".Q.qp";enlist "Returns 1b if given a partitioned table, 0b if splayed table, else 0")];
insert[`dotQ; (`$".Q.qt";enlist "Returns 1b if x is a table, 0b otherwise. ")];
insert[`dotQ; (`$".Q.s";enlist "Format an object to plain text (used by the q console, obeys \\c setting")];
insert[`dotQ; (`$".Q.ty";enlist "returns character type code of argument eg \"i\"=.Q.ty 1 2")];
insert[`dotQ; (`$".Q.u";enlist "true if each partition is uniquely found in one segment. ")];
insert[`dotQ; (`$".Q.v";enlist "given file handle sym, returns the splayed table stored there, any other sym, returns global")];
insert[`dotQ; (`$".Q.V";enlist "returns a table as a dictionary of column values ")];
insert[`dotQ; (`$".Q.view";enlist "set a subview eg .Q.view 2#date ")];


/  "slash"

slash:([sym:`$()] description:());
insert[`slash; (`$"\\";enlist "Exit q session")];
insert[`slash; (`$" ";enlist "Toggle q/k language or exit debug mode")];
insert[`slash; (`$"_";enlist "Compile q script (hide source)")];
insert[`slash; (`$"*";enlist "Execute OS command")];
insert[`slash; (`$"1";enlist "Redirect standard out to file")];
insert[`slash; (`$"2";enlist "Redirect standard error to file")];
insert[`slash; (`$"a";enlist "List tables in namespace. No parameter means current NS")];
insert[`slash; (`$"b";enlist "List dependencies in NS. No parameter means current NS")];
insert[`slash; (`$"B";enlist "Invalid dependencies in NS. No parameter means current NS")];
insert[`slash; (`$"c";enlist "Return/set console height & width -c H W 23 79")];
insert[`slash; (`$"C";enlist "Return/set web browser display height & width -C H W 36 2000")];
insert[`slash; (`$"d";enlist "Return/set current namespace `.")];
insert[`slash; (`$"e";enlist "Return/set error trap mode -e [0|1] 0")];
insert[`slash; (`$"f";enlist "List functions in NS. No parameter means current NS")];
insert[`slash; (`$"l";enlist "Load q script or database directory")];
insert[`slash; (`$"o";enlist "Return/set local time offset in hours from GMT -o N 0N")];
insert[`slash; (`$"p";enlist "Return/set port used \\p portNumber  . Note 0=no listening socket.")];
insert[`slash; (`$"P";enlist "Return/set print precision. 0 = maximum -P N 7")];
insert[`slash; (`$"r";enlist "Display replication (host;port); OR oldfile newfile /- Rename a file")];
insert[`slash; (`$"s";enlist "Display number of slaves used for parallel execution -s N 0")];
insert[`slash; (`$"S";enlist "Display/set seed for pseudo-random number generator -S N -314159")];
insert[`slash; (`$"t";enlist "Display/set timer in milliseconds. 0=timer off -t N 0")];
insert[`slash; (`$"ts";enlist "time and space measuring of function call")];
insert[`slash; (`$"T";enlist "Display/set timeout (secs) for single client call. 0=off -T N 0")];
insert[`slash; (`$"u";enlist "Reload user:password file -u F")];
insert[`slash; (`$"v";enlist "Display list of variables in current namespace")];
insert[`slash; (`$"w";enlist "Workspace memory (used/heap/peak/max/mapped); OR 0 /- print internalised symbol count and memory usage")];
insert[`slash; (`$"W";enlist "Display/set weekday offset. 0 = Saturday -W N 2")];
insert[`slash; (`$"x";enlist ".z.?? Reset .z function")];
insert[`slash; (`$"z";enlist "Display/set date conversion format from string -z [0|1] 0")];


/ "bang"
bang:([num:`int$()] sym:`$(); description:(); qEquivalent:());
insert[`bang; (0;`$"0N!";"Print input on stdout and return input";"")];
insert[`bang; (1;`$"-1!";"Prepend : to symbol if not present ";"hsym")];
insert[`bang; (2;`$"-2!";"Return attributes ";"attr")];
insert[`bang; (3;`$"-3!";"String representation of x ";".Q.s1")];
insert[`bang; (4;`$"-4!";"List of tokens for char vector";"")];
insert[`bang; (5;`$"-5!";"Return parse tree for char list ";"parse")];
insert[`bang; (6;`$"-6!";"Evaluate parse tree ";"eval")];
insert[`bang; (7;`$"-7!";"Size of file in bytes ";"hcount")];
insert[`bang; (8;`$"-8!";"IPC byte representation of x";"")];
insert[`bang; (9;`$"-9!";"x from IPC byte representation";"")];
insert[`bang; (11;`$"-11!";"Streaming execute  logfile or Count lines in logfile";"")];
insert[`bang; (12;`$"-12!";"Hostname from integer IP address ";".Q.host")];
insert[`bang; (13;`$"-13!";"Integer IP address of hostname ";".Q.addr")];
insert[`bang; (15;`$"-15!";"md5 encryption of char list ";"md5")];
insert[`bang; (17;`$"-17!";"Read kdb+ binary file of non-native architecture";"")];
insert[`bang; (18;`$"-18!";"IPC compression of data x";"")];


adverbs:([sym:`$()] dummy:`int$(); name:(); example:(); description:());
insert[`adverbs; (`$"'";1;"Each Both";"1 2 3 4 5,'10 20 30 40 50";"Operate on corresponding items on two lists of equal length.")];
insert[`adverbs; (`$"each";1;"Each Monadic";"reverse each (0 1 2; `a`b`c)";" 	Apply monadic function at nested level rather than topmost")];
insert[`adverbs; (`$"/:";1;"Each Right";"1 2{x+y}/:100 200 300";"Using same left argument, apply dyadic function to each item of right argument.")];
insert[`adverbs; (`$"\\:";1;"Each Left";"1 2{x+y}\\:100 200 300";"Using same right argument, apply dyadic function to each item of left argument.")];
insert[`adverbs; (`$"Scan";1;"Scan";"{x+y} scan 1 2 3 4 5";"Apply dyadically to first two items, then use result of previous to scan forward over list")];
insert[`adverbs; (`$"\\";1;"Scan";"{x+y}\\[1 2 3 4 5]";"Apply dyadically to first two items, then use result of previous to scan forward over list")];
insert[`adverbs; (`$"/";1;"Over";"0+/10 20 30";"Same as scan but only returns the final result, not intermediate calculations.")];
insert[`adverbs; (`$"Over";1;"Over";"{x+y} over 1 2 3 4 5";"Same as scan but only returns the final result, not intermediate calculations.")];
insert[`adverbs; (`$"':";1;"Each Previous";"{x+y}':[1 2 3 4 7]";"Dyadic function applies to numbers beside each other over entire list")];
delete dummy from `adverbs;

/ "error"
error:([sym:`$()] dummy:`int$(); example:(); description:());
insert[`error; (`$"Mlim";1;"";"more than 999 nested columns in splayed tables")];
insert[`error; (`$"Q7";1;"";"nyi op on file nested array")];
insert[`error; (`$"XXX";1;"";"value error (XXX undefined)")];
insert[`error; (`$"[{(\"\")}]";1;"";"open brackets or speech marks")];
insert[`error; (`$"arch";1;"`:test set til 100;-17!`:test";"attempt to load file of wrong endian format")];
insert[`error; (`$"access";1;"";"attempt to read files above directory; run system commands or failed usr/pwd")];
insert[`error; (`$"accp";1;"";"tried to accept an incoming tcp/ip connection but failed to do so")];
insert[`error; (`$"assign";1;"cos:12";"attempt to reuse a reserved word")];
insert[`error; (`$"badtail";1;"";"incomplete transaction at end of file  get good (count;length) with -11!(-2;`:file)")];
insert[`error; (`$"branch";1;"";"a branch(if;do;while;$.;.;.) more than 255 byte codes away")];
insert[`error; (`$"cast";1;"s:`a`b; c:`s$`a`e";"")];
insert[`error; (`$"char";1;"";"invalid character")];
insert[`error; (`$"conn";1;"";"too many incoming connections (1022 max)")];
insert[`error; (`$"constants";1;"";"too many constants (max 96)")];
insert[`error; (`$"core";1;"";"too many cores for license")];
insert[`error; (`$"cpu";1;"";"too many cpus for license")];
insert[`error; (`$"domain";1;"1?`10";"out of domain")];
insert[`error; (`$"exp";1;"";"expiry date passed")];
insert[`error; (`$"from";1;"select price trade";"Badly formed select statement")];
insert[`error; (`$"glim";1;"";"g# limit  kdb+ currently limited to 99 concurrent g#'s")];
insert[`error; (`$"globals";1;"";"too many global variables (31 max)")];
insert[`error; (`$"host";1;"";"unlicensed host")];
insert[`error; (`$"k4.lic";1;"";"k4.lic file not found  check QHOME/QLIC")];
insert[`error; (`$"length";1;"()+til 1";"incompatible lengths")];
insert[`error; (`$"limit";1;"0W#2";"tried to generate a list longer than 2 000 000 000")];
insert[`error; (`$"locals";1;"";"too many local variables (23 max)")];
insert[`error; (`$"loop";1;"a::a";"dependency loop")];
insert[`error; (`$"mismatch";1;"";"columns that can't be aligned for R;R or K;K")];
insert[`error; (`$"mq";1;"";"Multi-threading not allowed.")];
insert[`error; (`$"noamend";1;"t:([]a:1 2 3); enum:`a`b`c;";"Cannot perform global amend from within an amend.")];
insert[`error; (`$"";1;"update b:{`enum?`d;:`enum?`d}[] from `t";"")];
insert[`error; (`$"nosocket";1;"";"Only main thread can open/use sockets. (v3.0+)")];
insert[`error; (`$"noupdate";1;"";"update not allowed when using negative port number")];
insert[`error; (`$"nyi";1;"";"not yet implemented")];
insert[`error; (`$"os";1;"";"Operating System error OR wrong os (if licence error)")];
insert[`error; (`$"params";1;"f:{[a;b;c;d;e;f;g;h;e]}";"too many parameters (8 max)")];
insert[`error; (`$"parse";1;"";"invalid syntax")];
insert[`error; (`$"part";1;"";"something wrong with the partitions in the hdb")];
insert[`error; (`$"pl";1;"";"peach can't handle parallel lambda's (2.3 only)")];
insert[`error; (`$"rank";1;"+[2;3;4]";"invalid rank or valence")];
insert[`error; (`$"s-fail";1;"`s#3 2";"invalid attempt to set sorted attribute")];
insert[`error; (`$"splay";1;"";"nyi op on splayed table")];
insert[`error; (`$"srv";1;"";"attempt to use client-only license in server mode")];
insert[`error; (`$"stack";1;"{.z.s[]}[]";"ran out of stack space")];
insert[`error; (`$"stop";1;"";"user interrupt(ctrl-c) or time limit (-T)")];
insert[`error; (`$"stype";1;"'42";"invalid type used to signal")];
insert[`error; (`$"type";1;"key 2.2";"wrong type")];
insert[`error; (`$"u-fail";1;"`u#2 2";"invalid attempt to set unique attribute")];
insert[`error; (`$"upd";1;"";"attempt to use version of kdb+ more recent than update date")];
insert[`error; (`$"user";1;"";"unlicensed user")];
insert[`error; (`$"unmappable";1;"t:([]sym:`a`b;a:(();()));";"when saving partitioned data; each column must be mappable. () and ("";"";"") is ok")];
insert[`error; (`$"value";1;"";"no value")];
insert[`error; (`$"vd1";1;"";"attempted multithread update")];
insert[`error; (`$"view";1;"";"Trying to re-assign a view to something else")];
insert[`error; (`$"wha";1;"";"invalid system date (release date is after system date)")];
insert[`error; (`$"wsfull";1;"";"malloc failed. ran out of swap (or addressability on 32bit). or hit -w limit.")];
delete dummy from `error;



/ "types"
types:([typee:`$()] size:`int$(); charType:(); num:(); notation:(); nullValue:());
insert[`types; (`$"DELETEE";1;"bsssss";"1ssss";"1bsss";"0bssss")];
insert[`types; (`$"Mixed List";0N;" ";"0";" ";" ")];
insert[`types; (`$"boolean";1;"b";"1";"1b";"0b")];
insert[`types; (`$"byte";1;"x";"4";"0x26";"0x00")];
insert[`types; (`$"short";2;"h";"5";"42h";"0Nh")];
insert[`types; (`$"int";4;"i";"6";"42";"0N")];
insert[`types; (`$"long";8;"j";"7";"42j";"0Nj")];
insert[`types; (`$"real";4;"e";"8";"4.2e";"0Ne")];
insert[`types; (`$"float";8;"f";"9";"4.2";"0n")];
insert[`types; (`$"char";1;"c";"10";"\"z\"";"\" \"")];
insert[`types; (`$"symbol";0N;"s";"11";"`zaphod";"`")];
insert[`types; (`$"timestamp";8;"p";"12";"2011.07.08D21:48:48.703125000";"0Np")];
insert[`types; (`$"month";4;"m";"13";"2006.07m";"0Nm")];
insert[`types; (`$"date";4;"d";"14";"2006.07.21";"0Nd")];
insert[`types; (`$"datetime";4;"z";"15";"2006.07.21T09:13:39";"0Nz")];
insert[`types; (`$"timespan";8;"n";"16";"0D21:56:26.421875000";"0Nn")];
insert[`types; (`$"minute";4;"u";"17";"00:00";"0Nu")];
insert[`types; (`$"second";4;"v";"18";"00:00:00";"0Nv")];
insert[`types; (`$"time";4;"t";"19";"09:01:02:042";"0Nt")];
insert[`types; (`$"enum";4;"*";"20-77";"`u$v";" ")];
insert[`types; (`$"table";0N;" ";"98";"([] c1:ab`c; c2:10 20 30)";" ")];
insert[`types; (`$"dictionary";0N;" ";"99";"`a`b`c!!10 20 30";" ")];
insert[`types; (`$"Lambda";0N;" ";"100";" ";" ")];
insert[`types; (`$"Unary primitive";0N;" ";"101";" ";" ")];
insert[`types; (`$"binary primitive ";0N;" ";"102";" ";" ")];
insert[`types; (`$"ternary(operator) ";0N;" ";"103";" ";" ")];
insert[`types; (`$"projection";0N;" ";"104";" ";" ")];
insert[`types; (`$"composition";0N;" ";"105";" ";" ")];
insert[`types; (`$"f'";0N;" ";"106";" ";" ")];
insert[`types; (`$"f/";0N;" ";"107";" ";" ")];
insert[`types; (`$"f\\";0N;" ";"108";" ";" ")];
insert[`types; (`$"f':";0N;" ";"109";" ";" ")];
insert[`types; (`$"f/:";0N;" ";"110";" ";" ")];
insert[`types; (`$"f\\:";0N;" ";"111";" ";" ")];
insert[`types; (`$"dynamic load ";0N;" ";"112";" ";" ")];
delete from `types where typee=`$"DELETEE";


cmdline:([sym:`$()] n:`int$(); args:(); description:());
insert[`cmdline; (`b;1; ""; "block client write access to a kdb+ database")];
insert[`cmdline; (`f;1; ""; "this is either the script to load (*.q, *.k, *.s), or a file or directory")];
insert[`cmdline; (`c ;1; "rows cols"; "console maxRows maxCols, default 25 80. This is the maximum display size of any single terminal output.")];
insert[`cmdline; (`C ;1; "rows cols"; "webserver maxRows maxCols, default 36 2000. This is the maximum display size of any table shown through the web server.")];
insert[`cmdline; (`e ;1; "B"; "Boolean flag that if true causes the server to break when an error occurs including on client requests.")];
insert[`cmdline; (`g ;1; "Mode"; "Switch garbage collection between immediate 1 and deferred 0 modes.")];
insert[`cmdline; (`l;1; ""; "log updates to filesystem")];
insert[`cmdline; (`L;1; ""; "sync log updates to filesystem")];
insert[`cmdline; (`o;1; "N"; "offset N hours from GMT (affects .z.Z,.z.T)")];
insert[`cmdline; (`p;1; "Port"; "port which KDB server listens on (if -Port used, then server is multithreaded)")];
insert[`cmdline; (`P;1; "Precision"; "Display precision for floating point number. (default 7, use 0 to display all available)")];
insert[`cmdline; (`q;1; ""; "Quiet, ie. No startup, baber text or session prompts (typically used where no console required)")];
insert[`cmdline; (`r;1; ":H:P"; "replicate from Host/Port (seems to rely on log and running on same machine)")];
insert[`cmdline; (`s;1; "N"; "start N slaves for parallel execution")];
insert[`cmdline; (`t;1; "milliseconds"; "timer in N milliseconds between timer ticks. (default is 0 = no timeout)")];
insert[`cmdline; (`T;1; "seconds"; "timeout in seconds for client queries, i.e. maximum time a client call will execute. Default is 0, for no timeout.")];
insert[`cmdline; (`u;1; "passwdFile"; "usr:password file to protect access. File access restricted to inside start directory")];
insert[`cmdline; (`U;1; "passwdFile"; "usr:password file to protect access. File access unrestricted")];
insert[`cmdline; (`w;1; "MB"; "workspace MB limit (default:2*RAM)")];
insert[`cmdline; (`W;1; "weekOffset"; "offset from Saturday, default is 2, meaning Monday is start of week")];
insert[`cmdline; (`z;1; "B"; "format used for `date$ date parsing. 0 is mm/dd/yyyy (default) and 1 is dd/mm/yyyy.")];
delete n from `cmdline;


func:([] sym:`$(); section:`$(); n:`int$(); description:(); syntax:(); eg:(); seeAlso:());
insert[`func; (`all; `math; 1; "Function all returns a boolean atom 1b if all values in its argument are non-zero, and otherwise 0b.It applies to all data types except symbol, first converting the type to boolean if necessary. "; "r:all A"; "all 1 2 3=1 2 4"; enlist `any)];
insert[`func; (`bin; `misc; 1; "bin gives the index of the last element in x which is <=y. The result is -1 for y less than the first element of x.It uses a binary search algorithm, which is generally more efficient on large data than the linear search algorithm used by ?.The items of the left argument should be sorted non-descending although q does not enforce it. The right argument can be either an atom or simple list of the same type as the left argument. "; "r:x bin y"; "0 2 4 6 8 10 bin 5  "; `$(" "))];
insert[`func; (`cross; `math; 1; "Returns the cross product (i.e. all possible combinations) of its arguments."; "R:X cross Y"; ""; `$(" "))];
insert[`func; (`count; `essential; 1; "Returns the number of items in a list, for atoms 1 is returned"; ""; ""; `$(" "))];
insert[`func; (`differ; `qsql; 1; "The uniform function differ returns a boolean list indicating whether consecutive pairs differ. It applies to all data types. (The first item of the result is always 1b)"; "r:differ A"; ""; `$(" "))];
insert[`func; (`each; `essential; 1; "Takes a function on its left, and creates a new function that applies to each item of its argument."; ""; "count each (1 2;`p`o`i)"; `peach)];
insert[`func; (`eval; `misc; 1; "The eval function is the dual to parse and can be used to evaluate a parse tree as returned by that function (as well as manually constructed parse trees). "; ""; "eval parse \"2+3\""; `$(" "))];
insert[`func; (`except; `math; 1; "Returns all elements of its left argument that are not in its right argument. "; "x except y"; "1 3 2 4 except 1 2"; `inter`union`in)];
insert[`func; (`exp; `math; 1; "This function computes e to the power of x, where e is the base of the natural logarithms. Null is returned if the argument is null."; "R:exp 1"; ""; `$(" "))];
insert[`func; (`fby; `qsql; 1; "This verb is typically used with select, and obviates the need for many common correlated subqueries. It aggregates data in a similar way to by and computes a function on the result."; "(aggr;data) fby group"; ""; `$(" "))];
insert[`func; (`fills; `misc; 1; "Uniform function that is used to forward fill a list containing nulls."; "r:fills A"; "fills (0N 2 3 0N 0N 7 0N)"; `$(" "))];
insert[`func; (`fkeys; `qsql; 1; "The function fkeys takes a table as an argument and returns a dictionary that maps foreign key columns to their tables."; ""; ""; `meta)];
insert[`func; (`flip; `math; 1; "transposes its argument, which may be a list of lists, a dictionary or a table."; ""; "flip (`a`b`c; 1 2 3)"; `$(" "))];
insert[`func; (`getenv; `io; 1; "Returns the value of the given environment variable."; ""; "getenv `PATH"; `$(" "))];
insert[`func; (`group; `misc; 1; "Groups the distinct elements of its argument, and returns a dictionary whose keys are the distinct elements, and whose values are the indices where the distinct elements occur. The order of the keys is the order in which they are encountered in the argument."; "D:group L"; "group \"mississippi\""; `$(" "))];
insert[`func; (`gtime; `exotic; 1; "The gtime function returns the UTC datetime/timestamp for a given datetime/timestamp. Recall that the UTC and local datetime/timestamps are available as .z.z/.z.p and .z.Z/.z.P respectively."; ""; ""; `$(" "))];
insert[`func; (`hcount; `io; 1; "Gets the size in bytes of a file as a long integer."; ""; "hcount`:c:/q/test.txt"; `$(" "))];
insert[`func; (`hsym; `io; 1; "Converts its symbol argument into a file name, or valid hostname, ipaddress"; ""; "hsym`10.43.23.197"; `$(" "))];
insert[`func; (`iasc; `misc; 1; "Uniform function that returns the indices needed to sort the list argument."; "r:iasc L"; "iasc (2 1 3 4 2 1 2)"; `asc`desc`idesc)];
insert[`func; (`idesc; `misc; 1; "Uniform function that returns the indices needed to sort the list argument."; "r:idesc L"; "idesc (2 1 3 4 2 1 2)"; `asc`desc`iasc)];
insert[`func; (`in; `essential; 1; "Returns a boolean indicating which items of x are in y. Result is same size as x"; "x in y"; "1 4 5 in 10 5 11 1"; `$(" "))];
insert[`func; (`inter; `math; 1; "Returns all elements common to both arguments"; "x inter y"; "1 3 2 4 inter 1 2 6 7"; `except`union`in)];
insert[`func; (`insert; `qsql; 1; "Insert appends records to a table."; "`table insert records"; "`x insert (`s`t;40 50)"; `$(" "))];
insert[`func; (`inv; `math; 1; "inv computes the inverse of a non-singular floating point matrix."; "r:inv x"; "inv (3 3#2 4 8 3 5 6 0 7 1f)"; `mmu)];
insert[`func; (`key; `essential; 1; "Given a dictionary, it returns the keys"; "r:key D"; "key (`q`w`e!(1 2;3 4;5 6))"; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a keyed table, Returns the key columns of a keyed table"; "r:key KT"; "key ([s:`q`w`e]g:1 2 3;h:4 5 6)"; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a directory handle, returns a list of objects in the directory"; "r:key DIR"; "key`:c:/q"; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a file descriptor, returns the descriptor if the file exists, otherwise returns an empty list"; "r:key filedesc"; "key`:c:/q/sp.q"; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a foreign key column, returns the name of the foreign key table "; ""; ""; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a simple list, returns the name of the type as a symbol"; "key L"; "key each (\"abc\";101b;1 2 3h;1 2 3;1 2 3j;1 2 3f)"; `$(" "))];
insert[`func; (`key; `misc; 1; "Given an enumerated list, it returns the name of the enumerating list"; "key eL"; ""; `$(" "))];
insert[`func; (`key; `misc; 1; "Given a positive integer, it acts like til"; "key n"; "key 10"; `$(" "))];
insert[`func; (`keys ; `misc; 1; "Monadic function which takes a table as argument and returns a symbol list of the primary key columns of its argument and in the case of no keys it returns an empty symbol list. Can pass the table by reference or by value"; "keys T"; "keys ([s:`q`w`e]g:1 2 3;h:4 5 6)"; `$(" "))];
insert[`func; (`ltime; `exotic; 1; "The ltime function returns the local datetime/timestamp for a given UTC datetime/timestamp. Recall that the UTC and local datetime/timestamps are available as .z.z/.z.p and .z.Z/.z.P respectively."; ""; ""; `gtime)];
insert[`func; (`max; `math; 1; "The max function returns the maximum of its argument. If the argument is an atom, it is returned unchanged. "; "max a"; "max 1"; `min)];
insert[`func; (`max; `math; 1; "The max function returns the maximum of its argument. If the argument is a list, it returns the maximum of the list. The list may be any datatype except symbol. Nulls are ignored, except that if the argument has only nulls, the result is negative infinity. "; "max L"; "max 1 2 3 10 3 2 1"; `min)];
insert[`func; (`maxs; `math; 1; "The maxs function returns the maximums of the prefixes of its argument. If the argument is an atom, it is returned unchanged. "; "maxs a"; "maxs 1"; `mins)];
insert[`func; (`maxs; `math; 1; "The maxs function returns the maximums of the prefixes of its argument. If the argument is a list, it returns the maximums of the prefixes of the list. The list may be any datatype except symbol. Nulls are ignored, except that initial nulls are returned as negative infinity. "; "maxs L"; "maxs 1 2 3 10 3 2 1"; `mins)];
insert[`func; (`mcount; `math; 1; "The mcount verb returns the N-item moving count of the non-null items of its numeric right argument. The first N items of the result are the counts so far, and thereafter the result is the moving count."; "r:N mcount L"; "3 mcount 0N 1 2 3 0N 5"; `mavg`mdev`mmax`mmin`msum)];
insert[`func; (`mdev; `math; 1; "The mdev verb returns the N-item moving deviation of its numeric right argument, with any nulls after the first element replaced by zero. The first N items of the result are the deviations of the terms so far, and thereafter the result is the moving deviation. The result is floating point."; "r:N mdev L"; "2 mdev 1 2 3 5 7 10"; `mavg`mcount`mmax`mmin`msum)];
insert[`func; (`med; `math; 1; "Computes the median of a numeric list."; "r:med L"; "med 10 34 23 123 5 56"; `avg)];
insert[`func; (`meta; `qsql; 1; "The meta function returns the meta data of its table argument, passed by value or reference."; "K:meta T"; "meta ([s:`q`w`e]g:1 2 3;h:4 5 6)"; `$(" "))];
insert[`func; (`mmax; `math; 1; "The mmax verb returns the N-item moving maximum of its numeric right argument, with nulls after the first replaced by the preceding maximum. The first N items of the result are the maximums of the terms so far, and thereafter the result is the moving maximum."; "r:N mmax L"; "3 mmax 2 7 1 3 5 2 8"; `mavg`mcount`mdev`mmin`msum)];
insert[`func; (`mmu; `math; 1; "mmu computes the matrix multiplication of floating point matrices. The arguments must be floating point and must conform in the usual way, i.e. the columns of x must equal the rows of y."; "r:x mmu y"; "(2 4#2 4 8 3 5 6 0 7f) mmu (4 3#`float$til 12)"; `inv)];
insert[`func; (`mod; `math; 1; "x mod y returns the remainder of y%x. Applies to numeric types, and gives type error on sym, char and temporal types."; "r:L mod N"; "-3 -2 -1 0 1 2 3 4 mod 3"; `$(" "))];
insert[`func; (`msum; `math; 1; "The msum verb returns the N-item moving sum of its numeric right argument, with nulls replaced by zero. The first N items of the result are the sums of the terms so far, and thereafter the result is the moving sum."; "r:N msum L"; "3 msum 1 2 3 5 7 11"; `mavg`mcount`mdev`mmin`mmax)];
insert[`func; (`neg; `math; 1; "The function neg negates its argument, e.g. neg 3 is -3. Applies to all data types except sym and char. Applies item-wise to lists, dict values and table columns. "; "r:neg X"; "neg -1 0 1 2"; `$(" "))];
insert[`func; (`not; `essential; 1; "The logical not function returns a boolean result 0b when the argument is not equal to zero, and 1b otherwise. Applies to all data types except sym. Applies item-wise to lists, dict values and table columns. "; "r:not X"; "not -1 0 1 2"; `$(" "))];
insert[`func; (`null; `essential; 1; "The function null returns 1b if its argument is null.Applies to all data types. Applies item-wise to lists, dict values and table columns. "; "r:null X"; "null 0 0n 0w 1 0n"; `$(" "))];
insert[`func; (`or; `essential; 1; "The verb or returns the maximum of its arguments. It applies to all data types except symbol."; "r:L or Y"; "-2 0 3 7 or 0 1 3 4"; `$(" "))];
insert[`func; (`over; `misc; 1; "The over adverb takes a function of two arguments on its left, and creates a new atomic function that applies to successive items of its list argument. The result is the result of the last application of the function."; "r:f over L"; "{x+2*y} over 2 3 5 7"; `scan)];
insert[`func; (`parse; `exotic; 1; "parse is a monadic function that takes a string and parses it as a kdb+ expression, returning the parse tree. To execute a parsed expression, use the eval function. "; ""; "parse \"{x+42} each til 10\""; `eval)];
insert[`func; (`peach; `misc; 1; "The parallel each adverb is used for parallel execution of a function over data. In order to execute in parallel, q must be started with multiple slaves (-s). "; ""; "{sum exp x?1.0}peach 2#1000000 "; `each)];
insert[`func; (`prd; `math; 1; "Aggregation function, also called multiply over, applies to all numeric data types. It returns a type error with symbol, character and temporal types. prd always returns an atom and in the case of application to an atom returns the argument."; "ra:prd L"; "prd 2 4 5 6"; `prds)];
insert[`func; (`rand; `math; 1; "If X is an atom 0, it returns a random value of the same type in the range of that type:"; "r: rand 0"; "rand each 3#0h"; `$(" "))];
insert[`func; (`rand; `math; 1; "If X is a positive number, it returns a random number of the same type in the range [0,X)"; "r: rand a"; "rand 100"; `$(" "))];
insert[`func; (`rand; `math; 1; "If X is a list, it returns a random element from the list:"; "r:rand L"; "rand 1 30 45 32"; `$(" "))];
insert[`func; (`rank; `misc; 1; "The uniform function rank takes a list argument, and returns an integer list of the same length. Each value is the position where the corresponding list element would occur in the sorted list. This is the same as calling iasc twice on the list."; "r:rank L"; "rank 2 7 3 2 5"; `iasc)];
insert[`func; (`ratios; `math; 1; "The uniform function ratios returns the ratio of consecutive pairs. It applies to all numeric data types."; "r:ratios L"; "ratios 1 2 4 6 7 10"; `deltas)];
insert[`func; (`raze; `essential; 1; "The raze function joins items of its argument, and collapses one level of nesting. To collapse all levels, use over i.e. raze/[x].  An atom argument is returned as a one-element list."; ""; "raze (1 2;3 4 5)"; `$(" "))];
insert[`func; (`read0; `io; 1; "The read0 function reads a text file, returning a list of lines.Lines are assumed delimited by either LF or CRLF, and the delimiters are removed. "; ""; "read0`:test.txt"; `read1)];
insert[`func; (`read0; `io; 1; "Optionally, read0 can take a three-item list as its argument, containing the file handle, an offset at which to begin reading, and a length to read."; ""; "read0(`:/tmp/data;0;0+100000)"; `read1)];
insert[`func; (`read1; `io; 1; "The read1 function reads a file as a list of bytes."; ""; "read1`:test.txt   "; `read0)];
insert[`func; (`read1; `io; 1; "Optionally, read1 can take a three-item list as its argument, containing the file handle, an offset at which to begin reading, and a length to read."; ""; "read1(`:/tmp/data;0;0+100000)"; `read0)];
insert[`func; (`reciprocal; `math; 1; "Returns the reciprocal of its argument. The argument is first cast to float, and the result is float."; "r:reciprocal X"; "reciprocal 0 0w 0n 3 10"; `$(" "))];
insert[`func; (`reverse; `essential; 1; "Uniform function that reverses the items of its argument. On dictionaries, reverses the keys; and on tables, reverses the columns"; ""; "reverse 1 2 3 4"; `rotate)];
insert[`func; (`rload; `io; 1; "The rload function loads a splayed table. This can also be done, as officially documented, using the get function. "; ""; ""; `get)];
insert[`func; (`rotate; `essential; 1; "The uniform verb rotate takes an integer left argument and a list or table right argument. This rotates L by N positions to the left for positive N, and to the right for negative N. "; "r:N rotate L"; "2 rotate 2 3 5 7 11"; `reverse)];
insert[`func; (`save ; `io; 1; "The save function saves data to the filesystem."; ""; "t:([]x: 1 2 3; y: 10 20 30);save `t"; `load`set`get)];
insert[`func; (`scan; `misc; 1; "The scan adverb takes a function of two arguments on its left, and creates a new uniform function that applies to successive items of its list argument. The result is a list of the same length."; "r:f scan L"; "{x+2*y} scan 2 3 5 7"; `over)];
insert[`func; (`set ; `io; 1; "Dyadic functional form of assignment often used when saving objects to disk. set is used mainly to write data to disk and in this case the left argument is a file path, i.e. a symbol atom beginning with a :"; ""; "`:c:/q/testTradeTable set trade"; `get`save`load)];
insert[`func; (`setenv ; `io; 1; "Dyadic function which changes or adds an environment variable."; ""; "`name setenv value"; `getenv)];
insert[`func; (`show ; `essential; 1; "Monadic function used to pretty-print data to the console."; ""; "show 10#enlist til 10"; `$(" "))];
insert[`func; (`signum; `math; 1; "The function signum returns -1, 0 or 1 if the argument is negative, zero or positive respectively. Applies item-wise to lists, dictionaries and tables, and to all data types except symbol."; "r:signum X"; "signum -2 0 1 3"; `$(" "))];
insert[`func; (`ss; `string; 1; "The function ss finds positions of a substring within a string. It also supports some pattern matching capabilities of the function like: "; "r:HayStack ss needle"; "\"toronto ontario\" ss \"ont\""; `like`ssr)];
insert[`func; (`ssr; `string; 1; "The function ssr does search and replace on a string."; "r:ssr[haystack; needle;  replacement]"; "ssr[\"toronto ontario\"; \"ont\"; \"XX\"]"; `ss`like)];
insert[`func; (`like; `string; 1; "Perform simple pattern matching of strings."; "like[text; pattern]"; "like[(\"kim\";\"kyle\";\"Jim\"); \"k*\"]"; `ss`ssr)];
insert[`func; (`string; `essential; 1; "The function string converts each atom in its argument to a character string. It applies to all data types."; "r:string X"; "string ([]a:1 2 3;b:`ibm`goog`aapl)"; `$(" "))];
insert[`func; (`sublist; `essential; 1; "The verb sublist returns a sublist of its right argument, as specified by its left argument. The result contains only as many items as are available in the right argument. If X is a single integer, it returns X items from the beginning of Y if positive, or from the end of Y if negative.If X is an integer pair, it returns X 1 items from Y, starting at item X 0. "; "r:X sublist Y"; "3 sublist 2 3 5 7 11"; `$(" "))];
insert[`func; (`sv; `misc; 1; "scalar from vector- dyadic function that performs different functions on different data types."; ""; ""; `vs)];
insert[`func; (`sv; `string; 1; "When applied to a vector of strings it returns the elements of its right argument-the list of strings-separated by the left argument."; ""; "\"|\" sv (\"asdf\";\"hjkl\")"; `vs)];
insert[`func; (`sv; `misc; 1; "In the special case where the left argument is a `, it returns the concatenated right arg with each element terminated by a newline (\n on unix, \r\n on windows)."; ""; "` sv (\"asdf\";\"hjkl\")"; `vs)];
insert[`func; (`sv; `misc; 1; "When applied to a symbol list where the first element is a file handle and the left argument is a ` sv returns a file handle where the elements of the list are separated by slashes-this is very useful when building write paths"; ""; "wp:`:c:/q/data; (`)sv wp,`2005.02.02,`trade"; `vs)];
insert[`func; (`sv; `misc; 1; "In the case of using sv on a symbol list where the left argument is a ` it returns the elements separated by . this is useful for generating files with the required extension"; ""; "fp:`c:/q/sym; hsym` sv fp,`txt"; `vs)];
insert[`func; (`sv; `misc; 1; "Evaluates base value"; "rl: N sv L"; "10 sv 23 45 677"; `vs)];
insert[`func; (`sv; `misc; 1; "Converts bytes to ints base 256"; ""; "0x0 sv \"x\"$12 3 4 5"; `vs)];
insert[`func; (`system; `essential; 1; "Monadic function which executes system commands i.e. OS commands."; ""; "system\"pwd\""; `$(" "))];
insert[`func; (`tables; `essential; 1; "Monadic function which returns a list of the tables in the specified namespace, this list is sorted."; ""; "tables`."; `$(" "))];
insert[`func; (`til; `essential; 1; "takes positive integer n and returns list of numbers from 0 to n-1"; ""; "til 9"; `key)];
insert[`func; (`type ; `essential; 1; "This monadic function returns the type of its argument as a short integer. Negatives numbers are for atoms, positive numbers are for lists, and zero is a general K list."; ""; ""; `$(" "))];
insert[`func; (`ungroup ; `misc; 1; "The ungroup function monadic function ungroups a table."; ""; ""; `xgroup)];
insert[`func; (`union; `math; 1; "Dyadic function which returns the union of its arguments, i.e. returns the distinct elements of the combined lists respecting the order of the union."; "R:X union Y"; "1 2 3 union 2 4 6 8"; `inter`except)];
insert[`func; (`upsert; `qsql; 1; "Functional form of inserting into a table using the , primitive. It is called upsert because when applied to keyed tables it performs an insert if the key value is not there and otherwise performs an update."; "r: T upsert newEntries"; "([s:`q`w`e]r:1 2 3;u:5 6 7) upsert (`q;100;500)"; `insert)];
insert[`func; (`value; `misc; 1; "This is the same verb as get but is typically used for different things."; ""; ""; `$(" "))];
insert[`func; (`value; `essential; 1; "When passed a dictionary, This gets the values of a dictionary."; "r: value D"; "value `q`w`e!1 2 3"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed an object by reference it returns the value of that object"; ""; "D:`q`w`e!1 2 3 ; value `D"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object has an enumerated type, it returns the corresponding symbol list:"; ""; ""; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object is a lambda, it returns a list:(bytecode;params(8);locals(24);globals(32),Constants(96)"; ""; ""; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object is a projection, it returns a list where projected function is followed by parameters:"; ""; "value +[2]"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object is a composition, it returns a list of composed functions:"; ""; "value rank"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object is a primitive it returns an internal code:"; ""; "value each (::;+;-;*;%)"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed object is an adverb modified verb, it strips the adverb:"; ""; "value (+/)"; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed a string with valid q code, it evaluates it:"; ""; "value\"b:`a`b`c\""; `$(" "))];
insert[`func; (`value; `misc; 1; "When passed a list, applies the first element to the rest:"; ""; "value(+;1;2)"; `$(" "))];
insert[`func; (`value; `misc; 1; "If the first element of the list is a symbol, it is evaluated first:"; ""; "value(`.q.neg;2)"; `$(" "))];
insert[`func; (`var; `math; 1; "Aggregation function which applies to a list of numerical types and returns the variance of the list. Again for the usual reason it works on the temporal types."; "r:var X"; "var 10 343 232 55"; `$(" "))];
insert[`func; (`view; `exotic; 1; "Monadic function which returns the expression defining the dependency passed as its symbol argument."; ""; ""; `views)];
insert[`func; (`views; `essential; 1; "Monadic function which returns a list of the currently defined views in the root directory, this list is sorted and has the `s attribute set."; ""; ""; `view)];
insert[`func; (`vs; `misc; 1; "The dyadic vs vector from scalar function has several uses."; ""; ""; `sv)];
insert[`func; (`vs; `string; 1; "With a character or a string on the left hand side, it tokenizes a string on the right hand side using the left hand side as the specified delimiter. It returns a vector of substrings."; ""; "\",\"vs\"one,two,three\""; `sv)];
insert[`func; (`vs; `misc; 1; "With 0b on the left hand side, it returns the bit representation of the integer on the right hand side."; ""; "0b vs 1024h"; `sv)];
insert[`func; (`vs; `misc; 1; "With 0x0 on the left hand side, it returns the byte representation of the number on the right hand side."; ""; "0x0 vs 1024"; `sv)];
insert[`func; (`vs; `misc; 1; "With ` on the left hand side splits symbols on the . ; breaks file handles into directory and file parts; and domain names into components."; ""; "` vs`:/foo/bar/baz.txt"; `sv)];
insert[`func; (`where ; `qsql; 1; "Where the argument is a boolean list, this returns the indices of the 1's"; ""; "where 21 2 5 11 33 9>15"; `$(" "))];
insert[`func; (`within ; `qsql; 1; "The right argument of this primitive function is always a two-item list. The result is a boolean list with the same number of items as the left argument. The result indicates whether or not each item of the left argument is within the bounds defined by the right argument."; ""; "1 3 10 6 4 within 2 6"; `$(" "))];
insert[`func; (`within ; `qsql; 1; "The within function also applies to chars and syms because both are ordered"; ""; "\"acyxmpu\" within \"br\""; `$(" "))];
insert[`func; (`within ; `qsql; 1; "The within function will also work with a pair of n-ary lists as the right argument and an atom, a n-ary list or n-by-* ragged matrix as the left argument. The results in this case take the shape of the left argument."; ""; "5 within (1 2 6;3 5 7)"; `$(" "))];
insert[`func; (`wj; `qsql; 1; "Window join is a generalization of asof join, and is available from kdb+ 2.6. asof join takes a snapshot of the current state, while window join aggregates all values of specified columns within intervals."; ""; ""; `asof`aj)];
insert[`func; (`wsum; `math; 1; "The weighted sum aggregation function wsum produces the sum of the items of its right argument weighted by the items of its left argument. The left argument can be a scalar, or a list of equal length to the right argument. When both arguments are integer lists, they are converted to floating point. Any null elements in the arguments are excluded from the calculation."; ""; "2 3 4 wsum 1 2 4"; `$(" "))];
insert[`func; (`xasc; `qsql; 1; "Dyadic function-sorts a table in ascending order of a particular column, sorting is order preserving among equals. Takes a symbol list or atom and a table as arguments and returns the original table sorted by the columns as specified in the first argument."; "R:C xasc T"; "t:`sym xasc trade "; `xdesc)];
insert[`func; (`xasc; `qsql; 1; "It can be used to sort data on disk directly. xasc can be used to sort a splayed table on disk one column at a time without loading the entire table into memory. "; ""; "see notes"; `xdesc)];
insert[`func; (`xbar; `qsql; 1; "Interval bars are prominent in aggregation queries. For example, to roll-up prices and sizes in 10 minute bars:"; ""; "select last price, sum size by 10 xbar time.minute from trade"; `$(" "))];
insert[`func; (`xcol; `qsql; 1; "Dyadic function - rename columns in a table. Takes a symbol list of column names and a table as arguments, and returns the table with the new column names. The number of column names must be less than or equal to the number of columns in the table. The table must be passed by value."; "R:C xcol T"; "`A`S`D`F xcol trade"; `xcols)];
insert[`func; (`xcols; `qsql; 1; "Dyadic function - reorder columns in a table. Takes a symbol list of column names and a table as arguments and returns the table with the named columns moved to the front. The column names given must belong to the table. The table must have no primary keys and is passed by value."; "R:C xcols T"; "xcols[reverse cols trade;trade]"; `xcol)];
insert[`func; (`xexp; `math; 1; "This is the dyadic power function."; "r:xexp[X;Y]"; "2 xexp 3"; `xlog)];
insert[`func; (`xgroup; `qsql; 1; "The xgroup function dyadic function groups its right argument by the left argument (which is a foreign key)."; ""; ""; `ungroup)];
insert[`func; (`xkey ; `qsql; 1; "Dyadic function-sets a primary in a table. Takes a symbol list or atom and a table as arguments and returns the original table with a primary key corresponding to the column(s) specified in the first argument."; "R:C xkey T"; "`r xkey ([s:`q`w`e]r:1 2 3;u:5 6 7)"; `$(" "))];
insert[`func; (`xprev; `qsql; 1; "Uniform dyadic function, returns the n previous element to each item in its argument list."; "r:N xprev A"; "2 xprev 2 3 4 5 6 7 8"; `xrank)];
insert[`func; (`xrank; `qsql; 1; "Uniform dyadic function which allocates values to buckets based on value. This is commonly used to place items in N equal buckets."; ""; ""; `xprev)];
insert[`func; (`0:; `io; 1; "Prepare. The dyadic prepare text function takes a separator character as its first argument and a table or a list of columns as its second. The result is a list of character strings containing text representations of the rows of the second argument separated by the first."; ""; "show csv 0: ([]a:1 2 3;b:`x`y`z)"; `$(" "))];
insert[`func; (`0:; `io; 1; "Save. The dyadic save text function takes a file handle as its first argument and a list of character strings as its second. The strings are saved as lines in the file. The result of the prepare text function can be used as the second argument."; ""; ""; `$(" "))];
insert[`func; (`0:; `io; 1; "Load. The dyadic load text function takes file format description as its first argument and a file handle or a list of character strings as its second."; ""; "t:(\"SS\";enlist\" \")0:`:/tmp/txt /load 2 columns from space delimited file"; `$(" "))];
insert[`func; (`0:; `io; 1; "The format description takes the form of a list of types and either a list of widths for each field if the data to be loaded is fixed width, or the delimiter if delimited, if the delimiter is enlisted the first row of the input data will be used as column names and the data is loaded as a table, otherwise the data is loaded as an list of values for each column."; ""; "t:(\"IFC D\";4 8 10 6 4) 0: `:/q/Fixed.txt /reads a text file containing fixed length records"; `$(" "))];
insert[`func; (`0:; `io; 1; "note that when loading text you should specify the identifier as an uppercase letter, to load a field as a nested character column or list rather than symbol use '*' as the identifier and to skip a field from the load use ' '."; ""; ""; `$(" "))];
insert[`func; (`0:; `io; 1; "Optionally, load text can take a three-item list as its second argument, containing the file handle, an offset at which to begin reading, and a length to read."; ""; "(\"SS\";csv)0:(`:/tmp/data.csv;x;x+100000)"; `$(" "))];
insert[`func; (`0:; `io; 1; "Also works for key/value pairs."; ""; "show \"S=;\"0:\"one=1;two=2;three=3\""; `$(" "))];
insert[`func; (`1:; `io; 1; "The 1: dyadic function is used to read fixed length data from a file or byte sequence. The left argument is a list of types and their widths to read, and the right argument is the file handle or byte sequence."; ""; "(\"ich\";4 1 2)1:0x00000000410000FF00000042FFFF"; `$(" "))];
insert[`func; (`1:; `io; 1; "Optionally, it can also take a three-item list as its second argument, containing the file handle, an offset at which to begin reading, and a length to read."; ""; "(\"ii\";4 4)1:(`:/tmp/data;x;x+100000)"; `$(" "))];
insert[`func; (`2:; `io; 1; "The 2: function is a dyadic function used to dynamically load C functions into Kdb+. Its left argument is a symbol representing the name of the dynamic library from which to load the function. Its right argument is a list of a symbol which is the function name and an integer which is the number of arguments the function to be loaded takes."; ""; ""; `$(" "))];
insert[`func; (`1; `io; 1; "Write to standard output"; ""; "1 \"String vector here\n\""; `2)];
insert[`func; (`2; `io; 1; "write to standard error"; ""; "2 \"String vector here\n\""; `1)];

insert[`func; (`lj; `joins; 1; "Left Join - for each row in t, return a result row, where matches are performed by finding the first key in kt that matches. Non-matches have any new columns filled with null."; "t lj kt"; "([] a:1 2; b:3 4) lj ([a:2 3]; c:`p`o)"; `ij`ej`pj`uj`aj`wj)];
insert[`func; (`pj; `joins; 1; "Plus Join - Same principle as lj, but existing values are added to where column names match."; "t pj kt"; ""; `lj`ij`ej`uj`aj`wj)];
insert[`func; (`ij; `joins; 1; "Inner Join - Where matches occur between t and kt on primary key columns, update or add that column. Non-matches are not returned in the result."; "t ij kt"; "([] a:1 2; b:3 4) ij ([a:2 3]; c:`p`o)"; `lj`ej`pj`uj`aj`wj)];
insert[`func; (`ej; `joins; 1; "Equi Join - Same as ij but allows specifying the column names."; "ej[c;t1;t2]"; "ej[sym; trade; quote]"; `lj`ij`pj`uj`aj`wj)];
insert[`func; (`uj; `joins; 1; "Union Join - Combine all columns from both tables. Where possible common columns append or new columns created and filled with nulls."; "t1 uj t2"; "([] a:1 2; b:3 4) uj ([] a:2 3; c:`p`o)"; `lj`ij`ej`pj`aj`wj`aj0)];
insert[`func; (`aj; `joins; 1; "Asof Join -  Joins tables based on nearest time."; "aj[c1...cn;t1;t2]"; "aj[`sym`time; trade; quote]"; `lj`ij`ej`pj`uj`wj)];
insert[`func; (`wj; `joins; 1; "Window Join - Join all aggregates within a given time window to a corresponding table."; "wj[w;c;t;(q;(f0;c0);(f1;c1))]"; "wj[w;`sym`time;trade; (quote;(max;`ask);(min;`bid))]"; `lj`ij`ej`pj`uj`aj`wj1)];
insert[`func; (`select; `qsql; 1; "Select rows from a table."; "select columns by groups from table where filters"; "select max price by date,sym from trade where sym in `AA`C"; `update`delete)];
insert[`func; (`update; `qsql; 1; "Modify the table to update existing values or to create a new column."; "update col by c2 from t where filter"; "update price:price+10 from t where sym=`A"; `select`delete)];
insert[`func; (`delete; `qsql; 1; "two Formats. Either delete rows or delete columns from table."; "delete col from t. delete row from t where filter."; "delete from t where price<10"; `select`update)];
insert[`func; (`lower; `string; 1; "Monadic that converts strings and symbols to lower case"; "lower[text]"; "`small~lower `SMALL"; `upper)];
insert[`func; (`upper; `string; 1; "Monadic that converts strings and symbols to upper case"; "lower[text]"; "`BIG~upper `big"; `lower)];
insert[`func; (`trim; `string; 1; "Monadic that removes leading and trailing whitespace from strings."; "trim[text]"; "\"abc\"~trim \" abc \""; `rtrim`ltrim)];
insert[`func; (`rtrim; `string; 1; "Monadic that removes trailing whitespace from strings."; "rtrim[text]"; "\"abc\"~rtrim \"abc \""; `trim`ltrim)];
insert[`func; (`ltrim; `string; 1; "Monadic that removes leading whitespace from strings."; "ltrim[text]"; "\"abc\"~ltrim \" abc\""; `trim`rtrim)];
insert[`func; (`cols; `misc; 1; "Return a symbol list of column names for a given table, or a list of keys for a dictionary."; "cols[table]"; "cols trade"; `xcol`xcols)];

insert[`func; (`sin; `math; 1; "Accepts a single argument in radians and returns the sine."; "sin[radians]"; "sin 3.141593"; `asin`cos`acos`tan`atan)];
insert[`func; (`asin; `math; 1; "Accepts a single argument in radians and returns the arc sine."; "sin[radians]"; "sin 3.141593"; `sin`cos`acos`tan`atan)];
insert[`func; (`cos; `math; 1; "Accepts a single argument in radians and returns the cosine."; "cos[radians]"; "cos 3.141593"; `sin`asin`acos`tan`atan)];
insert[`func; (`acos; `math; 1; "Accepts a single argument in radians and returns the arc cosine."; "acos[radians]"; "acos 3.141593"; `sin`asin`cos`tan`atan)];
insert[`func; (`tan; `math; 1; "Accepts a single argument in radians and returns the tan."; "tan[radians]"; "tan 3.141593"; `sin`asin`cos`acos`atan)];
insert[`func; (`atan; `math; 1; "Accepts a single argument in radians and returns the arc tan."; "atan[radians]"; "atan 3.141593"; `sin`asin`cos`acos`tan)];

insert[`func; (`log; `math; 1; "Returns the natural logarithm of it's argument"; "log X"; "log 0 1 2.71828"; `exp`xlog`xexp)];
insert[`func; (`sqrt; `math; 1; "Returns the square root of it's argument"; "sqrt X"; "sqrt 0 1 4 9"; `xexp)];
insert[`func; (`abs; `math; 1; "Returns the absolute value of a number. i.e. the positive value"; "abs X"; "abs -2 -1 0 1"; `neg)];
insert[`func; (`min; `math; 1; "Returns the minimum value within a list"; "min X"; "3~min 100 10 3 22"; `max)];
insert[`func; (`sum; `math; 1; "Returns the sum total of a list"; "sum X"; "14~sum 2 4 8"; `max`min)];
insert[`func; (`last; `misc; 1; "Returns the item at the end of the list or table"; "last X"; "7~last 2 3 4 7"; `first)];
insert[`func; (`wavg; `math; 1; "Dyadic where first arg is weights, second is values, returns the weighted average."; "X wavg Y"; "7=1 1 2 wavg 5 5 9"; `wsum)];

insert[`func; (`hdel; `io; 1; "Delete a file."; "hdel fh"; "hdel `:readme.txt"; `hcount)];
insert[`func; (`hcount; `io; 1; "Gets the size in bytes of a file as a long integer."; "hcount fh"; "hcount `:readme.txt"; `hdel)];
insert[`func; (`each; `essential; 1; "Adverb that takes a function as it's first argument and applies it to each item of it's separate argument."; "f each l"; "reverse each (1 2 3;7 8 9)"; `peach)];
insert[`func; (`enlist; `essential; 1; "Take a single argument and return it wrapped it in a list."; "enlist X"; "enlist 1"; `first)];
insert[`func; (`ceiling; `math; 1; "When passed floating point values, return the smallest integer greater than or equal to those values."; "ceiling X"; "ceiling 1.2 3.4 5.8"; `floor)];
insert[`func; (`floor; `math; 1; "When passed floating point values, return the greatest integer less than or equal to those values."; "floor X"; "floor 1.2 3.4 5.8"; `ceiling)];
insert[`func; (`any; `math; 1; "Return 1b if there are any non-zero values in it's argument, otherwise return 0b."; "any X"; "any 1010111001b"; `all)];
insert[`func; (`all; `math; 1; "Function all returns a boolean atom 1b if all values in its argument are non-zero, and otherwise 0b.It applies to all data types except symbol, first converting the type to boolean if necessary."; "any X"; "any 1010111001b"; `any)];

delete n from `func;

/#########################   BELOW FUNCTIONS TAKEN FROM AARON DAVIES google groups post
/ http://groups.google.com/group/personal-kdbplus/browse_thread/thread/1e4d3a2ee663f67c#
mapd:{y!x y,:()}

dfilter:{where[x y]#y,:()}

/ gets the fully-qualified names of everything in or below its argument (which is defaulted to do both `. and key`, i.e. everything) 
wtfcat:{$[$[null x;1;99=type get x;`~first key x;0b]|`.~x;
 (raze/).z.s each'x .Q.dd''key each x:$[null x;`.`;x];x]}

 / gets specifically all the lambdas in the workspace, then recursively searches them for embedded lambdas and gives those unambiguous names 
wtffd:{(!). flip raze
 {enlist[(x;y)],raze .z.s'[(x,`lambda).Q.dd/:til count p;p@:where 100=type each p:get y]}.'
  {key[x],'get x}dfilter[100=type each]mapd[get each]wtfcat x}

  / wtf returns the name of a function matching its argument (intended use is wtf ".z.s") 
wtf:{{((key y) x)!((value y) x)}[where (string key a) like (x,"*");a:wtffd[]]} 


/#########################   BELOW FUNCTIONS TAKEN FROM AARON DAVIES K4 Post

createBlankFromTablePreserveAttribs:{[table] flip(table`c)!(table`a)#'((x:0!meta table)`t)$\:()}
createBlankFromTablePreserveCustomEnums:{[table] flip cols[table]!{attr[table]#key[table]$()}each get .Q.V table}
createBlankFromTablePreserveForeignKeys:{[table] flip cols[table]!{attr[table]#$[(19<t)&-10!t:type table;![;`int$()];$[;()]]key table}each get .Q.V table}

\d .
.man.:{	.man.whatis[x]}

/#########################   WARNING COMMENT BELOW BLOCKS ANYTHING BELOW HERE FROM BEING PROCESSED
/
/ see what all can be ran
.man

/ get listing commands etc.
.man.dotz
.man.dotQ
.man.slash
.man.bang
.man.errors
.man.types
.man.cmdline
.man.funcs

/ to lookup one thing
.man.whatis[".z.D"]
/ can shortcut to just this
.man.".z.D"
.man."\\p"
.man."-1!"
.man."type"
.man."-p"
.man."msum"
.man."0:"

/ type command with english explaination
.man.typr[(1 2;3;4.0 5.0; 6.0; 1b; {x})]
.man.typr each (1 2;3;4.0 5.0; 6.0; 1b; {x})


/#########################  Output for use in java prog
{1 string[x`sym],"(\"",string[x`sym],"\",\"",(x`args),"\",\"",(x`description),"\"));\n";}each (0!.man.cmdline)
/ 
{1 "kf.add(new Function(\"",string[x`sym],"\",\"",(x`description),"\"));\n"}each 0!select first description by sym from .man.func
{"dq.add(new DotQ(\"",string[x`sym],"\",\"",(x`description),"\"));\n"}each (0!.man.dotQ)

getForLexer:{"\" | \"" sv {$[count a:ss[x;"["];first[a]#x;x]} each string exec distinct sym from x}
getForLexer .man.func
getForLexer .man.dotQ
