variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "base_name" {
  type    = string
  default = "posaas"
}
variable "env" {
  type = string
}
variable "graphql_api_lambda_timeout" {
  type    = number
  default = 60
}
variable "sandbox_prefix" {
  type    = string
  default = ""
}
variable "api_gateway_cert_domain" {
  type    = string
  default = "mypostureservice.name"
}
variable "api_gateway_domain_name" {
  type    = string
  default = ""
}
variable "authorizer_api_allowed_client_ids" {
  type    = string
  default = ""
}
variable "public_hosted_zone" {
  type    = string
  default = "mypostureservice.name"
}

variable "api_gateway_stage_name" {
  type    = string
  default = "default"
}
variable "block_introspection_queries" {
  type    = bool
  default = false
}
variable "authorizer_settings" {
  type = map(object({
    reserved_concurrency    = number
    provisioned_concurrency = number
  }))
  default = {
    api-authorizer = {
      reserved_concurrency    = -1
      provisioned_concurrency = 0
    }
  }
}
variable "authorizer_config" {
  default = {
    api = {
      name = "api-authorizer"
      type = "REQUEST"
      lambda = {
        type                           = "public"
        handler                        = "src/authorizer/authorizer.handler"
        timeout                        = 10
        use_iroh_jwks_uri              = true
        use_attempt_timeout_for_aws_sm = false
      }
    }
  }
}
