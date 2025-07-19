variable "name" {
  type = string
  description = "Name tag for the subnets"
}

variable "app" {
  type = string
  description = "App tag for the subnets"
}
variable "vpc_id" {
  type = string
}

variable "public_subnet_count" {
  type    = number
  default = 2
}

variable "private_subnet_count" {
  type    = number
  default = 2
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}
