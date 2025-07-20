provider "aws" {
  region = var.region
}

# --- 1. Networking ---
module "vpc" {
  source = "./modules/vpc"

  name                 = local.name_prefix
  app                  = var.app
  cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  enable_nat_gateway   = var.enable_nat_gateway
}

# --- 2. Security ---
module "alb_public_sg" {
  source      = "./modules/sec_group"
  name        = "${local.name_prefix}-alb-public-sg"
  description = "ALB Public SG"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-public-sg"
  })

  ingress_rules = local.alb_public_ingress_rules
  egress_rules = [
    # Allow egress only to the public EC2 instances on the application port
    { referenced_sg_id = module.ec2_public_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow egress to public EC2 instances" }
  ]
}

module "ec2_public_sg" {
  source      = "./modules/sec_group"
  name        = "${local.name_prefix}-ec2-public-sg"
  description = "EC2 Public SG"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-public-sg"
  })

  ingress_rules = [
    # Allow ingress only from the public ALB security group
    { referenced_sg_id = module.alb_public_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP from Public ALB" }
  ]

  egress_rules = [
    local.allow_all_egress,
    # Allow outbound to internal ALB
    { referenced_sg_id = module.alb_private_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow outbound to Internal ALB" },
    { referenced_sg_id = module.alb_private_sg.security_group_id, from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS to Internal ALB" },
    # Allow HTTPS to private EC2 instances for SSM relay
    { referenced_sg_id = module.ec2_private_sg.security_group_id, from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS to Private EC2 for SSM relay" }
  ]
}

# --- Private Infrastructure Security Groups ---
module "alb_private_sg" {
  source      = "./modules/sec_group"
  name        = "${local.name_prefix}-alb-private-sg"
  description = "Internal ALB Security Group"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-private-sg"
  })

  ingress_rules = [
    # Allow traffic only from public EC2 security group
    { referenced_sg_id = module.ec2_public_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP from Public EC2" },
    { referenced_sg_id = module.ec2_public_sg.security_group_id, from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS from Public EC2" }
  ]

  egress_rules = [
    # Allow egress only to private EC2 instances
    { referenced_sg_id = module.ec2_private_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow egress to Private EC2" }
  ]
}

module "ec2_private_sg" {
  source      = "./modules/sec_group"
  name        = "${local.name_prefix}-ec2-private-sg"
  description = "Private EC2 Security Group"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-private-sg"
  })

  ingress_rules = [
    # Allow HTTP from internal ALB
    { referenced_sg_id = module.alb_private_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP from Internal ALB" },
    # Allow HTTPS from public EC2 instances for SSM relay
    { referenced_sg_id = module.ec2_public_sg.security_group_id, from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS from Public EC2 for SSM relay" }
  ]

  egress_rules = [local.allow_all_egress]
}

# --- 3. IAM ---
module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# --- 4. Launch Templates ---
module "lt_public" {
  source = "./modules/launch_template"

  name                  = var.name
  app                   = var.app
  name_prefix           = "${local.name_prefix}-public"
  image_id              = data.aws_ami.amazon_linux_2.id
  instance_type         = var.instance_type
  security_group_id     = module.ec2_public_sg.security_group_id
  instance_profile_name = module.iam.instance_profile_name
  user_data = base64encode(templatefile("${path.module}/public-server-userdata.sh", {
    private_alb_dns_name = module.alb_private.alb_dns_name
  }))
  key_pair_name = null
}

module "lt_private" {
  source = "./modules/launch_template"

  name                  = var.name
  app                   = var.app
  name_prefix           = "${local.name_prefix}-private"
  image_id              = data.aws_ami.amazon_linux_2.id
  instance_type         = var.instance_type
  security_group_id     = module.ec2_private_sg.security_group_id
  instance_profile_name = module.iam.instance_profile_name
  user_data             = filebase64("${path.module}/private-server-userdata.sh")
  key_pair_name         = null
}

# --- 5. Load Balancers ---
module "alb_public" {
  source = "./modules/alb"

  name                  = "${local.name_prefix}-public-alb"
  app                   = var.app
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb_public_sg.security_group_id
  internal              = false
  subnet_ids            = module.vpc.public_subnet_ids
}

module "alb_private" {
  source = "./modules/alb"

  name                  = "${local.name_prefix}-private-alb"
  app                   = var.app
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb_private_sg.security_group_id
  internal              = true
  subnet_ids            = module.vpc.private_subnet_ids
}

# --- 6. Auto Scaling Groups ---
module "asg_public" {
  source = "./modules/asg"

  desired_capacity   = local.asg_config.desired_capacity
  max_size           = local.asg_config.max_size
  min_size           = local.asg_config.min_size
  subnet_ids         = module.vpc.public_subnet_ids
  launch_template_id = module.lt_public.id
  target_group_arns  = [module.alb_public.target_group_arn]
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-asg"
  })
}

module "asg_private" {
  source = "./modules/asg"

  desired_capacity   = local.asg_config.desired_capacity
  max_size           = local.asg_config.max_size
  min_size           = local.asg_config.min_size
  subnet_ids         = module.vpc.private_subnet_ids
  launch_template_id = module.lt_private.id
  target_group_arns  = [module.alb_private.target_group_arn]
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-asg"
  })
}

# NOTE: A second ALB and ASG for the private subnets would follow the same pattern
# as the public one, but with `internal = true` for the ALB and using the private
# subnets and security group.