########################################################
# ChatLuckサーバをAmazon Linuxにインストールする
# https://www.chatluck.com/download/doc/install/ja_JP/Linux/linuxpg_chat.html
# IPを固定するなら、最初にやっておくべし
########################################################

sudo yum -y update

########################################################
# PostgreSQL 9.4のインストール
########################################################
sudo rpm -i http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
sudo yum -y install postgresql94-server postgresql94-contrib

export PG_NAME=postgresql94

sudo chkconfig $PG_NAME on

# Linuxのpostgresユーザのパスワードを設定しておく.
sudo passwd postgres
(パスワード設定)

su - postgres
(パスワード入力)
# initdb --encoding=UTF-8 --locale=ja_JP.UTF-8
initdb --encoding=UTF-8 --locale=ja_JP.UTF-8 -D /var/lib/pgsql94/data
# initdbにPATHが通っていない場合がある
exit

# サービス起動
sudo service $PG_NAME start

########################################################
# Redisのインストール
# http://qiita.com/stoshiya/items/b8c1d2eb41770f92ffcf
########################################################
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum --enablerepo=remi -y install redis
sudo chkconfig redis on

########################################################
# node.jsのインストール
# http://qiita.com/nki2/items/9a15eb151a9e389af318
########################################################
sudo yum install -y nodejs npm --enablerepo=epel
sudo npm install -g n
sudo n stable

########################################################
# Apacheのインストール
# http://promamo.com/?p=2924
########################################################
sudo yum install -y httpd
sudo chkconfig httpd on
sudo /etc/init.d/httpd start

(末尾に以下を追加)
SetEnv LD_LIBRARY_PATH /var/www/cgi-bin/chatlk/lib

# 再起動
sudo service httpd restart


# SSL対応にするなら以下を実行
sudo yum install -y mod_ssl
sudo vi /etc/httpd/conf.d/ssl.conf

# 以下２行のコメントを外す. ホスト名は適切に変更すること

DocumentRoot "/var/www/html"
ServerName <ホスト名>:443

# 以下３行を編集
SSLCertificateFile <サーバ証明書へのパス>
SSLCertificateKeyFile <秘密鍵へのパス>
SSLCertificateChainFile <中間証明書へのパス>

# httpリクエストをhttpsにリダイレクトする設定
sudo vi /etc/httpd/conf/httpd.conf

# 以下を設定ファイルの末尾に追記
<ifModule mod_rewrite.c>
      RewriteEngine On
      RewriteCond %{HTTPS} off
      RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R,L]
</ifModule>


# 設定ファイルを書き換えたらApacheを再起動
sudo service httpd restart



########################################################
# ChatLuckのインストールとDB構築
# https://www.chatluck.com/download/doc/install/ja_JP/Linux/linuxpg_neo.html
########################################################
# ChatLuckインストール
mkdir /tmp/chatluck
cd /tmp/chatluck
wget https://www.chatluck.com/download/binary/linuxpg93/chatluckV11R12pg93lRE6.tar.gz
tar xvf chatluckV11R12pg93lRE6.tar.gz
sudo chown -R apache:apache cgi-bin htdocs
sudo mv cgi-bin/chatlk cgi-bin/chatlksa /var/www/cgi-bin/.
sudo mv htdocs/chatres htdocs/chatsares /var/www/html/.

# DB構築
su - postgres
(パスワード入力)

psql -d template1 -c "CREATE USER chatlk WITH PASSWORD 'chatlk' CREATEUSER"
pg_restore -C -Fc -d template1 /var/www/cgi-bin/chatlk/dump/chatlkdb.pgdmp
pg_restore -C -Fc -d template1 /var/www/cgi-bin/chatlk/dump/chatladdb.pgdmp
exit

# 自動起動設定
sudo mv contrib/chatluck.linux /etc/init.d/chatluck
sudo chmod 0755 /etc/init.d/chatluck
sudo chkconfig --add chatluck

# ユーザ追加
sudo useradd chatluck
sudo passwd chatluck
(パスワード設定)

sudo chmod 0777 /var/www/cgi-bin/chatlk/rserver/log

# 起動
sudo service chatluck start

########################################################
# iOS版スマートフォンアプリのプッシュ通知証明書の更新
########################################################
cd /tmp/chatluck
wget https://www.chatluck.com/download/binary/linuxpg93/ios-apns-pem.tar.gz
tar xvf ios-apns-pem.tar.gz
cd ios-apns-pem
sudo cp ./* /var/www/cgi-bin/chatlk/rserver/iphone/
sudo service chatluck restart
