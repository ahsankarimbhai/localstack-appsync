resource "aws_cloudwatch_event_rule" "schedule_event" {
  name                = substr("${var.rule_base_name}-trigger", 0, 64)
  description         = "Triggers ${replace(var.rule_base_name, "-", " ")}"
  schedule_expression = var.schedule_expression
  is_enabled          = var.enable_cloudwatch_rule
}

resource "aws_cloudwatch_event_target" "schedule_event" {
  for_each = {
    for index, lambda in var.lambdas : index => lambda
  }
  rule      = aws_cloudwatch_event_rule.schedule_event.name
  target_id = substr("target-${each.value.function_name}", 0, 64)
  arn       = each.value.lambda_arn
  input     = each.value.event_input
}

resource "aws_lambda_permission" "schedule_event" {
  for_each = {
    for index, lambda in var.lambdas : index => lambda
  }
  statement_id  = "executeFromCloudWatch-${aws_cloudwatch_event_rule.schedule_event.name}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_event.arn
}
