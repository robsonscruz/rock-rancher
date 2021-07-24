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
variable "subnet_id" {
    default = "subnet-95f85abf"
}
variable "ami" {
    # Ubuntu Server
    default = "ami-042e8287309f5df03"
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
variable "instance_type_cluster" {
    default = "t4g.large"
}
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
    default = [22, 80, 8080, 443]
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
# Auto scale
#-----------------------------------
variable "aws_autoscaling_config" {
    default = {
        min_size = 1
        max_size = 3
        suspended_processes = []#["Terminate"]
        # Policy
        cooldown = 300 // seconds
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