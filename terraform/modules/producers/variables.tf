variable "name_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "umbrella_base_url" { type = string }
variable "umbrella_v2_base_url" { type = string }
variable "ms_graph_url" { type = string }
variable "meraki_base_url" { type = string }
variable "lambda_layer_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "os_versions_table_arn" { type = string }
variable "vulnerability_table_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "label_metadata_arn" { type = string }
variable "incident_mapping_arn" { type = string }
variable "function_state_table_arn" { type = string }
variable "scheduled_task_arn" { type = string }
variable "scheduled_task_metadata_arn" { type = string }
variable "saved_filter_arn" { type = string }
variable "graphql_api_id" { type = string }
variable "iam_role_arn" { type = string }
variable "api_gateway_endpoint" { type = string }
variable "should_create_fetch_posture_data_schedule" { type = bool }
variable "neptune_concurrency" { type = number }
variable "processing_internal_concurrency" { type = number }
variable "vulnerability_processing_internal_concurrency" { type = number }
variable "vulnerability_processing_concurrent_update_computers" { type = number }
variable "authorizers" { type = map(any) }
variable "iroh_uri" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "api_gateway_request_validator_id" { type = string }
variable "neptune_cluster_resource_ids" { type = list(string) }
variable "neptune_cluster_settings" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "event_bridge_bus_arn" { type = string }
variable "vulnerability_processing_batch_size" { type = number }
variable "vulnerability_processing_maximum_batching_window_in_seconds" { type = number }
variable "vulnerability_processing_parallelization_factor" { type = number }
variable "processing_maximum_batching_window_in_seconds" { type = number }
variable "webhook_registration_table_arn" { type = string }
variable "device_change_notification_event_bus_arn" { type = string }
variable "should_create_orbital_webhook_s3_bucket" { type = bool }
variable "should_throttle_vulnerability_lambda" {
  type    = bool
  default = false
}
variable "lambda_preprocessing_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_preprocessing_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_processing_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_processing_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_producer_notification_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_producer_notification_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "preprocessing_parallelization_factor" {
  type = number
}
variable "api_gateway" {
  type = object({
    id               = string,
    root_resource_id = string
  })
}
variable "should_create_development_api_gateway_endpoints" { type = bool }
variable "preprocessing_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "processing_kinesis_streams" {
  type = map(object({
    arn                    = string,
    name                   = string,
    parallelization_factor = number
  }))
}
variable "encoded_processing_stream_settings" {
  type = string
}
variable "vulnerability_processing_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "groups_fetcher_config" {
  default = {
    Umbrella = {
      topic_name = "umbrella"
      lambda = {
        name                  = "fetch-umbrella-groups"
        handler               = "src/index.fetchUmbrellaPolicies"
        use_umbrella_base_url = true
        timeout               = 180
      }
    }
  }
}
variable "fetcher_config" {
  default = {
    Generic = {
      topic_name = "generic"
      lambda = {
        name    = "fetch-generic-devices"
        handler = "src/index.fetchGenericDevices"
        timeout = 600
      }
    }
    AMP = {
      topic_name = "amp"
      lambda = {
        name    = "fetch-amp-computers"
        handler = "src/index.fetchAmpComputers"
        timeout = 180
      }
    }
    Defender = {
      topic_name = "defender"
      lambda = {
        name             = "fetch-defender-devices"
        handler          = "src/index.fetchDefenderDevices"
        use_ms_graph_url = true
        timeout          = 600
      }
    }
    DUO = {
      topic_name = "duo"
      lambda = {
        name    = "fetch-duo-endpoints"
        handler = "src/index.fetchDuoEndpoints"
        timeout = 180
      }
    }
    DUO_USERS = {
      topic_name = "duoUsers"
      lambda = {
        name    = "fetch-duo-users"
        handler = "src/index.fetchDuoUsers"
        timeout = 900
      }
    }
    JAMF = {
      topic_name = "jamf"
      lambda = {
        name    = "fetch-jamf-computers"
        handler = "src/index.fetchJamfComputers"
        timeout = 600
      }
    },
    InTune = {
      topic_name = "intune"
      lambda = {
        name             = "fetch-intune-devices"
        handler          = "src/index.fetchInTuneDevices"
        use_ms_graph_url = true
        timeout          = 600
      }
    }
    CyberVision = {
      topic_name = "cybervision"
      lambda = {
        name    = "fetch-cybervision-devices"
        handler = "src/index.fetchCyberVisionDevices"
        timeout = 600
      }
    }
    Meraki = {
      topic_name = "meraki"
      lambda = {
        name                = "fetch-meraki-devices"
        handler             = "src/index.fetchMerakiDevices"
        use_meraki_base_url = true
        timeout             = 600
      }
    },
    AirWatch = {
      topic_name = "airwatch"
      lambda = {
        name    = "fetch-air-watch-devices"
        handler = "src/index.fetchAirWatchDevices"
        timeout = 600
      }
    },
    UnifiedConnector = {
      topic_name = "unifiedConnector"
      lambda = {
        name    = "fetch-unified-connector-computers"
        handler = "src/index.fetchUnifiedConnectorComputers"
        timeout = 600
      }
    },
    Umbrella = {
      topic_name = "umbrella"
      lambda = {
        name                  = "fetch-umbrella-roaming-computers"
        handler               = "src/index.fetchUmbrellaRoamingComputers"
        use_umbrella_base_url = true
        timeout               = 900
      }
    }
    MobileIron = {
      topic_name = "mobileiron"
      lambda = {
        name    = "fetch-mobileiron-devices"
        handler = "src/index.fetchMobileIronDevices"
        timeout = 180
      }
    }
    ServiceNow = {
      topic_name = "servicenow"
      lambda = {
        name    = "fetch-service-now-devices"
        handler = "src/index.fetchServiceNowDevices"
        timeout = 180
      }
    }
    SentinelOne = {
      topic_name = "sentinelone"
      lambda = {
        name    = "fetch-sentinel-one-devices"
        handler = "src/index.fetchSentinelOneDevices"
        timeout = 900
      }
    }
    CrowdStrike = {
      topic_name = "crowdstrike"
      lambda = {
        name    = "fetch-crowd-strike-devices"
        handler = "src/index.fetchCrowdStrikeDevices"
        timeout = 180
      }
    }
    AzureUsers = {
      topic_name = "azureUsers"
      lambda = {
        name             = "fetch-azure-users"
        handler          = "src/index.fetchAzureUsers"
        use_ms_graph_url = true
        timeout          = 900
      }
    }
    TrendVisionOne = {
      topic_name = "trendvisionone"
      lambda = {
        name    = "fetch-trend-vision-one-devices"
        handler = "src/index.fetchTrendVisionOneDevices"
        timeout = 180
      }
    }
  }
}
variable "notification_config" {
  default = {
    ORBITAL = {
      api_gateway = {
        path               = "producer-notification"
        authorization_type = "CUSTOM"
        parent_path        = "/api"
        http_methods = [
          "GET",
          "POST"
        ]
        response_format = "json"
      }
      lambda = {
        type                           = "private"
        name                           = "producer-notification"
        handler                        = "src/fetchData.producerNotification"
        file_path                      = "../../../backend/dist/dataFetchers.zip"
        use_attempt_timeout_for_aws_sm = true
      }
    }
  }
}
variable "notification_config_development" {
  default = {
    DUO = {
      api_gateway = {
        path               = "duo-notification"
        authorization_type = "NONE"
        parent_path        = "/api"
        http_methods = [
          "POST"
        ]
        response_format = "json"
      }
      lambda = {
        type      = "private"
        name      = "duo-notification"
        handler   = "src/fetchData.duoNotification"
        file_path = "../../../backend/dist/dataFetchers.zip"
      }
    }
    ISE_SERVER_INFO = {
      api_gateway = {
        path               = "mdminfo"
        authorization_type = "NONE"
        parent_path        = "/ciscoise"
        http_methods = [
          "GET"
        ]
        response_format = "xml"
      }
      lambda = {
        type      = "private"
        name      = "ise-server-info"
        handler   = "src/ise-mdm.serverInfo"
        file_path = "../../../backend/dist/producers.zip"
      }
    }
    ISE_DEVICE_ATTRIBUTES = {
      api_gateway = {
        path               = "mdmapi"
        authorization_type = "NONE"
        parent_path        = "/ciscoise"
        http_methods = [
          "GET",
          "POST"
        ]
        response_format = "xml"
      }
      lambda = {
        type      = "private"
        name      = "ise-device-attributes"
        handler   = "src/ise-mdm.deviceAttributes"
        file_path = "../../../backend/dist/producers.zip"
      }
    }
  }
}
variable "rules_execution_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "rules_enabled" { type = bool }
