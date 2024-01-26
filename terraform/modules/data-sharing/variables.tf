variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "name_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "neptune_cluster_resource_ids" { type = list(string) }
variable "api_gateway_request_validator_id" { type = string }
variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}
variable "iroh_uri" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "authorizer_id" { type = string }
variable "tenants_table_arn" { type = string }
variable "tenant_config_table_arn" { type = string }
variable "webhook_registration_table_arn" { type = string }
variable "webhook_notification_table_arn" { type = string }
variable "os_versions_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "label_metadata_arn" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "neptune_cluster_settings" { type = string }
variable "scheduled_task_metadata_table_arn" { type = string }
variable "aws_event_bus_scheduled_tasks_arn" { type = string }
variable "device_change_notification_event_bus_arn" { type = string }
variable "webhooks_apis" {
  default = {
    createWebhook = {
      path                               = "register"
      name                               = "ds-create-webhook"
      handler                            = "src/data-sharing.createWebhook"
      parent_path                        = "/webhooks"
      http_method                        = ["POST"]
      should_create_api_gateway_resource = true
    },
    handleWebhookById = {
      path                               = "{webhookId}"
      name                               = "ds-handle-webhook"
      handler                            = "src/data-sharing.handleWebhook"
      parent_path                        = "/webhooks"
      http_method                        = ["PUT", "GET", "DELETE"],
      should_create_api_gateway_resource = true,
      request_parameters = {
        "method.request.path.webhookId" = true
      },
      integration_request_parameters = {
        "integration.request.path.webhookId" = "method.request.path.webhookId"
      }
    },
    handleTenantWebhooks = {
      path                               = ""
      name                               = "ds-handle-tenant-webhooks"
      handler                            = "src/data-sharing.handleTenantWebhooks"
      parent_path                        = "/webhooks"
      http_method                        = ["GET", "DELETE"]
      should_create_api_gateway_resource = false
    }
  }
}
