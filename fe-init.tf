#
# !!! LOGIN SETTINGS DO NOT MODIFIY
# 
#
terraform {
  required_providers {
    flexibleengine = {
      source  = "FlexibleEngineCloud/flexibleengine"
      version = "1.22.0"
    }
  }
}


provider "flexibleengine" {
  access_key  = "BLMJNYAVDFGZ4L7N5MCK"
  secret_key  = "3NZQDtklUlXiZSVFvZlM6mHfAXDj6fFFXku1R0sX"
  domain_name = "OCB0002176"
  tenant_name = "eu-west-0"
  auth_url    = "https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3"
  region      = "eu-west-0"
}

#
#
# DO NOT MODIFY ABOVE THIS LINE
#
#



# VARIABLES

variable "vpc_name" {
  default = "vpc-mircea-tff"
}

variable "vpc_cidr" {
  default = "192.168.20.0/24"
}

variable "subnet_name" {
  default = "mircea_subnet-tff"
}

variable "subnet_cidr" {
  default = "192.168.20.0/28"
}

variable "subnet_gateway_ip" {
  default = "192.168.20.1"
}

variable "elb_member_ip" {
  default = "192.168.20.10"
}

variable "instance_count" {
  default = 1
}

variable "subnet02_name" {
  default = "mircea_subnet02_tf"
}

variable "subnet02_cidr" {
  default = "192.168.20.96/28"
}

variable "subnet02_gateway_ip" {
  default = "192.168.20.97"
}

# END VARIABLES




# # START ECS CREATION
resource "flexibleengine_compute_instance_v2" "basic01" {
  name     = "mircea-terraform"
  image_id = "a785085a-f217-4a4b-abc8-ba143691ba7e"
  #flavor_id       = "s3.small.1"
  flavor_name     = "s3.small.1"
  key_pair        = "mircea-Orange"
  security_groups = ["mircea_secgroup"]

  network {
    #name = flexibleengine_networking_network_v2.mircea-network.name
    uuid = flexibleengine_vpc_subnet_v1.mircea_subnet_tf.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install epel-release -y
                sudo yum update -y
                sudo yum install nginx -y
                sudo systemctl enable nginx
                sudo systemctl start nginx
                sudo mkdir -p /var/www/html
                sudo touch /var/www/html/index.html
                sudo bash -c 'echo your very second web 02server > /var/www/html/index.html'
EOF
}

# END ECS CREATION


# # START ECS CREATION
resource "flexibleengine_compute_instance_v2" "basic02" {
  name     = "elb-mircea-terraform"
  image_id = "a785085a-f217-4a4b-abc8-ba143691ba7e"
  #flavor_id       = "s3.small.1"
  flavor_name     = "s3.small.1"
  key_pair        = "mircea-Orange"
  security_groups = ["mircea_secgroup"]

  network {
    #name = flexibleengine_networking_network_v2.mircea-network.name
    uuid = flexibleengine_vpc_subnet_v1.mircea_subnet_tf.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install epel-release -y
                sudo yum update -y
                sudo yum install nginx -y
                sudo systemctl enable nginx
                sudo systemctl start nginx
                sudo mkdir -p /var/www/html
                sudo touch /var/www/html/index.html
                sudo bash -c 'echo your very second web 02server > /var/www/html/index.html'
EOF
}

# END ECS CREATION


# BEGIN VPC CREATION

resource "flexibleengine_vpc_v1" "mircea_vpc_tf02" {
  name = var.vpc_name
  cidr = var.vpc_cidr
}
# END VPC CREATION


# BEGIN SUBNET CREATION

resource "flexibleengine_vpc_subnet_v1" "mircea_subnet_tf" {
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  gateway_ip = var.subnet_gateway_ip
  vpc_id     = flexibleengine_vpc_v1.mircea_vpc_tf02.id
}

# END SUBNET CREATION

# BEGIN SUBNET 2 CREATION

resource "flexibleengine_vpc_subnet_v1" "mircea_subnet02_tf" {
  name       = var.subnet02_name
  cidr       = var.subnet02_cidr
  gateway_ip = var.subnet02_gateway_ip
  vpc_id     = flexibleengine_vpc_v1.mircea_vpc_tf02.id
}


# BEGIN EIP ASSOCIATION

resource "flexibleengine_vpc_eip_v1" "mircea_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "mircea_test_eip"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "flexibleengine_compute_floatingip_associate_v2" "mircea_fip" {
  floating_ip = flexibleengine_vpc_eip_v1.mircea_eip.publicip.0.ip_address
  instance_id = flexibleengine_compute_instance_v2.basic01.id
}

# END EIP ASSOCIATION


# BEGIN EIP ASSOCIATION

resource "flexibleengine_vpc_eip_v1" "mircea_eip02" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "mircea_test_eip02"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "flexibleengine_compute_floatingip_associate_v2" "mircea_fip02" {
  floating_ip = flexibleengine_vpc_eip_v1.mircea_eip02.publicip.0.ip_address
  instance_id = flexibleengine_compute_instance_v2.basic02.id
}

# END EIP ASSOCIATION



# BEGIN SECURITY GROUP


resource "flexibleengine_networking_secgroup_v2" "mircea_secgroup" {
  name        = "mircea_secgroup"
  description = "My neutron security group"
}

resource "flexibleengine_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction      = "ingress"
  ethertype      = "IPv4"
  protocol       = "tcp"
  port_range_min = 22
  port_range_max = 22
  #remote_ip_prefix = flexibleengine_vpc_subnet_v1.mircea_subnet_tf.cidr
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.mircea_secgroup.id
}

resource "flexibleengine_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 80
  remote_ip_prefix = "0.0.0.0/0"
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.mircea_secgroup.id
}

# END SECURITY GROUP

# BEGIN ELB V2

resource "flexibleengine_lb_loadbalancer_v2" "mircea_tff02_lb" {
  #count          = var.instance_count
  name           = "mircea_tff02_lb"
  vip_subnet_id  = flexibleengine_vpc_subnet_v1.mircea_subnet02_tf.id
  admin_state_up = "true"
  depends_on     = [flexibleengine_vpc_v1.mircea_vpc_tf02]

}

resource "flexibleengine_lb_listener_v2" "mircea_tff_lst" {
  name = "mircea_tff_lst"
  #count            = var.instance_count
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = flexibleengine_lb_loadbalancer_v2.mircea_tff02_lb.id
  admin_state_up  = "true"
  #connection_limit = "-1"
}

resource "flexibleengine_lb_pool_v2" "pool" {
  protocol = "HTTP"
  #count          = var.instance_count
  lb_method   = "ROUND_ROBIN"
  listener_id = flexibleengine_lb_listener_v2.mircea_tff_lst.id
}

resource "flexibleengine_lb_member_v2" "member" {
  count   = 1
  address = element(flexibleengine_compute_instance_v2.basic01.*.access_ip_v4, 1.0)
  #address       = "${element(flexibleengine_compute_instance_v2.webserver.*.access_ip_v4, count.index)}"
  #aws_instance.www.*.public_ip[0].
  pool_id       = flexibleengine_lb_pool_v2.pool.id
  subnet_id     = flexibleengine_vpc_subnet_v1.mircea_subnet_tf.id
  protocol_port = 80
}

resource "flexibleengine_lb_monitor_v2" "monitor" {
  pool_id = flexibleengine_lb_pool_v2.pool.id
  #count          = var.instance_count
  type           = "HTTP"
  url_path       = "/"
  expected_codes = "200"
  delay          = 20
  timeout        = 10
  max_retries    = 5
}

