# ENABLE FOLLOWING TO TEST AGAINST REAL AWS
terraform {
  # backend "s3" {}
  required_providers {
    aws = {
      version = "5.29.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
    region = var.aws_region
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

module "api_gateway" {
  source                    = "./modules/api-gateway"
  name_prefix               = local.name_prefix
}

module "authorizer" {
  for_each                              = var.authorizer_config
  source                                = "./modules/authorizer"
  name_prefix                           = local.name_prefix
  env                                   = var.env
  systems_manager_prefix                = var.base_name
  nodejs_runtime                        = local.nodejs_runtime
  api_gateway                           = module.api_gateway.api_gateway
  lambda_layer_arn                      = module.common_node_modules_lambda_layer.lambda_layer_arn
  authorizer_name                       = each.value.name
  authorizer_type                       = each.value.type
  lambda                                = each.value.lambda
  api_allowed_client_ids                = var.authorizer_api_allowed_client_ids
  reserved_concurrency                  = var.authorizer_settings[each.value.name].reserved_concurrency
  provisioned_concurrency               = var.authorizer_settings[each.value.name].provisioned_concurrency
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
  lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
  graphql_api_id                           = module.appsync.graphql_api_id
  iam_role_arn                             = module.appsync.iam_role_arn
  api_gateway_endpoint                     = local.api_gateway_endpoint
}
