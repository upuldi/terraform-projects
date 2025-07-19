output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the created public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "The IDs of the created private subnets."
  value       = module.vpc.private_subnet_ids
}

output "public_alb_dns_name" {
  description = "The DNS name of the public Application Load Balancer."
  value       = module.alb_public.alb_dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb_public_sg.security_group_id
}

output "ec2_security_group_id" {
  description = "Security group ID of the EC2 instances"
  value       = module.ec2_public_sg.security_group_id
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = module.iam.instance_profile_name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = module.iam.instance_profile_arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.lt_public.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg_public.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.alb_public.target_group_arn
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "name_prefix" {
  description = "Name prefix used for resources"
  value       = local.name_prefix
}