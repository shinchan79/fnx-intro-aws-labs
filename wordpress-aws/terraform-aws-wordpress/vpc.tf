resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.stack}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.stack}-igw"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.eip.id

  tags = {
    Name = "${var.stack}-nat"
  }
}

resource "aws_eip" "eip" {

  vpc = true

  tags = {
    Name = "${var.stack}-nat-ip"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.stack}-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.stack}-public"
  }
}

resource "aws_route_table_association" "private1" {
  route_table_id = aws_route_table.private.id

  subnet_id = aws_subnet.private1.id
}

resource "aws_route_table_association" "private2" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private2.id
}

resource "aws_route_table_association" "public1" {
  route_table_id = aws_route_table.public.id

  subnet_id = aws_subnet.public1.id
}

resource "aws_route_table_association" "public2" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public2.id
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-3c"

  tags = {
    Name = "${var.stack}-public-c"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-3a"
  tags = {
    Name = "${var.stack}-public-a"
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-northeast-3c"

  tags = {
    Name = "${var.stack}-private-c"
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"

  availability_zone = "ap-northeast-3a"

  tags = {
    Name = "${var.stack}-private-a"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${var.stack}-subngroup"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "${var.stack}-subnetGroup"
  }
}
