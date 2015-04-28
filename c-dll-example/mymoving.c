// TimeStored.com example of windows DLL
// http://www.timestored.com/kdb-guides/compile-load-c-dll

#include"k.h"
#include <float.h>

// Find the moving sum for a given window size and array of nums
K mysum(K window, K nums) {
	
	long wsize = window->j;
	long i=0;
	K res = ktn(KF, nums->n);
	double total;

	F* resf = kF(res);
	F* numsf = kF(nums);

	// check type is float
	if( (nums->t != KF) || (window->t != -KJ)) {
		printf("invalid params");
		return krr("wrong type params");
	}
	
	total = numsf[0];
	resf[0] = total;
	for(i=1; i < wsize; i++) {
		total += numsf[i];
		resf[i]=total;
	}
	
	for(i=wsize; i < nums->n; i++) {
		total = total - numsf[i-wsize]+numsf[i];
		resf[i]=total;
	}

	return res;
} 


// Find the moving average for a given window size and array of nums
K myavg(K window, K nums) {
	
	// initialize variables
	long wsize = window->j;
	long i=0;
	K res = ktn(KF, nums->n);
	double total;
	long count;

	F* resf = kF(res);
	F* numsf = kF(nums);

	// check type is float
	if( (nums->t != KF) || (window->t != -KJ)) {
		printf("invalid params");
		return krr("wrong type params");
	}
	
	// find moving average of first window (special case)
	total = numsf[0];
	resf[0] = total;
	count = 2;
	for(i=1; i < wsize; i++) {
		total += numsf[i];
		resf[i] = total / count++;
	}
	
	// move window along by adding next number and removing earliest from average.
	for(i=wsize; i < nums->n; i++) {
		total = total - numsf[i-wsize]+numsf[i];
		resf[i] = total / wsize;
	}

	return res;
} 
