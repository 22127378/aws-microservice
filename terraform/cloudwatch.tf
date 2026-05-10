resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7 # Lưu log trong 7 ngày để tiết kiệm chi phí

  tags = {
    Name = "${var.project_name}-logs"
  }
}