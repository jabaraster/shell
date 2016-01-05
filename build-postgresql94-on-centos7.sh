#########################################################
# タイムゾーンを変えるなら下記Webページに従って操作すること
# http://qiita.com/azusanakano/items/b39bd22504313884a7c3
#########################################################

#########################################################
# 参考）VagrantでCentOS7を立てる場合のVagrantfile
# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
#   config.vm.box = "CentOS 7.1 x86_64"
#   config.vm.box_url = "https://github.com/holms/vagrant-centos7-box/releases/download/7.1.1503.001/CentOS-7.1.1503-x86_64-netboot.box"
#   config.vm.network "private_network", ip: "192.168.50.13"
# end
#########################################################

#########################################################
# rootのパスワード設定が必要なら下記Webページに従って操作すること
# http://qiita.com/shanonim/items/5496e0c6f6bf09e76f7c
#########################################################

#########################################################
# OSの最新化
#########################################################
sudo yum -y update

# PostgreSQL 9.4 インストール.
# サービス名
#   CentOS7  : postgresql-9.4
# インストールディレクトリ
#   CentOS7  : /usr/pgsql-9.4
# デフォルトデータディレクトリ(initdbで作られる)
#   CentOS7  : /var/lib/pgsql/9.4/data
#########################################################
sudo rpm -i http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm
sudo yum -y install postgresql94-server postgresql94-contrib

# Linuxのpostgresユーザのパスワードを設定しておく.
sudo passwd postgres

#########################################################
# DB初期化
# postgresユーザで初期化しないとエンコーディング指定が生きない.
#########################################################
su - postgres
(パスワード入力)
/usr/pgsql-9.4/bin/initdb --encoding=UTF-8 --locale=ja_JP.UTF-8
# 場合によってはinitdbにPATHが通っていない
exit

#########################################################
# PostgreSQLにアプリケーション用ユーザを作成.
#########################################################
# サービスを起動しておく必要がある
sudo systemctl enable postgresql-9.4
sudo systemctl start postgresql-9.4

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
# 設定内容については下記ページをほぼ鵜呑みに.
# http://qiita.com/awakia/items/54503f309216c840765e
#########################################################
sudo vi /var/lib/pgsql/9.4/data/postgresql.conf

# 外部からの接続を許可するために、下記行を書き換える.
# 本来ならアクセス可能IPアドレスをもっと限定するべき.
#listen_addresses = 'localhost'
↓
listen_addresses = '*'

# 設定ファイルを書き換えた後はPostgreSQLを再起動する.
sudo systemctl restart postgresql-9.4

#########################################################
# DBを作る
#########################################################
createdb -U app -h localhost -E UTF8 app
(PostgreSQLのappユーザのパスワード入力)

#########################################################
# 外部からの接続を許可する.
# ここでは乱暴にfirewalldを停めているが、本来は適切に設定するのが望ましい.
#########################################################
sudo systemctl stop firewalld
sudo systemctl disable firewalld

#########################################################
# 確認
#########################################################
psql -U app -h localhost
(PostgreSQLのappユーザのパスワード入力)

# データベース一覧を表示
\l

(appが表示されていればOK)
   名前    |  所有者  | エンコーディング |  照合順序   | Ctype(変換演算子) |      アクセス権       
-----------+----------+------------------+-------------+-------------------+-----------------------
 app       | app      | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | 
 postgres  | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | 
 template0 | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | =c/postgres          +
           |          |                  |             |                   | postgres=CTc/postgres
 template1 | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | =c/postgres          +
           |          |                  |             |                   | postgres=CTc/postgres

以上.
