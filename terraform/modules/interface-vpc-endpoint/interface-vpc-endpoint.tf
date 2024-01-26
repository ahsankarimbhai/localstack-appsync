data "aws_region" "current" {}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${var.service_name}"
  private_dns_enabled = true
  security_group_ids  = var.security_group_ids
  tags = {
    Name = "${var.base_name}-${var.service_name}"
  }
}

resource "aws_vpc_endpoint_subnet_association" "vpc_endpoint" {
  for_each        = toset(var.subnet_ids)
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint.id
  subnet_id       = each.key
}
