#include<stdio.h>
#include<stdlib.h>
#include"k.h"

// kdb+tick simple subscriber example
// author TimeStored.com
int main(int argc, char *argv[]) {

    // find host:port
    if(argc<3) {
	printf("progname {host} {port}");
	exit(1);
    }
    char * host = argv[1];
    int port = atoi(argv[2]);

    // connect
    int handle = khpu(host, port, "user:pass");

    if ((!handle) || (handle < 0)) {
	printf("Cannot connect\n");
	exit(1);
    } else {
	printf("connected %s:%i\n", host, port);
    }

    // subscribe to trade table
    K r = k(handle, ".u.sub[`trade;`]", (K) 0);
    if (!r) {
	printf("Network Error\n");
	perror("Network");
	exit(1);
    } else {
	printf("subscribed trade table\n");
    }

    // process ticks
    K tbl, colData, colNames;
    int c,cols;

    while(1) {
	r = k(handle,(S)0);
	if(r) {
	    if(r->t == 0) {
		// r is 3 item list of format (".u.upd"; `trade; updateTable)

		printf("\n%s update", kK(r)[1]->s); // table name symbol atom

		// latest table of trade data, type 98
		// means use ->k to access dictionary
		tbl = kK(r)[2]->k; 

		// in dictionary tbl, 
		//     [0] is symbol list of column names
		//     [1] is columns of data
		colNames = kK(tbl)[0];
		colData = kK(tbl)[1];

		printf(" rows: %lld cols: ", kK(colData)[0]->n);
		
		for(c=0; c < colNames->n; c++) {
		    printf("%s,", kS(colNames)[c]);
		}
	    }
	}
	r0(r); // decrement reference count, free memory
    }

    kclose(handle);
    return 0;
}

