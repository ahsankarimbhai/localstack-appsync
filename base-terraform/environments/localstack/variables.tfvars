base_name                      = "posaas-localstack"
bastion_key_name               = "posaas-dev-bastion"
service_discovery_hosted_zone  = "posaas.localstack.internal"
logs_es_volume_size            = 150
search_instance_type           = "m6g.large.elasticsearch"
search_volume_size             = 50
neptune_engine_version         = "1.3.0.0"
neptune_port                   = "4510"
neptune_parameter_group_family = "neptune1.2"
create_es_backup               = false
indices                        = "posture-devices, posture-persons"
subnet_ids                     = [" "]
security_group_ids             = " "
neptune_clusters = {
  base = {
    // set name to empty to avoid changing any attribute name of existing base db cluster
    name               = ""
    instance_size      = 2
    instance_type      = "db.t3.medium"
    shard_id           = "1"
    traffic_proportion = null
  }
}
create_tenable_ec2             = false
create_di_ssm_role             = false
