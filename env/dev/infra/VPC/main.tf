# Setting Up VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = var.vpc_tags
}

locals {
  target_az = data.aws_availability_zones.available.names[0]  # e.g., "eu-west-2a"
}

# Setting Up Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_public_subnet
  availability_zone = local.target_az
  tags              = var.public_subnet_tags
}

# Setting Up Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_private_subnet
  availability_zone = local.target_az
  tags              = var.private_subnet_tags
}

# Setting Up Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = var.igw_tags
}


# NAT Gateway for Private Subnet to Access the Internet
resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}


# Setting Up Public Route
resource "aws_route" "public__subnet_route" {
  route_table_id         = aws_route.public__subnet_route.id
  destination_cidr_block = var.cidr_block_public_subnet
  gateway_id             = aws_internet_gateway.igw.id
}

# Associating Public Route
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route.public__subnet_route.id
}

# Setting Up Private Route
resource "aws_route" "private_subnet_route" {
  route_table_id         = aws_route.private_subnet_route.id
  destination_cidr_block = var.private_destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Associating Private Route
resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route.private_subnet_route.id

}