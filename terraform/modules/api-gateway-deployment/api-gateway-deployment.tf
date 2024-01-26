#cloud front certificates have to be deployed in us-east-1 certificate manager
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  access_key                  = "mock_access_key"
  #s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    acm            = "http://localhost:4566"
  }
}

data "aws_acm_certificate" "api_gateway_deployment" {
  provider    = aws.us-east-1
  domain      = var.cert_domain
  most_recent = true
}

data "aws_route53_zone" "api_gateway_deployment" {
  name         = var.public_hosted_zone
  private_zone = false
}

resource "aws_api_gateway_domain_name" "api_gateway_deployment" {
  certificate_arn = data.aws_acm_certificate.api_gateway_deployment.arn
  domain_name     = var.api_gateway_domain_name
  security_policy = "TLS_1_2"
}

resource "aws_route53_record" "api_gateway_deployment" {
  name    = aws_api_gateway_domain_name.api_gateway_deployment.domain_name
  zone_id = data.aws_route53_zone.api_gateway_deployment.zone_id
  type    = "A"

  alias {
    evaluate_target_health = true
    # name                   = aws_api_gateway_domain_name.api_gateway_deployment.cloudfront_domain_name
    # zone_id                = aws_api_gateway_domain_name.api_gateway_deployment.cloudfront_zone_id
    name                   = aws_api_gateway_domain_name.api_gateway_deployment.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_deployment.regional_zone_id
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.stage_name
  triggers = {
    redeployment = timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "api_gateway_deployment_id" {
  value = aws_api_gateway_deployment.api_gateway_deployment.id
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_deployment" {
  api_id      = var.api_gateway_id
  stage_name  = aws_api_gateway_deployment.api_gateway_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.api_gateway_deployment.domain_name
}
