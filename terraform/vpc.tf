module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "microservice-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"] # Cho Microservices
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # Cho Load Balancer

  enable_nat_gateway = true #  Để Private Subnet có thể ra internet tải thư viện
  single_nat_gateway = true 

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "Terraform learning"
  }
}