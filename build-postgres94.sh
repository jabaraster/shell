#########################################################
# タイムゾーンを変えるなら下記Webページに従って操作すること
# http://qiita.com/azusanakano/items/b39bd22504313884a7c3
#########################################################

#########################################################
# rootのパスワード設定が必要なら下記Webページに従って操作すること
# http://qiita.com/shanonim/items/5496e0c6f6bf09e76f7c
#########################################################

#########################################################
# OSの最新化
#########################################################
sudo yum -y update

#########################################################
# PostgreSQL 9.4 インストール.
# サービス名
#   Amazon Linux: ?postgresql93
#   CentOS      : postgresql-9.4
# インストールディレクトリ
#   Amazon Linux: ?
#   CentOS      : /usr/pgsql-9.4
# データディレクトリ
#   Amazon Linux: ?/var/lib/pgsql93/data
#   CentOS      : /var/lib/pgsql/9.4/data
#########################################################
sudo rpm -i http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm
# Amazon Linuxの場合
# sudo rpm -i http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
sudo yum -y install postgresql94-server postgresql94-contrib

sudo chkconfig postgresql-9.4 on

# Linuxのpostgresユーザのパスワードを設定しておく.
sudo passwd postgres

#########################################################
# DB初期化
# postgresユーザで初期化しないとエンコーディング指定が生きない.
#########################################################
su - postgres
(パスワード入力)
initdb --encoding=UTF-8 --locale=ja_JP.UTF-8
# initdbにPATHが通っていない場合がある
exit

#########################################################
# サービス起動
#########################################################
sudo service postgresql-9.4 start

#########################################################
# PostgreSQLにアプリケーション用ユーザを作成.
# psqlコンソールの中でcreate userを叩く.
#########################################################
psql -U postgres -h localhost
create user app createdb password 'xxx' login;
\q

#########################################################
# 全てのDB/ユーザでパスワード認証を経ての接続を可能にする
#########################################################
sudo vi /var/lib/pgsql/9.4/data/pg_hba.conf

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
# 設定内容については下記ページを参考に.
# http://qiita.com/awakia/items/54503f309216c840765e
#########################################################
sudo vi /var/lib/pgsql/9.4/data/postgresql.conf

# 設定ファイルを書き換えた後はPostgreSQLを再起動する.
sudo service postgresql-9.4 restart

#########################################################
# DBを作る
#########################################################
createdb -U app -h localhost -E UTF8 app

以上.

