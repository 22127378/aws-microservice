# --- Các output bạn đã có ---

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}


output "alb_dns_name" {
  value       = "http://${aws_alb.main.dns_name}"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
}

# 3.Service name
output "ecs_service_name" {
  value       = aws_ecs_service.main.name
}

# 4. Log Group Name 
output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ecs_log_group.name
}