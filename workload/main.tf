provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "workload"
    }, var.tags)
  }
}

locals {
  name = "${replace(lower(var.project_name), "_", "-")}-${var.environment}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# checkov:skip=CKV2_AWS_11:VPC Flow Logs are omitted to keep the workshop small and low-cost.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# checkov:skip=CKV_AWS_130:A public subnet is intentional for this workshop PoC.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "Workshop web security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-web-sg"
  }
}

# checkov:skip=CKV_AWS_260:Public HTTP access is intentional for this workshop demo endpoint.
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "Public HTTP access for workshop demo"
  cidr_ipv4         = var.allowed_http_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# checkov:skip=CKV_AWS_382:Outbound access is required during bootstrap to install Python packages.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Workshop bootstrap egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# checkov:skip=CKV_AWS_88:Public IP is intentional for the workshop EC2 demo endpoint.
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  monitoring                  = true
  ebs_optimized               = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_py_b64       = filebase64("${path.module}/../app/app.py")
    requirements_b64 = filebase64("${path.module}/../app/requirements.txt")
  })

  user_data_replace_on_change = true

  depends_on = [aws_route_table_association.public]

  tags = {
    Name = "${local.name}-web"
  }
}
