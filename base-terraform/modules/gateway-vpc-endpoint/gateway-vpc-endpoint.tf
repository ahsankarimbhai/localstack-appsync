data "aws_region" "current" {}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${var.service_name}"
  tags = {
    Name = "${var.base_name}-${var.service_name}"
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint" {
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint.id
  route_table_id  = var.route_table_id
}
