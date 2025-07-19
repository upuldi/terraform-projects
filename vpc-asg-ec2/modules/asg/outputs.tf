output "name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = var.enable_scaling ? aws_autoscaling_policy.scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = var.enable_scaling ? aws_autoscaling_policy.scale_down[0].arn : null
}
