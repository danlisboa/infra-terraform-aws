variable "appName" {
  default = "APP-NAME"
  type    = string
}

variable "project" {
  description = "Name app"
  default     = "APP-NAME"
  type        = string
}

variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "access_key" {
  description = "YOUR ACCESS KEY"
  default     = ""
  type        = string
}

variable "secret_key" {
  description = "YOUR SECRET KEY"
  default     = ""
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco Classes Inter-Domain Routing VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  default     = "vpc-app-APP-NAME"
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
  default     = "ig-APP-NAME"
  type        = string
}

variable "route_table_name" {
  description = "Route table name"
  default     = "rt-public-APP-NAME"
  type        = string
}

variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-04505e74c0741db8d"
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t2.micro"
}

variable "key_name" {
  description = "key pem aws"
  default     = "APP-NAME"
}

variable "certificate_arn" {
  description = "certificate ssl"
  default     = "arn:aws:acm:us-east-1:104689598512:certificate/7229ee05-b031-4956-ab81-44937ff21785"
}

variable "roleNameAccessS3" {
  description = "access to s3"
  default     = "03-ec2-read-s3"
}
