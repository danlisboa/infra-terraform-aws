#!/bin/bash
set -x #echo on
echo "******** Terraform Soluti ******** "

echo "Update instance"
cd /home/ubuntu

apt-get -y update
sudo apt-get -y install wget

echo "Install DOCKER"
sudo snap install docker
sudo snap status docker #check the status
sudo snap start docker # start the service

sudo addgroup --system docker
sudo adduser ubuntu docker
sudo usermod -a -G docker ubuntu
docker -v
docker info

echo "Creating projects"
cd /home/ubuntu

sudo rm -rf /home/ubuntu/projects/
sudo mkdir projects
sudo chown -R ubuntu /home/ubuntu/projects/
sudo chmod -R 777 /home/ubuntu/projects

sudo mkdir tmp

echo "${varEnv}" > tmp/.env

cd /home/ubuntu/projects/

sudo echo "${manifest}" > cess-compose.yaml

sudo cp /home/ubuntu/tmp/.env /home/ubuntu/projects/

sudo git clone ${repo} .

set -a # automatically export all variables
source .env
set +a

#sudo docker login harbor.lab.vaultid.com.br -u="$USER_SOLUTI" -p="$PASS_SOLUTI" > log-docker-login.txt

echo "$PASS_SOLUTI" > /home/ubuntu/tmp/pass.txt

sudo cat /home/ubuntu/tmp/pass.txt | sudo docker login --username $USER_SOLUTI --password-stdin harbor.lab.vaultid.com.br

sudo docker-compose -f cess-compose.yaml up

sudo docker ps