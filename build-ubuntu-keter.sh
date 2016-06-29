# ubuntuにてketerサーバ環境を作る

# OS最新化
sudo apt-get update -y

# タイムゾーンを日本にする
sudo timedatectl set-timezone Asia/Tokyo

# VBox Guest Additionsをインストールする
cd /tmp
wget http://download.virtualbox.org/virtualbox/4.3.20/VBoxGuestAdditions_4.3.20.iso
sudo mount -t iso9660 /tmp/VBoxGuestAdditions_4.3.20.iso /mnt
cd /mnt/
sudo ./VBoxLinuxAdditions.run

# keterのインストール
# 参考URL
# https://github.com/snoyberg/keter

wget -O - https://raw.githubusercontent.com/snoyberg/keter/master/setup-keter.sh | bash
sudo cp /opt/keter/bin/keter /usr/bin/

# stackのインストール
# keterサーバには不要だけど、メモしておく
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 575159689BEFB442
echo 'deb http://download.fpcomplete.com/ubuntu trusty main'|sudo tee /etc/apt/sources.list.d/fpco.list
sudo apt-get update && sudo apt-get install stack -y
