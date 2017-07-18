system "d .tblTest";

t:([] a:1 2 3; b:4.4 5.5 6.6; c:`p`o`i; d:("asd";"qwe";"ppppp"); ni:(1 2i;3 4i; 5 6 7i));
rt:();

testMakeCompatibleNonexistantNested:{ 
    f:.tbl.makeCompatible[t; t; ];
    .qunit.assertError[f; `nonExistantColumn; "nonExistantColumn fails"]};
    
testMakeCompatibleSelf:{ 
    a:.tbl.makeCompatible[t; t; `];
    .qunit.assertEquals[a; t; "compatible with self."] };
    

testMakeCompatibleNoCommonCols:{ 
    a:.tbl.makeCompatible[ ([] a:1 2 3); ([] b:4 5 6); `];
    .qunit.assertEquals[count a; 0; "no nesting and no compatible columns = empty table returned in shape of destTbl"] };

testMakeCompatibleEmptyTbl:{ 
    a:.tbl.makeCompatible[0#t; t; `];
    lowMetaA:select from (meta a) where not null t,t=lower t;
    lowMetaT:select from (meta t) where not null t,t=lower t;
    .qunit.assertEquals[lowMetaT; lowMetaA; "compatible with self."] };    

/ Test only cases not involving nested data
testMakeCompatibleSimpleCases:{
    / every possible combo starting from left
    testCases:((1+til count c)#\:c:cols t)#\:t;
    / random column choices
    testCases,:({y; neg[1+rand count x]?x}[cols t;] each til 100)#\:t;
    checkInsert[;t;`] each testCases };

checkInsert:{ [tblSrc; tblDest; nestedColumn]
        rt::tblDest;
        transformedTbl:.tbl.makeCompatible[tblSrc; tblDest; nestedColumn];
        show transformedTbl;
        `.tblTest.rt insert transformedTbl;
        .qunit.assertEquals[meta rt; meta tblDest; "metas match"];
        transformedTbl };

testMakeCompatibleAdditonalSrcColumns:{
    checkInsert[ ([] a:1 2 3; b:100 200 300); ([] b:4 5 6); `]; };

testMakeCompatibleTypesDiff:{
    checkInsert[ ([] b:1.1 2.2 3.3); ([] b:4 5 6); `]; };


testMakeCompatibleNestingNoCommonCols:{
    destTbl:([] b:4 5 6; nestedCol:(::;::;::));
    ta:([] b:1.1 2.2 3.3);
    ra:checkInsert[ ta; destTbl; `nestedCol];
    .qunit.assertEquals[raze exec nestedCol from ra; ta; "expanded nestedCol = original table"];
    
    tb:([] f:`a`b`c);
    rb:checkInsert[tb ; destTbl; `nestedCol];
    .qunit.assertEquals[raze exec nestedCol from rb; tb; "expanded nestedCol = original table"];
    
    ra};
    
testMakeCompatibleNesting:{
    destTbl:([] b:4 5 6; nestedCol:(::;::;::));
    ta:([] b:10 11 12);
    ra:checkInsert[ ta; destTbl; `nestedCol];
    
    tb:([] f:`a`b`c; b:10 11 12);
    rb:checkInsert[tb ; destTbl; `nestedCol];
    .qunit.assertEquals[raze exec nestedCol from rb; enlist[`f]#tb; "expanded nestedCol = original table"];
    
    ra};

/ Some lines to run manually to get feel for result visually
/ .tbl.makeCompatible[ ([] ff:`a`b`c; a:5 6 7 ); ([] a:1 2; nestedCol:(::;::)); `]
/ .tbl.makeCompatible[ ([] ff:`a`b`c; a:5 6 7 ); ([] a:1 2; nestedCol:(::;::); jj:(1 2;3 4 5)); `]
/ .tbl.makeCompatible[ ([] ff:`a`b; a:5 6; jj:(-1 -1;-2 -3 -4) ); ([] a:1 3; nestedCol:(::;::); jj:(1 2;3 4 5)); `]
/ .tbl.makeCompatible[ ([] ff:`a`b`c; a:5 6 7 ); ([] a:1 2 3; nestedCol:(::;::;::)); `nestedCol]
/ .tbl.makeCompatible[ ([] f:`a`b`c; b:9 8 7); destTbl; `nestedCol]
/ raze exec nestedCol from .tbl.makeCompatible[ ([] f:`a`b`c; b:9 8 7; gg:(`p`o`i;`pp`oo;`iii)); destTbl; `nestedCol]


