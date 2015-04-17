######################################################
# AWSのRedHatにサイボウズOffice10をインストールする
# Office10のインストール手順は下記Webサイトを参照のこと.
# https://manual.cybozu.co.jp/of10/intro/install/lin.html
######################################################

######################################################
# rootパスワード変更
# http://qiita.com/shanonim/items/5496e0c6f6bf09e76f7c
######################################################
sudo su -
passwd
(パスワードを２回入力)

######################################################
# 全作業はrootユーザで行う
######################################################
su -
(パスワード入力)

######################################################
# タイムゾーンを日本に変更
# http://qiita.com/azusanakano/items/b39bd22504313884a7c3
######################################################
cp /etc/localtime /etc/localtime.org
yes | cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# 確認. 下記コマンドで表示されるタイムゾーンがJSTならOK.
date

######################################################
# OSの最新化と必要モジュールのインストール
######################################################
yum -y update
yum -y install wget

######################################################
# SELinux無効化
# https://www.ccdc.cam.ac.uk/SupportandResources/Support/pages/SupportSolution.aspx?supportsolutionid=217
######################################################
vi /etc/sysconfig/selinux
(SELINUX=disabledに書き換え)

# ここでOSを再起動した

######################################################
# Apacheインストール
# http://weblabo.oscasierra.net/installing-apache-with-yum/
######################################################
yum -y install httpd
chkconfig httpd on
service httpd start

######################################################
# Office10インストール
# http://weblabo.oscasierra.net/installing-apache-with-yum/
######################################################
yum -y install ld-linux.so.2
cd /tmp
wget http://download.cybozu.co.jp/office10/cbof-10.3.0-linux-k0.bin
sh cbof-10.3.0-linux-k0.bin

(ここからは、下記のサイボウズのインストールガイドに従うこと)
# https://manual.cybozu.co.jp/of10/intro/install/lin.html


