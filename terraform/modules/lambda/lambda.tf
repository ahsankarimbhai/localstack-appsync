data "aws_ssm_parameter" "lambda_subnet_ids" {
  name = "/${var.systems_manager_prefix}-${var.env}/${var.lambda_type}-tools-subnet-ids"
}

data "aws_ssm_parameter" "lambda_sg_id" {
  name = "/${var.systems_manager_prefix}-${var.env}/${var.lambda_type}-lambda-sg-id"
}

locals {
  full_function_name = "${var.name_prefix}-${var.function_name}"
}

resource "aws_lambda_function" "lambda" {
  function_name                  = local.full_function_name
  handler                        = var.handler
  role                           = var.iam_role_arn
  runtime                        = var.nodejs_runtime
  filename                       = var.lambda_file_path
  source_code_hash               = filebase64sha256(var.lambda_file_path)
  layers                         = var.layers
  timeout                        = var.lambda_timeout
  reserved_concurrent_executions = var.concurrent_executions
  memory_size                    = var.memory_size
  publish                        = var.publish

  vpc_config {
    subnet_ids         = split(",", data.aws_ssm_parameter.lambda_subnet_ids.value)
    security_group_ids = [data.aws_ssm_parameter.lambda_sg_id.value]
  }

  environment {
    variables = merge(
      { ENV_PREFIX = var.name_prefix },
    var.lambda_environment)
  }
}

resource "aws_lambda_function_event_invoke_config" "lambda" {
  function_name          = aws_lambda_function.lambda.function_name
  maximum_retry_attempts = var.maximum_retry_attempts
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${local.full_function_name}"
  retention_in_days = 30
}

# Data returned by this module.
output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "full_function_name" {
  value = local.full_function_name
}

output "function_version" {
  value = aws_lambda_function.lambda.version
}
