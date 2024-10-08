variable "vpc_cidr" {}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "eu_availability_zone" {}
variable "cidr_private_subnet" {}

output "vpc_id" {
  value = aws_vpc.jenkins_vpc_eu_west_1.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "public_subnet_cidr_block" {
  value = aws_subnet.public_subnets.*.cidr_block
}

# Setup VPC
resource "aws_vpc" "jenkins_vpc_eu_west_1" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# Setup Public Subnet
resource "aws_subnet" "public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.jenkins_vpc_eu_west_1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Setup Private Subnet
resource "aws_subnet" "private_subnets" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.jenkins_vpc_eu_west_1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "public_internet_gateway" {
  vpc_id = aws_vpc.jenkins_vpc_eu_west_1.id
  tags = {
    Name = "igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.jenkins_vpc_eu_west_1.id
  route {
    cidr_block = "0.0.0.0/0" # open for all (public)
    gateway_id = aws_internet_gateway.public_internet_gateway.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Public Subnet Association
resource "aws_route_table_association" "public_rt_subnet_association" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.jenkins_vpc_eu_west_1.id
  #depends_on = [aws_nat_gateway.nat_gateway]
  tags = {
    Name = "private-rt"
  }
}

# Private Subnet Association
resource "aws_route_table_association" "private_rt_subnet_association" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
