variable "name_prefix" { type = string }
variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "api_gateway" { type = object({ id = string, arn = string }) }
variable "api_gateway_api_resource_id" { type = string }
variable "api_authorizer_id" { type = string }
variable "api_gateway_request_validator_id" { type = string }
variable "block_introspection_queries" {
  type    = bool
  default = false
}
