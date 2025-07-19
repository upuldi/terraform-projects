resource "aws_launch_template" "this" {
  name_prefix   = var.name_prefix
  image_id      = var.image_id
  instance_type = var.instance_type
  user_data     = var.user_data

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # Tag the launch template resource itself
  tags = {
    Name = "${var.name_prefix}-lt"
    App  = var.app
  }

  # Specify tags for resources created by this launch template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.name_prefix
      App  = var.app
    }
  }
}