# Seafile EC2/S3 Terraform project
## Description
Terraform project to provision a [Seafile](https://www.seafile.com/en/home/) server (Community Edition) on EC2 and configure an S3 bucket as back end.
Seafile is installed using an [nginx](https://www.nginx.com/) webserver and a [MariaDB](https://mariadb.org/) database.
The [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse) project is used to mount the S3 bucket to the instance, so it can be used as data store.

The following AWS resources will be created:
- Amazon Linux 2-based EC2 instance hosting the Seafile server and serving the front end
- Amazon S3 bucket for back end
- VPC/Security Group configuration
- Route 53 record to access the front end
- IAM role to give S3 permissions to the EC2 instance.

In addition to that, this project includes:
- User data for the EC2 instance to mount the bucket and install Seafile
- Nginx configuration
- Systemd service files for Seafile and Seahub.

## Prerequisites
Before the installation, make sure to have the following prepared:
- Hosted zone in Amazon Route 53, where the DNS record for Seafile can be created
- SSH key uploaded to the Amazon EC2 console (in the region where the resources will be created)
- TLS certificate that Terraform can upload to the Seafile server.

## Installation
Clone this repostory, set all parameters in the `terraform.tfvars` file, and deploy the project:
```shell
$ terraform init
$ terraform apply
```

To check the progress of the Seafile installation, connect to the EC2 instance and take a look at `/var/log/cloud-init-output.log`.

Front end URL: `https://example.com/seafile/`.

## Tested with
| Name | Version |
|------|---------|
| Terraform | 0.13.5 |
| Provider aws | 3.12.0 |
| Provider template | 2.2.0 |

AWS regions: eu-west-1, us-east-1  
EC2 instance type: t3.micro (1 GB RAM)
