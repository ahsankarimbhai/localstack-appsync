data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_resource" "incidents" {
  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = "incidents"
}

resource "aws_iam_role" "incidents" {
  name = "${var.name_prefix}-incident"

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

resource "aws_iam_role_policy" "incidents" {
  name = "${var.name_prefix}-incident"
  role = aws_iam_role.incidents.id
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
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          var.incident_mapping_arn,
          "${var.incident_mapping_arn}/index/*",
          var.tenants_config_table_arn,
          "${var.tenants_config_table_arn}/index/*",
          var.tenants_table_arn,
          "${var.tenants_table_arn}/index/*"
        ]
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
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
        ]
      }
    ]
  })
}

module "incidents_lambda_development" {
  for_each               = var.incident_api
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.incidents.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/incidents.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 20
  env                    = var.env
  memory_size            = 256
  lambda_environment = {
    ENV                                      = var.env
    DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn
    IROH_URI                                 = var.iroh_uri
    IROH_REDIRECT_URI                        = var.iroh_redirect_uri
  }
}

module "incidents_notification_lambda" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "incidents-notification"
  iam_role_arn           = aws_iam_role.incidents.arn
  handler                = "src/incidents.incidentsNotification"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/incidents.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV = var.env
  }
}

module "incidents_gw" {
  for_each             = var.incident_api
  depends_on           = [aws_api_gateway_resource.incidents]
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = each.value.parent_path
  full_function_name   = module.incidents_lambda_development[each.key].full_function_name
  lambda_invoke_arn    = module.incidents_lambda_development[each.key].lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = each.value.path
  http_method          = ["POST"]
  response_format      = "json"
  authorization_type   = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = var.api_gateway_request_validator_id
  cors_disabled        = true
  allow_methods        = "'OPTIONS,POST'"
}

resource "aws_cloudwatch_event_rule" "incidents_notification" {
  event_bus_name = var.device_change_notification_event_bus_arn
  name           = "${var.name_prefix}-incidents-notification"
  description    = "trigger incidents-notification"
  event_pattern = jsonencode({
    "source" : ["${var.name_prefix}-incidents-notification"],
    "detail" : {
      "targetTask" : ["incidents-notification"]
    }
  })
}

resource "aws_lambda_permission" "incidents_notification" {
  statement_id  = "${var.name_prefix}-allow-execution-from-event-bridge-rule"
  action        = "lambda:InvokeFunction"
  function_name = module.incidents_notification_lambda.full_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.incidents_notification.arn
}

resource "aws_cloudwatch_event_target" "incidents_notification" {
  rule           = aws_cloudwatch_event_rule.incidents_notification.name
  event_bus_name = var.device_change_notification_event_bus_arn
  arn            = module.incidents_notification_lambda.lambda_arn
}
