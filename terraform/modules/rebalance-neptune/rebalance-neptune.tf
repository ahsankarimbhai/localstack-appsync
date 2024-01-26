data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rebalance_neptune" {
  name = "${var.name_prefix}-rebalance-neptune"

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

resource "aws_iam_role_policy" "rebalance_neptune" {
  name = "${var.name_prefix}-rebalance-neptune"
  role = aws_iam_role.rebalance_neptune.id
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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        "Resource" : [
          var.neptune_shard_table_arn,
          var.neptune_shard_migration_log_table_arn,
          var.neptune_shard_migration_log_detail_table_arn,
          "${var.neptune_shard_migration_log_detail_table_arn}/index/*",
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
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "timestream:Select",
          "timestream:DescribeEndpoints"
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
          "kinesis:PutRecords"
        ],
        "Resource" : [
          "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.timestream_kinesis_stream.name}"
        ]
      }
    ]
  })
}

module "neptune_migration_state_tracker" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "neptune-migration-state-tracker"
  iam_role_arn           = aws_iam_role.rebalance_neptune.arn
  handler                = "src/rebalance-neptune.neptuneMigrationStateTracker"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = 1
  env                    = var.env
  memory_size            = 256
  lambda_timeout         = 900
  lambda_environment = {
    ENV                                       = var.env
    ENABLE_AUTO_THROTTLER                     = var.enable_neptune_rebalance_auto_throttler
    MAX_TENANTS_IN_MIGRATION                  = var.max_tenants_in_migration
    MAX_EXPORT_VERTICES_IN_MIGRATION          = var.max_export_vertices_in_migration
    NEPTUNE_REBALANCE_SETTINGS                = var.neptune_rebalance_settings
    NEPTUNE_EXPORT_STATUS_SERVICE_LAMBDA_NAME = var.neptune_export_status_service_lambda_name
    NEPTUNE_QUERY_TIMEOUT                     = var.neptune_query_timeout
  }
}

module "exporter" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "export-neptune-data"
  iam_role_arn           = aws_iam_role.rebalance_neptune.arn
  handler                = "src/rebalance-neptune.exportNeptuneData"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = 1
  env                    = var.env
  memory_size            = 128
  lambda_timeout         = 900
  lambda_environment = {
    ENV                                        = var.env
    MAX_EXPORT_VERTICES_CHUNK_SIZE             = var.max_export_vertices_chunk_size
    NEPTUNE_REBALANCE_SETTINGS                 = var.neptune_rebalance_settings
    NEPTUNE_EXPORT_SERVICE_LAMBDA_NAME         = var.neptune_export_service_lambda_name
    NEPTUNE_EXPORT_SERVICE_CONCURRENCY_SETTING = jsonencode(var.neptune_export_service_concurrency_setting)
    NEPTUNE_QUERY_TIMEOUT                      = var.neptune_query_timeout
  }
}

module "bulk_loader" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "bulk-load-neptune-data"
  iam_role_arn           = aws_iam_role.rebalance_neptune.arn
  handler                = "src/rebalance-neptune.bulkLoadNeptuneData"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = 2
  env                    = var.env
  memory_size            = 128
  lambda_timeout         = 900
  lambda_environment = {
    ENV                        = var.env
    NEPTUNE_REBALANCE_SETTINGS = var.neptune_rebalance_settings
  }
}

module "schedule_migration_state_tracker" {
  source = "../cloudwatch-rule"
  lambdas = [
    {
      lambda_arn : module.neptune_migration_state_tracker.lambda_arn
      function_name : module.neptune_migration_state_tracker.full_function_name
      event_input : ""
    }
  ]
  schedule_expression    = "rate(15 minutes)"
  enable_cloudwatch_rule = var.enable_neptune_migration_state_tracker
  rule_base_name         = module.neptune_migration_state_tracker.full_function_name
}
