variable "role_name" {
  type        = string
  description = "Name for the IAM role"
  default     = "ec2-ssm-instance-role"
}

variable "profile_name" {
  type        = string
  description = "Name for the instance profile"
  default     = "ec2-ssm-instance-profile"
}

variable "app" {
  type        = string
  description = "App tag for resources"
}
