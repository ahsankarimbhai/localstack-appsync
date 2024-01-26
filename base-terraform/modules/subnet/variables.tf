variable "prefix" { type = string }
variable "base_name" { type = string }
variable "vpc_id" { type = string }
variable "route_table_ids" { type = list(string) }
variable "num_az_zones" { type = number }
variable "az_subname_map" { type = map(string) }
variable "subnet_config" { type = map(string) }
variable "map_public_ip_on_launch" {
  type    = bool
  default = false
}
