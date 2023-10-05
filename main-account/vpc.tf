module "workloads_vpc" {
  providers = {
    aws = aws.uswe2
  }
  
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

module "drs_vpc" {
  providers = {
    aws = aws.uswe1
  }
  source   = "git@github.com:aws-ia/terraform-aws-vpc"
  
  name                                 = var.drs_vpc_name
  cidr_block                           = var.drs_vpc_cidr
  vpc_egress_only_internet_gateway     = true
  az_count                             = 1

  subnets = {
    public = {
      name_prefix = "drs-public"
      netmask = 24
      nat_gateway_configuration = "all_azs"
    }
  
    stg = {
      name_prefix = "drs-staging"
      netmask = 24
      connect_to_public_natgw = true
    }

    drill = { 
      name_prefix = "drs-drill"
      netmask = 24
      connect_to_public_natgw = true
    }

    recovery = {
      name_prefix = "drs-recovery"
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
  drs_vpc = module.drs_vpc
  stg_subnet_id = [ for a in local.drs_vpc.azs : local.drs_vpc.private_subnet_attributes_by_az["stg/${a}"].id ]
  recovery_subnet_id = [ for a in local.drs_vpc.azs : local.drs_vpc.private_subnet_attributes_by_az["recovery/${a}"].id ]
  drill_subnet_ids =  [ for a in local.drs_vpc.azs : local.drs_vpc.private_subnet_attributes_by_az["drill/${a}"].id ] 
  drs_stg_rtb_id = one([ for k, rtb in local.drs_vpc.rt_attributes_by_type_by_az["private"] : rtb.id if strcontains(k, "stg")])
  drs_drill_rtb_id = one([ for k, rtb in local.drs_vpc.rt_attributes_by_type_by_az["private"] : rtb.id if strcontains(k, "drill")])
  drs_recovery_rtb_id = one([ for k, rtb in local.drs_vpc.rt_attributes_by_type_by_az["private"] : rtb.id if strcontains(k, "recovery")])
  all_drs_rtbs = [local.drs_stg_rtb_id, local.drs_drill_rtb_id, local.drs_recovery_rtb_id ]
}  



data "aws_caller_identity" "self" {
  provider = aws.uswe1
}

resource "aws_vpc_peering_connection" "workload" {
  provider = aws.uswe2
  vpc_id        = module.workloads_vpc.vpc_attributes.id
  peer_vpc_id   = module.drs_vpc.vpc_attributes.id
  peer_owner_id = data.aws_caller_identity.self.account_id
  peer_region   = "us-west-1"

  tags = {
    Name = "workload"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "drs" {
  provider                  = aws.uswe1
  vpc_peering_connection_id = aws_vpc_peering_connection.workload.id

  tags = {
    Name = "drs"
  }
}

resource "aws_route" "workload_to_drs_peer" {
  count = length(local.workload_private_rtb_ids)
  route_table_id = local.workload_private_rtb_ids[count.index]
  destination_cidr_block = var.drs_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.workload.id

  depends_on = [ aws_vpc_peering_connection_accepter.drs ]
}

resource "aws_route" "drs_to_workload_peer" {
  provider = aws.uswe1
  for_each = toset(local.all_drs_rtbs)
  route_table_id = each.value
  destination_cidr_block = var.workload_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.drs.id
  depends_on = [ aws_vpc_peering_connection.workload ]
}
