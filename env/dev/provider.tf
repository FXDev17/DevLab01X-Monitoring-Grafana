# provider "aws" {
#   region              = "eu-west-2"  
#   allowed_account_ids = ["817520395860"]
  
#   # This tells Terraform to automatically use the Jenkins-assumed role
#   assume_role {
#     role_arn = "arn:aws:iam::817520395860:role/terraform_deploy_role"
#   }
# }


provider "aws" {
  region = "eu-west-2"
}