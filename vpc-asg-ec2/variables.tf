
variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t2.micro"
}
variable "private_instance_name" {
  type = string
  default = "Private server A"
}
variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "name" {
  type = string
  description = "Name tag for resources"
  default = "my-stack"
}

variable "app" {
  type = string
  description = "App tag for resources"
  default = "my-app"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
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
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "public_instance_name" {
  type = string
  default = "Public Server A"
}