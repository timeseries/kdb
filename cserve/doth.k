/ Ryan Hamilton
/ for explanation of builtin functions see https://code.kx.com/trac/wiki/Doth 

/ ############ Configuration Section ################################

\C 300 250
\c 25 100


\d .h

LOGQUERIES:1b; / log to console query details
HIDDENNS:`q`h`man`Q`o`os`dbm`pd`html`j; / name spaces not to list in the menu
RUNNER:.:; / function used to run queries.
id:0;

/ need unique id's for some things
getId:{id::id+1; if[id>9999; id::0]; id};

/ ############ Constants ####

/ human readable form PC name / IP address
pcLoc:{($: .z.h)," ",("."/:$: `int$0x00 \: .z.a)};

FRAMESET:{
	title:	pcLoc[]," | qWebExplorer";
	a:"<link rel='icon' href='./favicon.ico' type='image/x-icon' /><link rel='shortcut icon' href='./favicon.ico' type='image/x-icon' />";
	a,:"<frameset frameborder='no' cols='220,*' scrolling='yes'><frame src='/?'><frame name='v' src='index.qhtml'></frameset>"
	htc[`html](htc[`head]htc[`title;title]),a}[];


CACHEDHEADER:{ bb:"\r\nLast-Modified: Tue, 15 Nov 1994 12:45:26 GMT\r\nExpires: Sun, 17-Jan-2038 19:14:07 GMT";
	cc:"\r\nCache-Control: Public, max-age=31536000\r\nConnection: close\r\nContent-Length: ";
	"HTTP/1.1 ",x,"\r\nContent-Type: ",$[#t:ty y;t;"application/octet-stream"],bb,cc,($#z),"\r\n\r\n",z}["200 OK"]	

addJs:{htac[`script;`type`src!("text/javascript";x)]""};
addCss:{htac[`style;(,`type)!,"text/css"]"@import '",x,"';"};

HEADER:{a:,"<html><head>";
	a,:,addCss'[("style.css";"codemirror.css")];
	a,:,addJs'[("sortable.js";"codemirror.js"; "google-jsapi.js")];
	,/,/ a,:,"</head><body id='dataRes'><div id='inner'>"}[];
	
FOOTER:{"</div> <div class='footer'><p><a href='http://www.timestored.com/kdb-guides/kdb-keyword-reference'>Function List</a> | <a href='http://www.timestored.com/kdb-guides/'>kdb Tutorials</a></p></div></body></html>"}[];	
	
TREEHEADER:{ a:,"<html><head>";
	a,:,addCss["style.css"],addJs["simpletreemenu.js"];
	a,:,"</head><body id='listing'><h1 id='logo'><a href='/index.qhtml' target='v'><span>q</span>Web<span>Explorer</span></a></h1>";
	a,:,"<div id='shortcuts'>";
	ms:{"<a href='",x,"' target='v'><img src='d.gif' class='icon ",y,"' title='",z,"' alt='",z,"' /></a>"};
	a,:,ms["/index.qhtml"; "ic_home"; "home"];
	a,:,ms["query.html"; "ic_tabgo"; "query manager"];
	a,:,ms["chart.html"; "ic_chart"; "time series chart"];
	a,:,ms["help.html"; "ic_help"; "help"];
	a,:,{"<a href='",x,"'><img src='d.gif' class='icon ",y,"' title='",z,"' alt='",z,"' /></a>"}["/?"; "ic_refresh"; "reload navigation pane"];
	,/ a,:,"</div>"}[];

TREEFOOTER:{ c:htac[`script;(,`type)!,("text/javascript")]"ddtreemenu.createTree(\"treemenu1\", true)";
	c,"</body></html>"}[];	
	
	
/ ############ common code ################################

logg:{$[LOGQUERIES; 1 .Q.s x; ::]};

/ get the html for a select drop down of options with a selected item
/ @params string selected an  entry in the options array
/ @param options list of strings
getSelect:{[id; options; selected]
	a:,"<select name='",id,"' id='",id,"' onchange='this.form.submit()'>";
	a,:, ({.h.htac[`option; $[y~x; (,`selected)!(,`$"\"selected\""); ()!()]; y]} selected)'[options];
	,/ a,:,"</select>"};
	
/ get the html for a list of links
/ @param options list of strings
getLinkList:{[id; linkPrefix; options; classes]
	a:,"<ul name='",id,"' id='",id,"'>";
	a,:, {.h.htac[`li; (,`class)!(,`$"\"abba\""); "<a href='",x,y,"'>",y,"</a>"]}[linkPrefix;]'[options];
	,/,/ a,:,"</ul>"};

/ activate the javascript to fancily style a textarea using codemirror
/ @param - mode `q`k for that code, anything else for other
getCodemirrorJs:{ [textAreaId; editable; mode]
	a:,"<script type=\"text/javascript\">var myCodeMirror = CodeMirror.fromTextArea(";
	a,:,"document.getElementById(\"",textAreaId,"\"), ";
	a,:,"{lineNumbers: true, matchBrackets: true, indentUnit: 4, tabMode: \"default\"";
	a,:,$[mode in `q`k; ", mode: \"text/x-plsql\""; ""];
	a,:,", readOnly:",$[editable; "false"; "true"];
	,/ a,:," });</script>"}

/ run the supplied q query and return html showing its code and result	
runAndShowQry:{ [qry] 
	res:$[~0=#qry; @[{(1;.h.RUNNER x)}; qry; {(0;x)}]; ()];
	PRE:"<form id='myForm' class='boxy' action=''><label>Query: <textarea rows='2' cols='20' id='query'>";
	POST:"</textarea> </label></form>Result:",getCodemirrorJs["query";0b;`q];
	$[#res; ,/PRE,qry,POST,"<div class='boxy",($[res 0;"'>";"err'>Error! "]),($res[1]),"</div><hr/>"; ""]};	
	
	
/ sublist that works for partitioned tables also	
subblist:{$[.Q.qp[y]; .Q.ind[y;`long$x[0] + ! x[1]]; .q.sublist[`int$x;y]]};
	

/ parse html query e.g. a=10&c=hello return dict `a`c!(10;"hello")
parseQ:{ 
	$[0~# .q.trim x; :()!(); ::]; 
	ar:{a:last x ss "="; (`$a#x;(a+1) _x)} ' "&" \:x;
	{$[1=#:x;x 0;x]}'[(.:b) @ =: !b:ar[;0]!ar[;1]]};

/ take a multiline query and report the time/space required for each line	
benchByLine:{ b:+: `n`line`time`space!+: (1+!#a),'{(.q.enlist x),.q.system "ts ",x} ' a:"\n"\:x;
	fmt:{.Q.fmt[5;1] ' 100*x%sum x};
	update pctSpace:fmt space,pctTime:fmt time from b};
		
/ ############ the data table and making it sorted
	
/ return the html represntation of a table (p means partitioned supported)
/ x - table to be shown
/ z - full table with attributes on it
formatPTableWithMeta:{  [x;y;z]
	g:{(#*y)#'(,,"<",x),y,,,"</",x:($x),">"};
	colStyles:" ";
	if[.Q.qt z;
		clss:{($[~x 3; "nk"; "key"]; $[^x 2; "na"; "att",$x 2])}' +.+. update k:c in .q.keys z from .q.meta z;
		colStyles:,/ {"<col class=\"",x,"\"/>"} ' {" "/: x} ' clss];
	rowVals:,/`td g',:'{$[(~:10h=@:x) & 0<@:x; .Q.s x; $:x]}''. x:+0!x;
	,/ ,/htac[`table;y] colStyles,(htc[`thead]htc[`tr]@,/htc[`th]'$!x),htc[`tbody]@,/,/'+g[`tr]@rowVals}; 

	
/ for partitioned table support
formatPTable: { bacup:{y;htc[`pre]@.q.ssr[;"\n";"<br />"] .Q.s x}[y;]; 
	@[formatPTableWithMeta[x; (,`class)!(,,"sortable")]; y; bacup]};
/ convert a q table to an html table with sortable columns
formatTable: {formatPTable[x;x]};
	
	
qTypeToJStype:(``b`d`i`f`e`j)!("string";"boolean";"date";"number";"number";"number";"number");	
getJStype:{$[""~a:qTypeToJStype[`$x];"string";a]};


formatGoogVis: { [query]
	tabVal:.h.RUNNER .h.uh $[0N ~ c:(last query ss "&tqx="); query; c#query];
	reqId: $[~: 0N ~ c:(last query ss "&tqx=reqId:"); "I"$ (c+11)_query; ~: 0N ~ c:(last query ss "&tqx=reqId%3A"); "I"$ (c+13)_query; 0];
	logg ,/ "reqId = ",($: reqId),"  query = ",$: query;
	t:{select c, {, getJStype[x]}' t from 0!.q.meta x} tabVal;
	colDat: ,/,/ {,/ "\n\t{id:'",($: x[0]),"', type: '",($: x[1]),"'},"} ' +: .: +: t;
	jsonCols:"cols: [",colDat,"]";
	rowDat: ,/,/  {,/  {"\n\t{c:[",x,"]},"}' +: {"{v: ",$["string"~getJStype[`char$32 + `int$ .Q.ty x];"'",($: x),"'";$: x],"},"}'' (.: +: x)} tabVal;
	,/ "google.visualization.Query.setResponse({\nstatus:'ok', reqId:'",($: reqId),"', \ntable:{\ncols: [",colDat,"], \n\nrows: [",rowDat,"]\n}\n})" };

	


/ dictionary of .Q.qp result to symbol of table type
tableType:(0b;1b;0)!(`splayed;`partitioned;`memory);
tableDesc:{ ($:tableType[.Q.qp x]),", ",($:#x)," rows" };

/ wraps most html data results to give css/js needed		
htmlForDataTable:{HEADER,x,FOOTER};

/ get the html for a simple data type (form box)
/ v is the data itself (e.g. 1 2 3 or {1+x}
getSimpleAsHTML:{ [x; showEditor] 
	/ check param is actual variable or value
	res:@[{(1;.h.RUNNER x)}; x; {(0;x)}]
	v:res 1;
	isSimple:{within[@x;(-19;19)] | within[@x;(99;112)] & (0b~.Q.qt x)};
	if[(~res 0) | ~isSimple v; :()]; / if problems return empty
	
	isEditable:{(0=#x) | (abs@ @:x) in 1 2 3 4 5 6 7 8 9 11 100h};
	isEd:isEditable[v] & showEditor;
	logg "getSimpleAsHTML -> isSimple= ",($:isSimple[v]),"   isEd= ",$:isEd;
	
	name:,/,"qd-",$:getId[];
	a:,(htac[`textarea; (`name`id)!(name;name)] @ ($[""~v; ""; isEd; -3!v; .Q.s v]));
	a,:,getCodemirrorJs[name; isEd; `q];
	a,:,$[isEd; "<button onclick=\"saveVar('",x,"','",name,"');\">Save</button>"; ""];
	,/htc[`pre] @a};

/ x can be either a KDB statement e.g. "1 2 3" or a variable name e.g. "v"
/ but if a statement, showEditor MUST be false
getVarAsHTML:{ [x; showEditor]
		logg "getVarAsHTML ",x,"   showEditor=",$:showEditor;
		$[#r:getSimpleAsHTML[x; showEditor]; r; {@[{,/ formatTable subblist[0,(*."\\C"); x] };x;he]}[.h.RUNNER x] ]};
	
/ ############ listing code - makes pretty hierachical menu #############################

/ x in the fgollowing is a symbol e.g. `.q  `.  `.  man etc.
getTables:{.q.asc {."\\a ",$$[^x;`;x]} x};
getViews:{.q.asc {."\\b ",$$[^x;`;x]} x};
getVars:{a:{."\\v ",$$[^x;`;x]} x; .q.asc a@&:~: a in getTables[x]};
getFuncs:{b:.q.asc (!:a)@&: .: {(x>99) & x<113} a:@:' .: x; b@&:~: b in getViews[x]};
getDisplayables:{.q.asc (!:a)@&: .: 100=a:@:' .: x};

/ text description of variable type
typr:{$: @: x};

/ make a list of the given items in a namespace (ns) and set the class of the links li to (lnkClass)
makeListy:{[ns;items;lnkClass] 
	formatTblLink:{[ns;item;lnkClass] 
		lnk:,/ $[ns in `.q`.; ($:item); ($:ns),".",($:item)];
		/ show args for functions
		txt:item,$[100h~@:(.: lnk); $[~`x~c:(. . lnk)[1]; "[",(";"/:$c),"]"; ""]; ""];
		htac[`li;(`title`class)!((vv);,/,/lnkClass," ",(" "/:"typ",/: 1_" "\: vv:typr[. ,/,/$:lnk]))]htac[`a;(`target`href)!(,"v";(,/"i.qhtml?e=",lnk))]@txt };
	formatTblLink[ns;;lnkClass]@'$:items};
	
/ make a list of links from the array (("name";"url1");("name2";"url2"))	
makeListyLinks:{[activeName;namesHrefsArray] 
	formatLink:{[activeName;nameHref] 	
		name:nameHref[0];
		href:nameHref[1];
		attribs:(`target`href)!(,"v";(href));
		$[activeName~name; attribs[`id]:"current"; ::];
		htc[`li]htac[`a;attribs]@name };
	formatLink[activeName]@'namesHrefsArray};
	

/ get the menu for a given namespace x
getMenu:{ 
	parseNS:{
		ml:makeListy[x;;];
		wrap:{ [ns;content]
			ulAttribs:$[ns=`.; (,`rel)!(,"open"); ()!()];
			htc[`li]($:ns),(htac[`ul; ulAttribs]@,/ content) }[x;];
		
		tabs:getTables[x];
		b:$[0<#tabs;ml[tabs;"tbl"];""];
		c:$[0<#vws:getViews@x; ml[getViews@x;"vw"]; ""];
		d:$[0<#vars:getVars@x; htc[`li]@"variables",htc[`ul]@ml[vars;"vars"]; ""];
		e:$[0<#funcs:getFuncs@x; htc[`li]@"functions",htc[`ul]@ml[funcs;"func"]; ""];
		wrap b,c,d,e };
	htac[`ul;(`id`class)!("treemenu1";"treeview")]@ ,/ parseNS @' `.,`$".",'$: .q.except[!:`; HIDDENNS]};
		

/ ############ pages - dictionary holds page name to function mapping #############################	

pageDict:()!();

/ return the HTML for this link or null if no page found
getPage:{ [pagename] 
	logg "pagename = ",pagename;
	ttmp:getPageParamPair@pagename;
    logg "ttmp= ",.Q.s ttmp;
	logg "  keypage = ",($:ttmp 0),/ "  args = ",$:ttmp 0;
	$[100h=@:page:pageDict[ttmp 0]; ,/htmlForDataTable@page@parseQ@ttmp 1; ""] };
	
/ the index page
pageDict[`$"index.qhtml"]:{  [args]
	a:, "<h1>",pcLoc[],"</h1>";
	a,:,"<h2>Server</h2>";
    setting:(".z.a";".z.h";".z.i";".z.k";".z.K";".z.o";".z.u";".z.x";"\\s");
	a,:,formatTable[([setting] val:.:'setting)];
	a,:,"<h2>Memory Usage</h2>";
	,/a,:,formatTable[+: {,x}'.Q.w[]]};

/ given a folder e.g. ".", return a list of its contents of form (isFolder; fullPath; fileOrFolderName)
ff:{ ({ fp:,/ $: x,"/",y; (11h=@! -1!`$fp; fp; y; -21! -1! `$fp) }[x;]) ' (`$".."),! -1!`$x}

showNice:{ ::;
	lnk:{"<a href=\"files.qhtml?dir=",($x[1]),"\">",($x[2]),"</a>"};
	icn:{$[x[0];"<img src='images/closed.gif' />";$[".q"~-2#$x[2]; "q"; $[".k"~-2#$x[2]; "k"; $[".txt"~-4#$x[2]; "<img src='images/txt.gif' />"; ""]]]]};
	del:{$[~: x[0]; "<a href=\"files.qhtml?dir=",($x[1]),"&act=del\"><img src='images/delete.png' /></a>"; ""]};
	cmp:{$[0~#a:x[3]; ""; "c ",($:`int$100 * a[`compressedLength] % a[`uncompressedLength]),"%"]};
	,/,/"<tr><td>",icn[x],"</td><td>",lnk[x],"</td><td>",cmp[x],"</td></tr>"}


/ paginate table entries
/ x is the query itself (no ? etc.) e.g. "10 20 sublist dailyTable", "tableB"...
/ v is the value of the item
paginate:{[x;j;v]
	k:j + N:(*."\\C");
	logg "paginate -> j = ",($: j),"  k = ",$: k;
	genQuery:{,/"?e=",y,$[~x=0;"&amp;o=",$(x); ""]}[;x];
	a:$[N<n:."k)#",x; htac[`ul;(,"class")!,("pagin")]@(" "/:{htc[`li]@ha[x;y]}'[genQuery@/:(0;0|j-N),|&\(n-N;j+N);$`home`up`down`end],,($j),"-",($k)," of ",($n);"");()];
	,/a,:,formatPTable[subblist[j,N; v]; v]};	
	
	
/ given the name of a table, show the table for its meta
getMetaTab:{ 
	/ create javascript link to function-funcName for given tab, col
	jLnk:{[tab; otherArgs; funcName; imgName; txt; col] 
		attrs:(`href`onclick)!(,"#";,/funcName,"('",$tab,"','",col,"'",otherArgs,");");
		htac[`a;attrs;"<img src='images/",imgName,".png' />",txt," "]}[x];
	lnk:jLnk[""];
	.q.meta (a:.h.RUNNER x)};

/ tab displayed when user clicks on tree menu	
pageDict[`$"i.qhtml"]:{ [args]
	e:$[0=#args[`e]; "1"; args[`e]];
	o:$[0=#args[`o]; 0j; "J"$args[`o]];
    v:.h.RUNNER e;
	subTitles:$[.Q.qt[v]; ("Data";"Meta")!("Data";"Meta"); ()!()];
	p:$[0=#subTitles[args[`p]]; "Data"; args[`p]]; / default page
	logg ,/,/ "i.qhtml p=",($p)," e=",($e)," o=",$o;
	a:, "<h1>",($e),"</h1>";
	a,:,$[0=#subTitles; ""; htac[`ul; (,`id)!,("tablist")]@ makeListyLinks[p]@ +: (.: subTitles;(,/ "i.qhtml?e=",($e),"&amp;o=",($o),"&amp;p="),/: !:subTitles)];
			
	/ was some kind of q query sent
	res:runAndShowQry[args[`qry]];
	a,:,$[p~"Data"; "<div id='iqhtml'><p>",$[.Q.qt[v]; paginate[e;o;v]; getVarAsHTML[e;0b]],"</div>"
		p~"Meta"; res,"<p>",(tableDesc (v)),"</p>",formatTable[getMetaTab e]
		""];
	,/ a}

/ ############ bringing it all together

getPageParamPair:{$[0N=a:*: &: "?"=x; (`$x;""); (`$x@ !:a;(a+1)_x)]};

.z.ph:{
  isHtml:{".html" ~ x (-1 + #:x) - |: !: 5};
	x:uh$[@x;x;*x];
    pp:@[getPageParamPair;x;(`;"")];
	$[LOGQUERIES;1 "\n----.z.ph ",.Q.s x; ::];
	doFrameset:{hy[`htm]FRAMESET};
	$[~#x; doFrameset[x]
  x~,"?"; {hy[`htm] TREEHEADER,getMenu[],TREEFOOTER}[]
  ".gjs?"~5#x; formatGoogVis[5_x]
  "?]"~2#x; getVarAsHTML[2_x; 0b]     / raw result for ajax tables
  "?["~2#x; hy[`htm] @[{.Q.s .h.RUNNER x};2 _ x;{"'",x,"\r\n"}]  / raw result for console
  "?"=*x ; hy[`htm]htmlForDataTable@getVarAsHTML[1_x; 0b]
  #r:@[1::;0N!`$":",p:HOME,"/",$pp 0;""]; $[isHtml[$pp 0]; hy; CACHEDHEADER] [0N!`$(1+x?".")_$pp 0; "c"$r]
  ~: ""~dynaPage:getPage[x]; hy[`htm]  dynaPage / if in dictionary of dynamic pages return result
  "?"in x; @[{hy[t]@`/:tx[t:`$-3#n#x]@ .h.RUNNER (1+n:x?"?")_x};x;he]
    hn["404 Not Found";`txt]p,": not found"]};

 
\d .

/ handle the simplest posts by replacing the space with ampersand
.z.pp:{ 0N!x[0]:(p#x 0),"&",.q.ssr[;,"+";," "]  (1+p:last ss[x 0;," "])_x 0; .z.ph x};
.h.ty[`qhtml]:"text/html"
.h.ty[`html]:"text/html"
.h.ty[`jsn]:"application/json"
.h.tx[`gjs]:{, .h.formatGoogVis  x}


.h.formatGoogVis "([] a:1 2 3; b:`p`o`i)";
.h.formatGoogVis "([]%20name:(%22aa%22;%22bb%22;%22cc%22);%20a:3?10.0)&tqx=reqId%3A1";

/ .h.formatGoogVis [([] task:`work`eat`commute; timeTaken:1 2 3)];

/
/ ######## IDEAS
- In query editor allow profiling of one call. Instument, make call, deinstrument
- write unit tests
- event handler override system screen
- look at program anew with critical eye of making things perfect!
- test in IE also, definite issues with CSS and javascript