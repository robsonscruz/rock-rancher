#-----------------------------------
# Load Balancer - Application
#-----------------------------------
resource "aws_lb" "lbapp" {
  name                              = var.project_name
  tags                              = var.tags_k8s
  internal                          = false
  load_balancer_type                = "application"
  enable_cross_zone_load_balancing  = true
  security_groups                   = [aws_security_group.sg.id]
  ip_address_type                   = "ipv4"
  subnets                           = var.elb_subnets
}

#-----------------------------------
# Target group
#-----------------------------------
resource "aws_lb_target_group" "api" {
  name      = var.project_name
  port      = "80"
  protocol  = "HTTP"
  vpc_id    = var.vpc_id
  tags      = var.tags_k8s

  health_check { 
    path = "/api/providers"
    port = "8080"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "600"
    enabled         = true
  }
}

#-----------------------------------
# Listener LB
#-----------------------------------
resource "aws_lb_listener" "ln-http" {
  load_balancer_arn = aws_lb.lbapp.arn
  port      = "80"
  protocol  = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}
resource "aws_lb_listener" "ln-https" {
  load_balancer_arn = aws_lb.lbapp.arn
  port       = "443"
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = aws_acm_certificate.cert.arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

#-----------------------------------
# Launch configuration
#-----------------------------------
resource "aws_launch_configuration" "cluster" {
    name_prefix          = "${var.project_name}-"
    image_id             = var.ami
    instance_type        = var.instance_type
    security_groups      = [aws_security_group.sg.id]
    key_name             = aws_key_pair.keypair.key_name
    associate_public_ip_address = false
    user_data            = file(var.user_data_k8s)
    
    root_block_device {
        volume_size           = "70"
        delete_on_termination = true
    }
    lifecycle {
        create_before_destroy = true
    }
    depends_on                = [aws_key_pair.keypair, aws_lb_listener.ln-http, aws_lb_listener.ln-https]
}

#-----------------------------------
# Autoscale
#-----------------------------------
resource "aws_autoscaling_group" "cluster" {
    name                 = var.project_name
    launch_configuration = aws_launch_configuration.cluster.name
    vpc_zone_identifier  = var.elb_subnets
    min_size             = try(var.aws_autoscaling_config.min_size, 1)
    max_size             = try(var.aws_autoscaling_config.max_size, 1)
    enabled_metrics      = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
    metrics_granularity  = "1Minute"
    health_check_type    = "ELB"
    suspended_processes  = try(var.aws_autoscaling_config.suspended_processes, [])

    tag { 
      key   = "Name"
      value = "k8s"
      propagate_at_launch = true
    }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.cluster.id
  alb_target_group_arn   = aws_lb_target_group.api.arn
}

#-----------------------------------
# Autoscale policy
#-----------------------------------
resource "aws_autoscaling_policy" "autopolicy" {
    name                    = "${var.project_name}-autoplicy"
    scaling_adjustment      = 1
    adjustment_type         = "ChangeInCapacity"
    cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
    autoscaling_group_name  = aws_autoscaling_group.cluster.name
}
resource "aws_autoscaling_policy" "autopolicy-down" {
    name                    = "${var.project_name}-autoplicy-down"
    scaling_adjustment      = -1
    adjustment_type         = "ChangeInCapacity"
    cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
    autoscaling_group_name  = aws_autoscaling_group.cluster.name
}
resource "aws_autoscaling_policy" "autopolicy-mem" {
    name                    = "${var.project_name}-autopolicy-mem"
    scaling_adjustment      = 1
    adjustment_type         = "ChangeInCapacity"
    cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
    autoscaling_group_name  = aws_autoscaling_group.cluster.name
}
resource "aws_autoscaling_policy" "autopolicy-mem-down" {
    name                    = "${var.project_name}-autopolicy-mem-down"
    scaling_adjustment      = -1
    adjustment_type         = "ChangeInCapacity"
    cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
    autoscaling_group_name  = aws_autoscaling_group.cluster.name
}

#-----------------------------------
# Cloudwatch policy
#-----------------------------------
resource "aws_cloudwatch_metric_alarm" "cpualarm" {
    alarm_name          = "${var.project_name}-cpu-high"
    comparison_operator = try(var.aws_autoscaling_config.comparison_operator_high, "GreaterThanOrEqualToThreshold")
    evaluation_periods  = try(var.aws_autoscaling_config.evaluation_periods, 2)
    metric_name         = try(var.aws_autoscaling_config.cpu_metric_name, "CPUUtilization")
    namespace           = "AWS/EC2"
    period              = try(var.aws_autoscaling_config.period_high, 120)
    statistic           = try(var.aws_autoscaling_config.statistic, "Average")
    threshold           = try(var.aws_autoscaling_config.cpu_threshold_high, 60)
    dimensions          = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions     = [aws_autoscaling_policy.autopolicy.arn]
}
resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
    alarm_name          = "${var.project_name}-cpu-low"
    comparison_operator = try(var.aws_autoscaling_config.comparison_operator_low, "LessThanOrEqualToThreshold")
    evaluation_periods  = try(var.aws_autoscaling_config.evaluation_periods, 2)
    metric_name         = try(var.aws_autoscaling_config.cpu_metric_name, "CPUUtilization")
    namespace           = "AWS/EC2"
    period              = try(var.aws_autoscaling_config.period_high, 120)
    statistic           = try(var.aws_autoscaling_config.statistic, "Average")
    threshold           = try(var.aws_autoscaling_config.cpu_threshold_low, 10)
    dimensions          = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions     = [aws_autoscaling_policy.autopolicy-down.arn]
}
resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name          = "${var.project_name}-mem-high"
    comparison_operator = try(var.aws_autoscaling_config.comparison_operator_high, "GreaterThanOrEqualToThreshold")
    evaluation_periods  = try(var.aws_autoscaling_config.evaluation_periods, 2)
    metric_name         = try(var.aws_autoscaling_config.mem_metric_name, "MemoryUtilization")
    namespace           = "AWS/EC2"
    period              = try(var.aws_autoscaling_config.period_high, 120)
    statistic           = try(var.aws_autoscaling_config.statistic, "Average")
    threshold           = try(var.aws_autoscaling_config.mem_threshold_high, 80)
    dimensions          = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
    alarm_description   = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions       = [aws_autoscaling_policy.autopolicy-mem.arn]
}
resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name          = "${var.project_name}-mem-low"
    comparison_operator = try(var.aws_autoscaling_config.comparison_operator_low, "LessThanOrEqualToThreshold")
    evaluation_periods  = try(var.aws_autoscaling_config.evaluation_periods, 2)
    metric_name         = try(var.aws_autoscaling_config.mem_metric_name, "MemoryUtilization")
    namespace           = "AWS/EC2"
    period              = try(var.aws_autoscaling_config.period_low, 300)
    statistic           = try(var.aws_autoscaling_config.statistic, "Average")
    threshold           = try(var.aws_autoscaling_config.mem_threshold_low, 40)
    dimensions          = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
    alarm_description   = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions       = [aws_autoscaling_policy.autopolicy-mem-down.arn]
}
#-----------------------------------
# Certificate
#-----------------------------------
resource "aws_acm_certificate" "cert" {
  private_key      = file("./data/cert_priv.pem")
  certificate_body = file("./data/cert_pub.pem")
}

#-----------------------------------
# DNS
#-----------------------------------
data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"

  alias {
    name    = aws_lb.lbapp.dns_name
    zone_id = aws_lb.lbapp.zone_id
    evaluate_target_health = false
  }
}