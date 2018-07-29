start "cserve" q supergw.q -p 5000
start "RDB-A" q rdb.q -p 6000
start "hdb-A" q hdb.q -p 6001 
start "RDB-B" q rdb.q -p 6002
start "hdb-B" q hdb.q -p 6003 