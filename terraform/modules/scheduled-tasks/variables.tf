variable "env" { type = string }
variable "systems_manager_prefix" { type = string }
variable "nodejs_runtime" { type = string }
variable "name_prefix" { type = string }
variable "lambda_layer_arn" { type = string }
variable "tenants_table_arn" { type = string }
variable "tenants_config_table_arn" { type = string }
variable "groups_table_arn" { type = string }
variable "policy_table_arn" { type = string }
variable "os_versions_table_arn" { type = string }
variable "function_state_table_arn" { type = string }
variable "scheduled_task_table_arn" { type = string }
variable "scheduled_task_metadata_table_arn" { type = string }
variable "data_migration_task_table_arn" { type = string }
variable "data_migration_task_metadata_table_arn" { type = string }
variable "label_metadata_arn" { type = string }
variable "graphql_api_id" { type = string }
variable "appsync_iam_role_arn" { type = string }
variable "iroh_uri" { type = string }
variable "orbital_base_url" { type = string }
variable "iroh_redirect_uri" { type = string }
variable "timestream_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "should_create_trigger_scheduled_tasks_schedule" { type = bool }
variable "amp_sns_topic_arn" { type = string }
variable "jamf_sns_topic_arn" { type = string }
variable "unifiedConnector_sns_topic_arn" { type = string }
variable "producer_notification_url" { type = string }
variable "orbital_webhook_notification_s3_bucket" { type = string }
variable "aws_event_bus_scheduled_tasks_arn" { type = string }
variable "event_bridge_bus_arn" { type = string }
variable "rules_clean_discrepancies_failure_handler_arn" { type = string }
variable "ms_graph_url" {
  type    = string
  default = "https://graph.microsoft.com"
}
variable "lambda_iroh_sync_producers_provisioned_concurrency" {
  type    = number
  default = 0
}
variable "lambda_iroh_sync_producers_reserved_concurrency" {
  type    = number
  default = -1
}
variable "lambda_rules_changes_handling_internal_concurrency" {
  type    = number
  default = 1
}
variable "vulnerability_processing_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "rules_execution_kinesis_stream" {
  type = object({
    arn  = string,
    name = string
  })
}
variable "neptune_cluster_resource_ids" { type = list(string) }
variable "neptune_cluster_settings" { type = string }
variable "neptune_shard_table_arn" { type = string }
variable "rules_table_arn" { type = string }
variable "incident_mapping_arn" { type = string }
variable "webhook_registration_table_arn" { type = string }
variable "device_change_notification_event_bus_arn" { type = string }
variable "delay_in_millis" { type = number }
variable "rules_enabled" { type = bool }
variable "max_allowed_concurrent_migration_tasks" {
  type = number
}
variable "should_throttle_vulnerability_lambda" {
  type    = bool
  default = false
}
variable "update_webhook_source_options" {
  type = string
}
variable "scheduled_tasks" {
  default = {
    trigger-data-migration = {
      event_bridge_rule = "trigger-data-migration"
      lambda = {
        name                               = "trigger-data-migration"
        handler                            = "src/migration.triggerDataMigration"
        file_path                          = "../../../backend/dist/producers.zip"
        type                               = "private"
        allowed_concurrent_migration_tasks = true
        trigger_state_machine_execution    = true
      }
    }
    deleteTenantData = {
      event_bridge_rule = "delete-tenant-data"
      lambda = {
        name                  = "delete-tenant-data"
        handler               = "src/scheduled-tasks.deleteTenantData"
        file_path             = "../../../backend/dist/producers.zip"
        type                  = "private"
        access_neptune        = true
        access_elastic_search = true
      }
    }
    cleanupRedundanciesFromES = {
      event_bridge_rule = "cleanup-redundancies-from-ES"
      lambda = {
        name                  = "cleanup-redundancies-from-ES"
        handler               = "src/scheduled-tasks.cleanupRedundanciesFromES"
        file_path             = "../../../backend/dist/producers.zip"
        type                  = "public"
        access_neptune        = true
        access_elastic_search = true
      }
    }
    triggerDeleteStaleTenantData = {
      event_bridge_rule = "trigger-delete-stale-tenant-data"
      lambda = {
        name                       = "trigger-delete-stale-tenant-data"
        handler                    = "src/scheduled-tasks.triggerDeleteStaleTenantData"
        file_path                  = "../../../backend/dist/producers.zip"
        type                       = "private"
        use_notification_event_bus = true
        access_elastic_search      = true
      }
    }
    updateStaleDevices = {
      event_bridge_rule = "update-stale-devices"
      is_scalable       = true
      lambda = {
        name                                     = "update-stale-devices"
        handler                                  = "src/scheduled-tasks.updateStaleDevices"
        file_path                                = "../../../backend/dist/producers.zip"
        type                                     = "public"
        memory_size                              = 256
        access_neptune                           = true
        access_elastic_search                    = true
        use_device_change_notification_event_bus = true
      }
    }
    syncNeptuneToEsDifference = {
      event_bridge_rule = "neptune-to-es-diff-sync-task"
      lambda = {
        name                  = "neptune-to-es-diff-sync-task"
        handler               = "src/scheduled-tasks.syncNeptuneToEsDifference"
        file_path             = "../../../backend/dist/producers.zip"
        type                  = "private"
        access_neptune        = true
        access_elastic_search = true
      }
    }
    deleteOldHistoricalData = {
      event_bridge_rule = "delete-old-data"
      is_scalable       = false
      lambda = {
        name                  = "delete-old-data"
        handler               = "src/scheduled-tasks.deleteOldHistoricalData"
        file_path             = "../../../backend/dist/producers.zip"
        type                  = "public"
        memory_size           = 150
        access_neptune        = true
        access_elastic_search = true
      }
    }
    cleanupShadowSources = {
      event_bridge_rule = "cleanup-shadow-sources"
      is_scalable       = false
      lambda = {
        name                                     = "cleanup-shadow-sources"
        handler                                  = "src/scheduled-tasks.cleanupShadowSources"
        file_path                                = "../../../backend/dist/producers.zip"
        type                                     = "public"
        memory_size                              = 256
        access_neptune                           = true
        access_elastic_search                    = true
        use_device_change_notification_event_bus = true
      }
    }
    clearESTasksIndex = {
      event_bridge_rule = "clear-es-tasks-index"
      lambda = {
        name        = "clear-es-tasks-index"
        handler     = "src/scheduled-tasks.clearEsTasksIndex"
        file_path   = "../../../backend/dist/producers.zip"
        type        = "public"
        memory_size = 128
      }
    }
    cleanLabelsOnAllDevicesFromNoLongerExisting = {
      event_bridge_rule = "clean-old-labels"
      lambda = {
        name                  = "clean-old-labels"
        handler               = "src/scheduled-tasks.cleanLabelsOnAllDevicesFromNoLongerExisting"
        file_path             = "../../../backend/dist/producers.zip"
        type                  = "public"
        memory_size           = 256
        access_elastic_search = true
      }
    }
    cleanupDeletedSourcesForAllTenants = {
      event_bridge_rule = "cleanup-del-src-for-all"
      lambda = {
        name                       = "cleanup-del-src-for-all"
        handler                    = "src/scheduled-tasks.cleanupDeletedSourcesForAllTenants"
        file_path                  = "../../../backend/dist/producers.zip"
        type                       = "public"
        use_notification_event_bus = true
        access_neptune             = true
        access_elastic_search      = true
      }
    }
    closeProducerCurrentStates = {
      event_bridge_rule = "close-producer-current-states"
      is_scalable       = false
      lambda = {
        name                                     = "close-producer-current-states"
        handler                                  = "src/scheduled-tasks.closeProducerCurrentStates"
        file_path                                = "../../../backend/dist/producers.zip"
        type                                     = "private"
        memory_size                              = 256
        access_neptune                           = true
        access_elastic_search                    = true
        use_device_change_notification_event_bus = true
      }
    },
    fetchAmpVulnerabilities = {
      event_bridge_rule = "fetch-amp-vulnerabilities"
      lambda = {
        name                       = "fetch-amp-vulnerabilities"
        handler                    = "src/index.fetchAmpVulnerabilities"
        file_path                  = "../../../backend/dist/producers.zip"
        type                       = "public"
        use_amp_sns_topic_arn      = true
        memory_size                = 256
        is_vulnerability_throttled = true
      }
    },
    fetchAmpGroups = {
      event_bridge_rule = "fetch-amp-groups"
      lambda = {
        name      = "fetch-amp-groups"
        handler   = "src/index.fetchAmpGroups"
        file_path = "../../../backend/dist/producers.zip"
        type      = "public"
      }
    },
    fetchAmpPolicies = {
      event_bridge_rule = "fetch-amp-policies"
      lambda = {
        name      = "fetch-amp-policies"
        handler   = "src/index.fetchAmpPolicies"
        file_path = "../../../backend/dist/producers.zip"
        type      = "public"
      }
    },
    liveOrbitalQuery = {
      event_bridge_rule = "live-orbital-query"
      lambda = {
        name                                     = "live-orbital-query"
        handler                                  = "src/index.liveOrbitalQuery"
        file_path                                = "../../../backend/dist/producers.zip"
        type                                     = "public"
        use_orbital_url                          = true
        access_neptune                           = true
        access_elastic_search                    = true
        use_device_change_notification_event_bus = true
      }
    },
    fetchDuoVersions = {
      event_bridge_rule = "fetch-duo-versions"
      lambda = {
        name      = "fetch-duo-versions"
        handler   = "src/index.fetchDuoVersions"
        file_path = "../../../backend/dist/producers.zip"
        type      = "public"
      }
    },
    updateAllRelevantScheduling = {
      event_bridge_rule = "update_relevant_scheduling"
      lambda = {
        name        = "update_relevant_scheduling"
        handler     = "src/scheduled-tasks.updateAllRelevantScheduling"
        file_path   = "../../../backend/dist/producers.zip"
        type        = "private"
        memory_size = 256
      }
    },
    syncIrohModuleInstances = {
      event_bridge_rule = "iroh-sync-producers"
      lambda = {
        name                               = "iroh-sync-producers"
        handler                            = "src/index.syncIrohModuleInstances"
        file_path                          = "../../../backend/dist/producers.zip"
        type                               = "public"
        use_iroh_url                       = true
        use_orbital_url                    = true
        use_notification_event_bus         = true
        use_producer_notification_url      = true
        use_amp_sns_topic_arn              = true
        use_jamf_sns_topic_arn             = true
        use_unifiedConnector_sns_topic_arn = true
        access_elastic_search              = true
      }
    },
    rulesChangesHandling = {
      event_bridge_rule = "rules-changes-handling"
      lambda = {
        name                                        = "rules-changes-handling"
        handler                                     = "src/rules.rulesChangesHandling"
        file_path                                   = "../../../backend/dist/rules.zip"
        type                                        = "private"
        memory_size                                 = 512
        rules_changes_handling_internal_concurrency = true
        access_elastic_search                       = true
        use_delay                                   = true
      }
    },
    rulesCleanDiscrepancies = {
      event_bridge_rule = "rules-clean-discrepancies"
      lambda = {
        name             = "rules-clean-discrepancies"
        handler          = "src/rules.rulesCleanDiscrepancies"
        file_path        = "../../../backend/dist/rules.zip"
        type             = "private"
        use_destinations = true
      }
    },
    rulesCleanDevicesDiscrepancies = {
      event_bridge_rule = "rules-clean-devices-discrepancies"
      lambda = {
        name                  = "rules-clean-devices-discrepancies"
        handler               = "src/rules.rulesCleanDevicesDiscrepancies"
        file_path             = "../../../backend/dist/rules.zip"
        type                  = "private"
        memory_size           = 512
        access_elastic_search = true
      }
    },
    updateTenantWebhooks = {
      event_bridge_rule = "update-tenant-webhooks"
      lambda = {
        name                          = "update-tenant-webhooks"
        handler                       = "src/scheduled-tasks.updateTenantWebhooks"
        file_path                     = "../../../backend/dist/producers.zip"
        type                          = "public"
        use_iroh_url                  = true
        use_producer_notification_url = true
        with_source_options           = true
      }
    },
    dsColdStartFetchDevices = {
      event_bridge_rule = "ds-cold-start-fetch-devices"
      is_scalable       = true
      lambda = {
        name                                     = "ds-cold-start-fetch-devices"
        handler                                  = "src/scheduled-tasks.dsColdStartFetchDevices"
        file_path                                = "../../../backend/dist/producers.zip"
        type                                     = "public"
        memory_size                              = 128
        access_neptune                           = true
        use_device_change_notification_event_bus = true
      }
    }
  }
}
