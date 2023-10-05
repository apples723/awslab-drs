terraform {
  backend "s3" {
    bucket = "drs-lab-tf"
    key = "inf/terraform.tfstate"
    region = "us-west-2"
    profile = "drslab-tf-user"
  }
}

provider "aws" {
  alias = "uswe1"
  region = "us-west-1"
  profile = "drslab-tf-user"
}
provider "aws" {
  alias = "uswe2"
  region = "us-west-2"
  profile = "drslab-tf-user"
}
provider "aws" {
  region = "us-west-2"
  profile = "drslab-tf-user"
}