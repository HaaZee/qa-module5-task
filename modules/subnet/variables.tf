# Subnet variables
variable "vpc_id" {
  description = "ID of the VPC to create the subnets on."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the subnet group. The IP range allocation."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet group on the AWS dashboard"
  type        = string
}