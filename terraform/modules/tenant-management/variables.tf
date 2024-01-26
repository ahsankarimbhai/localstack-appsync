variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "name_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "scheduled_task_arn" { type = string }
variable "scheduled_task_metadata_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "graphql_api_id" { type = string }
variable "iam_role_arn" { type = string }
variable "aws_event_bus_scheduled_tasks_arn" { type = string }
variable "producer_notification_url" { type = string }
variable "orbital_webhook_notification_s3_bucket" { type = string }
variable "function_state_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "iroh_uri" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "saved_filter_arn" { type = string }
variable "allow_es_tenant_data_cleanup" { type = bool }
variable "allow_es_tenant_person_cleanup" { type = bool }
variable "neptune_cluster_settings" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "use_predefined_neptune_shard_id" { type = bool }
variable "label_metadata_arn" { type = string }
variable "event_bridge_bus_arn" { type = string }
variable "metric_period_in_days" { type = string }
variable "rules_enabled" { type = bool }
variable "rule_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "incident_mapping_arn" { type = string }
variable "device_change_notification_event_bus_arn" { type = string }
variable "webhook_registration_table_arn" { type = string }
variable "rules_execution_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "tenant_management_functions" {
  default = {
    createTenant = {
      name                         = "create-tenant"
      handler                      = "src/tenant-management.createTenant"
      access_neptune               = true
      use_predefined_neptune_shard = true
    }
    listTenants = {
      name    = "list-tenants"
      handler = "src/tenant-management.listTenants"
    }
    deleteTenant = {
      name             = "delete-tenant"
      handler          = "src/tenant-management.deleteTenant"
      timeout          = 120
      is_public_lambda = true
    }
    removeProducerConfiguration = {
      name                       = "remove-producer-configuration"
      handler                    = "src/tenant-management.removeProducerConfiguration"
      use_notification_event_bus = true
      timeout                    = 60
      is_public_lambda           = true
      access_elastic_search      = true
    }
    removeProducerFromAllTenants = {
      name                       = "remove-producer-for-all-tenants"
      handler                    = "src/tenant-management.removeProducerFromAllTenants"
      use_notification_event_bus = true
      timeout                    = 900
      is_public_lambda           = true
      access_elastic_search      = true
    }
    clearSetupStatusForAllTenants = {
      name                       = "clear-setup-status-for-all"
      handler                    = "src/tenant-management.clearSetupStatusForAllTenants"
      use_notification_event_bus = true
      timeout                    = 900
      is_public_lambda           = true
    }
    removeAllProducersForTenant = {
      name                       = "remove-all-producers-for-tenant"
      handler                    = "src/tenant-management.removeAllProducersForTenant"
      use_notification_event_bus = true
      timeout                    = 600
      is_public_lambda           = true
      access_elastic_search      = true
    }
    removeCurrentStateForFunctionAndProducer = {
      name             = "remove-current-state-function-and-producer"
      handler          = "src/tenant-management.removeCurrentStateForFunctionAndProducer"
      timeout          = 900
      is_public_lambda = true
    }
    migrateTenantsToNewRegistrationFlow = {
      name                       = "migrate-tenants-to-new-registration-flow"
      handler                    = "src/tenant-management.migrateTenantsToNewRegistrationFlow"
      use_notification_event_bus = true
      timeout                    = 900
      is_public_lambda           = true
    }
    updateOrbitalQueryForAllTenants = {
      name                       = "update-orbital-query-for-all"
      handler                    = "src/tenant-management.updateOrbitalQueryForAllTenants"
      memorySize                 = 256
      use_notification_event_bus = true
      timeout                    = 900
      is_public_lambda           = true
    }
    rescheduleExpiringOrbitalQueries = {
      name                       = "reschedule-expiring-orbital-queries"
      handler                    = "src/tenant-management.rescheduleExpiringOrbitalQueries"
      use_notification_event_bus = true
      timeout                    = 900
      is_public_lambda           = true
    }
    updateOrbitalSecretsForAllTenants = {
      name                          = "update-orbital-secrets-for-all"
      handler                       = "src/tenant-management.updateOrbitalSecretsForAllTenants"
      memorySize                    = 256
      use_notification_event_bus    = true
      timeout                       = 900
      is_public_lambda              = true
      use_producer_notification_url = true
    }
    updateWebhookForAllTenants = {
      name                          = "update-query-for-all"
      handler                       = "src/tenant-management.updateWebhookForAllTenants"
      use_notification_event_bus    = true
      timeout                       = 900
      is_public_lambda              = true
      use_producer_notification_url = true
    }
    updateWebhookForAllTenantsByShards = {
      name                          = "update-query-for-all-sharded"
      handler                       = "src/tenant-management.updateWebhookForAllTenantsByShards"
      use_notification_event_bus    = true
      timeout                       = 900
      is_public_lambda              = true
      use_producer_notification_url = true
    }
    registerWebhooks = {
      name                          = "register-webhooks"
      handler                       = "src/tenant-management.registerWebhooks"
      use_producer_notification_url = true
      timeout                       = 60
      is_public_lambda              = true
    }
    deleteWebhooks = {
      name                          = "delete-webhooks"
      handler                       = "src/tenant-management.deleteWebhooks"
      use_producer_notification_url = true
      timeout                       = 60
      is_public_lambda              = true
    }
    deleteFailingWebhooks = {
      name                          = "delete-failing-webhooks"
      handler                       = "src/tenant-management.deleteFailingWebhooks"
      use_producer_notification_url = true
      timeout                       = 60
      is_public_lambda              = true
    }
    cleanupSchedulingTimes = {
      name    = "cleanup-scheduling-times"
      handler = "src/tenant-management.cleanupSchedulingTimes"
      timeout = 900
    }
    addTenantFeatureFlag = {
      name    = "add-tenant-feature-flag"
      handler = "src/tenant-management.addTenantFeatureFlags"
    }
    listTenantFeatureFlag = {
      name    = "list-tenant-feature-flag"
      handler = "src/tenant-management.listTenantFeatureFlags"
    }
    removeTenantFeatureFlag = {
      name    = "remove-tenant-feature-flag"
      handler = "src/tenant-management.removeTenantFeatureFlags"
    }
    enableFeatureFlagForAllTenants = {
      name    = "enable-feature-flag-for-all-tenants"
      handler = "src/tenant-management.enableFeatureFlagForAllTenants"
    }
    disableFeatureFlagForAllTenants = {
      name    = "disable-feature-flag-for-all-tenants"
      handler = "src/tenant-management.disableFeatureFlagForAllTenants"
    }
    getTenantByExtId = {
      name    = "get-tenant-by-extid"
      handler = "src/tenant-management.getTenantByExtId"
    }
    setSXModuleInstanceId = {
      name    = "set-sx-module-instance-id"
      handler = "src/tenant-management.setSXModuleInstanceId"
    }
    removeLabelsProcessing = {
      name                                     = "processing-for-labels-deletion"
      handler                                  = "src/tenant-management.removeLabelsProcessing"
      timeout                                  = 900
      is_public_lambda                         = true
      use_device_change_notification_event_bus = true
      access_elastic_search                    = true
    }
    fetchAndNotifyDevices = {
      name                                     = "fetch-and-notify-devices"
      handler                                  = "src/tenant-management.fetchAndNotifyDevices"
      timeout                                  = 900
      memorySize                               = 256
      is_public_lambda                         = true
      use_device_change_notification_event_bus = true
      access_elastic_search                    = true

    }
  }
}

variable "tenant_migration_functions" {
  default = {
  }
}
