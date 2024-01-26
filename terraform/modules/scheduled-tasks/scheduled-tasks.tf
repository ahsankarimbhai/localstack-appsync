data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "scheduled_tasks" {
  name = "${var.name_prefix}-scheduled-tasks"

  assume_role_policy = jsonencode({
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
          "Service" : "events.amazonaws.com"
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
  })
}

resource "aws_iam_role_policy" "scheduled_tasks" {
  name = "${var.name_prefix}-scheduled-tasks"
  role = aws_iam_role.scheduled_tasks.id
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
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          var.tenants_table_arn,
          var.tenants_config_table_arn,
          var.groups_table_arn,
          "${var.groups_table_arn}/index/*",
          var.policy_table_arn,
          "${var.policy_table_arn}/index/*",
          var.os_versions_table_arn,
          "${var.tenants_config_table_arn}/index/*",
          var.function_state_table_arn,
          var.scheduled_task_table_arn,
          "${var.scheduled_task_table_arn}/index/*",
          var.scheduled_task_metadata_table_arn,
          "${var.scheduled_task_metadata_table_arn}/index/*",
          var.data_migration_task_metadata_table_arn,
          var.data_migration_task_table_arn,
          var.label_metadata_arn,
          var.neptune_shard_table_arn,
          var.rules_table_arn,
          "${var.rules_table_arn}/index/*",
          var.incident_mapping_arn,
          "${var.incident_mapping_arn}/index/*",
          var.webhook_registration_table_arn,
          "${var.webhook_registration_table_arn}/index/*",
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
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DeleteSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
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
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kinesis:PutRecords"
        ],
        "Resource" : [
          "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.timestream_kinesis_stream.name}",
          "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.vulnerability_processing_kinesis_stream.name}",
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

module "scheduled_tasks" {
  for_each               = var.scheduled_tasks
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda.type
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/${each.value.lambda.file_path}"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = each.key == "syncIrohModuleInstances" ? var.lambda_iroh_sync_producers_reserved_concurrency : (var.should_throttle_vulnerability_lambda && lookup(each.value.lambda, "is_vulnerability_throttled", false)) ? 0 : -1
  publish                = each.key == "syncIrohModuleInstances" && var.lambda_iroh_sync_producers_provisioned_concurrency > 0
  env                    = var.env
  memory_size            = lookup(each.value.lambda, "memory_size", 128)
  lambda_timeout         = 900
  lambda_environment = merge(
    lookup(each.value.lambda, "use_notification_event_bus", false) ? { SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn } : {},
    lookup(each.value.lambda, "use_amp_sns_topic_arn", false) ? { AMP_SNS_TOPIC_ARN = var.amp_sns_topic_arn } : {},
    lookup(each.value.lambda, "use_jamf_sns_topic_arn", false) ? { JAMF_SNS_TOPIC_ARN = var.jamf_sns_topic_arn } : {},
    lookup(each.value.lambda, "use_unifiedConnector_sns_topic_arn", false) ? { UNIFIEDCONNECTOR_SNS_TOPIC_ARN = var.unifiedConnector_sns_topic_arn } : {},
    lookup(each.value.lambda, "use_iroh_url", false) ? { IROH_URI = var.iroh_uri, IROH_REDIRECT_URI = var.iroh_redirect_uri } : {},
    lookup(each.value.lambda, "use_orbital_url", false) ? { ORBITAL_BASE_URL = var.orbital_base_url } : {},
    lookup(each.value.lambda, "use_ms_graph_url", false) ? { MS_GRAPH_URL = var.ms_graph_url } : {},
    lookup(each.value.lambda, "use_producer_notification_url", false) ? {
      GW_API_PRODUCER_NOTIFICATION_URL = var.producer_notification_url,
      ORBITAL_WEBHOOK_S3_BUCKET        = var.orbital_webhook_notification_s3_bucket
    } : {},
    lookup(each.value.lambda, "access_neptune", false) ? { NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings } : {},
    lookup(each.value.lambda, "access_elastic_search", false) ? { EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn } : {},
    lookup(each.value.lambda, "rules_changes_handling_internal_concurrency", false) ? { RULES_EVENTS_HANDLING_CONCURRENCY = var.lambda_rules_changes_handling_internal_concurrency } : {},
    lookup(each.value.lambda, "allowed_concurrent_migration_tasks", false) ? { MAX_ALLOWED_CONCURRENT_MIGRATION_TASKS = var.max_allowed_concurrent_migration_tasks } : {},
    lookup(each.value.lambda, "with_source_options", false) ? { SOURCE_OPTIONS = var.update_webhook_source_options } : {},
    lookup(each.value.lambda, "use_device_change_notification_event_bus", false) ? { DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn } : {},
    lookup(each.value.lambda, "use_delay", false) ? { DELAY_IN_MILLIS = var.delay_in_millis } : {},
    lookup(each.value.lambda, "trigger_state_machine_execution", false) ? { STATE_MACHINE_ARN_PREFIX = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:" } : {},
    {
      ENV               = var.env
      IROH_URI          = var.iroh_uri
      IROH_REDIRECT_URI = var.iroh_redirect_uri
      RULES_ENABLED     = var.rules_enabled
  })
}

resource "aws_lambda_function_event_invoke_config" "rules-clean-discrepancies" {
  function_name = module.scheduled_tasks["rulesCleanDiscrepancies"].full_function_name
  destination_config {
    on_failure {
      destination = var.rules_clean_discrepancies_failure_handler_arn
    }
  }
  depends_on = [var.rules_clean_discrepancies_failure_handler_arn]
}

resource "aws_lambda_alias" "iroh_sync_producers" {
  count            = var.lambda_iroh_sync_producers_provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.scheduled_tasks["syncIrohModuleInstances"].full_function_name
  function_version = module.scheduled_tasks["syncIrohModuleInstances"].function_version
}

resource "aws_lambda_provisioned_concurrency_config" "iroh_sync_producers" {
  count                             = var.lambda_iroh_sync_producers_provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.scheduled_tasks["syncIrohModuleInstances"].full_function_name
  provisioned_concurrent_executions = var.lambda_iroh_sync_producers_provisioned_concurrency
  qualifier                         = aws_lambda_alias.iroh_sync_producers[0].name
}

resource "aws_cloudwatch_event_rule" "scheduled_tasks" {
  for_each       = var.scheduled_tasks
  event_bus_name = var.aws_event_bus_scheduled_tasks_arn
  name           = "${var.name_prefix}-${each.value.event_bridge_rule}"
  description    = "schedule task ${each.value.event_bridge_rule}"
  event_pattern  = <<EOF
{
  "source": ["${var.name_prefix}-scheduled_task_runner"],
  "detail": {
    "targetTask": ["${each.value.lambda.name}"]
  }
}
EOF
}

locals {
  non_scalable_tasks = {
    for name, task in var.scheduled_tasks : name => task
    if !lookup(task, "is_scalable", false)
  }
  scalable_tasks = {    
    for name, task in var.scheduled_tasks : name => task
    if lookup(task, "is_scalable", false)
  }
}

resource "aws_lambda_permission" "non_scalable_tasks" {
  for_each      = local.non_scalable_tasks
  statement_id  = "${var.name_prefix}-allow-execution-from-event-bridge-rule"
  action        = "lambda:InvokeFunction"
  function_name = module.scheduled_tasks[each.key].full_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_tasks[each.key].arn
  qualifier     = each.key == "syncIrohModuleInstances" && var.lambda_iroh_sync_producers_provisioned_concurrency > 0 ? aws_lambda_alias.iroh_sync_producers[0].name : null
}

resource "aws_cloudwatch_event_target" "non_scalable_tasks" {
  for_each       = local.non_scalable_tasks
  rule           = aws_cloudwatch_event_rule.scheduled_tasks[each.key].name
  event_bus_name = var.aws_event_bus_scheduled_tasks_arn
  arn            = each.key == "syncIrohModuleInstances" && var.lambda_iroh_sync_producers_provisioned_concurrency > 0 ? aws_lambda_alias.iroh_sync_producers[0].arn : module.scheduled_tasks[each.key].lambda_arn
}

resource "aws_cloudwatch_event_target" "scalable_tasks" {
  for_each       = local.scalable_tasks
  rule           = aws_cloudwatch_event_rule.scheduled_tasks[each.key].name
  event_bus_name = var.aws_event_bus_scheduled_tasks_arn
  arn            = aws_sfn_state_machine.scalable_tasks[each.key].arn
  role_arn       = aws_iam_role.scheduled_tasks.arn
}

resource "aws_sqs_queue" "scalable_tasks" {
  for_each                    = local.scalable_tasks
  name                        = "${var.name_prefix}-${each.value.lambda.name}.fifo"
  fifo_queue                  = true
  visibility_timeout_seconds  = 60
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  content_based_deduplication = true
}

resource "aws_sfn_state_machine" "scalable_tasks" {
  for_each = local.scalable_tasks
  name     = "${module.scheduled_tasks[each.key].full_function_name}-sm"
  role_arn = aws_iam_role.scheduled_tasks.arn
  definition = jsonencode({
    "Comment" : replace(each.value.lambda.name, "-", " "),
    "StartAt" : "${module.scheduled_tasks[each.key].full_function_name}-lambda",
    "States" : {
      "${module.scheduled_tasks[each.key].full_function_name}-lambda" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::lambda:invoke",
        "OutputPath" : "$.Payload",
        "Parameters" : {
          "Payload.$" : "$",
          "FunctionName" : module.scheduled_tasks[each.key].lambda_arn
        },
        "Next" : "if-ended",
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
      "if-ended" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.isEnded",
            "BooleanEquals" : false,
            "Next" : "${module.scheduled_tasks[each.key].full_function_name}-lambda"
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

module "trigger_scheduled_tasks" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "trigger-scheduled-tasks"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.triggerScheduledTasks"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 570
  memory_size            = 200
  lambda_environment = {
    ENV                    = var.env
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
  }
}

module "schedule_trigger_scheduled_tasks" {
  count  = var.should_create_trigger_scheduled_tasks_schedule ? 1 : 0
  source = "../cloudwatch-rule"
  lambdas = [
    {
      lambda_arn : module.trigger_scheduled_tasks.lambda_arn
      function_name : module.trigger_scheduled_tasks.full_function_name
      event_input : ""
    }
  ]
  schedule_expression = "rate(10 minutes)"
  rule_base_name      = module.trigger_scheduled_tasks.full_function_name
}

module "task_dispatchers" {
  for_each               = local.scalable_tasks
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "${each.value.lambda.name}-dispatcher"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.distributeScalableTasks"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  concurrent_executions  = 1
  lambda_timeout         = 110
  lambda_environment = {
    ENV                    = var.env
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
    TASK_NAME              = each.value.lambda.name
    TASK_QUEUE_URL         = aws_sqs_queue.scalable_tasks[each.key].url
    TASK_STATE_MACHINE_ARN = aws_sfn_state_machine.scalable_tasks[each.key].arn
  }
}

module "schedule_task_dispatchers" {
  source = "../cloudwatch-rule"
  lambdas = [
    for key in keys(module.task_dispatchers) :
    {
      lambda_arn : module.task_dispatchers[key].lambda_arn
      function_name : module.task_dispatchers[key].full_function_name
      event_input : ""
    }
  ]
  schedule_expression    = "rate(2 minutes)"
  rule_base_name         = "${var.name_prefix}-task-dispatchers"
  enable_cloudwatch_rule = var.should_create_trigger_scheduled_tasks_schedule
}

module "schedule_missing_tasks" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "schedule-missing-tasks"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.scheduleMissingTasks"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV                    = var.env
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
  }
}

module "schedule_schedule_missing_tasks" {
  count  = var.should_create_trigger_scheduled_tasks_schedule ? 1 : 0
  source = "../cloudwatch-rule"
  lambdas = [
    {
      lambda_arn : module.schedule_missing_tasks.lambda_arn
      function_name : module.schedule_missing_tasks.full_function_name
      event_input : ""
    }
  ]
  schedule_expression = "rate(1 hour)"
  rule_base_name      = module.schedule_missing_tasks.full_function_name
}

module "perform_regular_monitoring" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "perform-regular-monitoring"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.performRegularMonitoring"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV                    = var.env
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
  }
}

module "schedule_perform_regular_monitoring" {
  source = "../cloudwatch-rule"
  lambdas = [
    {
      lambda_arn : module.perform_regular_monitoring.lambda_arn
      function_name : module.perform_regular_monitoring.full_function_name
      event_input : ""
    }
  ]
  schedule_expression = "rate(1 hour)"
  rule_base_name      = module.perform_regular_monitoring.full_function_name
}

module "save_scheduled_task" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "save-scheduled-task"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.saveScheduledTask"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 90
  lambda_environment = {
    ENV = var.env
  }
}

module "delete_scheduled_task" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "delete-scheduled-task"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/scheduled-tasks.deleteScheduledTask"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 90
  lambda_environment = {
    ENV = var.env
  }
}

module "trigger_live_device_details" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "trigger-live-device-details"
  iam_role_arn           = aws_iam_role.scheduled_tasks.arn
  handler                = "src/index.triggerLiveDeviceDetails"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_environment = {
    ENV                    = var.env
    SCHEDULED_EVENTBUS_ARN = var.aws_event_bus_scheduled_tasks_arn
  }
}

resource "aws_appsync_datasource" "trigger_live_device_details" {
  api_id           = var.graphql_api_id
  name             = "triggerLiveDeviceDetails"
  service_role_arn = var.appsync_iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.trigger_live_device_details.lambda_arn
  }
}

resource "aws_appsync_resolver" "trigger_live_device_details" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "triggerLiveDeviceDetails"
  data_source = aws_appsync_datasource.trigger_live_device_details.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}
