terraform {
  backend "s3" {
    bucket = "devlab00-logging"
    key    = "monitoring-terraform.tfstate"
    region = "eu-west-2"
  }
}