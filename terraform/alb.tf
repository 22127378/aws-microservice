# 1. Khởi tạo Application Load Balancer
resource "aws_alb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Để internet có thể truy cập được
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets # Đặt vào Public Subnets

  enable_deletion_protection = false # Tắt để bạn có thể xóa project dễ dàng khi thực hành xong

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. Tạo Target Group (Nơi các container Docker sẽ đăng ký vào)
resource "aws_alb_target_group" "app_tg" {
  name        = "${var.project_name}-tg"
  port        = 8080        # Port mà container của bạn lắng nghe
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"        # Quan trọng: Fargate yêu cầu dùng target type là "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/" # Đường dẫn để ALB kiểm tra xem container còn sống không
    unhealthy_threshold = "2"
  }
}

# 3. Tạo Listener để nhận traffic từ cổng 80
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app_tg.arn
  }
}

# 4. Tạo Target Group cho Backend (port 5000, health check /health)
resource "aws_alb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }
}

# 5. Định tuyến các request bắt đầu bằng /api/* sang Backend Target Group
resource "aws_alb_listener_rule" "backend_rule" {
  listener_arn = aws_alb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}