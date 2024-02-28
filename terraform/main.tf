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

#cloud front certificates have to be deployed in us-east-1 certificate manager
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
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

resource "aws_route53_zone" "route53_zone" {
  name = var.public_hosted_zone

  tags = {
    Name = "${var.base_name}-route53-zone"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.public_hosted_zone
  validation_method = "DNS"

  tags = {
    Environment = "${var.base_name}-acm-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "common_node_modules_lambda_layer" {
  source                 = "./modules/lambda-layer"
  name_prefix            = local.name_prefix
  nodejs_runtime         = local.nodejs_runtime
  lambda_layer_name      = "common-node-modules-lambda-layer"
  lambda_layer_full_path = "${path.module}/../backend/dist/layer.zip"
}

module "api_gateway" {
  source                            = "./modules/api-gateway"
  name_prefix                       = local.name_prefix
  api_gateway_deployment_stage_name = module.api_gateway_deployment.api_gateway_deployment_stage_name
}

module "api_gateway_deployment" {
  providers = {
    aws.alternate = aws.us-east-1
  }
  source                     = "./modules/api-gateway-deployment"
  name_prefix                = local.name_prefix
  public_hosted_zone         = var.public_hosted_zone
  route_53_zone_id           = aws_route53_zone.route53_zone.zone_id
  cert_domain                = var.api_gateway_cert_domain
  stage_name                 = var.api_gateway_stage_name
  api_gateway_id             = module.api_gateway.api_gateway.id
  api_gateway_domain_name    = local.api_gateway_domain_name
  api_cloudfront_domain_name = module.cloudfront.api_cloudfront_domain_name
  api_cloudfront_zone_id     = module.cloudfront.api_cloudfront_zone_id
  depends_on                 = [ module.appsync ]
}

module "cloudfront" {
  providers = {
    aws.alternate = aws.us-east-1
  }
  source                  = "./modules/cloudfront"
  name_prefix             = local.name_prefix
  api_gateway_domain_name = module.api_gateway.api_gateway_domain
  cert_arn                = aws_acm_certificate.cert.arn
  cert_alias              = var.env == "prod" || var.env == "prodapjc" || var.env == "prodeu" ? var.api_gateway_cert_domain : "${local.name_prefix}.${var.api_gateway_cert_domain}"
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
