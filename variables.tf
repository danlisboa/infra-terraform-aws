variable "appName" {
  default = "Klivus"
  type    = string
}

variable "project" {
  description = "Name app"
  default     = "klivus"
  type        = string
}

variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "access_key" {
  description = "YOUR ACCESS KEY"
  default     = "AKIARQX74QAYMICRX546"
  type        = string
}

variable "secret_key" {
  description = "YOUR SECRET KEY"
  default     = "bG8ss86L8nVY93Pov2L6/mVmtQ2tJ+lBFZ+2ayIa"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco Classes Inter-Domain Routing VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  default     = "vpc-app-Klivus"
  type        = string
}

variable "subnet_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "subnet_azs" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}

variable "internet_gateway_name" {
  description = "Internet gateway name"
  default     = "ig-Klivus"
  type        = string
}

variable "route_table_name" {
  description = "Route table name"
  default     = "rt-public-Klivus"
  type        = string
}

variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-04505e74c0741db8d"
}

variable "instance_type_api" {
  description = "type for aws EC2 instance"
  default     = "t2.small"
}
variable "instance_type_site" {
  description = "type for aws EC2 instance"
  default     = "t2.small"
}

variable "instance_type_soluti" {
  description = "type for aws EC2 instance"
  default     = "t2.micro"
}
variable "key_name" {
  description = "key pem aws"
  default     = "klivus"
}

variable "certificate_arn" {
  description = "certificate ssl"
  default     = "arn:aws:acm:us-east-1:104689598512:certificate/7229ee05-b031-4956-ab81-44937ff21785"
}

variable "roleNameAccessS3" {
  description = "access to s3"
  default     = "03-ec2-read-s3"
}
variable "repo" {
  description = "repository git to instance"
  default     = "https://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@github.com/klivus/klivus-api.git"
}

variable "repoSite" {
  description = "repository git to instance"
  default     = "https://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@github.com/klivus/klivus-front.git"
}
variable "repoSoluti" {
  description = "repository git to instance"
  default     = "https://github.com/VaultID/docker-cess.git"
}

variable "EnvApi" {
  description = "EnvApi"
  default     = <<EOT
    MAIL_HOST=smtp.gmail.com
    MAIL_PORT=587
    MAIL_USER=klivus.corp@gmail.com
    MAIL_PWD=!$!Kl1vu5
    MAIL_SECURE=0
    MAIL_FROM=Klivus

    WHATSAPP_API=https://api.z-api.io/instances/3A85174A25C7B0CFFD9DCA51DBE1EE3C/token/0DFA493534BFE6DFB80DDFEB

    BD_TYPE=postgres
    BD_HOST=db-klivus.clcs0jkncxw4.us-east-1.rds.amazonaws.com
    BD_PORT=5432
    BD_USER_NAME=postgres
    BD_PASSWORD=!#!kl1vus
    BD_DATA_BASE=postgres
  EOT
}

variable "EnvSite" {
  description = "EnvSite"
  default     = <<EOT
    #SENTRY
    NEXT_PUBLIC_SENTRY_DSN=https://d97aeb544f9a461e8e93f60d19b5ed79@o1002988.ingest.sentry.io/6233836

    #NEXT_AUTH
    NEXTAUTH_URL=https://klivus.tech
    NEXTAUTH_SECRET=bQw2+JYL+2Sxc5fBFOobAwfewawMEqcACGMxs6SNs98=

    #API
    NEXT_PUBLIC_API_ENDPOINT=http://api.klivus.tech
  EOT
}

variable "EnvSoluti" {
  description = "EnvSoluti"
  default     = <<EOT
    USER_SOLUTI=klivus
    PASS_SOLUTI=gaphjanOc6
  EOT
}

variable "installRuby" {
  description = "install ruby"
  default     = <<EOT
    sudo apt-get -y install build-essential git-core curl libgdbm-dev libncurses5-dev libtool bison libffi-dev
    # Install rbenv
    git clone git://github.com/sstephenson/rbenv.git ~/.rbenv

    echo $PATH

    # Add rbenv paths and eval to .bashrc and .bash_profile (needed in login/non-login shells)
    echo -e 'export PATH="./bin:$HOME/.rbenv/bin:$PATH"\neval "$(rbenv init -)"' | tee ~/.bash_profile ~/.bashrc
    . ~/.bash_profile

    echo $PATH

    # Install rbenv plugns
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    git clone git://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
    git clone git://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/rbenv-update
    git clone git://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo

    # Install and set default ruby version
    cd ~/.rbenv
    rbenv install --keep 2.1.6
    rbenv global 2.1.6
    ruby -v
    echo ruby -v

    sudo apt -y install rbenv

    source ~/.bash_profile
    rbenv versions
    ruby -v
    #ls /home/ubuntu/.rbenv/versions/
    #ls /home/ubuntu/.rbenv/
    #sudo apt-get update
    #sudo apt-get -y install unzip
    #sudo apt-get -y install libqt4-dev libsndfile1-dev
    #wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip
    #sudo mkdir -p /usr/local/ec2
    #sudo unzip ec2-ami-tools.zip -d /usr/local/ec

  EOT
}

variable "manifest" {
  description = "manifest"
  default     = <<EOT
# Arquivo para deploy do CESS em produção.
# VaultID - Soluções em criptografia e identidade.
# 02/01/2019
version: \"3\"
services:
  cess:
    image: harbor.lab.vaultid.com.br/cess/cess:latest
    depends_on:
      - redis
    restart: always
    user: \"33\"
    environment:
      - \"clientIdMd=34301485000175\"
      - \"clientSecretMd=gaphjanOc6\"
      # Se necessário, edite apenas as variávies abaixo: #
      - 'urlsMultiCloud={\"https:\/\/apihom.birdid.com.br\":{\"id\":\"SOLUTI\",\"client_id\":\"34301485000175\",\"client_secret\":\"gaphjanOc6\"},\"https:\/\/apicloudid.hom.vaultid.com.br\":{\"id\":\"VAULTID\",\"client_id\":\"34301485000175\",\"client_secret\":\"gaphjanOc6\"}}'
      - \"signatureAdapter=MultiCloudAdapter\"
      - \"cessUrl=http://localhost:8080\"
      - \"APACHE_SSL=false\"
      - \"tokenValidityMAX=6\"
      - \"ttlCacheGeneric=21600\"
      - \"ttlCacheTrust=21600\"
      - \"lifetime=86400\"
      - \"sleep=100\"
      - \"limit=100\"
      - \"MEMORY_LIMIT=4096M\"
      - \"America/Sao_Paulo\"
      - \"timezone=America/Sao_Paulo\"
      - \"level=INFO\"
      - \"redisHost=redis\"
      - \"redisPort=6379\"

    ports:
      # Definir a PORTA_EXTERNA TCP pela qual o container será exposto na rede.
      - 3002:8080
    volumes:
      - ./hom-truststore:/var/www/data/trust
    #      - path_crt:/etc/apache2/cert/cert.pem
    #      - path_key:/etc/apache2/cert/cert.key
    #      - ./license:/var/www/data/license
    networks:
      - nw-cess
  redis:
    image: \"healthcheck/redis:alpine\"
    restart: always
    networks:
      - nw-cess
networks:
  nw-cess:
    driver: bridge
    ipam:
      driver: default

  EOT
}
