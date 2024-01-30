data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  appsync_name                         = "${var.name_prefix}-appsync"
  appsync_api_gateway_name             = "${var.name_prefix}-appsync-api-gateway"
  graphql_schema                       = "${path.module}/../../templates/schema.graphql"
  block_introspection_queries_template = <<EOF
      #set($inputRoot = $input.json('$'))
      #set($isIntrospection = $inputRoot.toString().matches(".*__schema.*") || $inputRoot.toString().matches(".*introspectionQuery.*"))
      #if($isIntrospection)
        #set($context.responseOverride.status = 403)
        {
          "message": "Error: Introspection queries are not allowed"
        }
      #else
        $inputRoot
      #end
   EOF
  default_template                     = "$input.json('$')"
}

resource "aws_iam_role" "appsync" {
  name = local.appsync_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "appsync" {
  name   = local.appsync_name
  role   = aws_iam_role.appsync.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "lambda:InvokeFunction",
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  ]
}
EOF
}

data "template_file" "graphql_schema" {
  template = file(local.graphql_schema)
}

resource "aws_appsync_graphql_api" "graphql_api" {
  name                = var.name_prefix
  authentication_type = "AWS_IAM"
  schema              = data.template_file.graphql_schema.rendered
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
    field_log_level          = "NONE"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.graphql_api.id}"
  retention_in_days = 30
}

resource "aws_api_gateway_method" "appsync_api_gateway_post" {
  rest_api_id          = var.api_gateway.id
  resource_id          = var.api_gateway_api_resource_id
  http_method          = "POST"
  authorization        = "CUSTOM"
  authorizer_id        = var.api_authorizer_id
  request_validator_id = var.api_gateway_request_validator_id
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_iam_role" "api_gateway" {
  name = local.appsync_api_gateway_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api_gateway" {
  name   = local.appsync_api_gateway_name
  role   = aws_iam_role.api_gateway.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "appsync:GraphQL",
            "Resource": "${aws_appsync_graphql_api.graphql_api.arn}/*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_integration" "appsync_api_gateway_post" {
  rest_api_id             = var.api_gateway.id
  resource_id             = var.api_gateway_api_resource_id
  http_method             = aws_api_gateway_method.appsync_api_gateway_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:${split("/", aws_appsync_graphql_api.graphql_api.uris["GRAPHQL"])[4]}.appsync-api:path/graphql"
  # change to following uri when running against real AWS
  # # uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:${replace(split(".", aws_appsync_graphql_api.graphql_api.uris["GRAPHQL"])[0], "https://", "")}.appsync-api:path/graphql"
  credentials             = aws_iam_role.api_gateway.arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  request_parameters = {
    "integration.request.header.id"          = "context.authorizer.id"
    "integration.request.header.tenantUid"   = "context.authorizer.tenantUid"
    "integration.request.header.tenantName"  = "context.authorizer.tenantName"
    "integration.request.header.role"        = "context.authorizer.role"
    "integration.request.header.irohToken"   = "context.authorizer.irohToken"
    "integration.request.header.tenantExtId" = "context.authorizer.tenantExtId"
    "integration.request.header.httpMethod"  = "context.httpMethod"
    "integration.request.header.path"        = "context.path"
  }
  request_templates = {
    "application/json" = var.block_introspection_queries ? local.block_introspection_queries_template : local.default_template
  }
}

resource "aws_api_gateway_method_response" "appsync_api_gateway_post" {
  rest_api_id = var.api_gateway.id
  resource_id = var.api_gateway_api_resource_id
  http_method = aws_api_gateway_method.appsync_api_gateway_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "appsync_api_gateway_post" {
  depends_on = [aws_api_gateway_integration.appsync_api_gateway_post]

  rest_api_id = var.api_gateway.id
  resource_id = var.api_gateway_api_resource_id
  http_method = aws_api_gateway_method.appsync_api_gateway_post.http_method
  status_code = "200"
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

output "graphql_api_id" {
  value = aws_appsync_graphql_api.graphql_api.id
}

output "iam_role_arn" {
  value = aws_iam_role.appsync.arn
}

output "graphql_uri" {
  value = aws_appsync_graphql_api.graphql_api.uris["GRAPHQL"]
}

output "api_gateway_iam_role_arn" {
  value = aws_iam_role.api_gateway.arn
}

