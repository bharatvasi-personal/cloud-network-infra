variable "aws_region" {
  default = "ap-south-2"
}

variable "instance_type_master" {
  default = "t3.micro"
}

variable "instance_type_worker" {
  default = "t3.micro"
}

variable "key_name" {
  default = "k8s-key"
}