locals {
  drs_cross_account_role_arn = "arn:aws:iam::718147145862:role/workload-ec2-instance-role"
}

#EC2 Role 
resource "aws_iam_instance_profile" "workload_ec2" {
  name = "workload-ec2-instance"
  role = aws_iam_role.workload_ec2_role.name
}

resource "aws_iam_role" "workload_ec2_role" {
  name               = "workload-ec2-instance-role"
  assume_role_policy = file("./ec2-trust-policy.json")
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "drs_cross_account_role" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    effect  = "Allow"
   resources = [local.drs_cross_account_role_arn]
  }
}

resource "aws_iam_role_policy" "ec2_ssm_policy" {
  name   = "drs-assume-role"
  role   = aws_iam_role.workload_ec2_role.name
  policy = data.aws_iam_policy_document.drs_cross_account_role.json
}
