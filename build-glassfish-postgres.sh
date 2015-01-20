#########################################################
# Amazon LinuxにGlassFishをインストール
#########################################################

#########################################################
# OSの最新化
#########################################################
sudo yum -y update

#########################################################
# JDKのインストール
#########################################################
sudo yum -y install java-1.7.0-openjdk-devel

#########################################################
# GlassFish-v4.1のインストール
#########################################################
sudo yum -y install wget
sudo yum -y install unzip
cd /tmp
wget -P /tmp http://dlc.sun.com.edgesuite.net/glassfish/4.1/release/glassfish-4.1-web.zip
unzip /tmp/glassfish-4.1-web.zip
sudo mv glassfish4/ /opt/
cd /opt
sudo mv glassfish4/ glassfish-4.1-web

# PostgreSQLのJDBCドライバを取得してGlassFish環境下に置く.
wget -P /opt/glassfish-4.1-web/glassfish/domains/domain1/lib/ext/ http://central.maven.org/maven2/org/postgresql/postgresql/9.3-1102-jdbc41/postgresql-9.3-1102-jdbc41.jar

# GlassFishに各種設定を施す
cd glassfish-4.1-web/bin/
./asadmin start-domain
./asadmin change-admin-password
(パスワード入力)

# パスワードファイル作成
echo AS_ADMIN_PASSWORD=xxx >> pass.txt

#########################################################
# 自動起動設定
# 以下のURLを参考(というかほぼ丸コピー)にした
# http://shinsuke789.hatenablog.jp/entry/20121002/1349134548
# また自動起動はroot権限で行われるため、80番ポートでリッスン可能になる.
# リッスンポートはデフォルト8080であり、これを変更するコマンドは現在調査中.
#########################################################
sudo touch /etc/init.d/glassfish
sudo chmod +x /etc/init.d/glassfish
sudo vi /etc/init.d/glassfish

(ファイル内容を以下の通りにする)

#!/bin/bash
#
# glassfish    Startup script for the Apache HTTP Server
#
# chkconfig: - 85 15
# description: Startup script of Glassfish Application Server.
# processname: glassfish
#
export LANG=ja_JP.utf8

GLASSFISH_HOME=/opt/glassfish-4.1-web

case $1 in
start)
sh ${GLASSFISH_HOME}/bin/asadmin start-domain $2
;;
stop)
sh ${GLASSFISH_HOME}/bin/asadmin stop-domain $2
;;
restart)
sh ${GLASSFISH_HOME}/bin/asadmin restart-domain $2
;;
esac
exit 0

(ファイル内容ここまで)

sudo chkconfig --add glassfish
sudo chkconfig glassfish on
sudo service glassfish restart

#########################################################
# 不要リソース削除
#########################################################
./asadmin -W pass.txt enable-secure-admin
./asadmin -W pass.txt delete-jdbc-resource jdbc/__default
./asadmin -W pass.txt delete-jdbc-resource jdbc/__TimerPool
./asadmin -W pass.txt delete-jdbc-connection-pool DerbyPool
./asadmin -W pass.txt delete-jdbc-connection-pool __TimerPool
./asadmin -W pass.txt delete-http-listener http-listener-2
./asadmin -W pass.txt delete-threadpool thread-pool-1

#########################################################
# PostgreSQL 9.3 インストール.
# サービス名
#   Amazon Linux: postgresql93
#   CentOS      : postgresql-9.3
# データディレクトリ
#   Amazon Linux: /var/lib/pgsql93/data
#   CentOS      : /var/lib/pgsql/9.3/data
#########################################################
sudo rpm -i http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
sudo yum -y install postgresql93-server postgresql93-contrib

sudo chkconfig postgresql93 on
sudo service postgresql93 start

# Linuxのpostgresユーザのパスワードを設定しておく.
sudo passwd postgres

#########################################################
# DB初期化
#########################################################
su - postgres
(パスワード入力)
initdb --encoding=UTF-8 --locale=ja_JP.UTF-8
# 場合によってはinitdbにPATHが通っていない
exit

#########################################################
# PostgreSQLにアプリケーション用ユーザを作成.
#########################################################
psql -U postgres -h localhost
create user app createdb password 'xxx' login;
\q

#########################################################
# 全てのDB/ユーザでパスワード認証を経ての接続を可能にする
#########################################################
sudo vi /var/lib/pgsql93/data/pg_hba.conf

(ファイルの内容を下記に置換)

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer

# IPv4 local connections:
host    all             postgres        127.0.0.1/32            ident
host    all             all             0.0.0.0/0               password

# IPv6 local connections:
host    all             all             ::/0                    password

(ファイル内容ここまで)

#########################################################
# PostgreSQLのチューニング
# 設定内容については下記ページをほぼ鵜呑みに.
# http://qiita.com/awakia/items/54503f309216c840765e
#########################################################
sudo vi /var/lib/pgsql93/data/postgresql.conf

# 設定ファイルを書き換えた後はPostgreSQLを再起動する.
sudo service postgresql93 restart

#########################################################
# DBを作る
#########################################################
createdb -U app -h localhost -E UTF8 app

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

