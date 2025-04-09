module "vpc" {
  source        = "./infra/VPC"
  lambda_SG_Out = module.vpc.lambda_SG_Out
}

module "ec2" {
  source = "./infra/JENKINS"
  vpc_id = module.vpc.vpc_id
}

module "dynamodB" {
  source             = "./infra/DYNAMO_DB"
}

module "lambda" {
  source                 = "./infra/LAMBDA"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.subnet_ids
  dynamodb_table_name    = module.dynamodB.table_name
  lambda_SG_Out          = module.vpc.lambda_SG_Out
  request_metrics_db_arn = module.dynamodB.request_metrics_db_arn

}

module "api_gateway" {
  source            = "./infra/API_GATEWAY"
  lambda_name       = module.lambda.lambda_function_name
  lambda_arn        = module.lambda.lambda_function_arn
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  vpc_id            = module.vpc.vpc_id
}
