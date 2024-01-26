variable "env" { type = string }
variable "name_prefix" { type = string }
variable "should_enable_iroh_token_request" { type = bool }
variable "nodejs_runtime" { type = string }
variable "lambda_layer_arn" { type = string }
variable "systems_manager_prefix" { type = string }
variable "tenants_table_arn" { type = string }
variable "scheduled_task_arn" { type = string }
variable "scheduled_task_metadata_arn" { type = string }
variable "api_gateway_request_validator_id" { type = string }
variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}
variable "iroh_uri" { type = string }
#variable "iroh_redirect_uri" { type = string }
