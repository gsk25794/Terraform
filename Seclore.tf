terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "xxx"
  secret_key = "xxx"
}

#Provisioning the VPC
resource "aws_vpc" "tf_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Terraform_VPC"
  }
}

#Provisioning the Internet Gateway
resource "aws_internet_gateway" "tf_IGW" {
  vpc_id = aws_vpc.tf_VPC.id

  tags = {
    Name = "Terraform_IGW"
  }
}

#Provisioning the Route Table
resource "aws_route_table" "tf_RT" {
  vpc_id = aws_vpc.tf_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_IGW.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.tf_IGW.id
  }

  tags = {
    Name = "Terraform_RT"
  }
}

#Provisioning the Subnet
resource "aws_subnet" "tf_Subnet-1" {
  vpc_id     = aws_vpc.tf_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Terraform-Subnet-Public"
  }
}

#Creating Route table & Subnet Association
resource "aws_route_table_association" "tf_RTandSubnet" {
  subnet_id      = aws_subnet.tf_Subnet-1.id
  route_table_id = aws_route_table.tf_RT.id
}

#Provisioning Security Group
resource "aws_security_group" "tf_SG" {
  vpc_id      = aws_vpc.tf_VPC.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform_SG"
  }
}

#Provisioning the Server Instance
resource "aws_instance" "tf_Server" {
  ami           = "ami-03d315ad33b9d49c4" #us-east-1
  instance_type = "t2.micro"
  private_ip = "10.0.1.100"
  subnet_id = aws_subnet.tf_Subnet-1.id
  security_groups = [aws_security_group.tf_SG.id]
  availability_zone = "us-east-1a"
  key_name = "MyUSE1KP"


  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Terraform Web Server is Online > /var/www/html/index.html'
              EOF

  tags = {
      Name = "Terraform-Server"
    }
}

#Provisioning the Elastic IP
resource "aws_eip" "tf_EIP" {
  instance = aws_instance.tf_Server.id
  vpc      = true
}
