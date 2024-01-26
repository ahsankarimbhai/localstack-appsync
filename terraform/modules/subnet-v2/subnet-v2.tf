data "aws_availability_zones" "all" {}
data "aws_region" "current" {}

resource "aws_subnet" "subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.tag_name
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_id
}

# Data returned by this module.
output "subnet_id" {
  value = aws_subnet.subnet.id
}
