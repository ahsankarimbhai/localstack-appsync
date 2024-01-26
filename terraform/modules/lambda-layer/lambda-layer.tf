locals {
  full_lambda_layer_name = "${var.name_prefix}-${var.lambda_layer_name}"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name       = local.full_lambda_layer_name
  filename         = var.lambda_layer_full_path
  source_code_hash = filebase64sha256(var.lambda_layer_full_path)

  compatible_runtimes = [var.nodejs_runtime]

  lifecycle {
    create_before_destroy = true
  }
}

# Data returned by this module.
output "lambda_layer_arn" {
  value = aws_lambda_layer_version.lambda_layer.arn
}
