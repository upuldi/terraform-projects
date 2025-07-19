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
