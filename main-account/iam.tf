resource "aws_iam_instance_profile" "workload_ec2" {
  name = "workload-ec2-instance"
  role = aws_iam_role.workload_ec2_role.name
}

resource "aws_iam_role" "workload_ec2_role" {
  name               = "workload-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
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

  statement {
    actions = [ "sts:AssumeRole" , "sts:TagSession", "sts:SetSourceIdentity" ]
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [ "arn:aws:iam::645885595427:root" ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "drs" {
  role       = aws_iam_role.workload_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticDisasterRecoveryRecoveryInstancePolicy"
}


resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.workload_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}