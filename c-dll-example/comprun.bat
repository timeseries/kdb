CALL "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" amd64 
cl /LD /DKXVER=3 mymoving.c mymoving.def q.lib
q load-functions.q