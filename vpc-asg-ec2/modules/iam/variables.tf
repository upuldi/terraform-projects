variable "name_prefix" {
  description = "Prefix for naming IAM resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to IAM resources"
  type        = map(string)
  default     = {}
}
