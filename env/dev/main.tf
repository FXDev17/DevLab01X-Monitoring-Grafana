module "vpc" {
  source = "./infra/VPC"
}

module "ec2" {
  source = "./infra/JENKINS"
}