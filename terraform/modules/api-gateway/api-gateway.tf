data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.name_prefix
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_usage_plan" "graphql_usage_plan" {
  name = "${var.name_prefix}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = "default"
  }

  throttle_settings {
    burst_limit = 1000
    rate_limit  = 500
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "api"
}

module "cors" {
  source        = "../cors"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api.id
  allow_methods = "'OPTIONS,POST'"
  allow_headers = "'Content-Type,x-amz-user-agent,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,posaas-tenant-uid,access-control-allow-origin'"
}

resource "aws_api_gateway_request_validator" "api_gateway" {
  name                        = "${var.name_prefix}-api-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api_gateway.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_gateway_response" "api_gateway_gateway_response" {
  for_each = toset([
    "DEFAULT_4XX",
    "DEFAULT_5XX"
  ])
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  response_type = each.value

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

output "api_gateway" {
  value = aws_api_gateway_rest_api.api_gateway
}

output "api_gateway_api_resource_id" {
  value = aws_api_gateway_resource.api.id
}

output "request_validator_id" {
  value = aws_api_gateway_request_validator.api_gateway.id
}

output "api_gateway_execution_arn" {
  value = aws_api_gateway_rest_api.api_gateway.execution_arn
}

output "api_gateway_domain" {
  value = "${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}