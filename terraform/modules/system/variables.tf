variable "name_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "scheduled_task_arn" { type = string }
variable "scheduled_task_metadata_arn" { type = string }
variable "neptune_cluster_resource_ids" { type = list(string) }
variable "neptune_cluster_settings" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "rule_arn" { type = string }
variable "event_bridge_bus_arn" { type = string }
variable "authorizers" { type = map(any) }
variable "should_create_development_api_gateway_endpoints" { type = bool }

variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}

variable "system_config" {
  default = {
    modulesSync = {
      api_gateway = {
        path                               = "module-update"
        authorization_type                 = "CUSTOM"
        should_create_api_gateway_resource = true
        http_methods = [
          "POST"
        ]
        response_format = "json"
      }
      lambda = {
        type    = "private"
        name    = "system-modules-updated"
        handler = "src/system.modulesUpdated"
      }
    }
  }
}

variable "system_config_development" {
  default = {
    DEACTIVATE = {
      api_gateway = {
        path                               = "tenant"
        authorization_type                 = "CUSTOM"
        should_create_api_gateway_resource = false
        http_methods = [
          "DELETE"
        ]
        response_format = "json"
      }
      lambda = {
        type                  = "private"
        name                  = "deactivate-tenant"
        handler               = "src/system.deactivateTenant"
        access_elastic_search = true
      }
    }
  }
}
