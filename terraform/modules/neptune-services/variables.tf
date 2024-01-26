variable "name_prefix" {
  type = string
}
variable "nodejs_runtime" {
  type = string
}
variable "env" {
  type = string
}
variable "systems_manager_prefix" {
  type = string
}
variable "lambda_layer_arn" {
  type = string
}
variable "neptune_cluster_resource_ids" {
  type = list(string)
}
variable "allow_neptune_services" {
  type = bool
}
