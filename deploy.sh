#!/bin/bash
set -x #echo on
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
sudo git clone https://github.com/danlisboa/test-server.git

sudo service codedeploy-agent status