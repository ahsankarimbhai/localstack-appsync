variable "name_prefix" { type = string }
variable "env" { type = string }
variable "authorizer_name" { type = string }
variable "authorizer_type" { type = string }
variable "nodejs_runtime" { type = string }
variable "lambda_layer_arn" { type = string }
variable "systems_manager_prefix" { type = string }
variable "api_allowed_client_ids" { type = string }
variable "reserved_concurrency" {
  type    = number
  default = -1
}
variable "provisioned_concurrency" {
  type    = number
  default = 0
}
variable "api_gateway" {
  type = object({
    id  = string
    arn = string
  })
}
variable "lambda" {
  type = object({
    type                           = string
    handler                        = string
    timeout                        = number
    use_iroh_jwks_uri              = bool
    use_attempt_timeout_for_aws_sm = bool
  })
}
