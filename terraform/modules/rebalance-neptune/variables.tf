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
variable "neptune_cluster_resource_ids" {
  type = list(string)
}
variable "enable_neptune_rebalance_auto_throttler" {
  type    = bool
  default = false
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
variable "neptune_rebalance_settings" {
  type = string
}
variable "max_tenants_in_migration" {
  type    = number
  default = 2
}
variable "max_export_vertices_in_migration" {
  type    = number
  default = 1000000
}
variable "max_export_vertices_chunk_size" {
  type = number
}
variable "neptune_export_service_lambda_name" {
  type = string
}
variable "neptune_export_status_service_lambda_name" {
  type = string
}
variable "neptune_export_service_concurrency_setting" {
  type = object({
    xlargeJob = number,
    largeJob  = number
    mediumJob = number
    smallJob  = number
  })
}
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "enable_neptune_migration_state_tracker" {
  type = bool
}
variable "neptune_query_timeout" {
  type    = number
  default = 300000
}
