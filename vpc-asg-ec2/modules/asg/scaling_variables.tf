variable "enable_scaling" {
  description = "Enable auto scaling policies and CloudWatch alarms"
  type        = bool
  default     = true
}

variable "scale_up_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 70

  validation {
    condition     = var.scale_up_threshold >= 50 && var.scale_up_threshold <= 95
    error_message = "Scale up threshold must be between 50 and 95."
  }
}

variable "scale_down_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 20

  validation {
    condition     = var.scale_down_threshold >= 5 && var.scale_down_threshold <= 50
    error_message = "Scale down threshold must be between 5 and 50."
  }
}

variable "scaling_adjustment" {
  description = "Number of instances to add/remove during scaling"
  type        = number
  default     = 1

  validation {
    condition     = var.scaling_adjustment >= 1 && var.scaling_adjustment <= 5
    error_message = "Scaling adjustment must be between 1 and 5."
  }
}

variable "cooldown_period" {
  description = "Cooldown period in seconds between scaling actions"
  type        = number
  default     = 300

  validation {
    condition     = var.cooldown_period >= 60 && var.cooldown_period <= 3600
    error_message = "Cooldown period must be between 60 and 3600 seconds."
  }
}
