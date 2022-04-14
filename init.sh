#!/bin/bash
set -x #echo on
echo "******** Terraform command ******** "

echo "Update instance"
cd /home/ubuntu

echo "Install DOCKER"
sudo snap install docker
sudo snap status docker #check the status
sudo snap start docker # start the service

sudo addgroup --system docker
sudo adduser ubuntu docker
sudo usermod -a -G docker ubuntu
docker -v
docker info
#sudo groupadd docker
#sudo gpasswd -a $USER docker
#sudo service docker restart
docker info
echo "End Install DOCKER"

echo "Creating projects"
apt-get -y update
apt-get -y install ruby
apt-get -y install wget
cd /home/ubuntu

wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start

cd /home/ubuntu
sudo mkdir projects
cd projects/
sudo git clone https://github.com/danlisboa/test-server.git .

sudo service codedeploy-agent status
echo "End Creating projects"

echo "Init bash"
chmod +x init.sh

bash init.sh

echo "End bash"

sudo docker stats