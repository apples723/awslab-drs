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
  cidr_blocks       = ["${data.http.home_ip.response_body}/32"]
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

module "workload_instance" {
  count = length(local.workload_private_subnet_ids)
  source                      = "terraform-aws-modules/ec2-instance/aws"

  version                     = "5.5.0"
  name                        = "workload-instance-${count.index + 1}"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  key_name                    = "onering"
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  subnet_id                   = local.workload_private_subnet_ids[count.index]
  iam_instance_profile = aws_iam_instance_profile.workload_ec2.name
  associate_public_ip_address = true
  user_data_base64 = base64encode(file("./user_data.sh"))
  user_data_replace_on_change = true
  ignore_ami_changes = true
}

#Home IP
data "http" "home_ip" {
  url = "https://homeip.gsiders.app"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Ubuntu

}