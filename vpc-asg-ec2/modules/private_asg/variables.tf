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

variable "launch_template_id" {
  type = string
}
