data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_resource" "webhooks" {
  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = "webhooks"
}

resource "aws_iam_role" "data_sharing" {
  name = "${var.name_prefix}-data-sharing"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "data_sharing" {
  name = "${var.name_prefix}-data-sharing"
  role = aws_iam_role.data_sharing.id
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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          var.tenants_table_arn,
          "${var.tenants_table_arn}/index/*",
          var.tenant_config_table_arn,
          "${var.tenant_config_table_arn}/index/*",
          var.webhook_registration_table_arn,
          "${var.webhook_registration_table_arn}/index/*",
          var.webhook_notification_table_arn,
          var.os_versions_table_arn,
          var.groups_table_arn,
          "${var.groups_table_arn}/index/*",
          var.policy_table_arn,
          "${var.policy_table_arn}/index/*",
          var.label_metadata_arn,
          var.neptune_shard_table_arn,
          var.scheduled_task_metadata_table_arn,
          "${var.scheduled_task_metadata_table_arn}/index/*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
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
          "events:PutEvents"
        ],
        "Resource" : [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
    ]
  })
}

module "webhook_apis" {
  for_each               = var.webhooks_apis
  depends_on             = [aws_api_gateway_resource.webhooks]
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.data_sharing.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/data-sharing.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 20
  env                    = var.env
  memory_size            = 128
  lambda_environment = {
    ENV                    = var.env
    IROH_URI               = var.iroh_uri
    IROH_REDIRECT_URI      = var.iroh_redirect_uri
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
  }
}

module "webhook_apis_gw" {
  for_each                           = var.webhooks_apis
  depends_on                         = [aws_api_gateway_resource.webhooks]
  source                             = "../lambda-gateway"
  rest_api_id                        = var.api_gateway.id
  rest_api_parent_path               = each.value.parent_path
  should_create_api_gateway_resource = each.value.should_create_api_gateway_resource
  full_function_name                 = module.webhook_apis[each.key].full_function_name
  lambda_invoke_arn                  = module.webhook_apis[each.key].lambda_invoke_arn
  name_prefix                        = var.name_prefix
  path_part                          = each.value.path
  http_method                        = each.value.http_method
  response_format                    = "json"
  authorization_type                 = "CUSTOM"
  authorizer_id                      = var.authorizer_id
  request_validator_id               = var.api_gateway_request_validator_id
  request_parameters                 = lookup(each.value, "request_parameters", {})
  integration_request_parameters     = lookup(each.value, "integration_request_parameters", {})
}

module "dispatch_webhook_notification" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "ds-dispatch-webhook-notification"
  iam_role_arn           = aws_iam_role.data_sharing.arn
  handler                = "src/data-sharing.dispatchWebhookNotification"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/data-sharing.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 900
  env                    = var.env
  memory_size            = 256
  lambda_environment = {
    ENV                      = var.env
    IROH_URI                 = var.iroh_uri
    IROH_REDIRECT_URI        = var.iroh_redirect_uri
    NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
  }
}

resource "aws_cloudwatch_event_rule" "dispatch_webhook_notification" {
  event_bus_name = var.device_change_notification_event_bus_arn
  name           = "${var.name_prefix}-dispatch-webhook-notification"
  description    = "dispatch webhook notification"
  event_pattern = jsonencode({
    "source" : ["${var.name_prefix}-ds-webhook-event"],
    "detail" : {
      "targetTask" : ["dispatch-webhook-notification"]
    }
  })
}

resource "aws_lambda_permission" "dispatch_webhook_notification" {
  statement_id  = "${var.name_prefix}-allow-execution-from-event-bridge-rule"
  action        = "lambda:InvokeFunction"
  function_name = module.dispatch_webhook_notification.full_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dispatch_webhook_notification.arn
}

resource "aws_cloudwatch_event_target" "dispatch_webhook_notification" {
  rule           = aws_cloudwatch_event_rule.dispatch_webhook_notification.name
  event_bus_name = var.device_change_notification_event_bus_arn
  arn            = module.dispatch_webhook_notification.lambda_arn
}
