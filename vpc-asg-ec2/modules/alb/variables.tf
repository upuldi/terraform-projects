variable "name" {
  type        = string
  description = "Name tag for the ALB"
}

variable "app" {
  type        = string
  description = "App tag for the ALB"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for the ALB"
}
