terraform {
  required_providers {
    aws = {
      version = "5.37.0"
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.alternate ]
    }
  }
}

data "aws_route53_zone" "api_gateway_deployment" {
  name         = var.public_hosted_zone
  private_zone = false
}

resource "aws_route53_record" "api_gateway_deployment" {
  name    = var.api_gateway_domain_name
  zone_id = var.route_53_zone_id
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = var.api_cloudfront_domain_name
    zone_id                = var.api_cloudfront_zone_id
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  triggers = {
    redeployment = timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  rest_api_id   = var.api_gateway_id
  stage_name    = var.stage_name
}

output "api_gateway_deployment_id" {
  value = aws_api_gateway_deployment.api_gateway_deployment.id
}

output "api_gateway_deployment_stage_name" {
  value = aws_api_gateway_stage.default.stage_name
}