terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region1
  alias  = "r1"
}

provider "aws" {
  region = var.region2
  alias  = "r2"
}

# -----------------------
# VPC for Region 1
# -----------------------
resource "aws_vpc" "vpc_r1" {
  provider = aws.r1
  cidr_block = "10.0.0.0/16"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}

resource "aws_internet_gateway" "ig_r1" {
  provider = aws.r1
  vpc_id = aws_vpc.vpc_r1.id
}

resource "aws_subnet" "subnet_r1" {
  provider = aws.r1
  vpc_id            = aws_vpc.vpc_r1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region1}a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt_r1" {
  provider = aws.r1
  vpc_id = aws_vpc.vpc_r1.id
}

resource "aws_route" "public_route_r1" {
  provider = aws.r1
  route_table_id         = aws_route_table.rt_r1.id
  gateway_id             = aws_internet_gateway.ig_r1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "rt_assoc_r1" {
  provider = aws.r1
  route_table_id = aws_route_table.rt_r1.id
  subnet_id      = aws_subnet.subnet_r1.id
}

resource "aws_security_group" "sg_r1" {
  provider = aws.r1
  name   = "allow_all_r1"
  vpc_id = aws_vpc.vpc_r1.id

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

# EC2 Instances Region 1
resource "aws_instance" "servers_r1" {
  provider = aws.r1
  count    = var.server_count_r1

  ami           = var.amazon_linux_ami_r1
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.subnet_r1.id
  vpc_security_group_ids = [aws_security_group.sg_r1.id]

  user_data = file("userdata.sh")

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}

# -----------------------
# Region 2 (Duplicate logic)
# -----------------------
resource "aws_vpc" "vpc_r2" {
  provider = aws.r2
  cidr_block = "10.1.0.0/16"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}

resource "aws_internet_gateway" "ig_r2" {
  provider = aws.r2
  vpc_id = aws_vpc.vpc_r2.id
}

resource "aws_subnet" "subnet_r2" {
  provider = aws.r2
  vpc_id            = aws_vpc.vpc_r2.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "${var.region2}a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt_r2" {
  provider = aws.r2
  vpc_id = aws_vpc.vpc_r2.id
}

resource "aws_route" "public_route_r2" {
  provider = aws.r2
  route_table_id         = aws_route_table.rt_r2.id
  gateway_id             = aws_internet_gateway.ig_r2.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "rt_assoc_r2" {
  provider = aws.r2
  route_table_id = aws_route_table.rt_r2.id
  subnet_id      = aws_subnet.subnet_r2.id
}

resource "aws_security_group" "sg_r2" {
  provider = aws.r2
  name   = "allow_all_r2"
  vpc_id = aws_vpc.vpc_r2.id

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

# EC2 Instances Region 2
resource "aws_instance" "servers_r2" {
  provider = aws.r2
  count    = var.server_count_r2

  ami           = var.amazon_linux_ami_r2
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.subnet_r2.id
  vpc_security_group_ids = [aws_security_group.sg_r2.id]

  user_data = file("userdata.sh")

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = []
    replace_triggered_by  = []
  }
}
