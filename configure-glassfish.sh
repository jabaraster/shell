#########################################################
# JDBCリソース作成
#########################################################
./asadmin -W pass.txt create-jdbc-connection-pool \
  --datasourceclassname=org.postgresql.ds.PGConnectionPoolDataSource \
  --restype=javax.sql.ConnectionPoolDataSource \
  --steadypoolsize=10 \
  --maxpoolsize=80 \
  --poolresize=5 \
  --property serverName=localhost:portNumber=5432:databaseName=app:user=app:password=xxx \
 app-connection-pool
./asadmin -W pass.txt create-jdbc-resource --connectionpoolid app-connection-pool jdbc/App

#########################################################
# JVM設定.
#########################################################
./asadmin -W pass.txt delete-jvm-options -Xmx512m
./asadmin -W pass.txt create-jvm-options -Xms12288m
./asadmin -W pass.txt create-jvm-options -Xmx12288m
./asadmin -W pass.txt delete-jvm-options "-XX\:MaxPermSize=192m"
./asadmin -W pass.txt create-jvm-options "-XX\:MaxPermSize=512m"
./asadmin -W pass.txt create-jvm-options -Dwicket.configuration=deployment
sudo service glassfish restart


# 以下、実験中のコマンド.

./asadmin -W pass.txt create-threadpool \
  --minthreadpoolsize=10 \
  --maxthreadpoolsize=1000 \
 app-thread-pool

./asadmin -W pass.txt create-protocol app-protocol

./asadmin -W pass.txt create-network-listener \
  --address=0.0.0.0 \
  --listenerport=8383 \
  --threadpool=app-thread-pool \
  --protocol=app-http-listener \
 app-http-listener

./asadmin -W pass.txt create-http-listener \
  --listeneraddress=0.0.0.0 \
  --listenerport=8282 \
  --default-virtual-server=server \
 app-http-listener

./asadmin -W pass.txt create-http \
  --default-virtual-server=server
 app-protocol

