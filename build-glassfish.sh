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
cd /tmp
wget -P /tmp http://dlc.sun.com.edgesuite.net/glassfish/4.1/release/glassfish-4.1-web.zip
unzip /tmp/glassfish-4.1-web.zip
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
./asadmin -W pass.txt delete-jdbc-resource jdbc/__default
./asadmin -W pass.txt delete-jdbc-resource jdbc/__TimerPool
./asadmin -W pass.txt delete-jdbc-connection-pool DerbyPool
./asadmin -W pass.txt delete-jdbc-connection-pool __TimerPool
# ./asadmin -W pass.txt delete-http-listener http-listener-2
./asadmin -W pass.txt delete-threadpool thread-pool-1
