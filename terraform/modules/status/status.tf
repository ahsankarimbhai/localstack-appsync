data "aws_region" "current" {}

module "status" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "status"
  iam_role_arn           = var.lambda_iam_role_arn
  handler                = "src/status.systemStatus"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/status.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 20
  lambda_environment = {
    TEST_SNS_TOPIC_ARN       = var.test_sns_topic_arn
    NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
  }
}

resource "aws_appsync_datasource" "status" {
  api_id           = var.graphql_api_id
  name             = "systemStatus"
  service_role_arn = var.appsync_iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.status.lambda_arn
  }
}

resource "aws_appsync_resolver" "status" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "systemStatus"
  data_source = aws_appsync_datasource.status.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_api_gateway_resource" "status" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_api_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_method" "status" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "GET"
  authorization = "NONE"
}

data "template_file" "status" {
  template = file("${path.module}/templates/status.tpl")
}

resource "aws_api_gateway_integration" "status" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.status.id
  http_method             = aws_api_gateway_method.status.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:${split("/", var.graphql_uri)[4]}.appsync-api:path/graphql"
  credentials             = var.api_gateway_iam_role_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = data.template_file.status.rendered
  }
}

resource "aws_api_gateway_method_response" "status" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "status" {
  depends_on = [aws_api_gateway_integration.status]

  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
