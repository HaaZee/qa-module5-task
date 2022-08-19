# Variables for this project
# Values come from secrets.auto.tfvars
variable "secret_key" {
  sensitive = "true"
  type      = string
}

variable "access_key" {
  sensitive = "true"
  type      = string
}


variable "db_username" {
  sensitive = "true"
  type      = string
}


variable "db_password" {
  sensitive = "true"
  type      = string
}