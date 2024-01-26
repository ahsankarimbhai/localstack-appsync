variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "base_name" { type = string }
variable "combined_subnet_ranges" {
  type = map(string)

  default = {
    "VPC"           = "10.210.0.0/16"
    "public-tools"  = "10.210.0.0/20"
    "private-tools" = "10.210.16.0/20"
    "private-sm"    = "10.210.32.0/24"
  }
}
variable "subnet_config" {
  type = map(map(string))

  default = {
    "a" = {
      name                = "AZa"
      "public-tools"      = "10.210.0.0/21"
      "private-tools"     = "10.210.16.0/21"
      "private-endpoints" = "10.210.32.0/25"
      "public"            = "10.210.33.0/25"
    }
    "b" = {
      name                = "AZb"
      "public-tools"      = "10.210.8.0/21"
      "private-tools"     = "10.210.24.0/21"
      "private-endpoints" = "10.210.32.128/25"
      "public"            = "10.210.33.128/25"
    }
  }
}
variable "region_domain_map" {
  type = map(string)

  default = {
    us-east-1      = "ec2.internal"
    us-east-2      = "us-east-2.compute.internal"
    eu-central-1   = "eu-central-1.compute.internal"
    ap-southeast-2 = "ap-southeast-2.compute.internal"
  }
}
variable "logs_es_instance_count" {
  type    = number
  default = 1
}
variable "logs_es_instance_type" {
  type    = string
  default = "t3.medium.elasticsearch"
}
variable "logs_es_volume_size" {
  type    = number
  default = 35
}
variable "cognito_user_pool_id" {
  type    = string
  default = "us-east-1_v1mSmRzUs"
}
variable "cognito_identity_pool_id" {
  type    = string
  default = "us-east-1:f1af4a88-ce36-450a-a208-549971441f38"
}
variable "cognito_role_arn" {
  type    = string
  default = "arn:aws:iam::578161469167:role/cognito-access-for-amazon-es"
}
variable "neptune_clusters" {
  type = map(object({
    name               = string
    instance_size      = number
    instance_type      = string
    shard_id           = string
    traffic_proportion = number
  }))
  default = {
    base = {
      // set name to empty to avoid changing any attribute name of existing base db cluster
      name               = ""
      instance_size      = 1
      instance_type      = "db.t3.medium"
      shard_id           = "1"
      traffic_proportion = null
    }
  }
}
variable "neptune_engine_version" {
  type    = string
  default = "1.0.5.0"
}
variable "neptune_parameter_group_family" {
  type    = string
  default = "neptune1"
}
variable "turn_on_neptune_rebalance" {
  type    = bool
  default = false
}
variable "neptune_rebalance_query_timeout" {
  type    = string
  default = "10800000"
}
variable "neptune_port" {
  type    = number
  default = 8182
}
variable "bastion_key_name" {
  type = string
}
variable "service_discovery_hosted_zone" {
  type = string
}
variable "public_hosted_zone" {
  type    = string
  default = "mypostureservice.name"
}
variable "search_instance_count" {
  type    = number
  default = 1
}
variable "search_instance_type" {
  type    = string
  default = "t3.medium.elasticsearch"
}
variable "search_volume_size" {
  type    = number
  default = 35
}
variable "search_zone_awareness_enabled" {
  type    = bool
  default = false
}
variable "log_shipper_reserved_concurrent_executions" {
  default = -1
}
variable "node_to_node_encryption_enabled" {
  type    = bool
  default = true
}
variable "encrypt_at_rest_enabled" {
  type    = bool
  default = true
}

variable "create_es_backup" {
  type    = bool
  default = false
}

variable "indices" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = string
}

variable "create_tenable_ec2" {
  type    = bool
  default = false
}

variable "tenable_private_ip" {
  type    = string
  default = "10.210.4.213"
}
variable "create_memorydb_cluster" {
  type    = bool
  default = false
}

variable "create_di_ssm_role" {
  type = bool
}