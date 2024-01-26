locals {
  cloudfront_apps_endpoint = "${var.cloudfront_apps_subdomain}.${var.cloudfront_domain}"
}

resource "aws_s3_bucket" "frontend" {
  count  = var.should_create_cloudfront_endpoint ? 1 : 0
  bucket = local.cloudfront_apps_endpoint

  tags = merge(
    var.s3_bucket_tags,
    {
      Name        = local.cloudfront_apps_endpoint
      Environment = var.s3_bucket_env
  })
}

resource "aws_s3_bucket_acl" "frontend" {
  count  = var.should_create_cloudfront_endpoint ? 1 : 0
  bucket = local.cloudfront_apps_endpoint
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  count  = var.should_create_cloudfront_endpoint ? 1 : 0
  bucket = local.cloudfront_apps_endpoint

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

locals {
  cloudfront_apps_origin_id = var.should_create_cloudfront_endpoint ? aws_s3_bucket_website_configuration.frontend[0].website_endpoint : ""
}

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

data "aws_acm_certificate" "frontend" {
  provider = aws.us-east-1
  count    = var.should_create_cloudfront_endpoint ? 1 : 0
  domain   = var.cloudfront_apps_acm_cert_domain
}

resource "aws_cloudfront_distribution" "frontend" {
  count = var.should_create_cloudfront_endpoint ? 1 : 0
  origin {
    domain_name = local.cloudfront_apps_origin_id
    origin_id   = local.cloudfront_apps_origin_id
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }
  enabled         = true
  is_ipv6_enabled = true
  comment         = local.cloudfront_apps_endpoint

  aliases = [local.cloudfront_apps_endpoint]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = local.cloudfront_apps_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = local.cloudfront_apps_endpoint
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.frontend[count.index].arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}

data "aws_route53_zone" "frontend" {
  name         = var.public_hosted_zone
  private_zone = false
}

resource "aws_route53_record" "frontend" {
  count   = var.should_create_cloudfront_endpoint ? 1 : 0
  zone_id = data.aws_route53_zone.frontend.zone_id
  name    = local.cloudfront_apps_endpoint
  type    = "CNAME"
  ttl     = "900"
  records = [aws_cloudfront_distribution.frontend[count.index].domain_name]
}

output "content_bucket_name" {
  value = var.should_create_cloudfront_endpoint ? aws_s3_bucket.frontend[0].id : ""
}

output "cloudfront_apps_endpoint" {
  value = var.is_local_dev_env ? "http://localhost:3000" : "https://${local.cloudfront_apps_endpoint}"
}
