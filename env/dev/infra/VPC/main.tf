# Setting Up VPC
# checkov:skip=CKV2_AWS_5:SG is attached to Lambda (Checkov visibility issue)
# checkov:skip=CKV2_AWS_12:Default SG unused (custom SGs applied)
# checkov:skip=CKV2_AWS_11:Flow logs unnecessary for demo (monitor Lambda logs instead)
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = var.vpc_tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  target_az = data.aws_availability_zones.available.names[0]
}

# Subnets 
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_public_subnet
  availability_zone = local.target_az
  tags              = var.public_subnet_tags
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_private_subnet
  availability_zone = local.target_az
  tags              = var.private_subnet_tags
}

# Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = var.igw_tags
}

# NAT Gateway
# checkov:skip=CKV2_AWS_19:EIP attached to NAT
resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Corrected Route Tables and Routes
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

# Public Route - Using YOUR variable for destination CIDR
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.cidr_block_public_subnet  # Your original variable
  gateway_id             = aws_internet_gateway.igw.id
}

# Private Route - Using YOUR variable for destination CIDR
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.private_destination_cidr_block  # Your original variable
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Route Table Associations (unchanged structure, fixed references)
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}