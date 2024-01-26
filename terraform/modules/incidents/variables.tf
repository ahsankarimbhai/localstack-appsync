variable "name_prefix" { type = string }
variable "env" { type = string }
variable "nodejs_runtime" { type = string }
variable "systems_manager_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "authorizer_id" { type = string }
variable "api_gateway_request_validator_id" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "incident_mapping_arn" { type = string }
variable "iroh_uri" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}
variable "device_change_notification_event_bus_arn" {
  type = string
}
variable "incident_api" {
  default = {
    mapIncidentToIdentities = {
      path        = "map-incident-to-identities"
      name        = "map-incident-to-identities"
      handler     = "src/incidents.mapIncidentToIdentities"
      parent_path = "/incidents"
    }
    mapIncidentsToUnresolvedIdentity = {
      path        = "map-incidents-to-unresolved-identity"
      name        = "map-incidents-to-unresolved-identity"
      handler     = "src/incidents.mapIncidentsToUnresolvedIdentity"
      parent_path = "/incidents"
    }
  }
}
