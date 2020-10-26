variable "aws_region" {
  type = string
  description = "AWS region where Seafile will be set up"
}

variable "instance_type" {
  type = string
  description = "EC2 instance type"
}

variable "key_name" {
  type = string
  description = "Name of an existing SSH key to access the EC2 instance"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for the new VPC"
}

variable "sg_cidr" {
  type = list
  description = "CIDR blocks for the Security Group (IP ranges where the EC2 instance will be accessed from)"
}

variable "bucket_name" {
  type = string
  description = "Name for the new S3 bucket serving as data store"
}

variable "mysql_root_password" {
  type = string
  description = "Password for the MySQL root user"
}

variable "mysql_seafile_password" {
  type = string
  description = "Password for the MySQL seafile user"
}

variable "download_url" {
  type = string
description = "URL of the Seafile server package"
}

variable "seahub_email" {
  type = string
  description = "Email address for the Seahub admin user"
}

variable "seahub_password" {
  type = string
  description = "Password for the Seahub admin user"
}

variable "hosted_zone" {
  type = string
  description = "Hosted zone ID for the DNS record in Route53"
}

variable "dns_record" {
  type = string
  description = "DNS record (type A) for the webserver, to be created in Route53"
}

variable "server_cert_path" {
  type = string
  description = "Local path to the .crt file of the SSL/TLS certificate to be uploaded to the Seafile server"
}

variable "server_key_path" {
  type = string
  description = "Local path to the .key file of the SSL/TLS certificate to be uploaded to the Seafile server"
}

locals {
  project_name		= "Seafile"
  s3fs_endpoint_url	= var.aws_region == "us-east-1" ? "https://s3.amazonaws.com" : "https://s3-${var.aws_region}.amazonaws.com"
}

