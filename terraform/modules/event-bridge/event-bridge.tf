resource "aws_cloudwatch_event_bus" "scheduled_tasks" {
  name = "${var.name_prefix}-scheduled"
}

resource "aws_cloudwatch_event_bus" "event_bridge_bus" {
  name = "${var.name_prefix}-event-bridge-bus"
}

resource "aws_cloudwatch_event_bus" "device_change_notification" {
  name = "${var.name_prefix}-device-change-notifcation"
}

output "aws_event_bus_scheduled_tasks_arn" {
  value = aws_cloudwatch_event_bus.scheduled_tasks.arn
}

output "event_bridge_bus_arn" {
  value = aws_cloudwatch_event_bus.event_bridge_bus.arn
}

output "device_change_notification_event_bus_arn" {
  value = aws_cloudwatch_event_bus.device_change_notification.arn
}
