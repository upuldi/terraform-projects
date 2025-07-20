output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the created public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the created private subnets."
  value       = aws_subnet.private[*].id
}

output "public_network_acl_id" {
  description = "The ID of the public network ACL"
  value       = aws_network_acl.public.id
}

output "private_network_acl_id" {
  description = "The ID of the private network ACL"
  value       = aws_network_acl.private.id
}

output "public_subnet_cidrs" {
  description = "The CIDR blocks of the public subnets"
  value       = var.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "The CIDR blocks of the private subnets"
  value       = var.private_subnet_cidrs
}
