#################################
# Provider
#################################

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

#################################
# Data Source (Existing VPC)
#################################

data "aws_vpc" "default" {
  default = true
}

#################################
# Security Group
#################################

resource "aws_security_group" "my_sg" {
  name        = "terraform-custom-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  # Inbound rules
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.56.69.46/32"]  # Your public IP
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-sg"
  }
}

#################################
# Key Pair (for SSH)
#################################

variable "public_key_path" {
  default = "~/.ssh/my-web-app-key.pub"
}

variable "private_key_path" {
  default = "~/.ssh/my-web-app-key"
}

resource "aws_key_pair" "my_key" {
  key_name   = "terraform-key"
  public_key = file(var.public_key_path)
}

#################################
# Latest Ubuntu AMI
#################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

#################################
# EC2 Instance
#################################

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = "My-Web-App"
  }
}

#################################
# Outputs
#################################

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "security_group_id" {
  value = aws_security_group.my_sg.id
}

output "key_path" {
  value = var.private_key_path
}




