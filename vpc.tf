# VPC with a public subnet and the security group definition for the Seafile server
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = local.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = local.project_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.vpc_cidr
  tags = {
    Name = local.project_name
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = local.project_name
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  # Default ingress rule
  ingress {
    description = "Security Group"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr
  }

  ingress {
    description = "Seafile"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr
  }

  ingress {
    description = "Seahub"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr
  }

  # Default egress rule
  egress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.project_name
  }
}

