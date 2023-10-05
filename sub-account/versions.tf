terraform {
  backend "s3" {
    bucket = "drs-lab-tf"
    key = "secondary/terraform.tfstate"
    region = "us-west-2"
    profile = "drslab-tf-user"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "drslab-2-tf-user"
}