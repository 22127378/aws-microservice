# 1. Tạo Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # Giúp bạn theo dõi biểu đồ CPU/RAM trên Console
  }
}

# 2. Định nghĩa Task (Giống như docker-compose.yml)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc" # Bắt buộc cho Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    # 0.25 vCPU
  memory                   = "512"    # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 3. Tạo Service để vận hành Task
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2 # Chạy 2 container để dự phòng (High Availability)
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = module.vpc.private_subnets # Chạy trong Private Subnet cho an toàn
    assign_public_ip = false # Không cần IP công khai vì đã có NAT Gateway
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 8080
  }

  # Đợi Load Balancer tạo xong rồi mới tạo Service
  depends_on = [aws_alb_listener.http]
}

# 4. Định nghĩa Task cho Backend (Express API)
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend-task"
  network_mode             = "awsvpc" # Bắt buộc cho Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    # 0.25 vCPU
  memory                   = "512"    # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Task Role cấp quyền tương tác AWS DynamoDB

  container_definitions = jsonencode([
    {
      name      = "backend-container"
      image     = "${aws_ecr_repository.backend_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      environment = [
        {
          name  = "DYNAMODB_TABLE_NAME"
          value = aws_dynamodb_table.tasks.name
        },
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs-backend"
        }
      }
    }
  ])
}

# 5. Tạo Service để vận hành Task cho Backend
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2 # Chạy 2 container để dự phòng (High Availability)
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = module.vpc.private_subnets # Chạy trong Private Subnet bảo mật
    assign_public_ip = false # Không cần IP công khai
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.backend_tg.arn
    container_name   = "backend-container"
    container_port   = 5000
  }

  # Đợi Load Balancer Listener Rule tạo xong rồi mới tạo Service
  depends_on = [aws_alb_listener.http, aws_alb_listener_rule.backend_rule]
}