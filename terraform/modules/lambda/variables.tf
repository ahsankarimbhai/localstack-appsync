variable "name_prefix" { type = string }
variable "lambda_type" { type = string }
variable "function_name" { type = string }
variable "iam_role_arn" { type = string }
variable "handler" { type = string }
variable "nodejs_runtime" { type = string }
variable "lambda_file_path" { type = string }
variable "systems_manager_prefix" { type = string }
variable "env" { type = string }
variable "publish" {
  type    = bool
  default = false
}
variable "concurrent_executions" {
  type    = number
  default = -1
}
variable "maximum_retry_attempts" {
  type    = number
  default = 0
}
variable "memory_size" {
  type    = number
  default = 128
}
variable "lambda_environment" {
  type    = map(string)
  default = {}
}
variable "layers" {
  type    = list(string)
  default = []
}
variable "lambda_timeout" {
  type    = number
  default = 3
}
