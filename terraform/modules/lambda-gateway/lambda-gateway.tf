data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_api_gateway_resource" "parent" {
  rest_api_id = var.rest_api_id
  path        = var.rest_api_parent_path
}

resource "aws_api_gateway_resource" "lambda_gateway" {
  count       = var.should_create_api_gateway_resource ? 1 : 0
  rest_api_id = var.rest_api_id
  parent_id   = data.aws_api_gateway_resource.parent.id
  path_part   = var.path_part
}

resource "aws_api_gateway_method" "lambda_gateway" {
  for_each             = toset(var.http_method)
  rest_api_id          = var.rest_api_id
  resource_id          = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].id : data.aws_api_gateway_resource.parent.id
  http_method          = each.key
  authorization        = var.authorization_type
  authorizer_id        = var.authorizer_id
  request_validator_id = var.request_validator_id
  request_parameters = merge(
    {
      "method.request.header.Authorization" = true
    },
    var.request_parameters
  )
}

resource "aws_api_gateway_integration" "lambda_gateway" {
  for_each                = toset(var.http_method)
  rest_api_id             = var.rest_api_id
  resource_id             = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].id : data.aws_api_gateway_resource.parent.id
  http_method             = aws_api_gateway_method.lambda_gateway[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
  request_parameters      = var.integration_request_parameters
}

resource "aws_api_gateway_method_response" "lambda_gateway" {
  for_each    = toset(var.http_method)
  rest_api_id = var.rest_api_id
  resource_id = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].id : data.aws_api_gateway_resource.parent.id
  http_method = aws_api_gateway_method.lambda_gateway[each.key].http_method
  status_code = "200"
  response_models = {
    "application/${var.response_format}" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "lambda_gateway" {
  for_each   = toset(var.http_method)
  depends_on = [aws_api_gateway_integration.lambda_gateway]

  rest_api_id = var.rest_api_id
  resource_id = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].id : data.aws_api_gateway_resource.parent.id
  http_method = aws_api_gateway_method.lambda_gateway[each.key].http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "lambda_gateway" {
  for_each      = toset(var.http_method)
  statement_id  = "${var.full_function_name}-${each.key}-allow-execution-from-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = var.full_function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = var.function_qualifier
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/${aws_api_gateway_method.lambda_gateway[each.key].http_method}${var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].path : data.aws_api_gateway_resource.parent.path}"
}

module "cors" {
  count         = var.cors_disabled ? 1 : 0
  source        = "../cors"
  rest_api_id   = var.rest_api_id
  resource_id   = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].id : data.aws_api_gateway_resource.parent.id
  allow_methods = var.allow_methods
  allow_headers = "'Content-Type,x-amz-user-agent,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,posaas-tenant-uid'"
}

# Data returned by this module.
output "lambda_gw_resources" {
  value = concat(
    [var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].path : ""],
    [for key in var.http_method : aws_api_gateway_method.lambda_gateway[key]],
    [for key in var.http_method : aws_api_gateway_integration.lambda_gateway[key]],
    [for key in var.http_method : aws_api_gateway_method_response.lambda_gateway[key]],
    [for key in var.http_method : aws_api_gateway_integration_response.lambda_gateway[key]],
    [for key in var.http_method : aws_lambda_permission.lambda_gateway[key]],
    var.cors_disabled ? module.cors[0].gw_resources : []
  )
}

output "aws_api_gateway_resource_path" {
  value = var.should_create_api_gateway_resource ? aws_api_gateway_resource.lambda_gateway[0].path : data.aws_api_gateway_resource.parent.path
}
