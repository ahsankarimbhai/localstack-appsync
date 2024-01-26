data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_resource" "assets" {
  rest_api_id = var.api_gateway.id
  parent_id   = var.api_gateway.root_resource_id
  path_part   = "assets"
}

resource "aws_iam_role" "assets_api" {
  name = "${var.name_prefix}-assets-api"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "assets_api" {
  name = "${var.name_prefix}-assets-api"
  role = aws_iam_role.assets_api.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "cloudwatch:GetMetricStatistics"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        "Resource" : [
          "${var.os_versions_table_arn}",
          "${var.groups_table_arn}",
          "${var.groups_table_arn}/index/*",
          "${var.policy_table_arn}",
          "${var.policy_table_arn}/index/*",
          "${var.tenants_table_arn}",
          "${var.tenants_table_arn}/index/*",
          "${var.tenant_config_arn}",
          "${var.tenant_config_arn}/index/*",
          "${var.vulnerability_table_arn}",
          "${var.label_metadata_arn}",
          "${var.neptune_shard_table_arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "neptune-db:*"
        ],
        "Resource" : [
          for res_id in var.neptune_cluster_resource_ids : "arn:aws:neptune-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${res_id}/*"
        ]
      }
    ]
  })
}

module "assets" {
  for_each               = var.assets_api
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = each.value.name
  iam_role_arn           = aws_iam_role.assets_api.arn
  handler                = each.value.handler
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/assets.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 20
  env                    = var.env
  memory_size            = 512
  lambda_environment = merge(
    lookup(each.value, "access_neptune", false) ? {
      NEPTUNE_CLUSTER_SETTINGS = var.neptune_cluster_settings
    } : {},
    {
      ENV                  = var.env
      POSTURE_URL          = var.posture_url
      IROH_URI             = var.iroh_uri
      IROH_REDIRECT_URI    = var.iroh_redirect_uri
      EVENT_BRIDGE_BUS_ARN = var.event_bridge_bus_arn
      RULES_ENABLED        = var.rules_enabled
  })
}

module "assets_gw" {
  for_each             = var.assets_api
  depends_on           = [aws_api_gateway_resource.assets]
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = each.value.parent_path
  full_function_name   = module.assets[each.key].full_function_name
  lambda_invoke_arn    = module.assets[each.key].lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = each.value.path
  http_method          = ["POST"]
  response_format      = "json"
  authorization_type   = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = var.api_gateway_request_validator_id
  cors_disabled        = true
  allow_methods        = "'OPTIONS,POST'"
}
