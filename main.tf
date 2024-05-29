# VPC 생성
# Public Subnet 생성
# Routing Table 생성
# Routing Table <-> Public Subnet 연결하기 
# EC2 생성

provider "aws" {
  region = "us-east-2"
}



# VPC  생성
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# Public Subnet 만들기
resource "aws_subnet" "myPubSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSubnet"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}


# Pubcic Routing Table 생성
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myRT"
  }
}

# Public Routing Table를 Public Subnet에 연결
resource "aws_route_table_association" "myRTass" {
  subnet_id      = aws_subnet.myPubSubnet.id
  route_table_id = aws_route_table.myPubRT.id
}

# Security Group 생성
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_http"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_oupbound" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # 전부 다
}

# EC2 생성
# *ami: amazon Linux 2023 AMI
resource "aws_instance" "myWEB" {
  ami                    = "ami-0ca2e925753ca2fb4"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.myPubSubnet.id
  vpc_security_group_ids = [aws_security_group.allow_http.id]

  user_data_replace_on_change = true
  user_data                   = <<EOF
  #!bin/bash
  yum -y install httpd
  echo "myWEB" >/var/www/html/index.html
  systemctl enable --now httpd
  EOF


  tags = {
    Name = "myWEB"
  }
}


