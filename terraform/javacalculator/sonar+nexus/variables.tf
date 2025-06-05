variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "ami_id" {
  default = "ami-0f403e3180720dd7e" # Amazon Linux 2023 in us-east-1
}

variable "key_name" {
  default = "hw-3" # Not hw-3.pem
}

