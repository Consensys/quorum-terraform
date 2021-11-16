provider "aws" {
  region  = var.region
}
data "aws_ami" "ubuntu" {
 most_recent = true
 owners      = ["099720109477"] # canonical
 filter {
   name   = "name"
   values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
 }
}


