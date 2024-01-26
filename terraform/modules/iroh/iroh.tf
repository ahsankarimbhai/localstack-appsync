data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "iroh_token_request" {
  name = "${var.name_prefix}-iroh-token-request"

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

resource "aws_iam_role_policy" "iroh_token_request" {
  name   = "${var.name_prefix}-iroh-token-request"
  role   = aws_iam_role.iroh_token_request.id
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "dynamodb:Query",
            "dynamodb:PutItem",
            "dynamodb:GetItem"
          ],
          "Resource": [
            "${var.tenants_table_arn}",
            "${var.tenants_table_arn}/index/*",
            "${var.scheduled_task_arn}",
            "${var.scheduled_task_arn}/index/*",
            "${var.scheduled_task_metadata_arn}",
            "${var.scheduled_task_metadata_arn}/index/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
              "secretsmanager:GetSecretValue",
              "secretsmanager:UpdateSecret",
              "secretsmanager:CreateSecret",
              "secretsmanager:PutSecretValue"
          ],
          "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
        }
      ]
    }
  EOF
}

module "iroh_token_request" {
  count                  = var.should_enable_iroh_token_request ? 1 : 0
  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "public"
  function_name          = "iroh-token-request"
  iam_role_arn           = aws_iam_role.iroh_token_request.arn
  handler                = "src/iroh.irohTokenRequest"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/iroh.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 20
  env                    = var.env
  lambda_environment = {
    ENV               = var.env
    IROH_URI          = var.iroh_uri
    // IROH_REDIRECT_URI = var.iroh_redirect_uri
    IROH_JWKS_URI     = "${var.iroh_uri}/.well-known/jwks"
  }
}

module "iroh_token_request_gw" {
  count                = var.should_enable_iroh_token_request ? 1 : 0
  source               = "../lambda-gateway"
  rest_api_id          = var.api_gateway.id
  rest_api_parent_path = "/api"
  full_function_name   = module.iroh_token_request[0].full_function_name
  lambda_invoke_arn    = module.iroh_token_request[0].lambda_invoke_arn
  name_prefix          = var.name_prefix
  path_part            = "iroh-auth"
  http_method          = ["POST"]
  response_format      = "json"
  authorization_type   = "NONE"
  request_validator_id = var.api_gateway_request_validator_id
  request_parameters = {
    "method.request.header.Authorization" = false
  }
  cors_disabled = true
  allow_methods = "'OPTIONS,POST'"
}
