variable "name" {
  description = "The base name for tags."
  type        = string
}

variable "app" {
  description = "The app name for tags."
  type        = string
}

variable "name_prefix" {
  description = "A prefix for the launch template name."
  type        = string
}

variable "image_id" {
  description = "The ID of the AMI to use for the instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the instance."
  type        = string
}

variable "instance_profile_name" {
  description = "The name of the IAM instance profile to associate with the instance."
  type        = string
}

variable "user_data" {
  description = "User data to provide when launching the instance, base64-encoded."
  type        = string
}