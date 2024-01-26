variable "env" { type = string }
variable "name_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "lambda_layer_arn" { type = string }
variable "iroh_uri" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "systems_manager_prefix" { type = string }
variable "api_gateway_request_validator_id" { type = string }
variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}
variable "posture_url" { type = string }
variable "authorizer_id" { type = string }
variable "os_versions_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "tenant_config_arn" { type = string }
variable "vulnerability_table_arn" { type = string }
variable "label_metadata_arn" { type = string }
variable "neptune_cluster_resource_ids" { type = list(string) }
variable "neptune_cluster_settings" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "event_bridge_bus_arn" { type = string }
variable "rules_enabled" { type = bool }
variable "assets_api" {
  default = {
    health = {
      path        = "health"
      name        = "health"
      handler     = "src/assets.health"
      parent_path = "/"
    }
    assetsResolveLatest = {
      path        = "resolve-latest"
      name        = "assets-resolve-latest"
      handler     = "src/assets.resolveLatest"
      parent_path = "/assets"
    }
    assetsResolve = {
      path           = "resolve"
      name           = "assets-resolve"
      handler        = "src/assets.resolve"
      parent_path    = "/assets"
      access_neptune = true
    }
    assetsDescribe = {
      path           = "describe"
      name           = "assets-describe"
      handler        = "src/assets.describe"
      parent_path    = "/assets"
      access_neptune = true
    }
  }
}
