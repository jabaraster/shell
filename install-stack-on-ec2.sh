sudo yum -y update
curl -sSL https://s3.amazonaws.com/download.fpcomplete.com/centos/7/fpco.repo | sudo tee /etc/yum.repos.d/fpco.repo
sudo yum -y install stack
