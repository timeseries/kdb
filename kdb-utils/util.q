/ Generic q Utilities
/ Only for storing functions that a)Have no dependencies other than logging b)Can go nowhere else
/ © TimeStored - Free for non-commercial use.

.log.info:.log.warn:.log.error:{1 string[.z.t],$[type[x]=98h; "\r\n"; "  "],$[type[x] in 10 -10h; x; .Q.s x],"\r\n"; x};

system "d .util";

/ Protectively evaluate a handle or function against an object, log any exception stack traces and return the result.
/ @param hndOrFunc Handle or function that will be called
/ @param obj Object that the function or handle is applied to
call:{ [hndOrFunc; obj]
    errHandler:{.log.error "Calling ",.Q.s1[x]," error: ",y,"\tbacktrace:\t",.Q.sbt z; 'y}[(hndOrFunc;obj);];
    .Q.trp[hndOrFunc; obj; errHandler] };
    
/ Protectively evaluate a handle or function against an object, log any exceptions and return the result.
/ Note a full stack trace is not provided in order to provide a quicker function than call. (Roughly 2x the speed)
callFast:{ [hndOrFunc; obj]
    errHandler:{.log.error "Calling ",.Q.s1[x]," error: ",y; 'y}[(hndOrFunc;obj);];
    @[hndOrFunc; obj; errHandler] };

/ Protectively evaluate a command, returning only a boolean, true for success, false for error.
apply:{ [hndOrFunc; obj] 
    @[{x y;1b}[.util.call[hndOrFunc;];]; obj; {0b}] };

/ Call a system command while logging before and after the call including exceptions
sys:{ [cmdString]
    .log.info "system: ",cmdString;
    .util.callFast[system; cmdString] };
    
system "d .";