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
    instance_type        = var.instance_type_cluster
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
locals {
    autoscaling_policy = [
        {
            name                    = "terraform-autoplicy"
            scaling_adjustment      = 1
            adjustment_type         = "ChangeInCapacity"
            cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
            autoscaling_group_name  = aws_autoscaling_group.cluster.name
        },
        {
            name                    = "terraform-autoplicy-down"
            scaling_adjustment      = -1
            adjustment_type         = "ChangeInCapacity"
            cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
            autoscaling_group_name  = aws_autoscaling_group.cluster.name
        },
        {
            name                    = "terraform-autopolicy-mem"
            scaling_adjustment      = 1
            adjustment_type         = "ChangeInCapacity"
            cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
            autoscaling_group_name  = aws_autoscaling_group.cluster.name
        },
        {
            name                    = "terraform-autopolicy-mem-down"
            scaling_adjustment      = -1
            adjustment_type         = "ChangeInCapacity"
            cooldown                = try(var.aws_autoscaling_config.cooldown, 300)
            autoscaling_group_name  = aws_autoscaling_group.cluster.name
        }
    ]
    autoscaling_policy_map  = {for key, val in local.autoscaling_policy: key => val} 
}
resource "aws_autoscaling_policy" "autopolicy" {
    for_each               = local.autoscaling_policy_map

    name                   = each.value.name
    scaling_adjustment     = each.value.scaling_adjustment
    adjustment_type        = each.value.adjustment_type
    cooldown               = each.value.cooldown
    autoscaling_group_name = each.value.autoscaling_group_name
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
  type    = "CNAME"

  alias {
    name    = aws_lb.lbapp.dns_name
    zone_id = aws_lb.lbapp.zone_id
    evaluate_target_health = false
  }
}