data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "system" {
  name = "${var.name_prefix}-system"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "system" {
  name = "${var.name_prefix}-producers"
  role = aws_iam_role.system.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "cloudwatch:GetMetricStatistics"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DeleteSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          "${var.tenants_config_table_arn}",
          "${var.tenants_config_table_arn}/index/*",
          "${var.tenants_table_arn}",
          "${var.tenants_table_arn}/index/*",
          "${var.scheduled_task_arn}",
          "${var.scheduled_task_arn}/index/*",
          "${var.scheduled_task_metadata_arn}",
          "${var.scheduled_task_metadata_arn}/index/*",
          "${var.neptune_shard_table_arn}",
          "${var.rule_arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "neptune-db:*"
        ],
        "Resource" : [
          for res_id in var.neptune_cluster_resource_ids : "arn:aws:neptune-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${res_id}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "timestream:*"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "SNS:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
        ],
        "Resource" : [
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}

module "system_lambda" {
  for_each               = var.system_config
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda.type
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.system.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 50
  lambda_environment = merge(
    lookup(each.value.lambda, "access_neptune", false) ? { NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings } : {},
    lookup(each.value.lambda, "access_elastic_search", false) ? { EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn } : {},
    {
      ENV = var.env
  })
}

module "system_lambda_development" {
  for_each               = var.should_create_development_api_gateway_endpoints ? tomap(var.system_config_development) : tomap({})
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda.type
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.system.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 50
  lambda_environment = merge(
    lookup(each.value.lambda, "access_neptune", false) ? { NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings } : {},
    lookup(each.value.lambda, "access_elastic_search", false) ? { EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn } : {},
    {
      ENV = var.env
  })
}

resource "aws_api_gateway_resource" "system" {
  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = "system"
}

resource "aws_api_gateway_resource" "system_tenant" {
  rest_api_id = var.api_gateway.id
  parent_id   = aws_api_gateway_resource.system.id
  path_part   = "tenant"
}

module "system_gw" {
  depends_on                         = [aws_api_gateway_resource.system]
  for_each                           = var.system_config
  source                             = "../lambda-gateway"
  rest_api_id                        = var.api_gateway.id
  rest_api_parent_path               = aws_api_gateway_resource.system_tenant.path
  should_create_api_gateway_resource = each.value.api_gateway.should_create_api_gateway_resource
  full_function_name                 = module.system_lambda[each.key].full_function_name
  lambda_invoke_arn                  = module.system_lambda[each.key].lambda_invoke_arn
  name_prefix                        = var.name_prefix
  path_part                          = each.value.api_gateway.path
  http_method                        = each.value.api_gateway.http_methods
  response_format                    = each.value.api_gateway.response_format
  authorizer_id                      = var.authorizers["api"].authorizer_id
  integration_request_parameters = {
    "integration.request.header.id"          = "context.authorizer.id"
    "integration.request.header.tenantUid"   = "context.authorizer.tenantUid"
    "integration.request.header.tenantExtId" = "context.authorizer.tenantExtId"
    "integration.request.header.role"        = "context.authorizer.role"
  }
  authorization_type = each.value.api_gateway.authorization_type
}

module "system_gw_development" {
  depends_on                         = [aws_api_gateway_resource.system]
  for_each                           = var.should_create_development_api_gateway_endpoints ? tomap(var.system_config_development) : tomap({})
  source                             = "../lambda-gateway"
  rest_api_id                        = var.api_gateway.id
  rest_api_parent_path               = aws_api_gateway_resource.system_tenant.path
  should_create_api_gateway_resource = each.value.api_gateway.should_create_api_gateway_resource
  full_function_name                 = module.system_lambda_development[each.key].full_function_name
  lambda_invoke_arn                  = module.system_lambda_development[each.key].lambda_invoke_arn
  name_prefix                        = var.name_prefix
  path_part                          = each.value.api_gateway.path
  http_method                        = each.value.api_gateway.http_methods
  response_format                    = each.value.api_gateway.response_format
  authorizer_id                      = var.authorizers["api"].authorizer_id
  integration_request_parameters = {
    "integration.request.header.id"          = "context.authorizer.id"
    "integration.request.header.tenantUid"   = "context.authorizer.tenantUid"
    "integration.request.header.tenantExtId" = "context.authorizer.tenantExtId"
    "integration.request.header.role"        = "context.authorizer.role"
  }
  authorization_type = each.value.api_gateway.authorization_type
}

output "lambda_iam_role_arn" {
  value = aws_iam_role.system.arn
}
