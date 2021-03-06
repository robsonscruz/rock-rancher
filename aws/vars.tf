#-----------------------------------
# Setup - provider
#-----------------------------------
variable "credential" {
    default = "~/.aws/credentials"
}
variable "profile" {
    default = "default"
}
variable "region" {
    default = "us-east-1"
}
#-----------------------------------
# VMs
#-----------------------------------
variable "key_path" {
    default = "./data/cert.pub"
}
variable "instance_type" {
    default = "t3a.medium"
}
variable "instance_type_k8s" {
    default = "t3.large"
}
variable "subnet_id" {
    default = "subnet-95f85abf"
}
variable "ami" {
    # Ubuntu Server 20.04
    default = "ami-042e8287309f5df03"
}
variable "ami_k8s" {
    # Ubuntu Server 18.04
    default = "ami-0747bdcabd34c712a"
}
variable "user_data_rancher" {
    default = "./user-data/rancher.sh"
}
variable "user_data_k8s" {
    default = "./user-data/k8s.sh"
}
#-----------------------------------
# LB - Cluster
#-----------------------------------
variable "elb_subnets" {
    default = ["subnet-95f85abf", "subnet-511faa09"]
}
variable "vpc_id" {
    default = "vpc-dc1520b8"
}
#-----------------------------------
# Security group
#-----------------------------------
variable "sg_ingress" {
    default = [22, 80, 8080, 443, 6443] // 6443 usada pelo rancher
}
#-----------------------------------
# TAGs
#-----------------------------------
variable "tags_rancher" {
   default = {
        Name = "rancherserver"
   }
}
variable "tags_k8s" {
   default = {
        Name = "k8s"
   }
}
#-----------------------------------
# Health check
#-----------------------------------
variable "target_group_config" {
    default = {
        port                        = 80
        protocol                    = "HTTP"
        http_health_check_port      = 8080
        health_check_path           = "/api/providers"
        stickiness_type             = "lb_cookie"
        stickiness_cookie_duration  = "600"
        stickiness_enabled          = true
    }
}
#-----------------------------------
# Auto scale
#-----------------------------------
variable "aws_autoscaling_config" {
    default = {
        min_size = 2
        max_size = 3
        suspended_processes = []#["Terminate"]
        # Policy
        cooldown = 300 // seconds
        # Cloudwatch
        comparison_operator_low     = "LessThanOrEqualToThreshold"
        comparison_operator_high    = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 2
        cpu_metric_name     = "CPUUtilization"
        mem_metric_name     = "MemoryUtilization"
        statistic           = "Average"
        period_high         = 120
        period_low          = 300
        cpu_threshold_high  = 60
        cpu_threshold_low   = 10
        mem_threshold_high  = 80
        mem_threshold_low   = 40
    }
}
#-----------------------------------
# DNS
#-----------------------------------
variable "project_name" {
    default = "rock-devops"
}
variable "domain_name" {
    default = "rock-devops.ml"
}