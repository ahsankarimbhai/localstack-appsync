data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rules" {
  name = "${var.name_prefix}-rules"

  assume_role_policy = jsonencode(
    {
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

resource "aws_iam_role_policy" "rules" {
  name = "${var.name_prefix}-rules"
  role = aws_iam_role.rules.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "secretsmanager:GetSecretValue"
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
            "dynamodb:Scan",
            "dynamodb:UpdateItem",
            "dynamodb:BatchWriteItem"
          ],
          "Resource" : [
            "${var.rules_table_arn}",
            "${var.rules_table_arn}/index/*",
            "${var.os_versions_table_arn}",
            "${var.tenants_config_table_arn}",
            "${var.tenants_config_table_arn}/index/*",
            "${var.tenants_table_arn}",
            "${var.tenants_table_arn}/index/*",
            "${var.webhook_registration_table_arn}",
            "${var.webhook_registration_table_arn}/index/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary",
            "kinesis:PutRecords",
            "kinesis:PutRecord",
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:ListShards",
            "kinesis:ListStreams",
            "kinesis:SubscribeToShard"
          ],
          "Resource" : [
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.timestream_kinesis_stream.name}",
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.rules_execution_kinesis_stream.name}"
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
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
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
        }
      ]
  })
}

module "rules_execution" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "rules_execution"
  iam_role_arn           = aws_iam_role.rules.arn
  handler                = "src/rules.kinesisEventsHandling"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/rules.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  concurrent_executions  = var.lambda_rules_execution_reserved_concurrency
  publish                = var.lambda_rules_execution_provisioned_concurrency > 0
  lambda_environment = {
    ENV                                      = var.env
    INTERNAL_CONCURRENCY                     = var.rules_execution_internal_concurrency
    DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn
  }
}

resource "aws_lambda_alias" "rules_execution" {
  count            = var.lambda_rules_execution_provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.rules_execution.full_function_name
  function_version = module.rules_execution.function_version
}

resource "aws_lambda_provisioned_concurrency_config" "rules_execution" {
  count                             = var.lambda_rules_execution_provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.rules_execution.full_function_name
  provisioned_concurrent_executions = var.lambda_rules_execution_provisioned_concurrency
  qualifier                         = aws_lambda_alias.rules_execution[0].name
}

resource "aws_lambda_event_source_mapping" "rules_execution" {
  event_source_arn                   = var.rules_execution_kinesis_stream.arn
  function_name                      = var.lambda_rules_execution_provisioned_concurrency > 0 ? aws_lambda_alias.rules_execution[0].arn : module.rules_execution.lambda_arn
  batch_size                         = 1000
  maximum_batching_window_in_seconds = var.rules_execution_maximum_batching_window_in_seconds
  starting_position                  = "TRIM_HORIZON"
  parallelization_factor             = var.parallelization_factor
  maximum_retry_attempts             = 3
}

output "lambda_iam_role_arn" {
  value = aws_iam_role.rules.arn
}

resource "aws_cloudwatch_event_rule" "rules_devices_filtered_modifications" {
  event_bus_name = var.event_bridge_bus_arn
  name           = "${var.name_prefix}-rules-devices-filtered-modifications"
  description    = "publish and trigger rules-devices-filtered-modifications handling"
  event_pattern  = <<EOF
{
  "source": ["${var.name_prefix}-rules-devices-filtered-modifications"],
  "detail": {
    "targetTask": ["rules-devices-filtered-modifications"]
  }
}
EOF
}

module "rules_devices_filtered_modifications" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "rules-devices-filtered-modifications"
  iam_role_arn           = aws_iam_role.rules.arn
  handler                = "src/rules.rulesDevicesFilteredModificationsHandling"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/rules.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV                  = var.env
    EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn
    DELAY_IN_MILLIS      = var.delay_in_millis
  }
}

resource "aws_lambda_permission" "rules_devices_filtered_modifications" {
  statement_id  = "${var.name_prefix}-allow-execution-from-event-bridge-rule"
  action        = "lambda:InvokeFunction"
  function_name = module.rules_devices_filtered_modifications.full_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rules_devices_filtered_modifications.arn
}

resource "aws_cloudwatch_event_target" "rules_devices_filtered_modifications" {
  rule           = aws_cloudwatch_event_rule.rules_devices_filtered_modifications.name
  event_bus_name = var.event_bridge_bus_arn
  arn            = module.rules_devices_filtered_modifications.lambda_arn
}

module "create_system_rules" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "create-system-rules"
  iam_role_arn           = aws_iam_role.rules.arn
  handler                = "src/rules.createSystemRules"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/rules.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV = var.env
  }
}

module "delete_system_rules" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "delete-system-rules"
  iam_role_arn           = aws_iam_role.rules.arn
  handler                = "src/rules.deleteSystemRules"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/rules.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV = var.env
  }
}

module "rules_clean_discrepancies_failure_handler" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "rules-clean-discrepancies-failure-handler"
  iam_role_arn           = aws_iam_role.rules.arn
  handler                = "src/rules.rulesCleanDiscrepanciesHandleOnFailure"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/rules.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 128
  lambda_environment = {
    ENV = var.env
  }
}

output "rules_clean_discrepancies_failure_handler_arn" {
  value = module.rules_clean_discrepancies_failure_handler.lambda_arn
}

