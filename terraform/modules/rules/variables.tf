variable "name_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "rules_table_arn" { type = string }
variable "os_versions_table_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "iam_role_arn" { type = string }
variable "webhook_registration_table_arn" { type = string }
variable "device_change_notification_event_bus_arn" { type = string }
variable "rules_execution_internal_concurrency" { type = number }
variable "lambda_rules_execution_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_rules_execution_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "rules_execution_maximum_batching_window_in_seconds" {
  type    = number
  default = 60
}
variable "parallelization_factor" {
  type = number
}
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "rules_execution_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "event_bridge_bus_arn" {
  type = string
}
variable "delay_in_millis" {
  type = number
}
