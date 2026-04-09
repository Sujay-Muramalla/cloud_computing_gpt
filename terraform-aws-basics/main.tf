provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "tf-yaic-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "tf-private-subnet"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "tf-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "tf-public-rt"
  }
}


resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "public_ec2_sg" {
  name        = "tf-public-ec2-sg"
  description = "Security group for Terraform public EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "tf-public-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.public_ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  from_port = 22
  to_port   = 22
  ip_protocol = "tcp"

  description = "SSH from internet for training"
}


resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.public_ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "-1"

  description = "Allow all outbound traffic"
}


data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t4g.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_ec2_sg.id]
  key_name                    = "YAIC-KeyPair"
  associate_public_ip_address = true

  tags = {
    Name = "tf-public-ec2"
  }
}

