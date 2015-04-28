 / from the DLL mymoving load the functions and assign to named variables
 / The 2: is used for loading
 / 2 at the end specifies the number of arguments
mysum:`mymoving 2:(`mysum;2)
myavg:`mymoving 2:(`myavg;2)

show "myavg[3; 6 7 5 8 2.]";
myavg[3; 6 7 5 8 2.]