module "iam" {
  source = "./infra/IAM"
}

module "ec2" {
  source = "./infra/EC2"
  monitoring_pipeline_role = module.iam.monitoring_pipeline_role // From IAM 
  ssh_public_key = var.ssh_public_key
}
