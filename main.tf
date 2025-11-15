# Combined single main.tf without variables or tfvars
# Values are hardcoded directly as requested

terraform {
  required_version = ">= 1.13.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# ---------- PROVIDERS (2 REGIONS) ---------
provider "aws" {
  region = "ap-south-1"
  alias  = "aps1"
}

provider "aws" {
  region = "ap-southeast-1"
  alias  = "apse1"
}

# ---------- VPC / COMMON NETWORK COMPONENTS ----------
# Simple VPC with open security group
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_subnet" "demo" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route" "demo" {
  route_table_id         = aws_route_table.demo.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo.id
}

resource "aws_route_table_association" "demo" {
  subnet_id      = aws_subnet.demo.id
  route_table_id = aws_route_table.demo.id
}

# ---------- SECURITY GROUP (OPEN ALL PORTS) ----------
resource "aws_security_group" "open_all" {
  name        = "open-all"
  description = "Allow everything"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- USER DATA FILE (LOCAL) ----------
data "local_file" "userdata" {
  filename = "userdata.sh"
}

# ---------- EC2 INSTANCES (COUNT REQUIRED) ----------
resource "aws_instance" "server_aps1" {
  provider                  = aws.aps1
  ami                       = "ami-0f5e8a042c8bfcd5e" # Amazon Linux 2 for ap-south-1
  instance_type             = "t3.micro"
  key_name                  = "Selva Demo"
  subnet_id                 = aws_subnet.demo.id
  vpc_security_group_ids    = [aws_security_group.open_all.id]
  user_data                 = data.local_file.userdata.content

  count = 2

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}

resource "aws_instance" "server_apse1" {
  provider                  = aws.apse1
  ami                       = "ami-0f3f4f9d2d1f9b050" # Amazon Linux 2 for ap-southeast-1
  instance_type             = "t3.micro"
  key_name                  = "Selva Demo"
  subnet_id                 = aws_subnet.demo.id
  vpc_security_group_ids    = [aws_security_group.open_all.id]
  user_data                 = data.local_file.userdata.content

  count = 2

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}