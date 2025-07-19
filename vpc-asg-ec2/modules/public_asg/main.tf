resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy-public"
  autoscaling_group_name = aws_autoscaling_group.public_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy-public"
  autoscaling_group_name = aws_autoscaling_group.public_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "public-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Scale out if CPU > 60%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public_asg.name
  }
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "public-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale in if CPU < 20%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public_asg.name
  }
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
}
## Launch template is now external and passed in as a variable

resource "aws_autoscaling_group" "public_asg" {
  desired_capacity     = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.public_subnet_ids
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
  target_group_arns   = [var.target_group_arn]
  tag {
    key                 = "Name"
    value               = "public-server-asg"
    propagate_at_launch = false
  }
  tag {
    key                 = "App"
    value               = var.app
    propagate_at_launch = false
  }
}
