data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "migrate_data" {
  name = "${var.name_prefix}-migrate-data"

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
        },
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "states.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "migrate_data" {
  name = "${var.name_prefix}-migrate-data"
  role = aws_iam_role.migrate_data.id
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
          var.tenants_table_arn,
          var.tenants_config_table_arn,
          "${var.tenants_config_table_arn}/index/*",
          var.groups_table_arn,
          "${var.groups_table_arn}/index/*",
          var.policy_table_arn,
          "${var.policy_table_arn}/index/*",
          var.data_migration_task_metadata_table_arn,
          var.scheduled_task_metadata_table_arn,
          var.data_migration_task_table_arn,
          var.scheduled_task_table_arn,
          "${var.scheduled_task_table_arn}/index/*",
          var.os_versions_table_arn,
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
      },
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
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
          "states:ListExecutions",
          "states:StartExecution"
        ],
        "Resource" : [
          "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"
        ]
      }
    ]
  })
}

module "migrate_lambda" {
  for_each               = var.migration_scripts
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda_type
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.migrate_data.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = lookup(each.value, "memory_size", 128)
  concurrent_executions  = lookup(each.value, "allow_concurrency", false) ? -1 : 1
  lambda_environment = merge(
    lookup(each.value, "access_neptune", false) ? {
      NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
    } : {},
    lookup(each.value, "neptune_query_timeout", "") != "" ? {
      NEPTUNE_QUERY_TIMEOUT = each.value.neptune_query_timeout
    } : {},
    lookup(each.value, "use_orbital_webhook_s3_bucket", false) ? {
      ORBITAL_WEBHOOK_S3_BUCKET = var.orbital_webhook_notification_s3_bucket
    } : {},
    {
      ENV               = var.env
      IROH_URI          = var.iroh_uri
      IROH_REDIRECT_URI = var.iroh_redirect_uri
  })
}

resource "aws_sfn_state_machine" "extendable_tasks" {
  for_each = var.migration_scripts
  name     = "${module.migrate_lambda[each.key].full_function_name}-sm"
  role_arn = aws_iam_role.migrate_data.arn
  definition = jsonencode({
    "Comment" : replace(each.value.name, "-", " "),
    "StartAt" : "${module.migrate_lambda[each.key].full_function_name}-lambda",
    "States" : {
      "${module.migrate_lambda[each.key].full_function_name}-lambda" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::lambda:invoke",
        "OutputPath" : "$.Payload",
        "Parameters" : {
          "Payload.$" : "$",
          "FunctionName" : module.migrate_lambda[each.key].lambda_arn
        },
        "Next" : "should-continue",
        "Catch" : [
          {
            "ErrorEquals" : [
              "States.ALL"
            ],
            "Next" : "Fail"
          }
        ]
      },
      "Fail" : {
        "Type" : "Fail"
      },
      "should-continue" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.shouldContinue",
            "BooleanEquals" : true,
            "Next" : "${module.migrate_lambda[each.key].full_function_name}-lambda"
          }
        ],
        "Default" : "Success"
      },
      "Success" : {
        "Type" : "Succeed"
      }
    }
  })
}
