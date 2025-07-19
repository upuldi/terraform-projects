locals {
  # Common tags applied to all resources
  common_tags = {
    Name        = var.name
    App         = var.app
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "vpc-asg-ec2"
  }

  # Name prefix for resources
  name_prefix = "${var.name}-${var.environment}"

  # Security group rules for ALB
  alb_public_ingress_rules = [
    {
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP from anywhere"
    },
    {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS from anywhere"
    }
  ]

  # Common egress rule for allowing all outbound traffic
  allow_all_egress = {
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all egress"
  }

  # ASG configuration
  asg_config = {
    desired_capacity = var.asg_desired_capacity
    max_size         = var.asg_max_size
    min_size         = var.asg_min_size
  }
}
