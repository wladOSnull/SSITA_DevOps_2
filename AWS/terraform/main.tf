terraform {
  backend "s3" {
    bucket = "ssita-geocitizen"
    key    = "terraform/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
   region  = "eu-north-1"
   profile = "devops1"
}

### Ubuntu
##################################################

resource "aws_instance" "UbuntuServer" {
    ami                    = "ami-092cce4a19b438926"  
    instance_type          = "t3.micro" 
    key_name               = "id_rsa_ubuntu"
    vpc_security_group_ids = [aws_security_group.SG_Ubuntu.id]

    tags = {
      Name = "terraform_Ubuntu"
    }

#    provisioner "local-exec" {
#      command = "rm ./ip && echo 'ubuntu_server: ${aws_instance.UbuntuServer.private_ip}' >> ./ip"
#    }
}

resource "aws_eip" "eip" {
  instance = aws_instance.UbuntuServer.id
  vpc      = true
}

resource "aws_security_group" "SG_Ubuntu" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {  
      cidr_blocks      = ["0.0.0.0/0",]
      description      = "for Tomcat"
      from_port        = 8080
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 8080
    },
    {  
      cidr_blocks      = var.mint_ip
      description      = "for Mint - AWX"
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },  
    {  
      cidr_blocks      = var.host_ip
      description      = "for host"
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
  tags = {
    Name = "terraform_SG_Ubuntu"
  }
}

### Amazon Linux 2
##################################################

resource "aws_instance" "AmazonLinux2" {
    ami                    = "ami-013126576e995a769"  
    instance_type          = "t3.micro" 
    key_name               = "id_rsa_centos"
    vpc_security_group_ids = [aws_security_group.SG_AmazonLinux2.id]

    tags = {
      Name = "terraform_AmazonLinux2"
    }

#    provisioner "local-exec" {
#      command = "echo 'centos: ${aws_instance.AmazonLinux2.private_ip}' >> ./ip"
#    }    
}

resource "aws_security_group" "SG_AmazonLinux2" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {  
      cidr_blocks      = ["${aws_instance.UbuntuServer.private_ip}/32",]
      description      = "for PostgreSQL"
      from_port        = 5432
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 5432
    },
    {  
      cidr_blocks      = var.mint_ip
      description      = "for Mint - AWX"
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },  
    {  
      cidr_blocks      = var.host_ip
      description      = "for host"
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
  tags = {
    Name = "terraform_SG_AmazonLinux2"
  }  
}

### Ansible IPs
##################################################

#resource "local_file" "inventory_ips" {
#    filename = "../ansible/hosts.ini"
#    content  = <<EOF
#[geoDB]
#${aws_instance.AmazonLinux2.public_ip}
#
#[geoDBprivate]
#${aws_instance.AmazonLinux2.private_ip}
#
#[geoServer]
#${aws_eip.eip.public_ip}
#
#EOF
#}

resource "local_file" "inventory_names" {
    filename = "../ansible/names.yml"
    content  = <<EOF
var_db: ${aws_instance.AmazonLinux2.tags.Name}
var_server: ${aws_instance.UbuntuServer.tags.Name}
EOF
}

### Output
##################################################

output "public_ip" {
  value = aws_eip.eip.public_ip
}
