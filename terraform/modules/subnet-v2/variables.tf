variable "vpc_id" { type = string }
variable "route_table_id" { type = string }
variable "cidr_block" { type = string }
variable "availability_zone" { type = string }
variable "tag_name" { type = string }


variable "map_public_ip_on_launch" {
  type    = bool
  default = false
}
