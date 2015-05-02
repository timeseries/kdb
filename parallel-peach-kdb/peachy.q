/ Parallel Processing - peach and .Q.fc

/ Ryan Hamilton
/ start q with -s 2

/ ### 1. Parallel processing can be used to speed up calculations
/ ### 2. The function must be costly enough to justify the messaging overhead
/ ### 3. Take account of how work is being distributed
/ ### 4. The normal rule of using vector operations still applies. (prefer .Q.fc)
/ ### 5. Parallelising on different functions/data is possible



/ ### 1.Parallel processing can be used to speed up calculations
/ slow function that allows us to simulate doing work
f:{do[x*1500; r:x xexp 1.1]; r}; 
a:10*(100#1),100#4 
f
a
f each a
\t f each a
\s
/ The peach adverb is used for parallel execution of a function over data
/ as long as we started KDB with -s 2
/ Arguments to and results from the peach function are copied
\t f peach a
(f each a)~(f peach a)
/ so as we can see the parallel processing has provided a significant speedup

/ ### 2. The function must be costly enough to justify the messaging overhead
\t do[5000; {x+1} each a]
\t do[5000; {x+1} peach a]
/ When the function is fast the overhead of passing the data 
/ to the threads outweighs the parallelisation benefits

/ ### 3. Take account of how work is being distributed
\t {f x; show x} peach 10 10 10000 10000
\t {f x; show x} peach 10 10000 10 10000
/ one processor has much less work to do and is finishing before the other then just idling
/ PEACH - when 2 slaves, assigns items at 0,2,4,6.. to one thread. 1,3,5,7 to another. 

\t .Q.fc[{r:f each x; show x; r}] 10 10 10000 10000
\t .Q.fc[{r:f each x; show x; r}] 10 10000 10 10000
/ .Q.FC - cuts vector into s equal sized continuous pieces, where s is number slaves
/ passes whole vector piece at once to each thread

/ see diagram!

/ lets examine performance for semi-realistic data sizes
a:10*(100#1),100#4 
a
b:10*200#1 4
b
c:10*1+200?4
c
sum each (a;b;c)


r1:{system "ts f each ",x} each "abc"
r2:{system "ts f peach ",x} each "abc"
r3:{system "ts .Q.fc[{f each x}] ",x} each "abc"
r:flip `method`data`time`space!flip (raze 3#/:`each`peach`Qfc),'(9#`a`b`c),'r1,r2,r3
update time%min time, space%min space from r
/ note:
/ each was consistantly slow
/ peach was faster except on data b
/ .Q.fc was slightly faster still except on a
/ conclusion - careful sending unbalanced workloads to peach / .Q.fc
/ would be nice if they were smarter to batch into groups and queue them to each processor
/
/ .Q.fc appears to use less memory but this test isn't really representative
/ in real world usage I've seen .Q.fc explode memory wise particularly when
/ the vectors its passing to threads are just over a power of 2 as the memory 
/ manager then allocates bascially double the space needed.
/ peach is less likely to explode like that.

/ ### 4. The normal rule of using vector operations still applies. (prefer .Q.fc)
g:{do[10000;x:sqrt x xexp 1.9999]; x} 
\t r:g each 2000#999
\t r1:g peach 2000#999
r~r1
/ peach would provide a slight speedup
/ but we shouldn't really be using each
\t r2: g 2000#999
r~r2
/ therefore use .Q.fc to maintain advantage of using vectors
\t r3:.Q.fc[g] 2000#999
r~r3

/ ### 5. Parallelising on different functions/data is possible
/ typical peach format is f peach d
/ where f is a function that is applied the same to every piece of data
f:{do[x*1000; r:x xexp 1.1]; r};
d:100?100
\t f each d
\t f peach d

/ what if we have multiple functions we want to apply to a single piece of data?
h1:{do[19000*x; r:sqrt x xexp 2.0001]; r}
h2:{do[19000*x; r:sqrt x xexp 1.9999]; r}

/ multiple instruction - single data
data:100;
\t r1:(h1 data; h2 data)
\t r2:{x data} peach (h1;h2)
r1~r2 
/ so applying diff functions in parallel to same data is possible and faster

/ multiple instruction - diff data
d1:100;
d2:200;
\t r1:(h1 d1; h2 d2)
\t r2:{(x[0]) x 1} peach ((h1;d1);(h2;d2))
r1~r2 
/ so you can basically parallelise any functions and data
/ it just isn't pretty


/ ### 1. Parallel processing can be used to speed up calculations
/ ### 2. The function must be costly enough to justify the messaging overhead
/ ### 3. Take account of how work is being distributed
/ ### 4. The normal rule of using vector operations still applies. 
/ ### 5. Parallelising on different functions/data is possible
/
/ ### .Q.fc vs peach
/ Basically if vector use .Q.fc at all costs. 
/ If memory easily allows use .Q.fc to reduce separate serializations
/ Otherwise if not significant difference use peach



