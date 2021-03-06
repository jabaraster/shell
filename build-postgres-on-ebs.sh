#######################################################
# 当コマンド集は
# ファイルシステムがまだ作られていない、まっさらな
# EBSボリュームがアタッチされているEC2インスタンスで
# PostgreSQLのデータをEBSに格納する環境を作成するためのものです.
# 前提）
# ・EBSが/dev/xvdfにアタッチされている
# 注意）
# このファイルの拡張子はshですが
# ところどころ対話形式になる箇所があり、
# そのままは実行出来ません.
# １行ずつ実行することを推奨します.
#######################################################

#######################################################
# OSの最新化
#######################################################
sudo yum -y update

#######################################################
# PostgreSQLのデータディレクトリにEBSをマウントする.
# http://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ebs-using-volumes.html
# ※EC2とEBSのAZはそろえておく必要がある.
#######################################################
# ファイルシステム作成
# デバイス名は適宜変更すること
# なおデバイス名は lsblk コマンドで確認可能.
sudo mkfs -t ext4 /dev/xvdf

# デフォルトのPostgreSQLのデータディレクトリにEBSをマウントする
# デバイス名は適宜変更すること
sudo mkdir /var/lib/pgsql93/
sudo mount /dev/xvdf /var/lib/pgsql93

#######################################################
# PostgreSQLのインストール
#######################################################
sudo rpm -i http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
sudo yum -y install postgresql93-server postgresql93-contrib

#######################################################
# postgresユーザのパスワードを設定する.
# これをしないとsuコマンドでのログインが出来ない.
#######################################################
sudo passwd postgres
(パスワードを入力)

#######################################################
# DB初期化.
# postgresユーザで実行しないと、ロケールが日本語に出来ない.
#######################################################
su - postgres
(パスワードを入力)
initdb --encoding=UTF-8 --locale=ja_JP.UTF-8
exit

#######################################################
# 認証の設定.
# 全てのDB/ユーザでパスワード認証を経ての接続を可能にする
#######################################################
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

#######################################################
# 接続元を限定するならば、設定を変更.
# デフォルトではlocalhostからしか接続を受け付けない.
#######################################################
sudo vi /var/lib/pgsql93/data/postgresql.conf

#######################################################
# PostgreSQLのチューニング
# 設定内容については下記ページをほぼ鵜呑みに.
# http://qiita.com/awakia/items/54503f309216c840765e
#######################################################
sudo vi /var/lib/pgsql93/data/postgresql.conf

#######################################################
# PostgreSQLを再起動.
#######################################################
sudo chkconfig postgresql93 on
sudo service postgresql93 restart

#######################################################
# PostgreSQLにアプリ用ユーザを作る.
# postgresユーザで作業する
#######################################################
su - postgres
(パスワードを入力)
psql
create user app createdb password 'xxx' login;
\q
exit

#######################################################
# DBを作る
#######################################################
createdb -U app -h localhost -E UTF8 app

#######################################################
# 動作確認
#######################################################
psql -U app -h localhost
(appユーザのパスワードを入力)
\l

(以下のように表示されればOK)

                                         データベース一覧
   名前    |  所有者  | エンコーディング |  照合順序   | Ctype(変換演算子) |      アクセス権       
-----------+----------+------------------+-------------+-------------------+-----------------------
 app       | app      | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | 
 postgres  | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | 
 template0 | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | =c/postgres          +
           |          |                  |             |                   | postgres=CTc/postgres
 template1 | postgres | UTF8             | ja_JP.UTF-8 | ja_JP.UTF-8       | =c/postgres          +
           |          |                  |             |                   | postgres=CTc/postgres
(4 行)


