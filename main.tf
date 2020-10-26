provider "aws" {
  region = var.aws_region
}

# The Seafile server
resource "aws_instance" "ec2_instance" {
  ami				= data.aws_ami.amazon-linux-2.id
  associate_public_ip_address	= true
  instance_type			= var.instance_type
  key_name			= var.key_name
  iam_instance_profile		= aws_iam_instance_profile.instance_profile.name
  subnet_id			= aws_subnet.subnet.id
  vpc_security_group_ids	= [aws_default_security_group.default.id]
  user_data			= data.template_file.user_data.rendered

  credit_specification {
    # default for t3 instances: unlimited
    cpu_credits = "standard"
  }

#  lifecycle {
#    prevent_destroy = true
#  }

  tags = {
    Name = local.project_name
  }
}

# Route53 record for the Seafile front end
resource "aws_route53_record" "dns_record" {
  zone_id = var.hosted_zone
  name    = "${var.dns_record}."
  type    = "A"
  ttl     = "300"
  records = [aws_instance.ec2_instance.public_ip]
}
