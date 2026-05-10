#!/bin/bash

# Ngắt script ngay lập tức nếu có lệnh nào bị lỗi
set -e 

# 1. Tự động lấy biến từ Terraform (Cách 1 chúng ta đã bàn)
echo "--- Fetching infrastructure info from Terraform ---"
# Chui vào thư mục terraform để lấy output (giả sử script nằm ngoài thư mục terraform)
cd terraform
REGION=$(terraform var region) # Hoặc dán cứng nếu không đổi
REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
cd ..

# 2. Xử lý Image Tag (Sử dụng Git Commit Hash cho chuyên nghiệp)
# Nếu không phải thư mục git, nó sẽ dùng timestamp
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)

echo "--- Start CI/CD for Image Tag: $IMAGE_TAG ---"

# 3. Đăng nhập vào AWS ECR
echo "[1/4] Login ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPOSITORY_URL

# 4. Build Docker Image (Build cho nền tảng Linux x86_64 để chạy trên Fargate)
echo "[2/4] Building Docker image..."
docker build --platform linux/amd64 -t $REPOSITORY_URL:$IMAGE_TAG -t $REPOSITORY_URL:latest .

# 5. Push Image lên ECR (Push cả tag định danh và tag latest)
echo "[3/4] Pushing image to ECR..."
docker push $REPOSITORY_URL:$IMAGE_TAG
docker push $REPOSITORY_URL:latest

# 6. Cập nhật ECS Service
echo "[4/4] Updating ECS Service (Deploy)..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $REGION

echo "--- DEPLOYMENT SUCCESSFUL! ---"
echo "Check your app at: $(cd terraform && terraform output -raw alb_dns_name)"