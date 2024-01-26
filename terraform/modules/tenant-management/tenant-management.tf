data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "tenant_management" {
  name = "${var.name_prefix}-tenant-management"

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

resource "aws_iam_role_policy" "tenant_management" {
  name = "${var.name_prefix}-tenant-management"
  role = aws_iam_role.tenant_management.id
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
          "secretsmanager:CreateSecret",
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
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          var.tenants_table_arn,
          var.tenants_config_table_arn,
          "${var.tenants_config_table_arn}/index/*",
          "${var.tenants_table_arn}/index/*",
          var.scheduled_task_arn,
          "${var.scheduled_task_arn}/index/*",
          var.scheduled_task_metadata_arn,
          var.function_state_table_arn,
          var.groups_table_arn,
          "${var.groups_table_arn}/index/*",
          "${var.scheduled_task_metadata_arn}/index/*",
          var.saved_filter_arn,
          var.neptune_shard_table_arn,
          var.label_metadata_arn,
          var.rule_arn,
          var.policy_table_arn,
          "${var.policy_table_arn}/index/*",
          var.incident_mapping_arn,
          "${var.incident_mapping_arn}/index/*",
          var.webhook_registration_table_arn,
          "${var.webhook_registration_table_arn}/index/*",
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
          "events:PutEvents"
        ],
        "Resource" : [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/*"
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
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kinesis:PutRecords"
        ],
        "Resource" : [
          "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.timestream_kinesis_stream.name}",
          "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.rules_execution_kinesis_stream.name}"
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

module "tenant_function" {
  for_each               = var.tenant_management_functions
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = lookup(each.value, "is_public_lambda", false) ? "public" : "private"
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.tenant_management.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = lookup(each.value, "timeout", 15)
  memory_size            = lookup(each.value, "memorySize", 128)
  lambda_environment = merge(
    lookup(each.value, "use_notification_event_bus", false) ? { SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn } : {},
    lookup(each.value, "use_producer_notification_url", false) ? {
      GW_API_PRODUCER_NOTIFICATION_URL = var.producer_notification_url,
      ORBITAL_WEBHOOK_S3_BUCKET        = var.orbital_webhook_notification_s3_bucket
    } : {},
    lookup(each.value, "use_device_change_notification_event_bus", false) ? { DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn } : {},
    lookup(each.value, "access_neptune", false) ? {
      METRIC_PERIOD_IN_DAYS    = var.metric_period_in_days
      NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
    } : {},
    var.use_predefined_neptune_shard_id ? { PREDEFINED_NEPTUNE_SHARD_ID = "1" } : {},
    lookup(each.value, "access_elastic_search", false) ? { EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn } : {},
    {
      ENV               = var.env
      IROH_URI          = var.iroh_uri
      IROH_REDIRECT_URI = var.iroh_redirect_uri
      RULES_ENABLED     = var.rules_enabled
  })
}

module "tenant_migration" {
  for_each               = var.tenant_migration_functions
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = lookup(each.value, "is_public_lambda", false) ? "public" : "private"
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.tenant_management.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = lookup(each.value, "timeout", 15)
  lambda_environment = {
    ENV           = var.env
    RULES_ENABLED = var.rules_enabled
  }
}

module "es_tenant_data_cleanup_lambda" {
  count = var.allow_es_tenant_data_cleanup ? 1 : 0

  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "delete-all-devices-in-es-for-tenant"
  iam_role_arn           = aws_iam_role.tenant_management.arn
  handler                = "src/tenant-management.deleteAllDevicesInESForTenant"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 60
  env                    = var.env
  lambda_environment = {
    ENV                  = var.env
    EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn
    RULES_ENABLED        = var.rules_enabled
  }
}

module "es_tenant_person_cleanup_lambda" {
  count = var.allow_es_tenant_person_cleanup ? 1 : 0

  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "delete-all-persons-in-es-for-tenant"
  iam_role_arn           = aws_iam_role.tenant_management.arn
  handler                = "src/tenant-management.deleteAllPersonsInESForTenant"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 60
  env                    = var.env
  lambda_environment = {
    ENV = var.env
  }
}

resource "aws_appsync_datasource" "remove_producer_configuration" {
  api_id           = var.graphql_api_id
  name             = "removeProducerConfiguration"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.tenant_function["removeProducerConfiguration"].lambda_arn
  }
}

resource "aws_appsync_resolver" "remove_producer_configuration" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "removeProducerConfiguration"
  data_source = aws_appsync_datasource.remove_producer_configuration.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "register_webhooks" {
  api_id           = var.graphql_api_id
  name             = "registerWebhooks"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.tenant_function["registerWebhooks"].lambda_arn
  }
}

resource "aws_appsync_resolver" "register_webhooks" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "registerWebhooks"
  data_source = aws_appsync_datasource.register_webhooks.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_webhooks" {
  api_id           = var.graphql_api_id
  name             = "deleteWebhooks"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.tenant_function["deleteWebhooks"].lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_webhooks" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteWebhooks"
  data_source = aws_appsync_datasource.delete_webhooks.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}
