terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "yogeshtiwari-tf-state" # Change this if your bucket name is different
    key    = "k8s-cluster/terraform.tfstate"
    region = "ap-south-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# Find the latest Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "k8s-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "k8s" {
  vpc_id = aws_vpc.main.id
  ingress { from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 6443; to_port = 6443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 30080; to_port = 30080; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["10.0.0.0/16"] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# --- IAM ---
resource "aws_iam_role" "role" {
  name = "k8s_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_instance_profile" "profile" {
  name = "k8s_profile"
  role = aws_iam_role.role.name
}

# --- Instances ---
resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  iam_instance_profile = aws_iam_instance_profile.profile.name
  user_data = file("userdata/master.sh")
  tags = { Name = "k8s-master" }
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  iam_instance_profile = aws_iam_instance_profile.profile.name
  user_data = file("userdata/worker.sh")
  tags = { Name = "k8s-worker-${count.index}" }
}