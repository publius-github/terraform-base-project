locals {
  resource_name = "test-network"

  common_tags = {
    Name = "test-network"
    env  = "test"
  }
}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "az_count" {
  default = "3"
}

variable "subnet_length" {
  default = "4"
}
