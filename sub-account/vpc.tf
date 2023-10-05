module "workloads_vpc" {  
  source = "git@github.com:aws-ia/terraform-aws-vpc"
  
  name                                 = var.workload_vpc_name
  cidr_block                           = var.workload_vpc_cidr
  vpc_egress_only_internet_gateway     = true
  az_count                             = var.num_of_azs

  subnets = {

    public = {
      name_prefix = "workload-public"
      netmask = 24
      nat_gateway_configuration = "all_azs"
    }
  
    private = {
      name_prefix = "workload-private"
      netmask = 24
      connect_to_public_natgw = true
    }

  }
}
locals {
  workload_vpc = module.workloads_vpc
  workload_private_subnet_ids = [ for s in local.workload_vpc.private_subnet_attributes_by_az : s.id ] 
  workload_public_subnet_ids =[ for s in local.workload_vpc.public_subnet_attributes_by_az : s.id ]  
  workload_private_rtb_ids  = [ for rtb in local.workload_vpc.rt_attributes_by_type_by_az["private"] : rtb.id ]
  workload_public_rtb_ids = [ for rtb in local.workload_vpc.rt_attributes_by_type_by_az["public"] : rtb.id ]
}  

resource "aws_security_group" "ec2" {
  description = "SSH Access for EC2 instances"

  vpc_id = module.workloads_vpc.vpc_attributes.id
  name   = "ec2-sg"
}

#allows access from my home public IP
resource "aws_security_group_rule" "home_ip" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}

#allows network cidr 
resource "aws_security_group_rule" "network_cidr" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.ec2.id
}


resource "aws_security_group_rule" "outbound" {
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}