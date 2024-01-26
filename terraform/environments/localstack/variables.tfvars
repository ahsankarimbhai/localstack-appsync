env                                             = "localstack"
iroh_env                                        = "localstack"
allow_neptune_services                          = true
allow_es_tenant_data_cleanup                    = true
allow_es_tenant_person_cleanup                  = true
deploy_mock_uc_api                              = true
cloudfront_apps_subdomain                       = "localstack"
global_iroh_module_type_id                      = "b95d5cd0-5bcb-45f6-921c-e2777468f6b0"
authorizer_api_allowed_client_ids               = "client-112935af-985c-447b-9523-c7dac97442e0,client-0d064eed-7582-4124-b410-898b04a8ca38,client-9e730903-38a2-48b2-af16-a91c67e3c276,client-1f6426ec-b37d-4188-8ddb-afdf1ab0991d,client-760e29d7-3985-4af7-89ea-85d9668f1b8b,client-472a64a1-cd25-41ae-9aaa-2f332260d984,client-d2a149f2-3a8e-42fc-8784-247c12a03d34"
processing_internal_concurrency                 = 2
should_create_development_api_gateway_endpoints = true
graphql_api_lambda_timeout                      = 600
rules_enabled                                   = true

#base_name                      = "posaas-localstack"
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