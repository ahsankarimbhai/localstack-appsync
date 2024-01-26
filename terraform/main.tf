# terraform {
#   backend "s3" {}
#   required_providers {
#     aws = {
#       version = "5.29.0"
#       source  = "hashicorp/aws"
#     }
#   }
# }

provider "aws" {
  region = var.aws_region  
  access_key                  = "mock_access_key"
  #s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    lambda         = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    appsync        = "http://localhost:4566" 
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    eventbridge    = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    acm            = "http://localhost:4566"
  }
}

provider "template" {
}

locals {
  name_prefix                  = "${var.sandbox_prefix}${var.env}-${var.base_name}"
  nodejs_runtime               = "nodejs18.x"
  api_gateway_domain_name      = length(var.api_gateway_domain_name) > 0 ? var.api_gateway_domain_name : "${local.name_prefix}.${var.api_gateway_cert_domain}"
  api_gateway_endpoint         = "https://${local.api_gateway_domain_name}"
  # neptune_cluster_resource_ids = split(",", data.aws_ssm_parameter.neptune_cluster_resource_ids.value)
}

module "base" {
  source                        = "./modules/base"
  combined_subnet_ranges        = var.combined_subnet_ranges
  subnet_config                 = var.subnet_config
  base_name                     = var.base_name
  region_domain_map             = var.region_domain_map
  service_discovery_hosted_zone = var.service_discovery_hosted_zone
  turn_on_neptune_rebalance     = var.turn_on_neptune_rebalance
  #bastion_source                = module.bastion_ssm.instance_private_ip
}

module "common_node_modules_lambda_layer" {
  source                 = "./modules/lambda-layer"
  name_prefix            = local.name_prefix
  nodejs_runtime         = local.nodejs_runtime
  lambda_layer_name      = "common-node-modules-lambda-layer"
  lambda_layer_full_path = "${path.module}/../backend/dist/layer.zip"
}

module "dynamodb-tables" {
  source                                          = "./modules/dynamodb-tables"
  global_iroh_module_type_id                      = var.global_iroh_module_type_id
  name_prefix                                     = local.name_prefix
  dynamodb_schedule_tasks_additional_config       = var.dynamodb_schedule_tasks_additional_config
  dynamodb_data_migration_tasks_additional_config = var.dynamodb_data_migration_tasks_additional_config
}

# module "event-bridge" {
#   source      = "./modules/event-bridge"
#   name_prefix = local.name_prefix
# }

# data "aws_ssm_parameter" "neptune_cluster_resource_ids" {
#   name = "/${var.base_name}-${var.env}/neptune-cluster-resource-ids"
# }

# data "aws_ssm_parameter" "neptune_cluster_settings" {
#   name = "/${var.base_name}-${var.env}/neptune-cluster-settings"
# }

# data "aws_ssm_parameter" "neptune_rebalance_settings" {
#   count = var.turn_on_neptune_rebalance ? 1 : 0
#   name  = "/${var.base_name}-${var.env}/neptune-rebalance-settings"
# }

module "api_gateway" {
  source                    = "./modules/api-gateway"
  name_prefix               = local.name_prefix
  api_gateway_deployment_id = module.api_gateway_deployment.api_gateway_deployment_id
}

# module "mock_uc_api_gateway" {
#   count       = var.deploy_mock_uc_api ? 1 : 0
#   source      = "./modules/mock-uc-api-gateway"
#   name_prefix = local.name_prefix
# }

# module "kinesis" {
#   source                               = "./modules/kinesis"
#   name_prefix                          = local.name_prefix
#   preprocessing_shard_count            = var.kinesis_preprocessing_shard_count
#   processing_stream_settings           = var.processing_stream_settings
#   vulnerability_processing_shard_count = var.vulnerability_processing_shard_count
#   timestream_shard_count               = var.timestream_shard_count
#   enable_shard_metrics                 = var.enable_shard_metrics
#   rules_execution_shard_count          = var.kinesis_rules_execution_shard_count
# }

module "authorizer" {
  for_each                              = var.authorizer_config
  source                                = "./modules/authorizer"
  name_prefix                           = local.name_prefix
  env                                   = var.env
  systems_manager_prefix                = var.base_name
  iroh_uri                              = var.iroh_env_mapping[var.iroh_env]
  nodejs_runtime                        = local.nodejs_runtime
  api_gateway                           = module.api_gateway.api_gateway
  lambda_layer_arn                      = module.common_node_modules_lambda_layer.lambda_layer_arn
  tenants_table_arn                     = module.dynamodb-tables.tenants_table_arn
  tenants_config_table_arn              = module.dynamodb-tables.tenants_config_table_arn
  authorizer_name                       = each.value.name
  authorizer_type                       = each.value.type
  lambda                                = each.value.lambda
  scheduled_task_arn                    = module.dynamodb-tables.scheduled_task_table_arn
  scheduled_task_metadata_arn           = module.dynamodb-tables.scheduled_task_metadata_table_arn
  iroh_redirect_uri                     = ""
  api_allowed_client_ids                = var.authorizer_api_allowed_client_ids
  reserved_concurrency                  = var.authorizer_settings[each.value.name].reserved_concurrency
  provisioned_concurrency               = var.authorizer_settings[each.value.name].provisioned_concurrency
  dynamodb_request_timeout_milliseconds = 5000
}

module "appsync" {
  source                           = "./modules/appsync"
  name_prefix                      = local.name_prefix
  env                              = var.env
  systems_manager_prefix           = var.base_name
  api_gateway_api_resource_id      = module.api_gateway.api_gateway_api_resource_id
  api_gateway                      = module.api_gateway.api_gateway
  api_authorizer_id                = module.authorizer["api"].authorizer_id
  api_gateway_request_validator_id = module.api_gateway.request_validator_id
  block_introspection_queries      = var.block_introspection_queries
}

# module "producers" {
#   depends_on                                                  = [module.kinesis]
#   source                                                      = "./modules/producers"
#   name_prefix                                                 = local.name_prefix
#   nodejs_runtime                                              = local.nodejs_runtime
#   systems_manager_prefix                                      = var.base_name
#   env                                                         = var.env
#   umbrella_base_url                                           = var.umbrella_base_url
#   umbrella_v2_base_url                                        = var.umbrella_v2_base_url
#   ms_graph_url                                                = var.ms_graph_url
#   meraki_base_url                                             = var.meraki_base_url
#   neptune_shard_table_arn                                     = module.dynamodb-tables.neptune_shard_table_arn
#   neptune_cluster_resource_ids                                = local.neptune_cluster_resource_ids
#   neptune_cluster_settings                                    = data.aws_ssm_parameter.neptune_cluster_settings.value
#   lambda_layer_arn                                            = module.common_node_modules_lambda_layer.lambda_layer_arn
#   tenants_config_table_arn                                    = module.dynamodb-tables.tenants_config_table_arn
#   label_metadata_arn                                          = module.dynamodb-tables.label_metadata_arn
#   groups_table_arn                                            = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                                            = module.dynamodb-tables.policy_table_arn
#   os_versions_table_arn                                       = module.dynamodb-tables.os_versions_table_arn
#   vulnerability_table_arn                                     = module.dynamodb-tables.vulnerability_table_arn
#   function_state_table_arn                                    = module.dynamodb-tables.function_state_table_arn
#   tenants_table_arn                                           = module.dynamodb-tables.tenants_table_arn
#   scheduled_task_arn                                          = module.dynamodb-tables.scheduled_task_table_arn
#   scheduled_task_metadata_arn                                 = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   api_gateway                                                 = module.api_gateway.api_gateway
#   graphql_api_id                                              = module.appsync.graphql_api_id
#   iam_role_arn                                                = module.appsync.iam_role_arn
#   preprocessing_kinesis_stream                                = module.kinesis.preprocessing_kinesis_stream
#   processing_kinesis_streams                                  = module.kinesis.processing_kinesis_streams
#   encoded_processing_stream_settings                          = module.kinesis.encoded_processing_stream_settings
#   vulnerability_processing_kinesis_stream                     = module.kinesis.vulnerability_processing_kinesis_stream
#   vulnerability_processing_batch_size                         = var.vulnerability_processing_batch_size
#   vulnerability_processing_maximum_batching_window_in_seconds = var.vulnerability_processing_maximum_batching_window_in_seconds
#   vulnerability_processing_parallelization_factor             = var.vulnerability_processing_parallelization_factor
#   vulnerability_processing_internal_concurrency               = var.vulnerability_processing_internal_concurrency
#   vulnerability_processing_concurrent_update_computers        = var.vulnerability_processing_concurrent_update_computers
#   timestream_kinesis_stream                                   = module.kinesis.timestream_kinesis_stream
#   should_create_fetch_posture_data_schedule                   = var.should_create_fetch_posture_data_schedule
#   neptune_concurrency                                         = var.neptune_concurrency
#   processing_internal_concurrency                             = var.processing_internal_concurrency
#   preprocessing_parallelization_factor                        = var.preprocessing_parallelization_factor
#   should_create_development_api_gateway_endpoints             = var.should_create_development_api_gateway_endpoints
#   api_gateway_endpoint                                        = local.api_gateway_endpoint
#   authorizers                                                 = module.authorizer
#   api_gateway_request_validator_id                            = module.api_gateway.request_validator_id
#   saved_filter_arn                                            = module.dynamodb-tables.saved_filter_table_arn
#   iroh_uri                                                    = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                                           = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   processing_maximum_batching_window_in_seconds               = var.processing_maximum_batching_window_in_seconds
#   lambda_processing_provisioned_concurrency                   = var.lambda_processing_provisioned_concurrency
#   lambda_processing_reserved_concurrency                      = var.lambda_processing_reserved_concurrency
#   lambda_preprocessing_provisioned_concurrency                = var.lambda_preprocessing_provisioned_concurrency
#   lambda_preprocessing_reserved_concurrency                   = var.lambda_preprocessing_reserved_concurrency
#   lambda_producer_notification_provisioned_concurrency        = var.lambda_producer_notification_provisioned_concurrency
#   lambda_producer_notification_reserved_concurrency           = var.lambda_producer_notification_reserved_concurrency
#   event_bridge_bus_arn                                        = module.event-bridge.event_bridge_bus_arn
#   rules_enabled                                               = var.rules_enabled
#   rules_execution_kinesis_stream                              = module.kinesis.rules_execution_kinesis_stream
#   should_throttle_vulnerability_lambda                        = var.should_throttle_vulnerability_lambda
#   incident_mapping_arn                                        = module.dynamodb-tables.incident_mapping_arn
#   device_change_notification_event_bus_arn                    = module.event-bridge.device_change_notification_event_bus_arn
#   webhook_registration_table_arn                              = module.dynamodb-tables.webhook_registration_table_arn
#   should_create_orbital_webhook_s3_bucket                     = var.should_create_orbital_webhook_s3_bucket
# }

module "graphql-api" {
  source                                   = "./modules/graphql-api"
  name_prefix                              = local.name_prefix
  nodejs_runtime                           = local.nodejs_runtime
  systems_manager_prefix                   = var.base_name
  env                                      = var.env
  graphql_api_lambda_timeout               = var.graphql_api_lambda_timeout
  dynamodb_request_timeout_milliseconds    = 10000
  metric_period_in_days                    = var.metric_period_in_days
  lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
  tenants_config_table_arn                 = module.dynamodb-tables.tenants_config_table_arn
  groups_table_arn                         = module.dynamodb-tables.groups_table_arn
  policy_table_arn                         = module.dynamodb-tables.policy_table_arn
  os_versions_table_arn                    = module.dynamodb-tables.os_versions_table_arn
  vulnerability_table_arn                  = module.dynamodb-tables.vulnerability_table_arn
  function_state_table_arn                 = module.dynamodb-tables.function_state_table_arn
  tenants_table_arn                        = module.dynamodb-tables.tenants_table_arn
  scheduled_task_arn                       = module.dynamodb-tables.scheduled_task_table_arn
  scheduled_task_metadata_arn              = module.dynamodb-tables.scheduled_task_metadata_table_arn
  label_metadata_arn                       = module.dynamodb-tables.label_metadata_arn
  rule_arn                                 = module.dynamodb-tables.rule_arn
  graphql_api_id                           = module.appsync.graphql_api_id
  iam_role_arn                             = module.appsync.iam_role_arn
  saved_filter_arn                         = module.dynamodb-tables.saved_filter_table_arn
  #neptune_cluster_resource_ids             = local.neptune_cluster_resource_ids
  #neptune_cluster_settings                 = data.aws_ssm_parameter.neptune_cluster_settings.value
  neptune_shard_table_arn                  = module.dynamodb-tables.neptune_shard_table_arn
  use_predefined_neptune_shard_id          = var.use_predefined_neptune_shard_id
  iroh_uri                                 = var.iroh_env_mapping[var.iroh_env]
  #iroh_redirect_uri                        = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
  api_gateway_endpoint                     = local.api_gateway_endpoint
  # aws_event_bus_scheduled_tasks_arn        = module.event-bridge.aws_event_bus_scheduled_tasks_arn
  orbital_base_url                         = var.orbital_regions_mapping[var.env]
  #producer_notification_url                = module.producers.producer_notification_url
  #orbital_webhook_notification_s3_bucket   = module.producers.orbital_webhook_notification_s3_bucket
  #timestream_kinesis_stream                = module.kinesis.timestream_kinesis_stream
  #rules_execution_kinesis_stream           = module.kinesis.rules_execution_kinesis_stream
  #encoded_processing_stream_settings       = module.kinesis.encoded_processing_stream_settings
  #event_bridge_bus_arn                     = module.event-bridge.event_bridge_bus_arn
  rules_enabled                            = var.rules_enabled
  incident_mapping_arn                     = module.dynamodb-tables.incident_mapping_arn
  #device_change_notification_event_bus_arn = module.event-bridge.device_change_notification_event_bus_arn
  webhook_registration_table_arn           = module.dynamodb-tables.webhook_registration_table_arn
}

# module "neptune_services" {
#   source                       = "./modules/neptune-services"
#   name_prefix                  = local.name_prefix
#   nodejs_runtime               = local.nodejs_runtime
#   systems_manager_prefix       = var.base_name
#   env                          = var.env
#   allow_neptune_services       = var.allow_neptune_services
#   neptune_cluster_resource_ids = local.neptune_cluster_resource_ids
#   lambda_layer_arn             = module.common_node_modules_lambda_layer.lambda_layer_arn
# }

# module "tenant_management" {
#   source                                   = "./modules/tenant-management"
#   name_prefix                              = local.name_prefix
#   nodejs_runtime                           = local.nodejs_runtime
#   systems_manager_prefix                   = var.base_name
#   lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
#   env                                      = var.env
#   allow_es_tenant_data_cleanup             = var.allow_es_tenant_data_cleanup
#   allow_es_tenant_person_cleanup           = var.allow_es_tenant_person_cleanup
#   metric_period_in_days                    = var.metric_period_in_days
#   tenants_table_arn                        = module.dynamodb-tables.tenants_table_arn
#   tenants_config_table_arn                 = module.dynamodb-tables.tenants_config_table_arn
#   scheduled_task_arn                       = module.dynamodb-tables.scheduled_task_table_arn
#   scheduled_task_metadata_arn              = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   graphql_api_id                           = module.appsync.graphql_api_id
#   iam_role_arn                             = module.appsync.iam_role_arn
#   aws_event_bus_scheduled_tasks_arn        = module.event-bridge.aws_event_bus_scheduled_tasks_arn
#   producer_notification_url                = module.producers.producer_notification_url
#   orbital_webhook_notification_s3_bucket   = module.producers.orbital_webhook_notification_s3_bucket
#   function_state_table_arn                 = module.dynamodb-tables.function_state_table_arn
#   groups_table_arn                         = module.dynamodb-tables.groups_table_arn
#   saved_filter_arn                         = module.dynamodb-tables.saved_filter_table_arn
#   neptune_cluster_settings                 = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn                  = module.dynamodb-tables.neptune_shard_table_arn
#   use_predefined_neptune_shard_id          = var.use_predefined_neptune_shard_id
#   iroh_uri                                 = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                        = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   event_bridge_bus_arn                     = module.event-bridge.event_bridge_bus_arn
#   rules_enabled                            = var.rules_enabled
#   rule_arn                                 = module.dynamodb-tables.rule_arn
#   rules_execution_kinesis_stream           = module.kinesis.rules_execution_kinesis_stream
#   label_metadata_arn                       = module.dynamodb-tables.label_metadata_arn
#   timestream_kinesis_stream                = module.kinesis.timestream_kinesis_stream
#   incident_mapping_arn                     = module.dynamodb-tables.incident_mapping_arn
#   policy_table_arn                         = module.dynamodb-tables.policy_table_arn
#   device_change_notification_event_bus_arn = module.event-bridge.device_change_notification_event_bus_arn
#   webhook_registration_table_arn           = module.dynamodb-tables.webhook_registration_table_arn
# }

# module "migration" {
#   source                                       = "./modules/migration"
#   name_prefix                                  = local.name_prefix
#   nodejs_runtime                               = local.nodejs_runtime
#   systems_manager_prefix                       = var.base_name
#   lambda_layer_arn                             = module.common_node_modules_lambda_layer.lambda_layer_arn
#   env                                          = var.env
#   tenants_table_arn                            = module.dynamodb-tables.tenants_table_arn
#   tenants_config_table_arn                     = module.dynamodb-tables.tenants_config_table_arn
#   data_migration_task_metadata_table_arn       = module.dynamodb-tables.data_migration_task_metadata_table_arn
#   data_migration_task_table_arn                = module.dynamodb-tables.data_migration_task_table_arn
#   scheduled_task_metadata_table_arn            = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   scheduled_task_table_arn                     = module.dynamodb-tables.scheduled_task_table_arn
#   timestream_kinesis_stream                    = module.kinesis.timestream_kinesis_stream
#   os_versions_table_arn                        = module.dynamodb-tables.os_versions_table_arn
#   neptune_cluster_resource_ids                 = local.neptune_cluster_resource_ids
#   neptune_cluster_settings                     = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn                      = module.dynamodb-tables.neptune_shard_table_arn
#   neptune_shard_migration_log_table_arn        = module.dynamodb-tables.neptune_shard_migration_log_table_arn
#   neptune_shard_migration_log_detail_table_arn = module.dynamodb-tables.neptune_shard_migration_log_detail_table_arn
#   groups_table_arn                             = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                             = module.dynamodb-tables.policy_table_arn
#   iroh_uri                                     = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                            = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   orbital_webhook_notification_s3_bucket       = module.producers.orbital_webhook_notification_s3_bucket
# }

# module "scheduled_tasks" {
#   source                                             = "./modules/scheduled-tasks"
#   name_prefix                                        = local.name_prefix
#   nodejs_runtime                                     = local.nodejs_runtime
#   systems_manager_prefix                             = var.base_name
#   lambda_layer_arn                                   = module.common_node_modules_lambda_layer.lambda_layer_arn
#   env                                                = var.env
#   neptune_cluster_resource_ids                       = local.neptune_cluster_resource_ids
#   neptune_cluster_settings                           = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn                            = module.dynamodb-tables.neptune_shard_table_arn
#   tenants_table_arn                                  = module.dynamodb-tables.tenants_table_arn
#   tenants_config_table_arn                           = module.dynamodb-tables.tenants_config_table_arn
#   function_state_table_arn                           = module.dynamodb-tables.function_state_table_arn
#   timestream_kinesis_stream                          = module.kinesis.timestream_kinesis_stream
#   should_create_trigger_scheduled_tasks_schedule     = var.should_create_trigger_scheduled_tasks_schedule
#   scheduled_task_metadata_table_arn                  = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   scheduled_task_table_arn                           = module.dynamodb-tables.scheduled_task_table_arn
#   amp_sns_topic_arn                                  = module.producers.amp_sns_topic_arn
#   jamf_sns_topic_arn                                 = module.producers.jamf_sns_topic_arn
#   unifiedConnector_sns_topic_arn                     = module.producers.unifiedConnector_sns_topic_arn
#   vulnerability_processing_kinesis_stream            = module.kinesis.vulnerability_processing_kinesis_stream
#   groups_table_arn                                   = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                                   = module.dynamodb-tables.policy_table_arn
#   os_versions_table_arn                              = module.dynamodb-tables.os_versions_table_arn
#   graphql_api_id                                     = module.appsync.graphql_api_id
#   appsync_iam_role_arn                               = module.appsync.iam_role_arn
#   data_migration_task_metadata_table_arn             = module.dynamodb-tables.data_migration_task_metadata_table_arn
#   data_migration_task_table_arn                      = module.dynamodb-tables.data_migration_task_table_arn
#   iroh_redirect_uri                                  = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   iroh_uri                                           = var.iroh_env_mapping[var.iroh_env]
#   aws_event_bus_scheduled_tasks_arn                  = module.event-bridge.aws_event_bus_scheduled_tasks_arn
#   orbital_base_url                                   = var.orbital_regions_mapping[var.env]
#   producer_notification_url                          = module.producers.producer_notification_url
#   orbital_webhook_notification_s3_bucket             = module.producers.orbital_webhook_notification_s3_bucket
#   label_metadata_arn                                 = module.dynamodb-tables.label_metadata_arn
#   lambda_iroh_sync_producers_provisioned_concurrency = var.lambda_iroh_sync_producers_provisioned_concurrency
#   lambda_iroh_sync_producers_reserved_concurrency    = var.lambda_iroh_sync_producers_reserved_concurrency
#   rules_table_arn                                    = module.dynamodb-tables.rule_arn
#   lambda_rules_changes_handling_internal_concurrency = var.lambda_rules_changes_handling_internal_concurrency
#   rules_execution_kinesis_stream                     = module.kinesis.rules_execution_kinesis_stream
#   event_bridge_bus_arn                               = module.event-bridge.event_bridge_bus_arn
#   rules_enabled                                      = var.rules_enabled
#   max_allowed_concurrent_migration_tasks             = var.max_allowed_concurrent_migration_tasks
#   update_webhook_source_options                      = var.update_webhook_source_options
#   should_throttle_vulnerability_lambda               = var.should_throttle_vulnerability_lambda
#   incident_mapping_arn                               = module.dynamodb-tables.incident_mapping_arn
#   device_change_notification_event_bus_arn           = module.event-bridge.device_change_notification_event_bus_arn
#   webhook_registration_table_arn                     = module.dynamodb-tables.webhook_registration_table_arn
#   delay_in_millis                                    = var.delay_in_millis
#   rules_clean_discrepancies_failure_handler_arn      = module.rules.rules_clean_discrepancies_failure_handler_arn
# }

# module "status" {
#   source                      = "./modules/status"
#   name_prefix                 = local.name_prefix
#   nodejs_runtime              = local.nodejs_runtime
#   systems_manager_prefix      = var.base_name
#   env                         = var.env
#   neptune_cluster_settings    = data.aws_ssm_parameter.neptune_cluster_settings.value
#   graphql_api_id              = module.appsync.graphql_api_id
#   appsync_iam_role_arn        = module.appsync.iam_role_arn
#   api_gateway_iam_role_arn    = module.appsync.api_gateway_iam_role_arn
#   lambda_layer_arn            = module.common_node_modules_lambda_layer.lambda_layer_arn
#   lambda_iam_role_arn         = module.producers.lambda_iam_role_arn
#   api_gateway_id              = module.api_gateway.api_gateway.id
#   api_gateway_api_resource_id = module.api_gateway.api_gateway_api_resource_id
#   graphql_uri                 = module.appsync.graphql_uri
#   test_sns_topic_arn          = module.producers.amp_sns_topic_arn
# }

# module "system" {
#   source                                          = "./modules/system"
#   api_gateway                                     = module.api_gateway.api_gateway
#   authorizers                                     = module.authorizer
#   env                                             = var.env
#   lambda_layer_arn                                = module.common_node_modules_lambda_layer.lambda_layer_arn
#   name_prefix                                     = local.name_prefix
#   neptune_cluster_resource_ids                    = local.neptune_cluster_resource_ids
#   neptune_cluster_settings                        = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn                         = module.dynamodb-tables.neptune_shard_table_arn
#   nodejs_runtime                                  = local.nodejs_runtime
#   tenants_table_arn                               = module.dynamodb-tables.tenants_table_arn
#   scheduled_task_arn                              = module.dynamodb-tables.scheduled_task_table_arn
#   scheduled_task_metadata_arn                     = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   systems_manager_prefix                          = var.base_name
#   tenants_config_table_arn                        = module.dynamodb-tables.tenants_config_table_arn
#   should_create_development_api_gateway_endpoints = var.should_create_development_api_gateway_endpoints
#   event_bridge_bus_arn                            = module.event-bridge.event_bridge_bus_arn
#   rule_arn                                        = module.dynamodb-tables.rule_arn
# }

# module "frontend" {
#   source                            = "./modules/frontend"
#   name_prefix                       = local.name_prefix
#   should_create_cloudfront_endpoint = var.should_create_cloudfront_endpoint
#   is_local_dev_env                  = var.is_local_dev_env
#   cloudfront_domain                 = var.cloudfront_domain
#   cloudfront_apps_subdomain         = var.cloudfront_apps_subdomain
#   cloudfront_apps_acm_cert_domain   = var.cloudfront_apps_acm_cert_domain
#   public_hosted_zone                = var.public_hosted_zone
#   s3_bucket_tags                    = var.s3_bucket_tags
#   s3_bucket_env                     = var.s3_bucket_env
# }

module "iroh" {
  source                           = "./modules/iroh"
  name_prefix                      = local.name_prefix
  should_enable_iroh_token_request = var.should_enable_iroh_token_request
  nodejs_runtime                   = local.nodejs_runtime
  systems_manager_prefix           = var.base_name
  env                              = var.env
  lambda_layer_arn                 = module.common_node_modules_lambda_layer.lambda_layer_arn
  api_gateway                      = module.api_gateway.api_gateway
  api_gateway_request_validator_id = module.api_gateway.request_validator_id
  #iroh_redirect_uri                = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
  iroh_uri                         = var.iroh_env_mapping[var.env]
  tenants_table_arn                = module.dynamodb-tables.tenants_table_arn
  scheduled_task_arn               = module.dynamodb-tables.scheduled_task_table_arn
  scheduled_task_metadata_arn      = module.dynamodb-tables.scheduled_task_metadata_table_arn
}

# module "assets" {
#   source                           = "./modules/assets"
#   name_prefix                      = local.name_prefix
#   nodejs_runtime                   = local.nodejs_runtime
#   systems_manager_prefix           = var.base_name
#   env                              = var.env
#   neptune_cluster_resource_ids     = local.neptune_cluster_resource_ids
#   neptune_cluster_settings         = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn          = module.dynamodb-tables.neptune_shard_table_arn
#   lambda_layer_arn                 = module.common_node_modules_lambda_layer.lambda_layer_arn
#   api_gateway                      = module.api_gateway.api_gateway
#   api_gateway_request_validator_id = module.api_gateway.request_validator_id
#   posture_url                      = module.frontend.cloudfront_apps_endpoint
#   authorizer_id                    = module.authorizer["api"].authorizer_id
#   os_versions_table_arn            = module.dynamodb-tables.os_versions_table_arn
#   groups_table_arn                 = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                 = module.dynamodb-tables.policy_table_arn
#   vulnerability_table_arn          = module.dynamodb-tables.vulnerability_table_arn
#   tenants_table_arn                = module.dynamodb-tables.tenants_table_arn
#   tenant_config_arn                = module.dynamodb-tables.tenants_config_table_arn
#   label_metadata_arn               = module.dynamodb-tables.label_metadata_arn
#   iroh_uri                         = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   event_bridge_bus_arn             = module.event-bridge.event_bridge_bus_arn
#   rules_enabled                    = var.rules_enabled
# }

# module "incidents" {
#   source                                   = "./modules/incidents"
#   name_prefix                              = local.name_prefix
#   nodejs_runtime                           = local.nodejs_runtime
#   systems_manager_prefix                   = var.base_name
#   env                                      = var.env
#   lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
#   api_gateway                              = module.api_gateway.api_gateway
#   api_gateway_request_validator_id         = module.api_gateway.request_validator_id
#   authorizer_id                            = module.authorizer["api"].authorizer_id
#   tenants_table_arn                        = module.dynamodb-tables.tenants_table_arn
#   tenants_config_table_arn                 = module.dynamodb-tables.tenants_config_table_arn
#   incident_mapping_arn                     = module.dynamodb-tables.incident_mapping_arn
#   device_change_notification_event_bus_arn = module.event-bridge.device_change_notification_event_bus_arn
#   iroh_uri                                 = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                        = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
# }

# module "rebalance_neptune" {
#   count                                        = var.turn_on_neptune_rebalance ? 1 : 0
#   source                                       = "./modules/rebalance-neptune"
#   name_prefix                                  = local.name_prefix
#   nodejs_runtime                               = local.nodejs_runtime
#   systems_manager_prefix                       = var.base_name
#   lambda_layer_arn                             = module.common_node_modules_lambda_layer.lambda_layer_arn
#   enable_neptune_migration_state_tracker       = var.enable_neptune_migration_state_tracker
#   env                                          = var.env
#   neptune_cluster_resource_ids                 = local.neptune_cluster_resource_ids
#   enable_neptune_rebalance_auto_throttler      = var.enable_neptune_rebalance_auto_throttler
#   neptune_cluster_settings                     = data.aws_ssm_parameter.neptune_cluster_settings.value
#   neptune_shard_table_arn                      = module.dynamodb-tables.neptune_shard_table_arn
#   neptune_shard_migration_log_table_arn        = module.dynamodb-tables.neptune_shard_migration_log_table_arn
#   neptune_shard_migration_log_detail_table_arn = module.dynamodb-tables.neptune_shard_migration_log_detail_table_arn
#   neptune_rebalance_settings                   = data.aws_ssm_parameter.neptune_rebalance_settings[0].value
#   max_export_vertices_chunk_size               = var.max_export_vertices_chunk_size
#   neptune_export_service_lambda_name           = var.neptune_export_service_lambda_name
#   neptune_export_status_service_lambda_name    = var.neptune_export_status_service_lambda_name
#   neptune_export_service_concurrency_setting   = var.neptune_export_service_concurrency_setting
#   timestream_kinesis_stream                    = module.kinesis.timestream_kinesis_stream
# }

module "api_gateway_deployment" {
  source                  = "./modules/api-gateway-deployment"
  name_prefix             = local.name_prefix
  public_hosted_zone      = var.public_hosted_zone
  cert_domain             = var.api_gateway_cert_domain
  stage_name              = var.api_gateway_stage_name
  api_gateway_id          = module.api_gateway.api_gateway.id
  api_gateway_domain_name = local.api_gateway_domain_name
}

# module "mock_uc_api_gateway_deployment" {
#   depends_on = [
#     module.mock_uc_api_gateway
#   ]
#   count          = var.deploy_mock_uc_api ? 1 : 0
#   source         = "./modules/mock-uc-api-gateway-deployment"
#   name_prefix    = local.name_prefix
#   api_gateway_id = module.mock_uc_api_gateway[0].api_gateway.id
#   stage_name     = var.api_gateway_stage_name
# }

# module "rules" {
#   depends_on                                         = [module.kinesis]
#   source                                             = "./modules/rules"
#   name_prefix                                        = local.name_prefix
#   nodejs_runtime                                     = local.nodejs_runtime
#   systems_manager_prefix                             = var.base_name
#   env                                                = var.env
#   lambda_layer_arn                                   = module.common_node_modules_lambda_layer.lambda_layer_arn
#   rules_table_arn                                    = module.dynamodb-tables.rule_arn
#   os_versions_table_arn                              = module.dynamodb-tables.os_versions_table_arn
#   tenants_table_arn                                  = module.dynamodb-tables.tenants_table_arn
#   tenants_config_table_arn                           = module.dynamodb-tables.tenants_config_table_arn
#   iam_role_arn                                       = module.appsync.iam_role_arn
#   rules_execution_kinesis_stream                     = module.kinesis.rules_execution_kinesis_stream
#   rules_execution_internal_concurrency               = var.rules_execution_internal_concurrency
#   parallelization_factor                             = var.rules_parallelization_factor
#   rules_execution_maximum_batching_window_in_seconds = var.rules_execution_maximum_batching_window_in_seconds
#   lambda_rules_execution_provisioned_concurrency     = var.lambda_rules_execution_provisioned_concurrency
#   lambda_rules_execution_reserved_concurrency        = var.lambda_rules_execution_reserved_concurrency
#   event_bridge_bus_arn                               = module.event-bridge.event_bridge_bus_arn
#   device_change_notification_event_bus_arn           = module.event-bridge.device_change_notification_event_bus_arn
#   webhook_registration_table_arn                     = module.dynamodb-tables.webhook_registration_table_arn
#   timestream_kinesis_stream                          = module.kinesis.timestream_kinesis_stream
#   delay_in_millis                                    = var.delay_in_millis
# }

# module "data-sharing" {
#   source                                   = "./modules/data-sharing"
#   name_prefix                              = local.name_prefix
#   nodejs_runtime                           = local.nodejs_runtime
#   systems_manager_prefix                   = var.base_name
#   env                                      = var.env
#   neptune_cluster_resource_ids             = local.neptune_cluster_resource_ids
#   lambda_layer_arn                         = module.common_node_modules_lambda_layer.lambda_layer_arn
#   api_gateway                              = module.api_gateway.api_gateway
#   api_gateway_request_validator_id         = module.api_gateway.request_validator_id
#   iroh_uri                                 = var.iroh_env_mapping[var.iroh_env]
#   iroh_redirect_uri                        = "${module.frontend.cloudfront_apps_endpoint}/iroh/callback"
#   authorizer_id                            = module.authorizer["api"].authorizer_id
#   tenants_table_arn                        = module.dynamodb-tables.tenants_table_arn
#   tenant_config_table_arn                  = module.dynamodb-tables.tenants_config_table_arn
#   webhook_registration_table_arn           = module.dynamodb-tables.webhook_registration_table_arn
#   webhook_notification_table_arn           = module.dynamodb-tables.webhook_notification_table_arn
#   os_versions_table_arn                    = module.dynamodb-tables.os_versions_table_arn
#   groups_table_arn                         = module.dynamodb-tables.groups_table_arn
#   policy_table_arn                         = module.dynamodb-tables.policy_table_arn
#   label_metadata_arn                       = module.dynamodb-tables.label_metadata_arn
#   neptune_shard_table_arn                  = module.dynamodb-tables.neptune_shard_table_arn
#   neptune_cluster_settings                 = data.aws_ssm_parameter.neptune_cluster_settings.value
#   scheduled_task_metadata_table_arn        = module.dynamodb-tables.scheduled_task_metadata_table_arn
#   aws_event_bus_scheduled_tasks_arn        = module.event-bridge.aws_event_bus_scheduled_tasks_arn
#   device_change_notification_event_bus_arn = module.event-bridge.device_change_notification_event_bus_arn
# }

# output "frontend_content_bucket_name" {
#   value = var.env == "staging" ? module.frontend.content_bucket_name : module.frontend.content_bucket_name
# }

# output "graphql_endpoint" {
#   value = "${local.api_gateway_endpoint}/api"
# }

# output "aws_region" {
#   value = var.aws_region
# }

# output "cloudfront_apps_endpoint" {
#   value = module.frontend.cloudfront_apps_endpoint
# }

# output "mock_uc_endpoint" {
#   value = var.env == "ci" ? module.mock_uc_api_gateway_deployment[0].deployment_url : ""
# }