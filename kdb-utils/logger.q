/ #########################   logging to disk/table/console
/ a logger based on java's, including handlers,filters,formatters. But note there is only one gloal logger.
/ handlers - are notified when a logging event occurs
/ formatters - convert a logrecord into a string
/ filters - restrict what messages are actually logged
/ .
/ example uses
/ .logger.addHandler[.logger.getConsoleHandler[ .logger.getLevelFilter[`INFO]; .logger.getSimpleFormatter[] ] ]
/ .logger.addHandler[.logger.getFileHandler[ .logger.getLevelFilter[`WARNING]; .logger.getXMLFormatter[]; `:a.xml ] ]
/ .logger.addHandler[.logger.getTableHandler[ .logger.getLevelFilter[`INFO]; `bob ] ]
/ .logger.info["myClass";"err txt message"]

\d .logger

levels:((`OFF`SEVERE`WARNING`INFO`CONFIG`FINE`FINER`FINEST`ALL)!(8 7 6 5 4 3 2 1 0));
handlers:();

/### change any arg passed in, into a string
frmt:{$[10=abs type x; x; @[{""{x,"\n",y}/.h.td x}; x; "\r\n",.Q.s x]]}

/### Writes brief "human-readable" summaries of log records.
getSimpleFormatter:{ {[logRecord]	
	s:{[logRecord] (string .z.z)," #",(string logRecord[`level]),"# @",logRecord[`class],"@ ",frmt logRecord[`message]};
	$[(type logRecord)=99h; s[logRecord]; ""]}}

/### Writes detailed XML-structured information.
getXMLFormatter:{ {[logRecord]
		s:{[logRecord] "<record><date>",(string .z.z),"</date><level>",(string logRecord[`level]),"</level><class>",logRecord[`class],"</class><message>",(frmt logRecord[`message]),"</message></record>" };
		$[(type logRecord)=99h; s[logRecord]; ""]}}

/### Filters logRecords by only permitting ones at the filterLevel or above
getLevelFilter:{ [filterLevel]  
		filter:{ [filterLevel;logRecord]  $[ levels[logRecord[`level]]>=levels[filterLevel]; logRecord; ::]};
		filter[filterLevel;] }

/ ### log an actual message, notice its spelt with a Q, loQ, apply all handlers to this latest log entry
/ @param level - a logger.levels symbol, in order (higher priority first) `SEVERE`WARNING`INFO`CONFIG`FINE`FINER`FINEST
/ @param class - a string describing the class/namespace the logging is occuring in
/ @param message - the message to log
loq:{ [level;class;message] 
	// using a dictionary allows handlers arguements to be changed in future + allows overloading
	logRecord:(`level`class`message)!(level;class;message); 
	// pass the logRecord to all handlers
	(til count handlers) handlers \:logRecord; }

/### Handy Functions to make calling easier
severe:{ [class;message] loq[`SEVERE; class; message] }
warning:{ [class;message] loq[`WARNING; class; message] }
info:{ [class;message] loq[`INFO; class; message] }
config:{ [class;message] loq[`CONFIG; class; message] }
fine:{ [class;message] loq[`FINE; class; message] }
finer:{ [class;message] loq[`FINER; class; message] }
finest:{ [class;message] loq[`FINEST; class; message] }

/### adds a handler to the list of log handlers notified
addHandler:{[handler] handlers,:enlist(handler);}


/### A simple handler for writing formatted records to Console  
getConsoleHandler:{ [Filter;Formatter] 
		f:{ [Filter;Formatter;logRecord] str:Formatter Filter logRecord; $[(count str)>1;-1 str;]; ::};
		f[Filter;Formatter]  }

/### A handler that writes formatted log records to a single file
getFileHandler:{ [Filter; Formatter; filename]
		lfile:hopen filename; 
		logToFile:{[Filter;Formatter;logfile;logRecord] str:Formatter Filter logRecord; $[(count str)>1;(neg logfile) str;]; ::};
		logToFile[Filter;Formatter;lfile;]}


logTables:()!();		
/### A handler that writes log records to a single table
getTableHandler:{ [Filter; tableName]
		.logger.logTables[tableName]:: ([] level:(); class:(); message:());
		logToTable:{[Filter;tableName;logRecord] lr:Filter logRecord; $[(type lr)=99h; [temp::.logger.logTables; temp[tableName] insert value lr]; ::] };
		logToTable[Filter;tableName;]}		

		
/#########################   logging remote calls etc

operations:([] startTime:(); handle:();host:();username:();operation:();duration:();mem_delta:();mem_actual:();synch_or_asynch:())

/ log remote calls to the operations table
on:{[] .log.off[];
	.z.pg:{mem_start:(value "\\w");
	t_start:.z.t;
	comm:"ts res:",x;
	show comm;
	space:system comm;
	mem_delta:(value "\\w")-mem_start; 
	dur:.z.t-t_start;
	insert[`.log.operations;(t_start;.z.w;.z.h;.z.u;x;dur;mem_delta[0];space[0];`synch)];res}; }

/ stop logging remote calls
off:{[] value "\\x .z.pg"; value "\\x .z.ps"}
\




\d .
