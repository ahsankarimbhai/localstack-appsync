data "aws_availability_zones" "all" {}

data "template_file" "subnet_name" {
  count    = var.num_az_zones
  template = "$${subnet_prefix}-$${azname}"

  vars = {
    subnet_prefix = var.prefix
    azname        = lookup(var.az_subname_map, count.index)
  }
}

resource "aws_subnet" "subnet" {
  count                   = var.num_az_zones
  vpc_id                  = var.vpc_id
  cidr_block              = lookup(var.subnet_config, element(data.template_file.subnet_name.*.rendered, count.index))
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = "${var.base_name}-${element(data.template_file.subnet_name.*.rendered, count.index)}"
  }
}

resource "aws_route_table_association" "route_table_association" {
  count          = var.num_az_zones
  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = var.route_table_ids[min(length(var.route_table_ids) - 1, count.index)]
}

# Data returned by this module.
output "subnet_ids" {
  value = aws_subnet.subnet.*.id
}
