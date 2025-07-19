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