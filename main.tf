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
resource "aws_security_group" "AppSecurityGroup" {
  name        = "sgApp${var.appName}"
  description = "Security group app node"
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
    to_port     = 3002
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
    Name = "app-security-group"
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
    security_groups = [aws_security_group.AppSecurityGroup.id]
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
    aws_security_group.AppSecurityGroup
  ]

  tags = {
    Name = "sg-database-${var.appName}"
  }
}

//ROLE S3
resource "aws_iam_instance_profile" "readS3role" {
  role = var.roleNameAccessS3
  name = "read-s3-role-v2x"
}

data "template_file" "init" {
  template = file("init-api.sh.tpl")

  vars = {
    varEnv      = var.EnvApi,
    repo        = var.repo,
    installRuby = var.installRuby
  }
}

//CREATE EC2
resource "aws_instance" "ApiInstance" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type_api
  subnet_id              = element(aws_subnet.AppPublicSubnet.*.id, 0)
  vpc_security_group_ids = [aws_security_group.AppSecurityGroup.id]
  key_name               = var.key_name
  user_data              = data.template_file.init.rendered //file("./init.sh")
  iam_instance_profile   = aws_iam_instance_profile.readS3role.id


  depends_on = [
    aws_subnet.AppPublicSubnet,
    aws_security_group.AppSecurityGroup
  ]

  tags = {
    Name = "master-instance-api-${var.appName}"
  }
}

resource "aws_launch_configuration" "ApiLaunch" {
  image_id    = var.instance_ami # Amazon Linux 2 AMI (HVM), SSD Volume Type
  name_prefix = "api-launch-${var.appName}"

  instance_type = var.instance_type_api
  key_name      = var.key_name

  security_groups             = [aws_security_group.AppSecurityGroup.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.readS3role.id

  user_data = data.template_file.init.rendered //file("./init.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ApiLBGroup" {
  name        = "ApiSgLoadBalance"
  description = "Allow HTTP and HTTPS traffic to instances through Elastic Load Balancer"
  vpc_id      = aws_vpc.AppVPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  /* @todo voltar quando obtiver o certificado
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
  }*/

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

resource "aws_lb" "ApiLoadBalance" {
  name               = "api-lb-app-${var.appName}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ApiLBGroup.id]
  subnets            = [for s in aws_subnet.AppPublicSubnet : s.id]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = "lb-api-${var.appName}"
  }
}

resource "aws_autoscaling_group" "ApiScalingGroup" {
  name = "api-${aws_launch_configuration.ApiLaunch.name}-scaling-group"

  min_size         = 0
  max_size         = 4
  desired_capacity = 0

  health_check_type = "ELB"

  /*load_balancers = [
    aws_lb.ApiLoadBalance.id
  ]*/

  target_group_arns = [aws_lb_target_group.ApiLBTargetGroup.arn]

  launch_configuration = aws_launch_configuration.ApiLaunch.name

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
    value               = "scaled-instance-api"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "api_policy_up" {
  name                   = "api-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 800
  autoscaling_group_name = aws_autoscaling_group.ApiScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "api_cpu_alarm_up" {
  alarm_name          = "api-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "600"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoApiScalingGroupName = aws_autoscaling_group.ApiScalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.api_policy_up.arn]
}

resource "aws_autoscaling_policy" "api_policy_down" {
  name                   = "api-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 800
  autoscaling_group_name = aws_autoscaling_group.ApiScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "api_cpu_alarm_down" {
  alarm_name          = "api-cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "600"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoApiScalingGroupName = aws_autoscaling_group.ApiScalingGroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.api_policy_down.arn]
}

resource "aws_lb_target_group" "ApiLBTargetGroup" {
  name     = "api-lb-target-group-3000"
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

//remover após obter o certificado
resource "aws_lb_listener" "ApiListenerLB_80" {
  load_balancer_arn = aws_lb.ApiLoadBalance.arn
  port              = "80"
  protocol          = "HTTP"
  #certificate_arn   = "${var.elk_cert_arn}"

  default_action {
    target_group_arn = aws_lb_target_group.ApiLBTargetGroup.arn
    type             = "forward"
  }
}

/* retornar após obter certificado
resource "aws_lb_listener" "ApiListenerLB_80" {
  load_balancer_arn = aws_lb.ApiLoadBalance.arn
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

resource "aws_lb_listener" "ApiListenerLB_443" {
  load_balancer_arn = aws_lb.ApiLoadBalance.arn
  port              = "443"
  protocol          = "HTTPS"
  #certificate_arn   = "${var.elk_cert_arn}"
  certificate_arn = var.certificate_arn


  default_action {
    target_group_arn = aws_lb_target_group.ApiLBTargetGroup.arn
    type             = "forward"
  }
}
*/

resource "aws_lb_target_group_attachment" "ApiSchemaRegistryTgAttach" {
  target_group_arn = aws_lb_target_group.ApiLBTargetGroup.arn
  target_id        = aws_instance.ApiInstance.id
  port             = 3000
}

/* Manualmente
  - route53 (DNS)
    - set load balance group

  - Aplicativo grupo de implantação (CI/CD)
      - set load balance scale group


*/
