module "ec2" {
  source = "./infra/EC2"
#   ssh_public_key = var.ssh_public_key
}

module "iam" {
  source = "./infra/IAM"
}

