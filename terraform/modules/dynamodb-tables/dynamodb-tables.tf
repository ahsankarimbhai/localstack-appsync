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

# Data returned by this module.
output "tenants_table_arn" {
  value = aws_dynamodb_table.tenant.arn
}

output "tenants_config_table_arn" {
  value = aws_dynamodb_table.tenant_config.arn
}
