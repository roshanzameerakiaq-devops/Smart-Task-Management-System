terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# Existing default VPC
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "devops_sg" {
  name        = "smart-task-devops-sg"
  description = "Security group for Smart Task DevOps infrastructure"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube
  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Harbor HTTP
  ingress {
    description = "Harbor HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube
  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Harbor HTTPS
  ingress {
    description = "Harbor HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault
  ingress {
    description = "Vault"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes NodePort range
  ingress {
    description = "Kubernetes NodePorts"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes internal communication
  ingress {
    description = "Kubernetes internal TCP"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Kubernetes internal UDP"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "Smart-Task-Management-System"
  }
}

# -----------------------------
# EC2 Instances
# -----------------------------
locals {
  instances = {
    jenkins = {
      type = "t3.medium"
    }

    harbor-vault = {
      type = "t3.medium"
    }

    k8s-master = {
      type = "t3.medium"
    }

    k8s-worker-1 = {
      type = "t3.medium"
    }

    k8s-worker-2 = {
      type = "t3.medium"
    }
  }
}

resource "aws_instance" "devops" {
  for_each = local.instances

  ami           = "ami-007b1f3fdea0383d9"
  instance_type = each.value.type
  key_name      = "smart-task-devops-key"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.devops_sg.id
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name    = "smart-task-${each.key}"
    Project = "Smart-Task-Management-System"
    Role    = each.key
  }
}
