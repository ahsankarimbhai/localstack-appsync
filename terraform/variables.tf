variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "base_name" {
  type    = string
  default = "posaas"
}
variable "env" {
  type = string
}
variable "graphql_api_lambda_timeout" {
  type    = number
  default = 60
}
variable "metric_period_in_days" {
  type    = string
  default = "7"
}
variable "sandbox_prefix" {
  type    = string
  default = ""
}
variable "api_gateway_stage_name" {
  type    = string
  default = "default"
}
variable "api_gateway_cert_domain" {
  type    = string
  default = "mypostureservice.name"
}
variable "api_gateway_domain_name" {
  type    = string
  default = ""
}
variable "authorizer_api_allowed_client_ids" {
  type    = string
  default = ""
}
variable "public_hosted_zone" {
  type    = string
  default = "mypostureservice.name"
}
variable "umbrella_base_url" {
  type    = string
  default = "https://management.api.umbrella.com"
}
variable "umbrella_v2_base_url" {
  type    = string
  default = "https://api.umbrella.com"
}
variable "ms_graph_url" {
  type    = string
  default = "https://graph.microsoft.com"
}
variable "meraki_base_url" {
  type    = string
  default = "https://api.meraki.com"
}
variable "allow_neptune_services" {
  default = false
}
variable "allow_es_tenant_data_cleanup" {
  default = false
}
variable "allow_es_tenant_person_cleanup" {
  default = false
}
variable "deploy_mock_uc_api" {
  default = false
}
variable "enable_shard_metrics" {
  type    = bool
  default = false
}
variable "iroh_env" {
  type = string
}
variable "iroh_env_mapping" {
  type = map(string)

  default = {
    "localstack"  = "https://visibility.test.iroh.site"
    "dev"         = "https://visibility.test.iroh.site"
    "ci"          = "https://visibility.test.iroh.site"
    "integration" = "https://visibility.int.iroh.site"
    "staging"     = "https://visibility.test.iroh.site"
    "prod"        = "https://visibility.amp.cisco.com"
    "prodeu"      = "https://visibility.eu.amp.cisco.com"
    "prodapjc"    = "https://visibility.apjc.amp.cisco.com"
  }
}

variable "orbital_regions_mapping" {
  type = map(string)

  default = {
    "localstack"  = "https://demo.orbital.threatgrid.com"
    "dev"         = "https://demo.orbital.threatgrid.com"
    "ci"          = "https://demo.orbital.threatgrid.com"
    "integration" = "https://demo.orbital.threatgrid.com"
    "staging"     = "https://demo.orbital.threatgrid.com"
    "prod"        = "https://orbital.amp.cisco.com"
    "prodeu"      = "https://orbital.eu.amp.cisco.com"
    "prodapjc"    = "https://orbital.apjc.amp.cisco.com"
  }
}

variable "processing_maximum_batching_window_in_seconds" {
  type    = number
  default = 5
}
variable "rules_execution_maximum_batching_window_in_seconds" {
  type    = number
  default = 5
}
variable "preprocessing_parallelization_factor" {
  type    = number
  default = 1
}
variable "rules_parallelization_factor" {
  type    = number
  default = 3
}
variable "should_create_cloudfront_endpoint" {
  type    = bool
  default = true
}
variable "should_enable_iroh_token_request" {
  type    = bool
  default = true
}
variable "is_local_dev_env" {
  type    = bool
  default = false
}
variable "should_create_fetch_posture_data_schedule" {
  type    = bool
  default = false
}
variable "should_create_trigger_scheduled_tasks_schedule" {
  type    = bool
  default = false
}
variable "should_create_development_api_gateway_endpoints" {
  type    = bool
  default = false
}
variable "cloudfront_domain" {
  type    = string
  default = "mypostureservice.name"
}
variable "cloudfront_apps_subdomain" {
  type    = string
  default = "garbage-to-be-replaced"
}
variable "cloudfront_apps_acm_cert_domain" {
  type    = string
  default = "mypostureservice.name"
}
variable "neptune_concurrency" {
  type    = number
  default = 4
}
variable "processing_internal_concurrency" {
  type    = number
  default = 1
}
variable "vulnerability_processing_internal_concurrency" {
  type    = number
  default = 4
}
variable "vulnerability_processing_concurrent_update_computers" {
  type    = number
  default = 1
}
variable "rules_execution_internal_concurrency" {
  type    = number
  default = 1
}
variable "kinesis_preprocessing_shard_count" {
  type    = number
  default = 1
}
variable "delay_in_millis" {
  type    = number
  default = 500
}
variable "processing_stream_settings" {
  type = map(object({
    base_name              = string
    stream_id              = string
    shard_count            = number
    parallelization_factor = number
  }))
  default = {
    stream_1 = {
      base_name              = "processing-1"
      stream_id              = "1"
      shard_count            = 1
      parallelization_factor = 3
    }
  }
}
variable "vulnerability_processing_shard_count" {
  type    = number
  default = 1
}
variable "vulnerability_processing_batch_size" {
  type    = number
  default = 1000
}
variable "vulnerability_processing_maximum_batching_window_in_seconds" {
  type    = number
  default = 5
}
variable "vulnerability_processing_parallelization_factor" {
  type    = number
  default = 1
}
variable "timestream_shard_count" {
  type    = number
  default = 1
}
variable "kinesis_rules_execution_shard_count" {
  type    = number
  default = 1
}
variable "global_iroh_module_type_id" {
  type = string
}
variable "lambda_processing_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_processing_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_preprocessing_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_preprocessing_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_iroh_sync_producers_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_iroh_sync_producers_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_producer_notification_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_producer_notification_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_rules_execution_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_rules_execution_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_rules_changes_handling_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_rules_changes_handling_internal_concurrency" {
  type    = number
  default = 1
}
variable "use_predefined_neptune_shard_id" {
  type    = bool
  default = false
}
variable "turn_on_neptune_rebalance" {
  type    = bool
  default = false
}
variable "enable_neptune_migration_state_tracker" {
  type    = bool
  default = false
}
variable "enable_neptune_rebalance_auto_throttler" {
  type    = bool
  default = false
}
variable "max_export_vertices_chunk_size" {
  type    = number
  default = 500000
}
variable "neptune_export_service_lambda_name" {
  type    = string
  default = ""
}
variable "neptune_export_status_service_lambda_name" {
  type    = string
  default = ""
}
variable "max_allowed_concurrent_migration_tasks" {
  type    = number
  default = 1
}
variable "dynamodb_schedule_tasks_additional_config" {
  type    = any
  default = {}
}
variable "dynamodb_data_migration_tasks_additional_config" {
  type    = any
  default = {}
}
variable "should_throttle_vulnerability_lambda" {
  type    = bool
  default = false
}
variable "block_introspection_queries" {
  type    = bool
  default = false
}
variable "update_webhook_source_options" {
  type    = string
  default = "[{\"source\":\"AMP\"},{\"source\":\"Orbital\"},{\"source\":\"JAMF\"},{\"source\":\"UnifiedConnector\"}]"
}
variable "should_create_orbital_webhook_s3_bucket" {
  type    = bool
  default = true
}
variable "neptune_export_service_concurrency_setting" {
  type = object({
    xlargeJob = number,
    largeJob  = number
    mediumJob = number
    smallJob  = number
  })
  default = {
    xlargeJob : 20,
    largeJob : 20,
    mediumJob : 20,
    smallJob : 8
  }
}
variable "authorizer_settings" {
  type = map(object({
    reserved_concurrency    = number
    provisioned_concurrency = number
  }))
  default = {
    api-authorizer = {
      reserved_concurrency    = -1
      provisioned_concurrency = 0
    }
    webhook-authorizer = {
      reserved_concurrency    = -1
      provisioned_concurrency = 0
    }
  }
}
variable "authorizer_config" {
  default = {
    api = {
      name = "api-authorizer"
      type = "REQUEST"
      lambda = {
        type                           = "public"
        handler                        = "src/authorizer/authorizer.handler"
        timeout                        = 10
        use_iroh_jwks_uri              = true
        use_attempt_timeout_for_aws_sm = false
      }
    }
  }
}

variable "s3_bucket_tags" {
  type = map(string)

  default = {
    "DataClassification" = "Cisco Public"
    "ApplicationName"    = "posture"
    "ResourceOwner"      = "sxso infra"
    "CiscoMailAlias"     = "sxso-ops@cisco.com"
    "DataTaxonomy"       = "Cisco Operations Data"
  }
}

variable "s3_bucket_env" {
  type    = string
  default = "NonProd"
}
variable "rules_enabled" {
  default = false
}
