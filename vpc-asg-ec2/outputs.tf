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

output "private_alb_dns_name" {
  description = "The DNS name of the private/internal Application Load Balancer."
  value       = module.alb_private.alb_dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the public ALB"
  value       = module.alb_public_sg.security_group_id
}

output "alb_private_security_group_id" {
  description = "Security group ID of the private ALB"
  value       = module.alb_private_sg.security_group_id
}

output "ec2_security_group_id" {
  description = "Security group ID of the public EC2 instances"
  value       = module.ec2_public_sg.security_group_id
}

output "ec2_private_security_group_id" {
  description = "Security group ID of the private EC2 instances"
  value       = module.ec2_private_sg.security_group_id
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
  description = "Name of the public Auto Scaling Group"
  value       = module.asg_public.name
}

output "asg_private_name" {
  description = "Name of the private Auto Scaling Group"
  value       = module.asg_private.name
}

output "target_group_arn" {
  description = "ARN of the public ALB target group"
  value       = module.alb_public.target_group_arn
}

output "target_group_private_arn" {
  description = "ARN of the private ALB target group"
  value       = module.alb_private.target_group_arn
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "name_prefix" {
  description = "Name prefix used for resources"
  value       = local.name_prefix
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = module.vpc.public_network_acl_id
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = module.vpc.private_network_acl_id
}

output "network_security_summary" {
  description = "Summary of network security configuration"
  value = {
    public_subnets_cidr  = module.vpc.public_subnet_cidrs
    private_subnets_cidr = module.vpc.private_subnet_cidrs
    nacl_policy          = "Private subnets only allow traffic from public subnets"
    security_layers      = ["Security Groups", "Network ACLs", "Route Tables"]
  }
}