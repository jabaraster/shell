#######################################################
# OSの最新化
#######################################################
sudo yum -y update

#######################################################
# PostgreSQLのインストール
#######################################################
sudo rpm -i http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
sudo yum -y install postgresql93-server postgresql93-contrib

# サービスを止めておく
sudo service postgresql93 stop

#######################################################
# EBSにファイルシステムを作成し、マウントする.
# http://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ebs-using-volumes.html
# またEC2とEBSのAZはそろえておく必要がある.
#######################################################

# ファイルシステム作成
# デバイス名は適宜変更すること
sudo mkfs -t ext4 /dev/xvdf

# マウント.
sudo mkdir /data
sudo mount /dev/xvdf /data
sudo mkdir /data/postgres
sudo chown postgres:postgres /data/postgres

#######################################################
# postgresユーザのパスワードを設定しておく.
#######################################################
sudo passwd postgres

#######################################################
# DBの初期化.
# postgresユーザで実行する必要がある.
#######################################################
su - postgres
initdb --encoding=UTF-8 --locale=ja_JP.UTF-8 -D /data/postgres/
exit

#######################################################
# 認証の設定.
# 全てのDB/ユーザでパスワード認証を経ての接続を可能にする
#######################################################
sudo vi /data/postgres/pg_hba.conf

(ファイルの内容を下記に置換)

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer

# IPv4 local connections:
host    all             postgres        127.0.0.1/32            ident
host    all             all             0.0.0.0/0               password

# IPv6 local connections:
host    all             all             ::/0                    password

#######################################################
# 接続元を限定するならば、設定を変更.
# デフォルトではlocalhostからしか接続を受け付けない.
#######################################################
sudo vi /data/postgres/postgresql.conf

#######################################################
# PostgreSQLのチューニング
# 設定内容については下記ページをほぼ鵜呑みに.
# http://qiita.com/awakia/items/54503f309216c840765e
#######################################################
sudo vi /data/postgres/postgresql.conf

#######################################################
# PostgreSQLの起動スクリプトを変更する.
# EBS上のデータディレクトリを見るようにする.
#######################################################
sudo vi /etc/init.d/postgresql93

# PGDATA変数の値を変更する
PGDATA=/data/postgres

#######################################################
# PostgreSQLの起動
# 既に起動している場合、既プロセスはkillコマンドで消すこと.
#######################################################
sudo chkconfig postgresql93 on
sudo service postgresql93 start

#######################################################
# PostgreSQLにアプリ用ユーザを作る.
# postgresユーザで作業する
#######################################################
su - postgres
psql
create user app createdb password 'xxx' login;
\q
exit

#######################################################
# DBを作る
#######################################################
createdb -U app -h localhost -E UTF8 app

