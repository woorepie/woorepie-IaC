provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "woorepie_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "woorepie-vpc"
  }
}

resource "aws_internet_gateway" "woorepie_igw" {
  vpc_id = aws_vpc.woorepie_vpc.id
  tags = {
    Name = "woorepie-igw"
  }
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.woorepie_vpc.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "woorepie-subnet-public1-ap-northeast-2a"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.woorepie_vpc.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "woorepie-subnet-public2-ap-northeast-2c"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.woorepie_vpc.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "woorepie-subnet-private1-ap-northeast-2a"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.woorepie_vpc.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "woorepie-subnet-private2-ap-northeast-2c"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "woorepie-eip-ap-northeast-2a"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    Name = "woorepie-nat-public1-ap-northeast-2a"
  }
  depends_on = [aws_internet_gateway.woorepie_igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.woorepie_vpc.id
  tags = {
    Name = "woorepie-rtb-public"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.woorepie_igw.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.woorepie_vpc.id
  tags = {
    Name = "woorepie-rtb-private1-ap-northeast-2a"
  }
}

resource "aws_route" "private1_nat_route" {
  route_table_id         = aws_route_table.private1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.woorepie_vpc.id
  tags = {
    Name = "woorepie-rtb-private2-ap-northeast-2c"
  }
}

resource "aws_route" "private2_nat_route" {
  route_table_id         = aws_route_table.private2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.woorepie_vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private1.id, aws_route_table.private2.id]
  tags = {
    Name = "woorepie-vpce-s3"
  }
}