variable "tags" {
  type = map(string)
  description = "Tags to apply to the ASG and its resources"
  default = {}
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

variable "subnet_ids" {
  type = list(string)
  description = "A list of subnet IDs to launch resources in."
}

variable "launch_template_id" {
  type = string
}

variable "target_group_arns" {
  description = "A list of ALB target group ARNs to attach to the ASG."
  type        = list(string)
  default     = []
}
