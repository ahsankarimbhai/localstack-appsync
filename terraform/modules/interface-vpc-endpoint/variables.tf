variable "base_name" { type = string }
variable "service_name" { type = string }
variable "vpc_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "subnet_ids" { type = list(string) }
