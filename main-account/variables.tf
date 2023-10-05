variable "workload_vpc_cidr" { default = "10.1.0.0/16" }
variable "workload_vpc_name" { default = "workload-vpc" }
variable "drs_vpc_cidr" { default = "10.2.0.0/16"}
variable "drs_vpc_name" { default = "drs-vpc" }
variable "num_of_azs" { default = 2 }
variable "region" { default = "us-west-2" }

