resource "aws_launch_configuration" "SiteLaunch" {
  name_prefix = "site-launch-${var.appName}"

  image_id      = var.instance_ami # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = var.instance_type
  key_name      = var.key_name

  security_groups             = [aws_security_group.AppSecurityGroup.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.readS3role.id

  user_data = file("./init-site.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "SiteLBGroup" {
  name        = "SiteLBGroup"
  description = "Allow HTTP and HTTPS traffic to instances through Elastic Load Balancer"
  vpc_id      = aws_vpc.AppVPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_autoscaling_group" "SiteScalingGroup" {
  name = "site-${aws_launch_configuration.SiteLaunch.name}-scaling-group"

  min_size         = 1
  max_size         = 4
  desired_capacity = 1

  health_check_type = "ELB"

  /*load_balancers = [
    aws_lb.AppLoadBalance.id
  ]*/

  target_group_arns = [aws_lb_target_group.SiteLBTargetGroup.arn]

  launch_configuration = aws_launch_configuration.SiteLaunch.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = [for s in aws_subnet.AppPublicSubnet : s.id]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "scaled-instance-site"
    propagate_at_launch = true
  }
}

resource "aws_lb" "SiteLoadBalance" {
  name               = "site-lb-app-${var.appName}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SiteLBGroup.id]
  subnets            = [for s in aws_subnet.AppPublicSubnet : s.id]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = "lb-app-${var.appName}"
  }
}

resource "aws_lb_listener" "SiteListenerLB_80" {
  load_balancer_arn = aws_lb.SiteLoadBalance.arn
  port              = "80"
  protocol          = "HTTP"
  #certificate_arn   = "${var.elk_cert_arn}"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "SiteListenerLB_443" {
  load_balancer_arn = aws_lb.SiteLoadBalance.arn
  port              = "443"
  protocol          = "HTTPS"
  #certificate_arn   = "${var.elk_cert_arn}"
  certificate_arn = var.certificate_arn


  default_action {
    target_group_arn = aws_lb_target_group.SiteLBTargetGroup.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "SiteLBTargetGroup" {
  name     = "site-lb-target-group-3001"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.AppVPC.id

  health_check {
    path                = "/"
    port                = 3001
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group_attachment" "SiteSchemaRegistryTgAttach" {
  target_group_arn = aws_lb_target_group.SiteLBTargetGroup.arn
  target_id        = aws_instance.SiteInstance.id
  port             = 3001
}

resource "aws_instance" "SiteInstance" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.AppPublicSubnet.*.id, 0)
  vpc_security_group_ids = [aws_security_group.AppSecurityGroup.id]
  key_name               = var.key_name
  user_data              = file("./init-site.sh")
  iam_instance_profile   = aws_iam_instance_profile.readS3role.id


  depends_on = [
    aws_subnet.AppPublicSubnet,
    aws_security_group.AppSecurityGroup
  ]

  tags = {
    Name = "master-instance-site-${var.appName}"
  }
}


resource "aws_autoscaling_policy" "site_policy_up" {
  name                   = "site-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.SiteScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "site_cpu_alarm_up" {
  alarm_name          = "site-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoApiScalingGroupName = aws_autoscaling_group.SiteScalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.site_policy_up.arn]
}

resource "aws_autoscaling_policy" "site_policy_down" {
  name                   = "site-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ApiScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "site_cpu_alarm_down" {
  alarm_name          = "site-cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoApiScalingGroupName = aws_autoscaling_group.ApiScalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.site_policy_down.arn]
}
