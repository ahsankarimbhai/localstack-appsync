variable "name_prefix" { type = string }
variable "dynamodb_schedule_tasks_additional_config" {
  type = any
}
variable "dynamodb_data_migration_tasks_additional_config" {
  type = any
}
variable "task_metadata_config" {
  default = {
    fetch-amp-vulnerabilities : {
      type  = "daily"
      scope = "producer"
      additional_config = {
        producerTypeList : {
          SS : ["AMP"]
        }
      }
    }
    fetch-amp-groups : {
      type  = "daily"
      scope = "producer"
      additional_config = {
        producerTypeList : {
          SS : ["AMP"]
        }
      }
    }
    fetch-amp-policies : {
      type  = "daily"
      scope = "producer"
      additional_config = {
        producerTypeList : {
          SS : ["AMP"]
        }
      }
    }
    clear-es-tasks-index : {
      type              = "weekly"
      scope             = "global",
      additional_config = {}
      schedule          = "0 3 * * 2"
    }
    cleanup-del-src-for-all : {
      type              = "weekly"
      scope             = "global"
      additional_config = {}
      schedule          = "0 3 * * 2"
    }
    clean-old-labels : {
      type              = "weekly"
      scope             = "tenant"
      additional_config = {}
      schedule          = "0 3 * * 2"
    }
    update-stale-devices : {
      type  = "weekly"
      scope = "tenant"
      additional_config = {
        isScalable : {
          "BOOL" : true
        },
        concurrency : {
          "N" : "20"
        }
      }
    }
    neptune-to-es-diff-sync-task : {
      type              = "weekly"
      scope             = "tenant"
      additional_config = {}
    }
    cleanup-shadow-sources : {
      type  = "weekly"
      scope = "tenant"
      additional_config = {
        isScalable : {
          "BOOL" : true
        },
        concurrency : {
          "N" : "20"
        }
      }
    }
    cleanup-redundancies-from-ES : {
      type              = "daily"
      scope             = "tenant"
      additional_config = {}
    }
    delete-old-data : {
      type  = "daily"
      scope = "tenant"
      additional_config = {
        isScalable : {
          "BOOL" : true
        },
        concurrency : {
          "N" : "20"
        }
      }
    }
    fetch-duo-versions : {
      type              = "daily"
      scope             = "global"
      additional_config = {}
      schedule          = "0 3 * * *"
    }
    trigger-delete-stale-tenant-data : {
      type              = "daily"
      scope             = "global"
      additional_config = {}
      schedule          = "0 3 * * *"
    }
    iroh-sync-producers : {
      type              = "hourly"
      scope             = "tenant"
      additional_config = {}
    }
    reschedule-expiring-orbital-queries : {
      type              = "weekly"
      scope             = "global"
      additional_config = {}
      schedule          = "0 3 * * 2"
    }
    rules-changes-handling : {
      type              = "ten_minutes"
      scope             = "global"
      additional_config = {}
      schedule          = "*/10 * * * *"
    }
    rules-clean-discrepancies : {
      type              = "weekly"
      scope             = "tenant"
      additional_config = {}
    }
    rules-clean-devices-discrepancies : {
      type              = "weekly"
      scope             = "global"
      additional_config = {}
      schedule          = "0 3 * * 2"
    },
    update-tenant-webhooks : {
      type              = "weekly"
      scope             = "tenant"
      additional_config = {}
    }
    close-producer-current-states : {
      type  = "na"
      scope = "producer"
      additional_config = {
        isScalable : {
          "BOOL" : true
        },
        concurrency : {
          "N" : "20"
        }
      }
    },
    ds-cold-start-fetch-devices : {
      type  = "na"
      scope = "tenant"
      additional_config = {
        isScalable : {
          "BOOL" : true
        },
        concurrency : {
          "N" : "20"
        }
      }
    }
  }
}

variable "data_migration_task_metadata_config" {
  default = {
  }
}

variable "global_iroh_module_type_id" { type = string }
