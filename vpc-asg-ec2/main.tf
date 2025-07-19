provider "aws" {
  region = var.region
}

# --- 1. Networking ---
module "vpc" {
  source = "./modules/vpc"

  name                 = var.name
  app                  = var.app
  cidr_block           = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# --- 2. Security ---
module "alb_public_sg" {
  source      = "./modules/sec_group"
  name        = "${var.name}-alb-public-sg"
  description = "ALB Public SG"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "${var.name}-alb-public-sg"
    App  = var.app
  }

  ingress_rules = [
    { cidr_block = "0.0.0.0/0", from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP from anywhere" },
    { cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS from anywhere" }
  ]
  egress_rules = [
    # Allow egress only to the public EC2 instances on the application port
    { referenced_sg_id = module.ec2_public_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow egress to public EC2 instances" }
  ]
}

# module "alb_private_sg" {
#   source      = "./modules/sec_group"
#   name        = "${var.name}-alb-private-sg"
#   description = "ALB Private SG"
#   vpc_id      = module.vpc.vpc_id
#   tags = {
#     Name = "${var.name}-alb-private-sg"
#     App  = var.app
#   }

#   ingress_rules = [
#     { cidr_block = "0.0.0.0/0", from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP" },
#     { cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS" }
#   ]

#   egress_rules = [
#     { cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0, protocol = "-1", description = "Allow all egress" }
#   ]
# }

module "ec2_public_sg" {
  source      = "./modules/sec_group"
  name        = "${var.name}-ec2-public-sg"
  description = "EC2 Public SG"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "${var.name}-ec2-public-sg"
    App  = var.app
  }

  ingress_rules = [
    # Allow ingress only from the public ALB security group
    { referenced_sg_id = module.alb_public_sg.security_group_id, from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP from Public ALB" }
  ]

  egress_rules = [
    { cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0, protocol = "-1", description = "Allow all egress" }
  ]
}

# module "ec2_private_sg" {
#   source      = "./modules/sec_group"
#   name        = "${var.name}-ec2-private-sg"
#   description = "EC2 Private SG"
#   vpc_id      = module.vpc.vpc_id
#   tags = {
#     Name = "${var.name}-ec2-private-sg"
#     App  = var.app
#   }

#   ingress_rules = [
#     { cidr_block = "0.0.0.0/0", from_port = 80, to_port = 80, protocol = "tcp", description = "Allow HTTP" },
#     { cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443, protocol = "tcp", description = "Allow HTTPS" }
#   ]

#   egress_rules = [
#     { cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0, protocol = "-1", description = "Allow all egress" }
#   ]
# }



# --- 3. IAM ---
resource "aws_iam_instance_profile" "ssm_profile" {
  name_prefix = "${var.name}-ssm-instance-profile-"
  role        = aws_iam_role.ssm_role.name
}

resource "aws_iam_role" "ssm_role" {
  name_prefix = "${var.name}-ssm-role-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- 4. Launch Templates ---
module "lt_public" {
  source = "./modules/launch_template"

  name                = var.name
  app                 = var.app
  name_prefix         = "${var.name}-public"
  image_id            = data.aws_ami.amazon_linux_2.id
  instance_type       = var.instance_type
  security_group_id   = module.ec2_public_sg.security_group_id 
  instance_profile_name = aws_iam_instance_profile.ssm_profile.name
  user_data           = filebase64("${path.module}/public-server-userdata.sh")
}

# module "lt_private" {
#   source = "./modules/launch_template"

#   name                = var.name
#   app                 = var.app
#   name_prefix         = "${var.name}-private"
#   image_id            = data.aws_ami.amazon_linux_2.id
#   instance_type = var.instance_type
#   security_group_id = module.ec2_private_sg.security_group_id # Use module output
#   instance_profile_name = aws_iam_instance_profile.ssm_profile.name
#   user_data           = filebase64("${path.module}/public-server-userdata.sh")
# }

# --- 5. Load Balancers ---
module "alb_public" {
  source = "./modules/alb"

  name                  = "${var.name}-public-alb"
  app                   = var.app
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb_public_sg.security_group_id
}

# --- 6. Auto Scaling Groups ---
module "asg_public" {
  source = "./modules/asg"

  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  subnet_ids         = module.vpc.public_subnet_ids
  launch_template_id = module.lt_public.id
  target_group_arns  = [module.alb_public.target_group_arn]
  tags = {
    Name = "${var.name}-public-asg"
    App  = var.app
  }
}

# NOTE: A second ALB and ASG for the private subnets would follow the same pattern
# as the public one, but with `internal = true` for the ALB and using the private
# subnets and security group.