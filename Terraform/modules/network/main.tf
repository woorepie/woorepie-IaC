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

# 🔒 Public Security Group
resource "aws_security_group" "public_sg" {
  name        = "woorepie-public-sg"
  description = "Allow SSH and Redis"
  vpc_id      = aws_vpc.woorepie_vpc.id

  tags = {
    Name = "woorepie-public-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_ssh" {
  security_group_id = aws_security_group.public_sg.id
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "public_redis" {
  security_group_id = aws_security_group.public_sg.id
  from_port         = var.redis_port
  to_port           = var.redis_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "public_all_outbound" {
  security_group_id = aws_security_group.public_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# 🔒 Private Security Group
resource "aws_security_group" "private_sg" {
  name        = "woorepie-private-sg"
  description = "Allow full TCP and internal HTTPS"
  vpc_id      = aws_vpc.woorepie_vpc.id

  tags = {
    Name = "woorepie-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_all_tcp" {
  security_group_id = aws_security_group.private_sg.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "private_https_internal" {
  security_group_id = aws_security_group.private_sg.id
  from_port         = var.https_port
  to_port           = var.https_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.private_cidr_block
}

resource "aws_vpc_security_group_egress_rule" "private_all_outbound" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "private_http" {
  security_group_id = aws_security_group.private_sg.id
  from_port         = var.http_port
  to_port           = var.http_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# 22, 8000, 9001 from public SG
resource "aws_vpc_security_group_ingress_rule" "private_from_public_ssh" {
  security_group_id            = aws_security_group.private_sg.id
  from_port                    = var.ssh_port
  to_port                      = var.ssh_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "private_from_public_app" {
  security_group_id            = aws_security_group.private_sg.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "private_from_public_monitoring" {
  security_group_id            = aws_security_group.private_sg.id
  from_port                    = var.monitoring_port
  to_port                      = var.monitoring_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public_sg.id
}
