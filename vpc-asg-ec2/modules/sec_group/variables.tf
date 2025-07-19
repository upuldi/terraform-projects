variable "name" {
  description = "The name of the security group."
  type        = string
}

variable "description" {
  description = "The description of the security group."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the security group will be created."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the security group."
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "A list of ingress rules. Each rule can have cidr_block or referenced_sg_id."
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    description      = string
    cidr_block       = optional(string)
    referenced_sg_id = optional(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "A list of egress rules. Each rule can have cidr_block or referenced_sg_id."
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    description      = string
    cidr_block       = optional(string)
    referenced_sg_id = optional(string)
  }))
  default = []
}