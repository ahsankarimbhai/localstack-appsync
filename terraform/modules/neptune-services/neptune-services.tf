data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "neptune_services" {
  name = "${var.name_prefix}-neptune_services"

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

resource "aws_iam_role_policy" "neptune_services" {
  name = "${var.name_prefix}-neptune_services"
  role = aws_iam_role.neptune_services.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "neptune-db:*"
        ],
        "Resource" : [
          for res_id in var.neptune_cluster_resource_ids : "arn:aws:neptune-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${res_id}/*"
        ]
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
      }
    ]
  })
}

module "neptune_services_lambda" {
  count = var.allow_neptune_services ? 1 : 0

  source                 = "../lambda"
  name_prefix            = var.name_prefix
  lambda_type            = "private"
  function_name          = "neptune-services"
  iam_role_arn           = aws_iam_role.neptune_services.arn
  handler                = "src/helpers/NeptuneLambdaDelegator.executeNeptuneRequest"
  nodejs_runtime         = var.nodejs_runtime
  lambda_file_path       = "${path.module}/../../../backend/dist/neptune-services.zip"
  systems_manager_prefix = var.systems_manager_prefix
  layers                 = [var.lambda_layer_arn]
  lambda_timeout         = 60
  env                    = var.env
  lambda_environment = {
    ENV = var.env
  }
}
