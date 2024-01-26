
resource "aws_api_gateway_method" "lambda_gateway_options" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "lambda_gateway_options" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.lambda_gateway_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "lambda_gateway_options" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.lambda_gateway_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{"statusCode": 200}
EOF
  }
}

resource "aws_api_gateway_integration_response" "lambda_gateway_options" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.lambda_gateway_options.http_method
  status_code = aws_api_gateway_method_response.lambda_gateway_options.status_code
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = var.allow_headers,
    "method.response.header.Access-Control-Allow-Methods" = var.allow_methods,
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Data returned by this module.
output "gw_resources" {
  value = [
    jsonencode(aws_api_gateway_method.lambda_gateway_options),
    jsonencode(aws_api_gateway_method_response.lambda_gateway_options),
    jsonencode(aws_api_gateway_integration.lambda_gateway_options),
    jsonencode(aws_api_gateway_integration_response.lambda_gateway_options)
  ]
}
