variable "target_group_arn" {
  type = string
  description = "ARN of the ALB target group to attach ASG"
}
variable "launch_template_id" {
  type = string
}
variable "image_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "desired_capacity" {
  type = number
}

variable "max_size" {
  type = number
}

variable "min_size" {
  type = number
}

variable "app" {
  type = string
}