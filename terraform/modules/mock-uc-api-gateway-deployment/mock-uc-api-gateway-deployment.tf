resource "aws_api_gateway_deployment" "unifiedConnectorAPI_deployment" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.stage_name
  triggers = {
    redeployment = timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "deployment_url" {
  value = aws_api_gateway_deployment.unifiedConnectorAPI_deployment.invoke_url
}
