# EC2 Variables
variable "keypair_name" {
  description = "Name of the AWS KeyPair"
  type        = string
  default     = "qa_demo"
}

variable "ami_id" {
  description = "ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0d75513e7706cf2d9"
}

variable "type" {
  description = "Type of the EC2 instance (specification: t2.micro/t3.large/etc)"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "The name of the EC2 instance on the AWS dashboard"
  type        = string
  default     = "base instance"
}

variable "security_group_id" {
  description = "ID of the security group you want the EC2 instance to use"
  type        = list(string)
}

variable "subnet_id" {
  description = "ID of the subnet the EC2 instance will belong to"
  type        = string
}