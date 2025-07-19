resource "aws_autoscaling_group" "asg" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
  target_group_arns = var.target_group_arns

  # Health check settings
  health_check_type         = "ELB"
  health_check_grace_period = 300

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.enable_scaling ? 1 : 0
  name                   = "${aws_autoscaling_group.asg.name}-scale-up"
  scaling_adjustment     = var.scaling_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.cooldown_period
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.enable_scaling ? 1 : 0
  name                   = "${aws_autoscaling_group.asg.name}-scale-down"
  scaling_adjustment     = -var.scaling_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.cooldown_period
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_scaling ? 1 : 0
  alarm_name          = "${aws_autoscaling_group.asg.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.scale_up_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.enable_scaling ? 1 : 0
  alarm_name          = "${aws_autoscaling_group.asg.name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.scale_down_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
