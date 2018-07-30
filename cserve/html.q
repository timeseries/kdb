/ HTML helper library - Allows generating HTML to display kdb objects
/ © TimeStored - Free for non-commercial use.

system "d .html";


getHeader:{ [cssList; jsList; title; bodyDict; moreHeader]
    a:enlist "<html><head>";
	a,:enlist .html.addCss'[cssList];
	a,:enlist .html.addJs'[jsList];
	raze raze a,:enlist moreHeader,"</head>",.h.hta[`body;bodyDict]};

getFooter:{ "</body></html>" };	
	

addJs:{.h.htac[`script;`type`src!("text/javascript";x)]""};
addCss:{.h.htac[`style;(enlist `type)!enlist "text/css"]"@import '",x,"';"};


/ get the html for a select drop down of options with a selected item
/ @params string selected an  entry in the options array
/ @param options list of strings
getSelect:{[id; options; selected]
	a:enlist "<select name='",id,"' id='",id,"' onchange='this.form.submit()'>";
	a,:enlist  ({.h.htac[`option; $[y~x; (enlist `selected)!(enlist `$"\"selected\""); ()!()]; y]} selected)'[options];
	raze a,:enlist "</select>"};
	
/ get the html for a list of links
/ @param options list of strings
getLinkList:{[id; linkPrefix; options; classes]
	a:enlist "<ul name='",id,"' id='",id,"'>";
	a,:enlist  {.h.htac[`li; (enlist `class)!(enlist `$"\"abba\""); "<a href='",x,y,"'>",y,"</a>"]}[linkPrefix;]'[options];
	raze raze a,:enlist "</ul>"};

/ activate the javascript to fancily style a textarea using codemirror
/ @param - mode `q`k for that code, anything else for other
getCodemirrorJs:{ [textAreaId; editable; mode]
	a:enlist "<script type=\"text/javascript\">var myCodeMirror = CodeMirror.fromTextArea(";
	a,:enlist "document.getElementById(\"",textAreaId,"\"), ";
	a,:enlist "{lineNumbers: true, matchBrackets: true, indentUnit: 4, tabMode: \"default\"";
	a,:enlist $[mode in `q`k; ", mode: \"text/x-plsql\""; ""];
	a,:enlist ", readOnly:",$[editable; "false"; "true"];
	raze a,:enlist " });</script>" };

qTypeToJStype:(``b`d`i`f`e`j)!("string";"boolean";"date";"number";"number";"number";"number");	
getJStype:{$[""~a:.html.qTypeToJStype[`$x];"string";a]};


/ return the html represntation of a table (p means partitioned supported)
/ x - table to be shown
/ y - dictionary of class/id to their values for html etc.
/ z - full table with attributes on it
formatPTableWithMeta:{  [x;y;z]
	g:{("<",x),y,"</",x:(string x),">"};
	colStyles:" ";
	if[.Q.qt z;
        mt:update k:c in keys z from meta z;
		clss:{($[x `k; "key"; "nk"]; $[null x `a; "na"; "att",string x `a])} each mt;
		colStyles:raze {"<col class=\"",x,"\"/>"} each {" " sv x} each clss];
    valArray:flip value flip () xkey x;
    toString:{$[(not 10h~type x) & 0<type x; .Q.s x; string x]};
	rowVals:(g[`td]'') toString''[valArray];
    tblB:.h.htc[`tbody] raze g[`tr] each raze each rowVals;
    tblH:.h.htc[`thead] .h.htc[`tr] raze .h.htc[`th] each string cols x;
	raze raze .h.htac[`table;y] colStyles,tblH,tblB}; 

	
/ for partitioned table support
formatPTable:{ [tbl; tblOrSpecialPartitionTbl]
    AA::(tbl; tblOrSpecialPartitionTbl);
	bacup:{y;.h.htc[`pre]@ ssr[;"\n";"<br />"] .Q.s x}[tblOrSpecialPartitionTbl;];
	@[.html.formatPTableWithMeta[tbl; (enlist `class)!(enlist `sortable)]; tblOrSpecialPartitionTbl; bacup]};
	
/ convert a q table to an html table with sortable columns
formatTable: {.html.formatPTable[x;x]};
	
/ .html.formatTable  ([] a:1 2 3)


formatGoogVis: { [query]
	tabVal:value .h.uh $[0N ~ c:(last query ss "&tqx="); query; c#query];
	reqId:$[not 0N ~ c:(last query ss "&tqx=reqId:"); 
        "I"$(c+11)_query; 
    not 0N ~ c:(last query ss "&tqx=reqId%3A"); 
        "I"$(c+13)_query; 
        0];
	/ logg "reqId = ",($: reqId),"  query = ",query;
	t:{select c, .html.getJStype each t from 0!meta x} tabVal;
    toStrings:({$[10h=type x; x; string x]}'');
	colDat:raze  {"\n\t{id:'",x[0],"', type: '",x[1],"'},"} each toStrings[flip value flip t];
	jsonCols:"cols: [",colDat,"]";
    rr:flip {"{v: ",$["string"~.html.getJStype[`char$32 + `int$ .Q.ty x];"'",(string x),"'";string  x],"},"}''[value flip tabVal];
	rowDat: raze raze {"\n\t{c:[",x,"]},"} each rr;
	raze "google.visualization.Query.setResponse({\nstatus:'ok', reqId:'",(string reqId),"', \ntable:{\ncols: [",colDat,"], \n\nrows: [",rowDat,"]\n}\n})" };

	
system "d .";