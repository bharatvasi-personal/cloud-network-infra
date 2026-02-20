variable "aws_region" {
  default = "ap-south-2"
}

variable "key_name" {
  description = "Your AWS Key Pair name"
  default     = "k8s-key"
}

variable "instance_type_master" {
  default = "t3.medium"
}

variable "instance_type_worker" {
  default = "t3.small"
}

variable "ami_id" {
  # Ubuntu 22.04 LTS us-east-1
  default = "ami-0c7217cdde317cfec"
}
