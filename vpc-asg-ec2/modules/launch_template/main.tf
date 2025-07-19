resource "aws_launch_template" "this" {
  name_prefix   = var.name_prefix
  image_id      = var.image_id
  instance_type = var.instance_type
  user_data     = var.user_data
  key_name      = var.key_pair_name
  ebs_optimized = var.ebs_optimized

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
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

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.name_prefix}-volume"
      App  = var.app
    }
  }
}