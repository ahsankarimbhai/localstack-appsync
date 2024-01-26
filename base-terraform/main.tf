# terraform {
#   backend "s3" {}
# }

provider "aws" {
  region = var.aws_region  
  access_key                  = "mock_access_key"
  # s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    acm            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    appsync        = "http://localhost:4566" 
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    eventbridge    = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    elasticsearch  = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    neptune        = "http://localhost:4566"
    sagemaker      = "http://localhost:4566"
  }
}

locals {
  nodejs_runtime = "nodejs14.x"
  python_runtime = "python3.8"
}

data "aws_caller_identity" "id" {}

module "base" {
  source                        = "./modules/base"
  combined_subnet_ranges        = var.combined_subnet_ranges
  subnet_config                 = var.subnet_config
  base_name                     = var.base_name
  region_domain_map             = var.region_domain_map
  service_discovery_hosted_zone = var.service_discovery_hosted_zone
  turn_on_neptune_rebalance     = var.turn_on_neptune_rebalance
}