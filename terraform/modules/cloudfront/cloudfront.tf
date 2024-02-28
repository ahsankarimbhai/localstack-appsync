terraform {
  required_providers {
    aws = {
      version = "5.29.0"
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.alternate ]
    }
  }
}

resource "aws_cloudfront_distribution" "api_cloudfront_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_200"

  aliases = [var.cert_alias]

  origin {
    domain_name = var.api_gateway_domain_name
    origin_id   = "APIGatewayOrigin"
    origin_path = "/default"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  default_cache_behavior {
    target_origin_id       = "APIGatewayOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    compress               = true

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" #CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" #AllViewerExceptHostHeader

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  viewer_certificate {
    acm_certificate_arn      = var.cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "api_cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api_cloudfront_distribution.domain_name
}

output "api_cloudfront_zone_id" {
  description = "The zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api_cloudfront_distribution.hosted_zone_id
}
