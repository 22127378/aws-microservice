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

# 3. Tạo Task Role cho phép Container chạy mã nguồn gọi dịch vụ AWS khác (DynamoDB)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

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

# 4. Tạo Policy cho phép truy cập DynamoDB
resource "aws_iam_policy" "ecs_dynamodb_policy" {
  name        = "${var.project_name}-ecs-dynamodb-policy"
  description = "Allow ECS task to access DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.tasks.arn
      }
    ]
  })
}

# 5. Gắn Policy truy cập DynamoDB vào Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_role_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_dynamodb_policy.arn
}


