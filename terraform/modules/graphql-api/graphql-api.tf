data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  webhook_iam_name = "${var.name_prefix}-webhook"
}

resource "aws_iam_role" "graphql_api" {
  name = "${var.name_prefix}-graphql-api"

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

resource "aws_iam_role_policy" "graphql-api" {
  name = "${var.name_prefix}-graphql-api"
  role = aws_iam_role.graphql_api.id
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
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          var.tenants_config_table_arn,
          "${var.tenants_config_table_arn}/index/*",
          var.tenants_table_arn,
          "${var.tenants_table_arn}/index/*",
          var.groups_table_arn,
          "${var.groups_table_arn}/index/*",
          var.policy_table_arn,
          "${var.policy_table_arn}/index/*",
          var.os_versions_table_arn,
          var.function_state_table_arn,
          var.vulnerability_table_arn,
          var.scheduled_task_arn,
          "${var.scheduled_task_arn}/index/*",
          var.scheduled_task_metadata_arn,
          "${var.scheduled_task_metadata_arn}/index/*",
          var.saved_filter_arn,
          var.label_metadata_arn,
          var.rule_arn,
          var.neptune_shard_table_arn,
          var.incident_mapping_arn,
          "${var.incident_mapping_arn}/index/*",
          var.webhook_registration_table_arn,
          "${var.webhook_registration_table_arn}/index/*",
        ]
      },
      # {
      #   "Effect" : "Allow",
      #   "Action" : [
      #     "neptune-db:*"
      #   ],
      #   "Resource" : [
      #     for res_id in var.neptune_cluster_resource_ids : "arn:aws:neptune-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${res_id}/*"
      #   ]
      # },
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
          "kinesis:PutRecords"
        ],
        "Resource" : [
          "*"
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

module "graphql_api_lambda" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "graphql-api"
  iam_role_arn           = aws_iam_role.graphql_api.arn
  handler                = "src/graphql-index.handler"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/graphql.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = var.graphql_api_lambda_timeout
  env                    = var.env
  memory_size            = 256
  lambda_environment = merge(
    var.use_predefined_neptune_shard_id ? { PREDEFINED_NEPTUNE_SHARD_ID = "1" } : {},
    {
      ENV                                      = var.env
      IROH_URI                                 = var.iroh_uri
      // IROH_REDIRECT_URI                        = var.iroh_redirect_uri
      WEBHOOK_NOTIFICATION_BASE_URL            = var.api_gateway_endpoint
      ORBITAL_BASE_URL                         = var.orbital_base_url
      // GW_API_PRODUCER_NOTIFICATION_URL         = var.producer_notification_url
      // ORBITAL_WEBHOOK_S3_BUCKET                = var.orbital_webhook_notification_s3_bucket
      // SCHEDULED_EVENTBUS_ARN                   = var.aws_event_bus_scheduled_tasks_arn
      METRIC_PERIOD_IN_DAYS                    = var.metric_period_in_days
      // NEPTUNE_CLUSTER_SETTINGS                 = var.neptune_cluster_settings
      // PROCESSING_STREAM_SETTINGS               = var.encoded_processing_stream_settings
      // EVENT_BRIDGE_BUS_ARN                     = var.event_bridge_bus_arn
      RULES_ENABLED                            = var.rules_enabled
      DYNAMODB_REQUEST_TIMEOUT_MILLISECONDS    = var.dynamodb_request_timeout_milliseconds
      // DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn
    }
  )
}

resource "aws_appsync_datasource" "get_posture_device" {
  api_id           = var.graphql_api_id
  name             = "getPostureEndpoint"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_posture_device" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getPostureDevice"
  data_source = aws_appsync_datasource.get_posture_device.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_webhooks_status" {
  api_id           = var.graphql_api_id
  name             = "getWebhooksStatus"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_webhooks_status" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getWebhooksStatus"
  data_source = aws_appsync_datasource.get_webhooks_status.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "dashboard_counts" {
  api_id           = var.graphql_api_id
  name             = "dashboardCounts"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "dashboard_counts" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "dashboardCounts"
  data_source = aws_appsync_datasource.dashboard_counts.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "dashboard_person_counts" {
  api_id           = var.graphql_api_id
  name             = "dashboardPersonCounts"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "dashboard_person_counts" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "dashboardPersonCounts"
  data_source = aws_appsync_datasource.dashboard_person_counts.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "collection_metrics" {
  api_id           = var.graphql_api_id
  name             = "collectionMetrics"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "collection_metrics" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "collectionMetrics"
  data_source = aws_appsync_datasource.collection_metrics.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_user_endpoints" {
  api_id           = var.graphql_api_id
  name             = "getUserEndpoints"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_user_endpoints" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getUserEndpoints"
  data_source = aws_appsync_datasource.get_user_endpoints.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_posture_person" {
  api_id           = var.graphql_api_id
  name             = "getPosturePerson"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_posture_person" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getPosturePerson"
  data_source = aws_appsync_datasource.get_posture_person.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_tenant_deployments" {
  api_id           = var.graphql_api_id
  name             = "getTenantUCDeployments"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_tenant_deployments" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantUCDeployments"
  data_source = aws_appsync_datasource.get_tenant_deployments.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_posture_endpoint_merging_logic" {
  api_id           = var.graphql_api_id
  name             = "getPostureEndpointMergingLogic"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_posture_endpoint_merging_logic" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getPostureEndpointMergingLogic"
  data_source = aws_appsync_datasource.get_posture_endpoint_merging_logic.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "list_posture_endpoints" {
  api_id           = var.graphql_api_id
  name             = "listPostureEndpoints"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "list_posture_endpoints" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "listPostureDevices"
  data_source = aws_appsync_datasource.list_posture_endpoints.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "list_posture_persons" {
  api_id           = var.graphql_api_id
  name             = "listPosturePersons"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "list_posture_persons" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "listPosturePersons"
  data_source = aws_appsync_datasource.list_posture_persons.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "count_posture_endpoints" {
  api_id           = var.graphql_api_id
  name             = "countPostureEndpoints"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "count_posture_endpoints" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "countPostureDevices"
  data_source = aws_appsync_datasource.count_posture_endpoints.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "count_posture_persons" {
  api_id           = var.graphql_api_id
  name             = "countPosturePersons"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "count_posture_persons" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "countPosturePersons"
  data_source = aws_appsync_datasource.count_posture_persons.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_posture_persons_filter_choices" {
  api_id           = var.graphql_api_id
  name             = "getPosturePersonsFilterChoices"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_posture_persons_filter_choices" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getPosturePersonsFilterChoices"
  data_source = aws_appsync_datasource.get_posture_persons_filter_choices.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "list_historical_posture_endpoint_states" {
  api_id           = var.graphql_api_id
  name             = "listPostureEndpointsHistoricalState"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "list_historical_posture_endpoint_states" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "listPostureEndpointsHistoricalState"
  data_source = aws_appsync_datasource.list_historical_posture_endpoint_states.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "list_historical_posture_person_states" {
  api_id           = var.graphql_api_id
  name             = "listPosturePersonsHistoricalState"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "list_historical_posture_person_states" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "listPosturePersonsHistoricalState"
  data_source = aws_appsync_datasource.list_historical_posture_person_states.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_collection_errors" {
  api_id           = var.graphql_api_id
  name             = "getCollectionErrors"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_collection_errors" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getCollectionErrors"
  data_source = aws_appsync_datasource.get_collection_errors.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_tenant_policies" {
  api_id           = var.graphql_api_id
  name             = "getTenantPolicies"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_tenant_policies" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantPolicies"
  data_source = aws_appsync_datasource.get_tenant_policies.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_tenant_groups" {
  api_id           = var.graphql_api_id
  name             = "getTenantGroups"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_tenant_groups" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantGroups"
  data_source = aws_appsync_datasource.get_tenant_groups.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_tenant_tags" {
  api_id           = var.graphql_api_id
  name             = "getTenantTags"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_tenant_tags" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantTags"
  data_source = aws_appsync_datasource.get_tenant_tags.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "export_posture_endpoints_scroll" {
  api_id           = var.graphql_api_id
  name             = "exportPostureEndpointsScroll"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "export_posture_endpoints_scroll" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "exportPostureDevicesScroll"
  data_source = aws_appsync_datasource.export_posture_endpoints_scroll.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "export_posture_persons_scroll" {
  api_id           = var.graphql_api_id
  name             = "exportPosturePersonsScroll"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "export_posture_persons_scroll" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "exportPosturePersonsScroll"
  data_source = aws_appsync_datasource.export_posture_persons_scroll.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "add_filter" {
  api_id           = var.graphql_api_id
  name             = "addFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "add_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "addFilter"
  data_source = aws_appsync_datasource.add_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_filter" {
  api_id           = var.graphql_api_id
  name             = "deleteFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteFilter"
  data_source = aws_appsync_datasource.delete_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_tenant_metadata" {
  api_id           = var.graphql_api_id
  name             = "getTenantMetadata"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_datasource" "enable_sx_organization" {
  api_id           = var.graphql_api_id
  name             = "enableSXOrganization"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_datasource" "get_module_type_id" {
  api_id           = var.graphql_api_id
  name             = "getModuleTypeId"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_datasource" "is_sx_organization_enabled" {
  api_id           = var.graphql_api_id
  name             = "isSXOrganizationEnabled"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_datasource" "get_tenant_setup_status" {
  api_id           = var.graphql_api_id
  name             = "getTenantSetupStatus"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_tenant_metadata" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantMetadata"
  data_source = aws_appsync_datasource.get_tenant_metadata.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_resolver" "enable_sx_organization" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "enableSXOrganization"
  data_source = aws_appsync_datasource.enable_sx_organization.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_resolver" "get_module_type_id" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getModuleTypeId"
  data_source = aws_appsync_datasource.get_module_type_id.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_resolver" "is_sx_organization_enabled" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "isSXOrganizationEnabled"
  data_source = aws_appsync_datasource.is_sx_organization_enabled.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_resolver" "get_tenant_setup_status" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getTenantSetupStatus"
  data_source = aws_appsync_datasource.get_tenant_setup_status.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_producer_configurations" {
  api_id           = var.graphql_api_id
  name             = "getProducerConfigurations"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_producer_configurations" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getProducerConfigurations"
  data_source = aws_appsync_datasource.get_producer_configurations.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "add_producer_configuration" {
  api_id           = var.graphql_api_id
  name             = "addProducerConfiguration"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "add_producer_configuration" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "addProducerConfiguration"
  data_source = aws_appsync_datasource.add_producer_configuration.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "update_producer_configuration" {
  api_id           = var.graphql_api_id
  name             = "updateProducerConfiguration"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "update_producer_configuration" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "updateProducerConfiguration"
  data_source = aws_appsync_datasource.update_producer_configuration.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_json_schemas" {
  api_id           = var.graphql_api_id
  name             = "getJsonSchemas"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_json_schemas" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getJsonSchemas"
  data_source = aws_appsync_datasource.get_json_schemas.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "move_devices_to_deployment" {
  api_id           = var.graphql_api_id
  name             = "moveDevicesToDeployment"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "move_devices_to_deployment" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "moveDevicesToDeployment"
  data_source = aws_appsync_datasource.move_devices_to_deployment.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_labels" {
  api_id           = var.graphql_api_id
  name             = "getLabels"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_labels" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getLabels"
  data_source = aws_appsync_datasource.get_labels.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "create_label" {
  api_id           = var.graphql_api_id
  name             = "createLabel"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "create_label" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "createLabel"
  data_source = aws_appsync_datasource.create_label.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "update_labels" {
  api_id           = var.graphql_api_id
  name             = "updateLabels"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "update_labels" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "updateLabels"
  data_source = aws_appsync_datasource.update_labels.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_labels" {
  api_id           = var.graphql_api_id
  name             = "deleteLabels"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_labels" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteLabels"
  data_source = aws_appsync_datasource.delete_labels.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "add_labels_for_devices" {
  api_id           = var.graphql_api_id
  name             = "addLabelsForDevices"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "add_labels_for_devices" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "addLabelsForDevices"
  data_source = aws_appsync_datasource.add_labels_for_devices.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "remove_labels_for_devices" {
  api_id           = var.graphql_api_id
  name             = "removeLabelsForDevices"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "remove_labels_for_devices" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "removeLabelsForDevices"
  data_source = aws_appsync_datasource.remove_labels_for_devices.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "add_labels_for_a_filter" {
  api_id           = var.graphql_api_id
  name             = "addLabelsForAFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "add_labels_for_a_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "addLabelsForAFilter"
  data_source = aws_appsync_datasource.add_labels_for_a_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "remove_labels_for_a_filter" {
  api_id           = var.graphql_api_id
  name             = "removeLabelsForAFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "remove_labels_for_a_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "removeLabelsForAFilter"
  data_source = aws_appsync_datasource.remove_labels_for_a_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "set_devices_financial_risk_factor" {
  api_id           = var.graphql_api_id
  name             = "setDevicesFinancialRiskFactor"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "set_devices_financial_risk_factor" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "setDevicesFinancialRiskFactor"
  data_source = aws_appsync_datasource.set_devices_financial_risk_factor.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "set_devices_asset_value" {
  api_id           = var.graphql_api_id
  name             = "setDevicesAssetValue"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "set_devices_asset_value" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "setDevicesAssetValue"
  data_source = aws_appsync_datasource.set_devices_asset_value.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_devices_financial_risk_factor" {
  api_id           = var.graphql_api_id
  name             = "deleteDevicesFinancialRiskFactor"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_devices_financial_risk_factor" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteDevicesFinancialRiskFactor"
  data_source = aws_appsync_datasource.delete_devices_financial_risk_factor.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_devices_asset_value" {
  api_id           = var.graphql_api_id
  name             = "deleteDevicesAssetValue"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_devices_asset_value" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteDevicesAssetValue"
  data_source = aws_appsync_datasource.delete_devices_asset_value.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "set_devices_financial_risk_factor_with_filter" {
  api_id           = var.graphql_api_id
  name             = "setDevicesFinancialRiskFactorWithFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "set_devices_financial_risk_factor_with_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "setDevicesFinancialRiskFactorWithFilter"
  data_source = aws_appsync_datasource.set_devices_financial_risk_factor_with_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "set_devices_asset_value_with_filter" {
  api_id           = var.graphql_api_id
  name             = "setDevicesAssetValueWithFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "set_devices_asset_value_with_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "setDevicesAssetValueWithFilter"
  data_source = aws_appsync_datasource.set_devices_asset_value_with_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "remove_devices_financial_risk_factor_with_filter" {
  api_id           = var.graphql_api_id
  name             = "removeDevicesFinancialRiskFactorWithFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "remove_devices_financial_risk_factor_with_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "removeDevicesFinancialRiskFactorWithFilter"
  data_source = aws_appsync_datasource.remove_devices_financial_risk_factor_with_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "remove_devices_asset_value_with_filter" {
  api_id           = var.graphql_api_id
  name             = "removeDevicesAssetValueWithFilter"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "remove_devices_asset_value_with_filter" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "removeDevicesAssetValueWithFilter"
  data_source = aws_appsync_datasource.remove_devices_asset_value_with_filter.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "create_rule" {
  api_id           = var.graphql_api_id
  name             = "createRule"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "create_rule" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "createRule"
  data_source = aws_appsync_datasource.create_rule.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "update_rule" {
  api_id           = var.graphql_api_id
  name             = "updateRule"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "update_rule" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "updateRule"
  data_source = aws_appsync_datasource.update_rule.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "delete_rule" {
  api_id           = var.graphql_api_id
  name             = "deleteRule"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "delete_rule" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "deleteRule"
  data_source = aws_appsync_datasource.delete_rule.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "get_rules" {
  api_id           = var.graphql_api_id
  name             = "getRules"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.graphql_api_lambda.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_rules" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getRules"
  data_source = aws_appsync_datasource.get_rules.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

output "lambda_iam_role_arn" {
  value = aws_iam_role.graphql_api.arn
}
