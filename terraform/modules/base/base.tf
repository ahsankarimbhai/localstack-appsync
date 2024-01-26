data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.combined_subnet_ranges["VPC"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.base_name
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.base_name}-gateway"
  }
}

resource "aws_vpc_dhcp_options" "dhcp_opts" {
  domain_name         = "${var.region_domain_map[data.aws_region.current.name]} ${var.service_discovery_hosted_zone}"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "${var.base_name}-dchp-opts"
  }
}

resource "aws_vpc_dhcp_options_association" "dhcp_opts_assoc" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_opts.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.base_name}-public-rt"
  }
}

module "public_subnets" {
  for_each          = var.subnet_config
  source            = "../subnet-v2"
  vpc_id            = aws_vpc.vpc.id
  route_table_id    = aws_route_table.public_rt.id
  cidr_block        = each.value["public"]
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tag_name          = "${var.base_name}-public-${each.value["name"]}"
}

resource "aws_eip" "nat_gateway_eips" {
  for_each = var.subnet_config
  vpc      = true
  tags = {
    Name = "${var.base_name}-eip-ngw-${each.value["name"]}"
  }
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each      = var.subnet_config
  allocation_id = aws_eip.nat_gateway_eips[each.key].id
  subnet_id     = module.public_subnets[each.key].subnet_id
  tags = {
    Name = "${var.base_name}-ngw-${each.value["name"]}"
  }
}

resource "aws_route_table" "public_tools_rts" {
  for_each = var.subnet_config
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateways[each.key].id
  }
  tags = {
    Name = "${var.base_name}-public-tools-rt-${each.value["name"]}"
  }
}

module "public_tools_subnets" {
  for_each          = var.subnet_config
  source            = "../subnet-v2"
  vpc_id            = aws_vpc.vpc.id
  route_table_id    = aws_route_table.public_tools_rts[each.key].id
  cidr_block        = each.value["public-tools"]
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tag_name          = "${var.base_name}-public-tools-${each.value["name"]}"
}

resource "aws_ssm_parameter" "public_tools_subnet_ids" {
  name        = "/${var.base_name}/public-tools-subnet-ids"
  description = "Public Tools Subnet IDs"
  type        = "StringList"
  value = join(",", [
    for key in keys(var.subnet_config) :
    module.public_tools_subnets[key].subnet_id
  ])

  tags = {
    Name = "${var.base_name}-public-tools-subnet-ids"
  }
}

resource "aws_network_acl" "public_tools_network_acl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    for key in keys(var.subnet_config) :
    module.public_tools_subnets[key].subnet_id
  ]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8834
    to_port    = 8834
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "${var.base_name}-public-tools-network-acl"
  }
}

module "private_tools_subnets" {
  for_each          = var.subnet_config
  source            = "../subnet-v2"
  vpc_id            = aws_vpc.vpc.id
  route_table_id    = aws_route_table.private_tools_rt.id
  cidr_block        = each.value["private-tools"]
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tag_name          = "${var.base_name}-private-tools-${each.value["name"]}"
}

resource "aws_ssm_parameter" "private_tools_subnet_ids" {
  name        = "/${var.base_name}/private-tools-subnet-ids"
  description = "Private Tools Subnet IDs"
  type        = "StringList"
  value = join(",", [
    for key in keys(var.subnet_config) :
    module.private_tools_subnets[key].subnet_id
  ])

  tags = {
    Name = "${var.base_name}-private-tools-subnet-ids"
  }
}

resource "aws_network_acl" "private_tools_network_acl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    for key in keys(var.subnet_config) :
    module.private_tools_subnets[key].subnet_id
  ]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.combined_subnet_ranges["VPC"]
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.combined_subnet_ranges["VPC"]
    from_port  = 0
    to_port    = 65535
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "${var.base_name}-private-tools-network-acl"
  }
}

resource "aws_route_table" "private_tools_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.base_name}-private-tools-rt"
  }
}

module "private_endpoints_subnets" {
  for_each          = var.subnet_config
  source            = "../subnet-v2"
  vpc_id            = aws_vpc.vpc.id
  route_table_id    = aws_route_table.private_tools_rt.id
  cidr_block        = each.value["private-endpoints"]
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tag_name          = "${var.base_name}-private-endpoints-${each.value["name"]}"
}

resource "aws_network_acl" "private_endpoints_network_acl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    for key in keys(var.subnet_config) :
    module.private_endpoints_subnets[key].subnet_id
  ]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.combined_subnet_ranges["VPC"]
    from_port  = 0
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.combined_subnet_ranges["VPC"]
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "${var.base_name}-private-endpoints-network-acl"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.base_name}-vpc-endpoint-sg"
  description = "Security group for aws vpc endpoint"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.combined_subnet_ranges["VPC"]]
  }

  tags = {
    Name = "${var.base_name}-vpc-endpoint-sg"
  }
}

# module "interface_vpc_endpoints" {
#   for_each           = toset(var.interface_vpc_endpoint_config)
#   source             = "../interface-vpc-endpoint"
#   base_name          = var.base_name
#   vpc_id             = aws_vpc.vpc.id
#   service_name       = each.key
#   security_group_ids = [aws_security_group.vpc_endpoint.id]
#   subnet_ids = [
#     for key in keys(var.subnet_config) :
#     module.private_endpoints_subnets[key].subnet_id
#   ]
# }

module "gateway_vpc_endpoints" {
  for_each       = toset(var.gateway_vpc_endpoint_config)
  source         = "../gateway-vpc-endpoint"
  base_name      = var.base_name
  vpc_id         = aws_vpc.vpc.id
  service_name   = each.key
  route_table_id = aws_route_table.private_tools_rt.id
}

module "gateway_vpc_endpoints_neptune_rebalance" {
  for_each       = var.turn_on_neptune_rebalance ? aws_route_table.public_tools_rts : {}
  source         = "../gateway-vpc-endpoint"
  base_name      = var.base_name
  vpc_id         = aws_vpc.vpc.id
  service_name   = "s3"
  route_table_id = aws_route_table.public_tools_rts[each.key].id
}

resource "aws_security_group" "private_lambda_security_group" {
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.base_name}-private-lambda-sg"
  description = "Security group corresponding to the private lambda functions"

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.combined_subnet_ranges["VPC"]]
  }

  tags = {
    Name = "${var.base_name}-private-lambda-sg"
  }
}
resource "aws_ssm_parameter" "private_lambda_sg_id" {
  name        = "/${var.base_name}/private-lambda-sg-id"
  description = "Private Lambda SG IDs"
  type        = "String"
  value       = aws_security_group.private_lambda_security_group.id

  tags = {
    Name = "${var.base_name}-private-lambda-sg-id"
  }
}

resource "aws_security_group" "public_lambda_security_group" {
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.base_name}-public-lambda-sg"
  description = "Security group corresponding to the public lambda functions"

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.base_name}-public-lambda-sg"
  }
}

resource "aws_ssm_parameter" "public_lambda_sg_id" {
  name        = "/${var.base_name}/public-lambda-sg-id"
  description = "Public Lambda SG IDs"
  type        = "String"
  value       = aws_security_group.public_lambda_security_group.id

  tags = {
    Name = "${var.base_name}-public-lambda-sg-id"
  }
}

resource "aws_route53_zone" "service_discovery" {
  name = var.service_discovery_hosted_zone
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
  comment = "Service Discovery Zone"

  tags = {
    Name = var.base_name
  }
}

# Data returned by this module.
output "vpc_natgw_elastic_ips" {
  value = [for key in keys(var.subnet_config) : aws_eip.nat_gateway_eips[key].public_ip]
}

output "private_tools_subnet_ids" {
  value = [for key in keys(var.subnet_config) : module.private_tools_subnets[key].subnet_id]
}

output "public_subnet_ids" {
  value = [for key in keys(var.subnet_config) : module.public_subnets[key].subnet_id]
}

output "public_tools_subnet_ids" {
  value = [for key in keys(var.subnet_config) : module.public_tools_subnets[key].subnet_id]
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "service_discovery_hosted_zone_id" {
  value = aws_route53_zone.service_discovery.id
}

output "vpc_endpoint_security_group_id" {
  value = aws_security_group.vpc_endpoint.id
}

output "private_tools_subnets" {
  value = [
    for key in keys(var.subnet_config) :
    module.private_tools_subnets[key].subnet_id
  ]
}

output "private_tools_network_acl_name" {
  value = aws_network_acl.private_tools_network_acl.tags.Name
}
