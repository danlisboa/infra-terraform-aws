#!/bin/bash
set -x #echo on
echo "******** Terraform Api ******** "

echo "Update instance"
cd /home/ubuntu

apt-get -y update

sudo apt-get -y install wget

echo "Install ruby"
sudo mkdir tmp
echo "${installRuby}" > tmp/installruby.sh

sudo bash tmp/installruby.sh

echo "Install DOCKER"
sudo snap install docker
sudo snap status docker #check the status
sudo snap start docker # start the service

sudo addgroup --system docker
sudo adduser ubuntu docker
sudo usermod -a -G docker ubuntu
docker -v
docker info
echo "End Install DOCKER"

echo "Creating projects"
cd /home/ubuntu

# AGENT
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
sudo service codedeploy-agent status

cd /home/ubuntu

sudo rm -rf projects/
sudo mkdir projects
sudo chown -R ubuntu /home/ubuntu/projects/
sudo chmod -R 777 /projects

# curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
# . ~/.nvm/nvm.sh
# nvm install 14
# nvm use 14
# nvm alias default 14

echo "${varEnv}" > tmp/.env.local

# sudo git clone https://github.com/danlisboa/test-server.git .
cd /home/ubuntu/projects/

sudo git clone ${repo} .

#sudo git checkout 8af402c99de87ab06203546020e93d91908c0f28

sudo npm cache clean --force --unsafe-perm

sudo cp /home/ubuntu/tmp/.env.local /home/ubuntu/projects/

set -a # automatically export all variables
source .env
set +a

echo "Init bash start app"

chmod +x init.sh
sudo bash init.sh > log-deploy

echo "End bash"

#sudo docker stats