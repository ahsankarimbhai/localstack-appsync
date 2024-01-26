# terraform {
#   backend "s3" {}
#   required_providers {
#     aws = {
#       version = "5.29.0"
#       source  = "hashicorp/aws"
#     }
#   }
# }

provider "aws" {
  region = var.aws_region  
  access_key                  = "mock_access_key"
  #s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
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
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    acm            = "http://localhost:4566"
  }
}

provider "template" {
}

locals {
  name_prefix                  = "${var.sandbox_prefix}${var.env}-${var.base_name}"
  nodejs_runtime               = "nodejs18.x"
  api_gateway_domain_name      = length(var.api_gateway_domain_name) > 0 ? var.api_gateway_domain_name : "${local.name_prefix}.${var.api_gateway_cert_domain}"
  api_gateway_endpoint         = "https://${local.api_gateway_domain_name}"
}

module "common_node_modules_lambda_layer" {
  source                 = "./modules/lambda-layer"
  name_prefix            = local.name_prefix
  nodejs_runtime         = local.nodejs_runtime
  lambda_layer_name      = "common-node-modules-lambda-layer"
  lambda_layer_full_path = "${path.module}/../backend/dist/layer.zip"
}

module "dynamodb-tables" {
  source                                          = "./modules/dynamodb-tables"
  global_iroh_module_type_id                      = var.global_iroh_module_type_id
  name_prefix                                     = local.name_prefix
  dynamodb_schedule_tasks_additional_config       = var.dynamodb_schedule_tasks_additional_config
  dynamodb_data_migration_tasks_additional_config = var.dynamodb_data_migration_tasks_additional_config
}

module "api_gateway" {
  source                    = "./modules/api-gateway"
  name_prefix               = local.name_prefix
  api_gateway_deployment_id = module.api_gateway_deployment.api_gateway_deployment_id
}

module "authorizer" {
  for_each                              = var.authorizer_config
  source                                = "./modules/authorizer"
  name_prefix                           = local.name_prefix
  env                                   = var.env
  systems_manager_prefix                = var.base_name
  iroh_uri                              = var.iroh_env_mapping[var.iroh_env]
  nodejs_runtime                        = local.nodejs_runtime
  api_gateway                           = module.api_gateway.api_gateway
  lambda_layer_arn                      = module.common_node_modules_lambda_layer.lambda_layer_arn
  tenants_table_arn                     = module.dynamodb-tables.tenants_table_arn
  tenants_config_table_arn              = module.dynamodb-tables.tenants_config_table_arn
  authorizer_name                       = each.value.name
  authorizer_type                       = each.value.type
  lambda                                = each.value.lambda
  iroh_redirect_uri                     = ""
  api_allowed_client_ids                = var.authorizer_api_allowed_client_ids
  reserved_concurrency                  = var.authorizer_settings[each.value.name].reserved_concurrency
  provisioned_concurrency               = var.authorizer_settings[each.value.name].provisioned_concurrency
  dynamodb_request_timeout_milliseconds = 5000
}

module "appsync" {
  source                           = "./modules/appsync"
  name_prefix                      = local.name_prefix
  env                              = var.env
  systems_manager_prefix           = var.base_name
  api_gateway_api_resource_id      = module.api_gateway.api_gateway_api_resource_id
  api_gateway                      = module.api_gateway.api_gateway
  api_authorizer_id                = module.authorizer["api"].authorizer_id
  api_gateway_request_validator_id = module.api_gateway.request_validator_id
  block_introspection_queries      = var.block_introspection_queries
}

module "graphql-api" {
  source                                   = "./modules/graphql-api"
  name_prefix                              = local.name_prefix
  nodejs_runtime                           = local.nodejs_runtime
  systems_manager_prefix                   = var.base_name
  env                                      = var.env
  graphql_api_lambda_timeout               = var.graphql_api_lambda_timeout
  dynamodb_request_timeout_milliseconds    = 10000
  metric_period_in_days                    = var.metric_period_in_days
  lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
  tenants_config_table_arn                 = module.dynamodb-tables.tenants_config_table_arn
  tenants_table_arn                        = module.dynamodb-tables.tenants_table_arn
  graphql_api_id                           = module.appsync.graphql_api_id
  iam_role_arn                             = module.appsync.iam_role_arn
  iroh_uri                                 = var.iroh_env_mapping[var.iroh_env]
  api_gateway_endpoint                     = local.api_gateway_endpoint
}

# module "assets" {
#   source                           = "./modules/assets"
#   name_prefix                      = local.name_prefix
#   nodejs_runtime                   = local.nodejs_runtime
#   systems_manager_prefix           = var.base_name
#   env                              = var.env
#   neptune_cluster_resource_ids     = local.neptune_cluster_resource_ids
#   neptune_cluster_settings         = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn          = module.dynamodb-tables.neptune_shard_table_arn
#   lambda_layer_arn                 = module.common_node_modules_lambda_layer.lambda_layer_arn
#   api_gateway                      = module.api_gateway.api_gateway
#   api_gateway_request_validator_id = module.api_gateway.request_validator_id
#   posture_url                      = module.frontend.cloudfront_apps_endpoint
#   authorizer_id                    = module.authorizer["api"].authorizer_id
#   os_versions_table_arn            = module.dynamodb-tables.os_versions_table_arn
#   groups_table_arn                 = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                 = module.dynamodb-tables.policy_table_arn
#   vulnerability_table_arn          = module.dynamodb-tables.vulnerability_table_arn
#   tenants_table_arn                = module.dynamodb-tables.tenants_table_arn
#   tenant_config_arn                = module.dynamodb-tables.tenants_config_table_arn
#   label_metadata_arn               = module.dynamodb-tables.label_metadata_arn
#   iroh_uri                         = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   event_bridge_bus_arn             = module.event-bridge.event_bridge_bus_arn
#   rules_enabled                    = var.rules_enabled
# }

module "api_gateway_deployment" {
  source                  = "./modules/api-gateway-deployment"
  name_prefix             = local.name_prefix
  public_hosted_zone      = var.public_hosted_zone
  cert_domain             = var.api_gateway_cert_domain
  stage_name              = var.api_gateway_stage_name
  api_gateway_id          = module.api_gateway.api_gateway.id
  api_gateway_domain_name = local.api_gateway_domain_name
}
