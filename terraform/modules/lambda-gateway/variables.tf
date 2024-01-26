variable "lambda_invoke_arn" {
  type    = string
  default = ""
}
variable "rest_api_id" { type = string }
variable "rest_api_parent_path" { type = string }
variable "path_part" { type = string }
variable "allow_methods" {
  type    = string
  default = "'OPTIONS,GET'"
}
variable "full_function_name" {
  type    = string
  default = ""
}
variable "name_prefix" { type = string }
variable "http_method" {
  type    = list(string)
  default = ["POST"]
}
variable "response_format" {
  type    = string
  default = "json"
}
variable "authorizer_id" {
  type    = string
  default = null
}
variable "integration_request_parameters" {
  type    = map(string)
  default = {}
}
variable "request_validator_id" {
  type    = string
  default = null
}
variable "request_parameters" {
  type    = map(string)
  default = {}
}
variable "cors_disabled" {
  type    = bool
  default = false
}
variable "authorization_type" {
  type    = string
  default = "CUSTOM"
}
variable "should_create_api_gateway_resource" {
  type    = bool
  default = true
}
variable "function_qualifier" {
  type    = string
  default = null
}
