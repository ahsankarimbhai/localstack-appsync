data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "authorizer" {
  name = "${var.name_prefix}-${var.authorizer_name}"

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

resource "aws_iam_role_policy" "authorizer" {
  name   = "${var.name_prefix}-${var.authorizer_name}"
  role   = aws_iam_role.authorizer.id
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
            "secretsmanager:GetSecretValue",
            "secretsmanager:UpdateSecret",
            "secretsmanager:PutSecretValue",
            "secretsmanager:CreateSecret"
          ],
          "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:posture-*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "lambda:InvokeFunction"
          ],
          "Resource": [
            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:DeleteItem",
            "dynamodb:UpdateItem"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
  EOF
}

module "authorizer_lambda" {
  source                 = "../lambda"
  function_name          = var.authorizer_name
  lambda_type            = var.lambda.type
  name_prefix            = var.name_prefix
  iam_role_arn           = aws_iam_role.authorizer.arn
  handler                = var.lambda.handler
  lambda_file_path       = "${path.module}/../../../backend/dist/authorizer.zip"
  nodejs_runtime         = var.nodejs_runtime
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  concurrent_executions  = var.reserved_concurrency
  publish                = var.provisioned_concurrency > 0
  lambda_timeout         = lookup(var.lambda, "timeout", 10)
  env                    = var.env
}

resource "aws_lambda_alias" "authorizer" {
  count            = var.provisioned_concurrency > 0 ? 1 : 0
  name             = "current"
  description      = "latest version"
  function_name    = module.authorizer_lambda.full_function_name
  function_version = module.authorizer_lambda.function_version
}

resource "aws_lambda_provisioned_concurrency_config" "authorizer" {
  count                             = var.provisioned_concurrency > 0 ? 1 : 0
  function_name                     = module.authorizer_lambda.full_function_name
  provisioned_concurrent_executions = var.provisioned_concurrency
  qualifier                         = aws_lambda_alias.authorizer[0].name
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                             = "${var.name_prefix}-${var.authorizer_name}"
  rest_api_id                      = var.api_gateway.id
  authorizer_uri                   = var.provisioned_concurrency > 0 ? aws_lambda_alias.authorizer[0].invoke_arn : module.authorizer_lambda.lambda_invoke_arn
  type                             = var.authorizer_type
  authorizer_result_ttl_in_seconds = 0
}

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "${var.name_prefix}-allow-execution-from-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer_lambda.full_function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = var.provisioned_concurrency > 0 ? aws_lambda_alias.authorizer[0].name : null
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_gateway.id}/authorizers/${aws_api_gateway_authorizer.authorizer.id}"
}

output "authorizer_id" {
  value = aws_api_gateway_authorizer.authorizer.id
}
