data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  webhook_iam_name = "${var.name_prefix}-webhook"
}

resource "aws_s3_bucket" "producers" {
  bucket = "${var.name_prefix}-producers"

  tags = {
    Name = "${var.name_prefix}-producers"
  }
}

resource "aws_s3_bucket_ownership_controls" "producers" {
  bucket = aws_s3_bucket.producers.bucket
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "producers" {
  bucket = aws_s3_bucket.producers.bucket
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "producers" {
  bucket = aws_s3_bucket.producers.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "producers" {
  bucket = aws_s3_bucket.producers.bucket

  rule {
    id     = "cleanup"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = 60
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "producers" {
  bucket = aws_s3_bucket.producers.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "producers" {
  bucket = aws_s3_bucket.producers.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "producers" {
  name = aws_s3_bucket.producers.bucket

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

resource "aws_iam_role_policy" "producers" {
  name = aws_s3_bucket.producers.bucket
  role = aws_iam_role.producers.id
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
          "secretsmanager:UpdateSecret"
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
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          "${var.tenants_config_table_arn}",
          "${var.tenants_config_table_arn}/index/*",
          "${var.tenants_table_arn}",
          "${var.tenants_table_arn}/index/*",
          "${var.groups_table_arn}",
          "${var.groups_table_arn}/index/*",
          "${var.policy_table_arn}",
          "${var.policy_table_arn}/index/*",
          "${var.os_versions_table_arn}",
          "${var.function_state_table_arn}",
          "${var.vulnerability_table_arn}",
          "${var.scheduled_task_arn}",
          "${var.scheduled_task_arn}/index/*",
          "${var.scheduled_task_metadata_arn}",
          "${var.scheduled_task_metadata_arn}/index/*",
          "${var.saved_filter_arn}",
          "${var.neptune_shard_table_arn}",
          "${var.label_metadata_arn}",
          var.incident_mapping_arn,
          "${var.incident_mapping_arn}/index/*",
          var.webhook_registration_table_arn,
          "${var.webhook_registration_table_arn}/index/*",
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
        "Resource" : concat(
          [
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.preprocessing_kinesis_stream.name}",
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.vulnerability_processing_kinesis_stream.name}",
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.timestream_kinesis_stream.name}",
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.rules_execution_kinesis_stream.name}"
          ],
          [
            for stream in values(var.processing_kinesis_streams) :
            "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${stream.name}"
          ]
        )
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : concat(
          [
            "arn:aws:s3:::${aws_s3_bucket.producers.id}/*"
          ],
          var.should_create_orbital_webhook_s3_bucket ? ["arn:aws:s3:::${aws_s3_bucket.orbital_webhook[0].id}/*"] : []
        )
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.producers.id}"
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
          "events:PutEvents"
        ],
        "Resource" : [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/*"
        ]
      }
    ]
  })
}

module "notification_lambda" {
  for_each               = var.notification_config
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda.type
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/${each.value.lambda.file_path}"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = each.key == "ORBITAL" ? var.lambda_producer_notification_reserved_concurrency : -1
  publish                = each.key == "ORBITAL" && var.lambda_producer_notification_provisioned_concurrency > 0
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 512
  lambda_environment = merge(
    lookup(each.value.lambda, "use_attempt_timeout_for_aws_sm", false) ? { USE_ATTEMPT_TIMEOUT_FOR_AWS_SM = "true" } : {},
    {
      ENV = var.env
  })
}

module "orbital_s3_notification_lambda" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "orbital-s3-producer-notification"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/fetchData.orbitalS3ProducerNotification"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/dataFetchers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 512
  lambda_environment = {
    ENV                            = var.env,
    USE_ATTEMPT_TIMEOUT_FOR_AWS_SM = "true"
  }
}

resource "aws_lambda_permission" "orbital_s3_notification_lambda" {
  count         = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  statement_id  = "${var.name_prefix}-allow-execution-from-s3bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.orbital_s3_notification_lambda.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.orbital_webhook[0].arn
}

resource "aws_s3_bucket_notification" "orbital_s3_notification_lambda" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].id

  lambda_function {
    lambda_function_arn = module.orbital_s3_notification_lambda.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.orbital_s3_notification_lambda]
}

module "notification_lambda_development" {
  for_each               = var.should_create_development_api_gateway_endpoints ? var.notification_config_development : {}
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = each.value.lambda.type
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/${each.value.lambda.file_path}"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 512
  lambda_environment = {
    ENV = var.env
  }
}

resource "aws_lambda_alias" "producer_notification" {
  count            = var.lambda_producer_notification_provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.notification_lambda["ORBITAL"].full_function_name
  function_version = module.notification_lambda["ORBITAL"].function_version
}

resource "aws_lambda_provisioned_concurrency_config" "producer_notification" {
  count                             = var.lambda_producer_notification_provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.notification_lambda["ORBITAL"].full_function_name
  provisioned_concurrent_executions = var.lambda_producer_notification_provisioned_concurrency
  qualifier                         = aws_lambda_alias.producer_notification[0].name
}

resource "aws_api_gateway_resource" "ciscoise" {
  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = "ciscoise"
}

module "notification_gw" {
  depends_on           = [aws_api_gateway_resource.ciscoise]
  for_each             = var.notification_config
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = each.value.api_gateway.parent_path
  full_function_name   = module.notification_lambda[each.key].full_function_name
  lambda_invoke_arn    = each.key == "ORBITAL" && var.lambda_producer_notification_provisioned_concurrency > 0 ? aws_lambda_alias.producer_notification[0].invoke_arn : module.notification_lambda[each.key].lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = each.value.api_gateway.path
  http_method          = each.value.api_gateway.http_methods
  response_format      = each.value.api_gateway.response_format
  authorizer_id        = var.authorizers["webhook"].authorizer_id
  authorization_type   = each.value.api_gateway.authorization_type
  function_qualifier   = each.key == "ORBITAL" && var.lambda_producer_notification_provisioned_concurrency > 0 ? aws_lambda_alias.producer_notification[0].name : null
}

module "notification_gw_development" {
  depends_on           = [aws_api_gateway_resource.ciscoise]
  for_each             = var.should_create_development_api_gateway_endpoints ? var.notification_config_development : {}
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = each.value.api_gateway.parent_path
  full_function_name   = module.notification_lambda_development[each.key].full_function_name
  lambda_invoke_arn    = module.notification_lambda_development[each.key].lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = each.value.api_gateway.path
  http_method          = each.value.api_gateway.http_methods
  response_format      = each.value.api_gateway.response_format
  authorizer_id        = var.authorizers["webhook"].authorizer_id
  authorization_type   = each.value.api_gateway.authorization_type
}

locals {
  producer_notification_url = join("", [var.api_gateway_endpoint, module.notification_gw["ORBITAL"].aws_api_gateway_resource_path])
}

module "fetch_data" {
  for_each               = var.fetcher_config
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = each.value.lambda.timeout
  memory_size            = 256
  lambda_environment = merge(
    lookup(each.value.lambda, "use_ms_graph_url", false) ? { MS_GRAPH_URL = var.ms_graph_url } : {},
    lookup(each.value.lambda, "use_meraki_base_url", false) ? { MERAKI_BASE_URL = var.meraki_base_url } : {},
    lookup(each.value.lambda, "use_umbrella_base_url", false) ? { UMBRELLA_BASE_URL = var.umbrella_base_url, UMBRELLA_V2_BASE_URL = var.umbrella_v2_base_url } : {},
    {
      ENV               = var.env
      ENTRIES_BULK_SIZE = 100
      IROH_URI          = var.iroh_uri
      IROH_REDIRECT_URI = var.iroh_redirect_uri
  })
}

module "jamf_mobile_devices" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "fetch-jamf-mobile-devices"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.fetchJamfMobileDevices"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 600
  memory_size            = 256
  lambda_environment = {
    ENV               = var.env
    ENTRIES_BULK_SIZE = 100
    IROH_URI          = var.iroh_uri
    IROH_REDIRECT_URI = var.iroh_redirect_uri
  }
}

module "groups_fetch_data" {
  for_each               = var.groups_fetcher_config
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = each.value.lambda.name
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = each.value.lambda.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = each.value.lambda.timeout
  lambda_environment = merge(
    lookup(each.value.lambda, "use_umbrella_base_url", false) ? { UMBRELLA_BASE_URL = var.umbrella_base_url, UMBRELLA_V2_BASE_URL = var.umbrella_v2_base_url } : {},
    {
      ENV               = var.env
      IROH_URI          = var.iroh_uri
      IROH_REDIRECT_URI = var.iroh_redirect_uri
  })
}

resource "aws_sns_topic" "producers" {
  for_each = var.fetcher_config
  name     = "${var.name_prefix}-${each.value["topic_name"]}"
}

resource "aws_lambda_permission" "producers" {
  for_each      = var.fetcher_config
  statement_id  = "${var.name_prefix}-${each.value.topic_name}-allow-execution-from-sns"
  action        = "lambda:InvokeFunction"
  function_name = module.fetch_data[each.key].full_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.producers[each.key].arn
}

resource "aws_lambda_permission" "jamf_mobile_devices" {
  statement_id  = "${var.name_prefix}-jamf-mobile-devices-allow-execution-from-sns"
  action        = "lambda:InvokeFunction"
  function_name = module.jamf_mobile_devices.full_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.producers["JAMF"].arn
}

resource "aws_lambda_permission" "producer_groups" {
  for_each      = var.groups_fetcher_config
  statement_id  = "${var.name_prefix}-${each.value.topic_name}-allow-groups-execution-from-sns"
  action        = "lambda:InvokeFunction"
  function_name = module.groups_fetch_data[each.key].full_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.producers[each.key].arn
}

resource "aws_sns_topic_subscription" "producers" {
  for_each      = var.fetcher_config
  topic_arn     = aws_sns_topic.producers[each.key].arn
  protocol      = "lambda"
  endpoint      = module.fetch_data[each.key].lambda_arn
  filter_policy = "{\"target\": [\"fetch\"]}"
}

resource "aws_sns_topic_subscription" "jamf_mobile_devices" {
  topic_arn     = aws_sns_topic.producers["JAMF"].arn
  protocol      = "lambda"
  endpoint      = module.jamf_mobile_devices.lambda_arn
  filter_policy = "{\"target\": [\"fetch\"]}"
}

resource "aws_sns_topic_subscription" "producer_groups" {
  for_each      = var.groups_fetcher_config
  topic_arn     = aws_sns_topic.producers[each.key].arn
  protocol      = "lambda"
  endpoint      = module.groups_fetch_data[each.key].lambda_arn
  filter_policy = "{\"target\": [\"fetch\"]}"
}

resource "aws_lambda_permission" "vulnerability_sha_fetch" {
  statement_id  = "${var.name_prefix}-allow-vulnerability-sha-fetch"
  action        = "lambda:InvokeFunction"
  function_name = module.vulnerability_sha_fetch_computers.full_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.producers["AMP"].arn
}

resource "aws_sns_topic_subscription" "vulnerability_sha_fetch" {
  topic_arn     = aws_sns_topic.producers["AMP"].arn
  protocol      = "lambda"
  endpoint      = module.vulnerability_sha_fetch_computers.lambda_arn
  filter_policy = "{\"target\": [\"sha\"]}"
}

module "s3_upload_file_trigger" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "s3-upload-file-trigger"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/event-streaming.s3UploadFileTrigger"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
}

module "preprocessing" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "preprocessing"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/event-streaming.kinesisPreprocessing"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 512
  concurrent_executions  = var.lambda_preprocessing_reserved_concurrency
  publish                = var.lambda_preprocessing_provisioned_concurrency > 0
  lambda_environment = {
    ENV                        = var.env
    ENTRIES_BULK_SIZE          = 50,
    IROH_URI                   = var.iroh_uri,
    IROH_REDIRECT_URI          = var.iroh_redirect_uri
    NEPTUNE_CLUSTER_SETTINGS   = var.neptune_cluster_settings
    PROCESSING_STREAM_SETTINGS = var.encoded_processing_stream_settings
  }
}

resource "aws_lambda_alias" "preprocessing" {
  count            = var.lambda_preprocessing_provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.preprocessing.full_function_name
  function_version = module.preprocessing.function_version
}

resource "aws_lambda_provisioned_concurrency_config" "preprocessing" {
  count                             = var.lambda_preprocessing_provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.preprocessing.full_function_name
  provisioned_concurrent_executions = var.lambda_preprocessing_provisioned_concurrency
  qualifier                         = aws_lambda_alias.preprocessing[0].name
}


# module "preprocessing_backup" {
#   source                 = "../lambda"
#   name_prefix            = var.name_prefix
#   lambda_type            = "private"
#   function_name          = "preprocessing-backup"
#   iam_role_arn           = aws_iam_role.producers.arn
#   handler                = "src/event-streaming.kinesisPreprocessingBackup"
#   nodejs_runtime         = var.nodejs_runtime
#   lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
#   systems_manager_prefix = var.systems_manager_prefix
#   layers                 = [var.lambda_layer_arn]
#   env                    = var.env
#   lambda_timeout         = 900
#   memory_size            = 300
#   lambda_environment = {
#     ENV       = var.env
#     S3_BUCKET = aws_s3_bucket.producers.id
#   }
# }

resource "aws_lambda_event_source_mapping" "preprocessing" {
  event_source_arn                   = var.preprocessing_kinesis_stream.arn
  function_name                      = var.lambda_preprocessing_provisioned_concurrency > 0 ? aws_lambda_alias.preprocessing[0].arn : module.preprocessing.lambda_arn
  batch_size                         = 500
  maximum_batching_window_in_seconds = 5
  starting_position                  = "TRIM_HORIZON"
  parallelization_factor             = var.preprocessing_parallelization_factor
  maximum_retry_attempts             = 0
}

# resource "aws_lambda_event_source_mapping" "preprocessing_backup" {
#   event_source_arn                   = var.preprocessing_kinesis_stream.arn
#   function_name                      = module.preprocessing_backup.lambda_arn
#   batch_size                         = 1000
#   maximum_batching_window_in_seconds = 200
#   starting_position                  = "TRIM_HORIZON"
#   parallelization_factor             = 10
#   maximum_retry_attempts             = 0
# }

module "processing" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "processing"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/event-streaming.kinesisProcessing"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 512
  concurrent_executions  = var.lambda_processing_reserved_concurrency
  publish                = var.lambda_processing_provisioned_concurrency > 0
  lambda_environment = {
    ENV                                      = var.env
    ENTRIES_BULK_SIZE                        = 100
    PROCESSING_INTERNAL_CONCURRENCY          = var.processing_internal_concurrency
    NEPTUNE_CLUSTER_SETTINGS                 = var.neptune_cluster_settings
    EVENT_BRIDGE_BUS_ARN                     = var.event_bridge_bus_arn
    RULES_ENABLED                            = var.rules_enabled
    PROCESSING_STREAM_SETTINGS               = var.encoded_processing_stream_settings
    DEVICE_CHANGE_NOTIFICATION_EVENT_BUS_ARN = var.device_change_notification_event_bus_arn
  }
}

resource "aws_lambda_alias" "processing" {
  count            = var.lambda_processing_provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.processing.full_function_name
  function_version = module.processing.function_version
}

resource "aws_lambda_provisioned_concurrency_config" "processing" {
  count                             = var.lambda_processing_provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.processing.full_function_name
  provisioned_concurrent_executions = var.lambda_processing_provisioned_concurrency
  qualifier                         = aws_lambda_alias.processing[0].name
}

resource "aws_lambda_event_source_mapping" "processing" {
  for_each                           = var.processing_kinesis_streams
  event_source_arn                   = each.value.arn
  function_name                      = var.lambda_processing_provisioned_concurrency > 0 ? aws_lambda_alias.processing[0].arn : module.processing.lambda_arn
  batch_size                         = 20
  maximum_batching_window_in_seconds = var.processing_maximum_batching_window_in_seconds
  starting_position                  = "TRIM_HORIZON"
  parallelization_factor             = each.value.parallelization_factor
  maximum_retry_attempts             = 0
}

module "vulnerability_processing" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "vulnerability-processing"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/event-streaming.vulnerabilityKinesisProcessing"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 256
  lambda_environment = {
    ENV                                                  = var.env
    NEPTUNE_CLUSTER_SETTINGS                             = var.neptune_cluster_settings
    VULNERABILITY_PROCESSING_INTERNAL_CONCURRENCY        = var.vulnerability_processing_internal_concurrency
    VULNERABILITY_PROCESSING_CONCURRENT_UPDATE_COMPUTERS = var.vulnerability_processing_concurrent_update_computers
  }
}

module "vulnerability_sha_fetch_computers" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "vulnerability-sha-fetch-computers"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.vulnerabilityShaFetch"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = var.should_throttle_vulnerability_lambda ? 0 : -1
  env                    = var.env
  lambda_timeout         = 900
  lambda_environment = {
    ENV                      = var.env
    IROH_URI                 = var.iroh_uri
    IROH_REDIRECT_URI        = var.iroh_redirect_uri
    NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
  }
}

resource "aws_lambda_event_source_mapping" "vulnerability_processing" {
  event_source_arn                   = var.vulnerability_processing_kinesis_stream.arn
  function_name                      = module.vulnerability_processing.lambda_arn
  batch_size                         = var.vulnerability_processing_batch_size
  maximum_batching_window_in_seconds = var.vulnerability_processing_maximum_batching_window_in_seconds
  starting_position                  = "TRIM_HORIZON"
  parallelization_factor             = var.vulnerability_processing_parallelization_factor
  maximum_retry_attempts             = 0
}

module "timestream" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "timestream"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/event-streaming.kinesisTimestream"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 300
  lambda_environment = {
    ENV = var.env
  }
}

resource "aws_lambda_event_source_mapping" "timestream" {
  depends_on                         = [aws_iam_role_policy.producers]
  event_source_arn                   = var.timestream_kinesis_stream.arn
  function_name                      = module.timestream.lambda_arn
  batch_size                         = 1000
  maximum_batching_window_in_seconds = 30
  starting_position                  = "TRIM_HORIZON"
  parallelization_factor             = 10
  maximum_retry_attempts             = 0
}

resource "aws_lambda_permission" "s3_upload_file_trigger" {
  statement_id  = "${var.name_prefix}-allow-execution-from-s3bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_upload_file_trigger.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.producers.arn
}

resource "aws_s3_bucket_notification" "s3_upload_file_trigger" {
  bucket = aws_s3_bucket.producers.id

  lambda_function {
    lambda_function_arn = module.s3_upload_file_trigger.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "work/"
  }

  depends_on = [aws_lambda_permission.s3_upload_file_trigger]
}

module "trigger_fetch_posture_data" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "trigger-fetch-posture-data"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.triggerFetchPostureData"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 900
  memory_size            = 300
  lambda_environment = merge(
    {
      for key in keys(var.fetcher_config) :
      "${upper(var.fetcher_config[key].topic_name)}_SNS_TOPIC_ARN" => aws_sns_topic.producers[key].arn
    }
  )
}

module "schedule_fetch_posture_data" {
  count  = var.should_create_fetch_posture_data_schedule ? 1 : 0
  source = "../cloudwatch-rule"
  lambdas = [
    {
      lambda_arn : module.trigger_fetch_posture_data.lambda_arn
      function_name : module.trigger_fetch_posture_data.full_function_name
      event_input : ""
    }
  ]
  schedule_expression = "rate(15 minutes)"
  rule_base_name      = module.trigger_fetch_posture_data.full_function_name
}

module "test_fetch_data_from_producer" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "test-fetch-data-from-producer"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.testFetchForProducer"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 60
  lambda_environment = {
    ENV                  = var.env
    MS_GRAPH_URL         = var.ms_graph_url
    MERAKI_BASE_URL      = var.meraki_base_url
    UMBRELLA_BASE_URL    = var.umbrella_base_url
    UMBRELLA_V2_BASE_URL = var.umbrella_v2_base_url
    IROH_URI             = var.iroh_uri
    IROH_REDIRECT_URI    = var.iroh_redirect_uri
  }
}

module "test_fetch_data_from_producers" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "test-fetch-data-from-producers"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.testFetchForProducers"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 60
  lambda_environment = {
    ENV                  = var.env
    MS_GRAPH_URL         = var.ms_graph_url
    MERAKI_BASE_URL      = var.meraki_base_url
    UMBRELLA_BASE_URL    = var.umbrella_base_url
    UMBRELLA_V2_BASE_URL = var.umbrella_v2_base_url
    IROH_URI             = var.iroh_uri
    IROH_REDIRECT_URI    = var.iroh_redirect_uri
  }
}

module "initial_producers_sync" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "initial-producers-sync"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/iroh.initialProducersSync"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/iroh.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_timeout         = 30
  lambda_environment = {
    ENV               = var.env
    IROH_URI          = var.iroh_uri
    IROH_REDIRECT_URI = var.iroh_redirect_uri
  }
}

resource "aws_appsync_datasource" "test_fetch_data_from_producer" {
  api_id           = var.graphql_api_id
  name             = "testFetchForProducer"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.test_fetch_data_from_producer.lambda_arn
  }
}

resource "aws_appsync_resolver" "test_fetch_data_from_producer" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "testFetchDataFromProducer"
  data_source = aws_appsync_datasource.test_fetch_data_from_producer.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_appsync_datasource" "test_fetch_data_from_producers" {
  api_id           = var.graphql_api_id
  name             = "testFetchForProducers"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.test_fetch_data_from_producers.lambda_arn
  }
}

resource "aws_appsync_resolver" "test_fetch_data_from_producers" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "testFetchDataFromProducers"
  data_source = aws_appsync_datasource.test_fetch_data_from_producers.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

module "trigger_fetch_data_from_producer" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "trigger-fetch-data-from-producer"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.triggerFetchForProducer"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_environment = merge(
    {
    },
    {
      for key in keys(var.fetcher_config) :
      "${upper(var.fetcher_config[key].topic_name)}_SNS_TOPIC_ARN" => aws_sns_topic.producers[key].arn
    }
  )
}

resource "aws_appsync_datasource" "trigger_fetch_data_from_producer" {
  api_id           = var.graphql_api_id
  name             = "triggerFetchDataFromProducer"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.trigger_fetch_data_from_producer.lambda_arn
  }
}

resource "aws_appsync_resolver" "trigger_fetch_data_from_producer" {
  type        = "Mutation"
  api_id      = var.graphql_api_id
  field       = "triggerFetchDataFromProducer"
  data_source = aws_appsync_datasource.trigger_fetch_data_from_producer.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

module "get_file_upload_url" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "get-file-upload-url"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.getFileUploadUrl"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
  lambda_environment = {
    S3_BUCKET = aws_s3_bucket.producers.id
  }
}

module "get_file_upload_url_gw" {
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = "/api"
  full_function_name   = module.get_file_upload_url.full_function_name
  lambda_invoke_arn    = module.get_file_upload_url.lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = "file-upload-url"
  http_method          = ["GET"]
  response_format      = "json"
  authorizer_id        = var.authorizers["api"].authorizer_id
  integration_request_parameters = {
    "integration.request.header.id"         = "context.authorizer.id"
    "integration.request.header.tenantUid"  = "context.authorizer.tenantUid"
    "integration.request.header.tenantName" = "context.authorizer.tenantName"
    "integration.request.header.role"       = "context.authorizer.role"
  }
  request_parameters = {
    "method.request.querystring.sourceId" = true
  }
  request_validator_id = var.api_gateway_request_validator_id
  cors_disabled        = true
}

module "get_live_device_task_details" {
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "get-live-device-task-details"
  iam_role_arn           = aws_iam_role.producers.arn
  handler                = "src/index.getLiveDeviceTaskDetails"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/producers.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  env                    = var.env
}

resource "aws_appsync_datasource" "get_live_device_task_details" {
  api_id           = var.graphql_api_id
  name             = "getLiveDeviceTaskDetails"
  service_role_arn = var.iam_role_arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = module.get_live_device_task_details.lambda_arn
  }
}

resource "aws_appsync_resolver" "get_live_device_task_details" {
  type        = "Query"
  api_id      = var.graphql_api_id
  field       = "getLiveDeviceTaskDetails"
  data_source = aws_appsync_datasource.get_live_device_task_details.name

  request_template  = file("${path.module}/../../templates/generic-lambda-request.tpl")
  response_template = file("${path.module}/../../templates/generic-response.tpl")
}

resource "aws_s3_bucket" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = "${var.name_prefix}-orbital-webhook"

  tags = {
    Name = "${var.name_prefix}-producers"
  }
}

resource "aws_s3_bucket_ownership_controls" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket

  rule {
    id     = "cleanup"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "orbital_webhook" {
  count  = var.should_create_orbital_webhook_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.orbital_webhook[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "lambda_iam_role_arn" {
  value = aws_iam_role.producers.arn
}

output "amp_sns_topic_arn" {
  value = aws_sns_topic.producers["AMP"].arn
}

output "jamf_sns_topic_arn" {
  value = aws_sns_topic.producers["JAMF"].arn
}

output "unifiedConnector_sns_topic_arn" {
  value = aws_sns_topic.producers["UnifiedConnector"].arn
}

output "producer_notification_url" {
  value = local.producer_notification_url
}

output "orbital_webhook_notification_s3_bucket" {
  value = var.should_create_orbital_webhook_s3_bucket ? aws_s3_bucket.orbital_webhook[0].bucket : ""
}
