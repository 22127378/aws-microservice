# 1. Tạo thực thể Role cho ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  # Chính sách cho phép dịch vụ ECS được phép "mượn" (assume) role này
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Gắn chính sách chuẩn của AWS (AmazonECSTaskExecutionRolePolicy) vào Role trên
# Chính sách này đã có sẵn quyền: kéo image từ ECR và ghi log vào CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


