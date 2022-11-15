
data "aws_availability_zones" "available" {}

locals {
  azs = data.aws_availability_zones.available.names
}
resource "random_id" "rdm_id" {
  byte_length = 2
}

resource "aws_vpc" "main-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  # main_route_table_id = aws_route_table.main-rt.id

  tags = {
    "Name" = "main-vpc-${random_id.rdm_id.dec}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "main-ig" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    "Name" = "main-igw-${random_id.rdm_id.dec}"
  }
}

resource "aws_default_route_table" "private_rt" {
  default_route_table_id = aws_vpc.main-vpc.default_route_table_id

  tags = {
    "Name" = "private_rt"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    "Name" = "public-rt-${random_id.rdm_id.dec}"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main-ig.id
  depends_on = [
    aws_route_table.public-rt
  ]

}

resource "aws_subnet" "public_subnet" {
  for_each                = toset(var.public_cidrs)
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = each.key
  map_public_ip_on_launch = true
  availability_zone       = local.azs[index(var.public_cidrs, each.key) + 1]

  tags = {
    "Name" = "public_subnet-${index(var.public_cidrs, each.key) + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each                = toset(var.private_cidrs)
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = each.key
  map_public_ip_on_launch = false
  availability_zone       = local.azs[index(var.private_cidrs, each.key) + 1]

  tags = {
    "Name" = "private_subnet-${index(var.private_cidrs, each.key) + 1}"
  }
}

resource "aws_route_table_association" "mtc_public_assoc" {
  for_each = aws_subnet.public_subnet


  subnet_id      = each.value.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_security_group" "main_ec2_sg" {
  name        = "main_ec2_sg"
  description = "Main security group for our EC2 instances"
  vpc_id      = aws_vpc.main-vpc.id

  tags = {
    "Name" = "main_ec2_sg"
  }
}

resource "aws_security_group_rule" "ingress_allow_subnets" {
  type              = "ingress"
  security_group_id = aws_security_group.main_ec2_sg.id
  // normally we do that => cidr_blocks = concat(var.private_cidrs, var.public_cidrs)
  cidr_blocks = [var.access_ip]
  protocol    = "-1"
  from_port   = 0
  to_port     = 65535
  description = "Allow all TCP traffic"
}

resource "aws_security_group_rule" "egress_allow_internet" {
  type              = "egress"
  security_group_id = aws_security_group.main_ec2_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  description       = "Allow all TLS"
}