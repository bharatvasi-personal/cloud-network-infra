variable "aws_region" {
  default = "ap-south-2"
}

variable "key_name" {
  default = "k8s-key" # Make sure this key pair exists in your AWS Console!
}