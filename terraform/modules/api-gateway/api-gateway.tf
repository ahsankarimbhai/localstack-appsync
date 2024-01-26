resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.name_prefix
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method_settings" "api_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "api/POST"

  settings {
    throttling_burst_limit = 1000
    throttling_rate_limit  = 500
  }
}

resource "aws_api_gateway_method_settings" "producer_notification_get_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "api/producer-notification/GET"

  settings {
    throttling_burst_limit = 3000
    throttling_rate_limit  = 1000
  }
}

resource "aws_api_gateway_method_settings" "producer_notification_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "api/producer-notification/POST"

  settings {
    throttling_burst_limit = 3000
    throttling_rate_limit  = 1000
  }
}

resource "aws_api_gateway_method_settings" "file_upload_url_get_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "api/file-upload-url/GET"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 10
  }
}

resource "aws_api_gateway_method_settings" "status_get_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "api/status/GET"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 10
  }
}

resource "aws_api_gateway_usage_plan" "graphql_usage_plan" {
  name = "${var.name_prefix}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = "default"
  }

  throttle_settings {
    burst_limit = 1000
    rate_limit  = 500
  }
}

resource "aws_api_gateway_method_settings" "assets_describe_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "assets/describe/POST"

  settings {
    throttling_burst_limit = 1000
    throttling_rate_limit  = 500
  }
}

resource "aws_api_gateway_method_settings" "assets_resolve_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "assets/resolve/POST"

  settings {
    throttling_burst_limit = 1500
    throttling_rate_limit  = 500
  }
}

resource "aws_api_gateway_method_settings" "assets_resolve_latest_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "assets/resolve-latest/POST"

  settings {
    throttling_burst_limit = 1500
    throttling_rate_limit  = 500
  }
}

resource "aws_api_gateway_method_settings" "health_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "health/POST"

  settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

resource "aws_api_gateway_method_settings" "map_incidents_to_identities_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "incidents/map-incident-to-identities/POST"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "map_incidents_to_unresolved_identities_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "incidents/map-incidents-to-unresolved-identity/POST"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "system_tenant_module_update_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "system/tenant/module-update/POST"

  settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

resource "aws_api_gateway_method_settings" "webhooks_delete_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/DELETE"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "webhooks_get_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/GET"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "webhook_register_post_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/register/POST"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "webhook_id_get_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/{webhookId}/GET"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "webhook_id_put_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/{webhookId}/PUT"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_method_settings" "webhook_id_delete_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "default"
  method_path = "webhooks/{webhookId}/DELETE"

  settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 250
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "api"
}

module "cors" {
  source        = "../cors"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api.id
  allow_methods = "'OPTIONS,POST'"
  allow_headers = "'Content-Type,x-amz-user-agent,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,posaas-tenant-uid,access-control-allow-origin'"
}

resource "aws_api_gateway_request_validator" "api_gateway" {
  name                        = "${var.name_prefix}-api-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api_gateway.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_gateway_response" "api_gateway_gateway_response" {
  for_each = toset([
    "DEFAULT_4XX",
    "DEFAULT_5XX"
  ])
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  response_type = each.value

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

output "api_gateway" {
  value = aws_api_gateway_rest_api.api_gateway
}

output "api_gateway_api_resource_id" {
  value = aws_api_gateway_resource.api.id
}

output "request_validator_id" {
  value = aws_api_gateway_request_validator.api_gateway.id
}
