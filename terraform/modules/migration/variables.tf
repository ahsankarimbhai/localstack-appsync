variable "env" {
  type = string
}
variable "systems_manager_prefix" {
  type = string
}
variable "nodejs_runtime" {
  type = string
}
variable "name_prefix" {
  type = string
}
variable "lambda_layer_arn" {
  type = string
}
variable "tenants_table_arn" {
  type = string
}
variable "groups_table_arn" {
  type = string
}
variable "policy_table_arn" {
  type = string
}
variable "tenants_config_table_arn" {
  type = string
}
variable "os_versions_table_arn" {
  type = string
}
variable "data_migration_task_table_arn" {
  type = string
}
variable "data_migration_task_metadata_table_arn" {
  type = string
}
variable "scheduled_task_table_arn" {
  type = string
}
variable "scheduled_task_metadata_table_arn" {
  type = string
}
variable "neptune_cluster_resource_ids" {
  type = list(string)
}
variable "neptune_cluster_settings" {
  type = string
}
variable "neptune_shard_table_arn" {
  type = string
}
variable "neptune_shard_migration_log_table_arn" {
  type = string
}
variable "neptune_shard_migration_log_detail_table_arn" {
  type = string
}
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "iroh_uri" {
  type = string
}
variable "iroh_redirect_uri" {
  type = string
}
variable "orbital_webhook_notification_s3_bucket" {
  type = string
}
variable "migration_scripts" {
  default = {
    retrofitNeptunePsCvEdgeProperty = {
      name              = "retrofit-neptune-ps-cv-edge-property"
      handler           = "src/migration.retrofitNeptunePsCvEdgeProperty"
      lambda_type       = "public"
      memory_size       = 128
      allow_concurrency = true
      access_neptune    = true
    },
    extendMigrationTaskTTL = {
      name        = "extend-migration-task-ttl"
      handler     = "src/migration.extendMigrationTaskTTL"
      lambda_type = "public"
      memory_size = 128
    },
    restartFailedMigrationTask = {
      name        = "restart-failed-migration-task"
      handler     = "src/migration.restartFailedMigrationTask"
      lambda_type = "public"
      memory_size = 128
    },
    balanceTenantShardTask = {
      name        = "balance-tenant-shard-task"
      handler     = "src/migration.balanceTenantShardTask"
      lambda_type = "public"
      memory_size = 512
    },
    truncateTenantNeptuneData = {
      name                  = "truncate-tenant-neptune-data"
      handler               = "src/migration.truncateTenantNeptuneData"
      lambda_type           = "public"
      memory_size           = 512
      allow_concurrency     = true
      access_neptune        = true
      neptune_query_timeout = 120000
    },
    refreshOrbitalWebhookCredential = {
      name                          = "refresh-orbital-webhook-credential"
      handler                       = "src/migration.refreshOrbitalWebhookCredential"
      lambda_type                   = "public"
      memory_size                   = 512
      use_orbital_webhook_s3_bucket = true
    },
  }
}
