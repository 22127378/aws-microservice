# 1. Security Group cho Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Chấp nhận traffic HTTP từ internet"
  vpc_id      = module.vpc.vpc_id

  # Cho phép mọi người truy cập vào port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép ALB gửi traffic ra ngoài (để kiểm tra sức khỏe của container)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 nghĩa là tất cả các giao thức
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2. Security Group cho Microservices (ECS Tasks)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Chi chap nhan traffic tu Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # CHỈ cho phép traffic đến từ ALB Security Group
  ingress {
    from_port       = 8080 # Giả sử app Docker của bạn chạy port 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Đây chính là "Chaining"
  }

  # Cho phép container đi ra internet (qua NAT Gateway) để tải resource
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}