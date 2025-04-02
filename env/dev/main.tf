module "iam" {
  source = "./infra/IAM"
}

module "ec2" {
  source = "./infra/JENKINS"
  monitoring_pipeline_role = module.iam.monitoring_pipeline_role // From IAM 
  ssh_public_key = var.ssh_public_key
}


module "vpc" {
  source = "./infra/VPC"
}