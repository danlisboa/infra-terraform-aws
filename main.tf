provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

//CREATE VPC
resource "aws_vpc" "AppVPC" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

//CREATE SUBNET
resource "aws_subnet" "AppPublicSubnet" {
  count                   = length(var.subnet_cidr)
  vpc_id                  = aws_vpc.AppVPC.id
  cidr_block              = element(var.subnet_cidr, count.index)
  availability_zone       = element(var.subnet_azs, count.index)
  map_public_ip_on_launch = "true"
  depends_on = [
    aws_vpc.AppVPC
  ]

  tags = {
    Name = "sb-public-${var.appName}-${element(var.subnet_azs, count.index)}"
  }
}

//CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "AppGateway" {
  vpc_id = aws_vpc.AppVPC.id
  depends_on = [
    aws_vpc.AppVPC
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "AppRoutePublic" {
  vpc_id = aws_vpc.AppVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.AppGateway.id
  }
  depends_on = [
    aws_vpc.AppVPC,
    aws_internet_gateway.AppGateway
  ]

  tags = {
    "Name" = var.route_table_name
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  count          = length(var.subnet_cidr)
  subnet_id      = element(aws_subnet.AppPublicSubnet.*.id, count.index)
  route_table_id = aws_route_table.AppRoutePublic.id
  depends_on = [
    aws_subnet.AppPublicSubnet,
    aws_route_table.AppRoutePublic
  ]
}

//CREATE SECURITY GROUP
resource "aws_security_group" "AppSgApi" {
  name        = "sgApi${var.appName}"
  description = "Security group api node"
  vpc_id      = aws_vpc.AppVPC.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "sg com acesso https qualquer ip"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "sg com acesso ssh qualquer ip"
  }

  ingress {
    from_port   = 3000
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "sg com acesso http qualquer ip"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
    aws_vpc.AppVPC
  ]

  tags = {
    Name = "security-group-api"
  }
}

resource "aws_security_group" "AppSgDataBase" {
  name        = "sgDatabase${var.appName}"
  description = "Security group database"
  vpc_id      = aws_vpc.AppVPC.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["201.81.17.87/32"]
    description = "Meu ip"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "sg-api-${var.appName}"
    security_groups = [aws_security_group.AppSgApi.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
    aws_vpc.AppVPC,
    aws_security_group.AppSgApi
  ]

  tags = {
    Name = "sg-database-${var.appName}"
  }
}

//ROLE S3
resource "aws_iam_instance_profile" "readS3role" {
  name = "readS3role"
  role = var.roleNameAccessS3
}

//CREATE EC2
resource "aws_instance" "AppInstance" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.AppPublicSubnet.*.id, 0)
  vpc_security_group_ids = [aws_security_group.AppSgApi.id]
  key_name               = var.key_name
  user_data              = file("./init.sh")
  iam_instance_profile   = aws_iam_instance_profile.readS3role.id


  depends_on = [
    aws_subnet.AppPublicSubnet,
    aws_security_group.AppSgApi
  ]

  tags = {
    Name = "master-instance-api-${var.appName}"
  }
}

resource "aws_launch_configuration" "AppLaunch" {
  name_prefix = "api-launch-${var.appName}"

  image_id      = var.instance_ami # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = var.instance_type
  key_name      = var.key_name

  security_groups             = [aws_security_group.AppSgApi.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.readS3role.id

  user_data = file("./init.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "AppLoadBalanceSG" {
  name        = "sgLoadBalanceApp"
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

resource "aws_lb" "AppLoadBalance" {
  name               = "lb-app-${var.appName}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.AppLoadBalanceSG.id]
  subnets            = [for s in aws_subnet.AppPublicSubnet : s.id]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = "lb-app-${var.appName}"
  }
}

resource "aws_autoscaling_group" "scalingGroup" {
  name = "${aws_launch_configuration.AppLaunch.name}-scaling-group"

  min_size         = 1
  max_size         = 4
  desired_capacity = 1

  health_check_type = "ELB"

  /*load_balancers = [
    aws_lb.AppLoadBalance.id
  ]*/

  target_group_arns = [aws_lb_target_group.AppLbTargetGroup.arn]

  launch_configuration = aws_launch_configuration.AppLaunch.name

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
    value               = "instance-api-scaled"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.scalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.scalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_up.arn]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.scalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web-cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.scalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_down.arn]
}

resource "aws_lb_target_group" "AppLbTargetGroup" {
  name     = "lb-target-group-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.AppVPC.id

  health_check {
    path                = "/"
    port                = 3000
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }
}

resource "aws_lb_listener" "ops_alb_listener_80" {
  load_balancer_arn = aws_lb.AppLoadBalance.arn
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

resource "aws_lb_listener" "ops_alb_listener_443" {
  load_balancer_arn = aws_lb.AppLoadBalance.arn
  port              = "443"
  protocol          = "HTTPS"
  #certificate_arn   = "${var.elk_cert_arn}"
  certificate_arn = var.certificate_arn


  default_action {
    target_group_arn = aws_lb_target_group.AppLbTargetGroup.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "schemaRegistryTgAttach" {
  target_group_arn = aws_lb_target_group.AppLbTargetGroup.arn
  target_id        = aws_instance.AppInstance.id
  port             = 3000
}

/* Manualmente
  - configurar route53
  - configurar codedeploy e pipeline
*/
