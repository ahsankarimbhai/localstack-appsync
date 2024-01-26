variable "lambdas" { type = list(object({
  lambda_arn    = string
  function_name = string
  event_input   = string
})) }
variable "rule_base_name" { type = string }
variable "schedule_expression" { type = string }
variable "enable_cloudwatch_rule" {
  type    = bool
  default = true
}
