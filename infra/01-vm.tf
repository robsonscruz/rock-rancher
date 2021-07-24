#-----------------------------------
# KeyPair
#-----------------------------------
resource "aws_key_pair" "keypair" {
    key_name        = var.project_name
    public_key      = file(var.key_path)
}

#-----------------------------------
# Security Group
#-----------------------------------
resource "aws_security_group" "sg" {
  name        = "rancher-server"
  description = "Access Rancher Server"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-----------------------------------
# VM - Rancher Server
#-----------------------------------
resource "aws_instance" "rancher" {
    ami                  = var.ami
    instance_type        = var.instance_type
    security_groups      = [aws_security_group.sg.id]
    key_name             = aws_key_pair.keypair.key_name
    subnet_id            = var.subnet_id
    user_data            = file(var.user_data_rancher)
    tags                 = var.tags_rancher
    volume_tags          = var.tags_rancher
    
    root_block_device {
        delete_on_termination = true
    } 
}

output "rancher-ip-vm" {
  value = aws_instance.rancher.public_ip
}