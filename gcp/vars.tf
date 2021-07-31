#-----------------------------------
# Setup - provider
#-----------------------------------
variable "credentials_json" {
    default = "~/.ssh/gcp.json"
}
variable "project" {}
variable "region" {
    default = "us-central1"
}
variable "zone" {
    default = "a"
}
#-----------------------------------
# VMs
#-----------------------------------
variable "key_path_priv" {
    default = "./data/cert_priv.pem"
}
variable "key_path_pub" {
    default = "./data/cert_pub.pem"
}
variable "machine_type" {
    default = "e2-medium"
}
variable "source_image" {
    default = "debian-cloud/debian-9"
}
variable "startup_script" {
    default = "./user-data/k8s.sh"
}
#-----------------------------------
# NETWORK
#-----------------------------------
variable "network" {
    default = "default"
}
#-----------------------------------
# NAT
#-----------------------------------
variable "cloud_routers_name" {
    default = "nat-router"
}
variable "cloud_routers_nat_name" {
    default = "nat-config"
}
#-----------------------------------
# PORTS INSTANCE GROUP MANAGER
#-----------------------------------
variable "instance_group_manager_port" {
    default = [
        {
            name = "http"
            port = 80
        },
        {
            name = "https"
            port = 443
        }
    ]
}
#-----------------------------------
# HEALTH CHECK
#-----------------------------------
variable "health_check_config" {
    default = {
        check_interval_sec                 = 300
        timeout_sec                        = 1
        http_health_check_port             = "8080"
        request_path                       = "/api/providers"
        # Em ambiente de produção esse valor deve ser o tempo que
        # o serviço demora para subir
        healing_policies_initial_delay_sec = 600
        unhealthy_threshold                = 10
    }
}
#-----------------------------------
# FIREWALL
#-----------------------------------
variable "compute_firewall" {
    default = [
        {
            name        = "load-balancer-fw"
            protocol    = "tcp"
            ports       = ["80", "443"]
        },
        {
            name        = "health-check"
            protocol    = "tcp"
            ports       = ["80"]
        },
        {
            name        = "internal-rancher"
            protocol    = "tcp"
            ports       = ["6443"] // 6443 - porta usada pelo rancher
        }
    ]
}
locals {
  compute_firewall_map  = {for idx, val in var.compute_firewall: idx => val}  
}
#-----------------------------------
# INSTANCE TEMPLATE
#-----------------------------------
variable "tags" {
    default = ["app-backend"]
}
#-----------------------------------
# INSTANCE TEMPLATE
#-----------------------------------
variable "compute_instance_template" {
    default = {
        name_prefix = "tpl-"
        description = "This template is used to create vm server instances."
        desc_inst   = "K8s Rancher server instance"
    }
}
#-----------------------------------
# AUTO SCALER
#-----------------------------------
variable "compute_autoscaler" {
    default = {
        min_replicas    = 1
        max_replicas    = 2
        cooldown_period = 60
        cpu_utilization = 0.6
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