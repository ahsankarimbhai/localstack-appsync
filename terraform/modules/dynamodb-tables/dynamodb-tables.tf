resource "aws_dynamodb_table" "tenant_config" {
  name         = "${var.name_prefix}-tenant-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "tenantKey"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-tenant-uid-idx"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-tenant-config"
  }
}

resource "aws_dynamodb_table" "tenant" {
  name         = "${var.name_prefix}-tenant"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "extId"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-ext-id-idx"
    hash_key        = "extId"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-tenant"
  }
}

resource "aws_dynamodb_table" "function_state" {
  name         = "${var.name_prefix}-function-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "functionStateKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "functionStateKey"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-function-state"
  }
}

resource "aws_dynamodb_table" "group" {
  name         = "${var.name_prefix}-group"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "tenantKey"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-group-tenant-uid-idx"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "timeToExpire"
    enabled        = true
  }

  tags = {
    Name = "${var.name_prefix}-group"
  }
}

resource "aws_dynamodb_table" "policy" {
  name         = "${var.name_prefix}-policy"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "tenantKey"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-policy-tenant-uid-idx"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "timeToExpire"
    enabled        = true
  }

  tags = {
    Name = "${var.name_prefix}-policy"
  }
}

resource "aws_dynamodb_table" "os_versions" {
  name         = "${var.name_prefix}-os-versions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "osFamily"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "osFamily"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-os-versions"
  }
}

resource "aws_dynamodb_table" "label_metadata" {
  name         = "${var.name_prefix}-label-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantId"
  range_key    = "labelId"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "labelId"
    type = "S"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-label-metadata"
  }
}

resource "aws_dynamodb_table" "rule" {
  name         = "${var.name_prefix}-rule"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantId"
  range_key    = "ruleId"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "ruleId"
    type = "S"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-rule"
  }
}

resource "aws_dynamodb_table" "incident_mapping" {
  name         = "${var.name_prefix}-incident-mapping"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantId"
  range_key    = "id"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "observable"
    type = "S"
  }

  local_secondary_index {
    name            = "idx-observable"
    projection_type = "ALL"
    range_key       = "observable"
  }

  ttl {
    enabled        = true
    attribute_name = "expiryPeriod"
  }

  tags = {
    Name = "${var.name_prefix}-incident-mapping"
  }
}

resource "aws_dynamodb_table" "vulnerability" {
  name         = "${var.name_prefix}-vulnerability"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-vulnerability"
  }
}

resource "aws_dynamodb_table" "scheduled_task_metadata" {
  name         = "${var.name_prefix}-scheduled-task-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "name"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "scope"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-task-scope"
    hash_key        = "scope"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-scheduled-task-metadata"
  }
}

resource "aws_dynamodb_table_item" "scheduled_task_metadata" {
  for_each   = var.task_metadata_config
  table_name = aws_dynamodb_table.scheduled_task_metadata.name
  hash_key   = aws_dynamodb_table.scheduled_task_metadata.hash_key

  item = jsonencode(
    merge(
      {
        "name" : {
          "S" : each.key
        },
        "type" : {
          "S" : each.value.type
        },
        "scope" : {
          "S" : each.value.scope
        }
      },
      each.value.additional_config,
      lookup(var.dynamodb_schedule_tasks_additional_config, each.key, {})
    )
  )
}

resource "aws_dynamodb_table" "data_migration_task_metadata" {
  name         = "${var.name_prefix}-data-migration-task-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "name"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "scope"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-task-scope"
    hash_key        = "scope"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-data-migration-task-metadata"
  }
}

resource "aws_dynamodb_table_item" "data_migration_task_metadata" {
  for_each   = var.data_migration_task_metadata_config
  table_name = aws_dynamodb_table.data_migration_task_metadata.name
  hash_key   = aws_dynamodb_table.data_migration_task_metadata.hash_key

  item = jsonencode(
    merge(
      {
        "name" : {
          "S" : each.key
        },
        "scope" : {
          "S" : each.value.scope
        }
      },
      each.value.additional_config,
      lookup(var.dynamodb_data_migration_tasks_additional_config, each.key, {})
    )
  )
}

resource "aws_dynamodb_table" "scheduled_task" {
  name         = "${var.name_prefix}-scheduled-task"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "taskKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "taskKey"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  ttl {
    attribute_name = "timeToExpire"
    enabled        = true
  }

  global_secondary_index {
    name            = "${var.name_prefix}-tenant-id-idx"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-scheduled-task"
  }
}

resource "aws_dynamodb_table_item" "scheduled_task" {
  for_each = {
    for name, task_metadata_config in var.task_metadata_config : name => task_metadata_config
    if task_metadata_config.scope == "global"
  }
  table_name = aws_dynamodb_table.scheduled_task.name
  hash_key   = aws_dynamodb_table.scheduled_task.hash_key

  item = jsonencode(
    {
      "name" : {
        "S" : each.key
      },
      "schedule" : {
        "S" : each.value.schedule
      },
      "taskKey" : {
        "S" : each.key
      }
      "tenantUid" : {
        "S" : "global"
      }
    }
  )
}

resource "aws_dynamodb_table" "data_migration_task" {
  name         = "${var.name_prefix}-data-migration-task"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "taskKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "taskKey"
    type = "S"
  }

  ttl {
    attribute_name = "timeToExpire"
    enabled        = true
  }

  tags = {
    Name = "${var.name_prefix}-data-migration-task"
  }
}

resource "aws_dynamodb_table" "saved_filter" {
  name         = "${var.name_prefix}-saved-filter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "filterKey"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "filterKey"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-saved-filter"
  }
}

resource "aws_dynamodb_table_item" "global_iroh_module_type_id" {
  table_name = aws_dynamodb_table.tenant_config.name
  hash_key   = aws_dynamodb_table.tenant_config.hash_key

  item = jsonencode(
    merge(
      {
        "tenantKey" : {
          "S" : "global__iroh_module_type_id"
        },
        "value" : {
          "S" : var.global_iroh_module_type_id
        },
        "name" : {
          "S" : "Device Insights Module Type ID"
        },
        "createdAt" : {
          "S" : timestamp()
        }
      }
    )
  )
}

resource "aws_dynamodb_table" "neptune_shard" {
  name         = "${var.name_prefix}-neptune-shard"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantUid"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-neptune-shard"
  }
}

resource "aws_dynamodb_table" "neptune_shard_migration_log" {
  name         = "${var.name_prefix}-neptune-shard-migration-log"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantUid"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-neptune-shard-migration-log"
  }
}

resource "aws_dynamodb_table" "neptune_shard_migration_log_detail" {
  name         = "${var.name_prefix}-neptune-shard-migration-log-detail"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "exportId"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "exportId"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-nsmld-tenantuid-gsi"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-neptune-shard-migration-log-detail"
  }
}

resource "aws_dynamodb_table" "webhook_registration" {
  name         = "${var.name_prefix}-webhook-registration"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "webhookId"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "webhookId"
    type = "S"
  }

  attribute {
    name = "tenantUid"
    type = "S"
  }

  global_secondary_index {
    name            = "${var.name_prefix}-wr-tenantuid-gsi"
    hash_key        = "tenantUid"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.name_prefix}-webhook-registration"
  }
}

resource "aws_dynamodb_table" "webhook_notification" {
  name         = "${var.name_prefix}-webhook-notification"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "webhookId"
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "webhookId"
    type = "S"
  }

  tags = {
    Name = "${var.name_prefix}-webhook-notification"
  }
}

# Data returned by this module.
output "tenants_table_arn" {
  value = aws_dynamodb_table.tenant.arn
}

output "tenants_config_table_arn" {
  value = aws_dynamodb_table.tenant_config.arn
}

output "function_state_table_arn" {
  value = aws_dynamodb_table.function_state.arn
}

output "groups_table_arn" {
  value = aws_dynamodb_table.group.arn
}

output "policy_table_arn" {
  value = aws_dynamodb_table.policy.arn
}

output "vulnerability_table_arn" {
  value = aws_dynamodb_table.vulnerability.arn
}

output "scheduled_task_metadata_table_arn" {
  value = aws_dynamodb_table.scheduled_task_metadata.arn
}

output "scheduled_task_table_arn" {
  value = aws_dynamodb_table.scheduled_task.arn
}

output "data_migration_task_metadata_table_arn" {
  value = aws_dynamodb_table.data_migration_task_metadata.arn
}

output "data_migration_task_table_arn" {
  value = aws_dynamodb_table.data_migration_task.arn
}

output "os_versions_table_arn" {
  value = aws_dynamodb_table.os_versions.arn
}

output "saved_filter_table_arn" {
  value = aws_dynamodb_table.saved_filter.arn
}

output "neptune_shard_table_arn" {
  value = aws_dynamodb_table.neptune_shard.arn
}

output "neptune_shard_migration_log_table_arn" {
  value = aws_dynamodb_table.neptune_shard_migration_log.arn
}

output "neptune_shard_migration_log_detail_table_arn" {
  value = aws_dynamodb_table.neptune_shard_migration_log_detail.arn
}

output "label_metadata_arn" {
  value = aws_dynamodb_table.label_metadata.arn
}

output "rule_arn" {
  value = aws_dynamodb_table.rule.arn
}

output "incident_mapping_arn" {
  value = aws_dynamodb_table.incident_mapping.arn
}

output "webhook_registration_table_arn" {
  value = aws_dynamodb_table.webhook_registration.arn
}

output "webhook_notification_table_arn" {
  value = aws_dynamodb_table.webhook_notification.arn
}
