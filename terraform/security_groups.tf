# 1. Security Group cho Load Balancer 
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc.vpc_id # Lấy ID từ module vpc 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group cho Microservices 
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080 # Port của ứng dụng Docker
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # CHỈ cho phép ALB gọi vào
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}