variable "name_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "label_metadata_arn" { type = string }
variable "rule_arn" { type = string }
variable "os_versions_table_arn" { type = string }
variable "iroh_uri" { type = string }
// variable "iroh_redirect_uri" { type = string }
variable "vulnerability_table_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "function_state_table_arn" { type = string }
variable "scheduled_task_arn" { type = string }
variable "scheduled_task_metadata_arn" { type = string }
variable "saved_filter_arn" { type = string }
variable "graphql_api_id" { type = string }
variable "iam_role_arn" { type = string }
variable "api_gateway_endpoint" { type = string }
// variable "producer_notification_url" { type = string }
// variable "orbital_webhook_notification_s3_bucket" { type = string }
// variable "aws_event_bus_scheduled_tasks_arn" { type = string }
// variable "event_bridge_bus_arn" { type = string }
variable "orbital_base_url" { type = string }
variable "graphql_api_lambda_timeout" { type = number }
variable "dynamodb_request_timeout_milliseconds" { type = number }
variable "webhook_registration_table_arn" { type = string }
// variable "device_change_notification_event_bus_arn" { type = string }
# variable "timestream_kinesis_stream" {
#   type = object({
#     arn  = string,
#     name = string
#   })
# }
variable "metric_period_in_days" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "incident_mapping_arn" { type = string }
// variable "neptune_cluster_resource_ids" { type = list(string) }
#variable "neptune_cluster_settings" { type = string }
variable "use_predefined_neptune_shard_id" { type = bool }
# variable "rules_execution_kinesis_stream" {
#   type = object({
#     arn  = string,
#     name = string
#   })
# }
# variable "encoded_processing_stream_settings" {
#   type = string
# }
variable "rules_enabled" { type = bool }
