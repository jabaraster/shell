#########################################################
# タイムゾーンを変えるなら下記Webページに従って操作すること
# http://qiita.com/azusanakano/items/b39bd22504313884a7c3
#########################################################

#########################################################
# rootのパスワード設定が必要なら下記Webページに従って操作すること
# http://qiita.com/shanonim/items/5496e0c6f6bf09e76f7c
#########################################################

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
# 必要なツールのインストール
#########################################################
sudo yum -y install wget
sudo yum -y install unzip
sudo yum -y install expect # mkpasswdコマンドのために必要

#########################################################
# GlassFish-v4.1のインストール
#########################################################
cd ~/temp
wget -P ~/temp http://dlc.sun.com.edgesuite.net/glassfish/4.1/release/glassfish-4.1-web.zip
unzip ~/temp/glassfish-4.1-web.zip
sudo mv glassfish4/ /opt/
cd /opt
sudo mv glassfish4/ glassfish-4.1-web

# PostgreSQLのJDBCドライバを取得してGlassFish環境下に置く.
wget -P /opt/glassfish-4.1-web/glassfish/domains/domain1/lib/ext/ http://central.maven.org/maven2/org/postgresql/postgresql/9.3-1102-jdbc41/postgresql-9.3-1102-jdbc41.jar

#########################################################
# GlassFishの管理者パスワード設定
#########################################################
cd glassfish-4.1-web/bin/
./asadmin start-domain

# パスワード生成
export AS_ADMIN_PASSWORD=`mkpasswd`

# パスワード変更シェルを生成
touch auto.sh
chmod +x auto.sh
echo '#!/usr/bin/expect' >> auto.sh
echo 'set pass [lindex $argv 0]' >> auto.sh
echo 'spawn ./asadmin --user admin change-admin-password' >> auto.sh
echo 'expect "Enter the admin password"' >> auto.sh
echo 'send "\r"' >> auto.sh
echo 'expect "Enter the new admin password"' >> auto.sh
echo 'send "$pass\r"' >> auto.sh
echo 'expect "Enter the new admin password again"' >> auto.sh
echo 'send "$pass\r"' >> auto.sh
echo 'expect eof' >> auto.sh

# パスワード生成シェルを実行
./auto.sh $AS_ADMIN_PASSWORD
rm ./auto.sh

# パスワードファイル作成
echo AS_ADMIN_PASSWORD=$AS_ADMIN_PASSWORD >> pass.txt

#########################################################
# 自動起動設定
# 以下のURLを参考(というかほぼ丸コピー)にした
# http://shinsuke789.hatenablog.jp/entry/20121002/1349134548
# また自動起動はroot権限で行われるため、80番ポートでリッスン可能になる.
# リッスンポートはデフォルト8080であり、これを変更するコマンドは現在調査中.
#########################################################
sudo touch /etc/init.d/glassfish
sudo chown `whoami` /etc/init.d/glassfish

echo '#!/bin/bash' >> /etc/init.d/glassfish
echo '#' >> /etc/init.d/glassfish
echo '# glassfish    Startup script for the Apache HTTP Server' >> /etc/init.d/glassfish
echo '#' >> /etc/init.d/glassfish
echo '# chkconfig: - 85 15' >> /etc/init.d/glassfish
echo '# description: Startup script of Glassfish Application Server.' >> /etc/init.d/glassfish
echo '# processname: glassfish' >> /etc/init.d/glassfish
echo '#' >> /etc/init.d/glassfish
echo 'export LANG=ja_JP.utf8' >> /etc/init.d/glassfish
echo '' >> /etc/init.d/glassfish
echo 'GLASSFISH_HOME=/opt/glassfish-4.1-web' >> /etc/init.d/glassfish
echo '' >> /etc/init.d/glassfish
echo 'case $1 in' >> /etc/init.d/glassfish
echo 'start)' >> /etc/init.d/glassfish
echo 'sh ${GLASSFISH_HOME}/bin/asadmin start-domain $2' >> /etc/init.d/glassfish
echo ';;' >> /etc/init.d/glassfish
echo 'stop)' >> /etc/init.d/glassfish
echo 'sh ${GLASSFISH_HOME}/bin/asadmin stop-domain $2' >> /etc/init.d/glassfish
echo ';;' >> /etc/init.d/glassfish
echo 'restart)' >> /etc/init.d/glassfish
echo 'sh ${GLASSFISH_HOME}/bin/asadmin restart-domain $2' >> /etc/init.d/glassfish
echo ';;' >> /etc/init.d/glassfish
echo 'esac' >> /etc/init.d/glassfish
echo 'exit 0' >> /etc/init.d/glassfish

sudo chown root /etc/init.d/glassfish
sudo chmod +x /etc/init.d/glassfish
sudo chkconfig --add glassfish
sudo chkconfig glassfish on
sudo service glassfish restart

#########################################################
# リモートアクセス可能にする.
#########################################################
# 証明書の正しさをプロンプトで問われるので、yesコマンドを使う.
yes | ./asadmin -W pass.txt enable-secure-admin
# 要再起動
sudo service glassfish restart

#########################################################
# 不要リソース削除
#########################################################
# 証明書の正しさをプロンプトで問われるので、yesコマンドを使う.
yes | ./asadmin -W pass.txt delete-jdbc-resource jdbc/__default
./asadmin -W pass.txt delete-jdbc-resource jdbc/__TimerPool
./asadmin -W pass.txt delete-jdbc-connection-pool DerbyPool
./asadmin -W pass.txt delete-jdbc-connection-pool __TimerPool
./asadmin -W pass.txt delete-http-listener http-listener-1
./asadmin -W pass.txt delete-http-listener http-listener-2
./asadmin -W pass.txt delete-threadpool thread-pool-1
./asadmin -W pass.txt delete-threadpool http-thread-pool

#########################################################
# アプリ用ネットワークリスナー作成
# 具体的な数値は規模に応じてチューニングが必要.
#########################################################
./asadmin -W pass.txt create-threadpool \
  --maxthreadpoolsize 100 \
  --minthreadpoolsize 10 \
  --maxqueuesize 2048 \
  app-threadpool

./asadmin -W pass.txt create-protocol \
  --target server \
  app-listener

./asadmin -W pass.txt create-http \
  --default-virtual-server server \
  app-listener

./asadmin -W pass.txt create-network-listener \
  --listenerport 80 \
  --threadpool app-threadpool \
  --protocol app-listener \
  --target server \
  app-http-listener

# GlassFishを再起動.
# もし下記コマンドからいつまでたっても復帰しない場合は
# Ctrl+Cで止めてから再度コマンドを実行するとうまくいく.
sudo service glassfish restart

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
# postgresユーザで初期化しないとエンコーディング指定が生きない.
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

####################################################
# JVM設定
# 具体的な数値は規模に応じてチューニングが必要.
#########################################################
./asadmin -W pass.txt delete-jvm-options -Xmx512m
./asadmin -W pass.txt create-jvm-options -Xms12288m
./asadmin -W pass.txt create-jvm-options -Xmx12288m
./asadmin -W pass.txt delete-jvm-options "-XX\:MaxPermSize=192m"
./asadmin -W pass.txt create-jvm-options "-XX\:MaxPermSize=512m"
./asadmin -W pass.txt create-jvm-options -Dwicket.configuration=deployment

# JVM設定を変えた場合、GlassFishの再起動が必要.
sudo service glassfish restart
