module "iam" {
  source = "./infra/IAM"
}

module "ec2" {
  source                   = "./infra/JENKINS"
  monitoring_pipeline_role = module.iam.monitoring_pipeline_role // From IAM 
}


module "vpc" {
  source = "./infra/VPC"
}