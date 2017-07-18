/ Table manipulation functions
system "d .tbl";

/ Take a source table with certain columns and types and make it fit the format of destTbl to allow inserts to work.
/ @param srcTbl (table) Source table
/ @param destTbl (table) The meta format of destTbl will be the exact same format of data returned
/ @param nestedColumn (symbol) - Optional column in destTbl that should receive nested data from srcTbl that won't "fit" into destTbl.
/                                ` means do not nest any data.
.tbl.makeCompatible:{ [srcTbl; destTbl; nestedColumn]
    // place most common cases near start of code to make quicker
    commonCols:exec c from (meta[srcTbl]=meta[destTbl]) where t;
    
    // if no common columns, return nothing
    if[(0=count commonCols) and nestedColumn=`; :0#destTbl];
    extraSrcCols:cols[srcTbl] except commonCols;
    extraDestCols:cols[destTbl] except commonCols;
    
    // only perform drop/uj if necessary
    // have to be careful of taking or dropping when result would be empty
    st:$[0=count extraSrcCols; 
        srcTbl;
        $[asc[extraSrcCols] ~ asc cols srcTbl; ((count srcTbl)#0#destTbl);extraSrcCols _ srcTbl]];
    t:$[0<count extraDestCols; (0#destTbl) uj st; st];
    
    // shortcut return for no nested handling
    if[nestedColumn~`; :t];
        
    if[not nestedColumn in cols destTbl; 'nonExistantColumn];
    nt:$[count extraSrcCols; ([] {enlist x} each extraSrcCols#srcTbl); ([] count[srcTbl]#enlist (::))];
    nt:nestedColumn xcol nt;
    $[count st; st,'nt; nt]
    };
    