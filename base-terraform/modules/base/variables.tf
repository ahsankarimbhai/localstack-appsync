variable "base_name" { type = string }
variable "subnet_config" { type = map(map(string)) }
variable "combined_subnet_ranges" { type = map(string) }
variable "region_domain_map" { type = map(string) }
variable "service_discovery_hosted_zone" { type = string }
variable "turn_on_neptune_rebalance" {
  type    = bool
  default = false
}
variable "interface_vpc_endpoint_config" {
  type    = list(string)
  default = ["secretsmanager", "sns", "logs", "kinesis-streams", "lambda", "events", "monitoring", "states"]
}
variable "gateway_vpc_endpoint_config" {
  type    = list(string)
  default = ["s3", "dynamodb"]
}
variable "public_hosted_zone" {
  type    = string
  default = "mypostureservice.name"
}