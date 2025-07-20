variable "name" {
  type        = string
  description = "Name tag for the ALB"
  
  validation {
    condition     = length(var.name) <= 32
    error_message = "ALB name must be 32 characters or less. Current length: ${length(var.name)}."
  }
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

variable "internal" {
  description = "Whether the ALB is internal (private) or internet-facing"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB (public for external, private for internal)"
  type        = list(string)
  default     = []
}
