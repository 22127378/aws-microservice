#!/bin/bash

# Ngắt script ngay lập tức nếu có lệnh nào bị lỗi
set -e 

echo "--- Fetching infrastructure info from Terraform ---"

# Kiểm tra xem thư mục terraform có tồn tại không
if [ ! -d "terraform" ]; then
    echo "Lỗi: Không tìm thấy thư mục terraform!"
    exit 1
fi

# 1. Tự động lấy biến từ Terraform
cd terraform

REGION=$(terraform output -raw region 2>/dev/null || echo "ap-southeast-1") 
FRONTEND_REPO_URL=$(terraform output -raw ecr_repository_url)
BACKEND_REPO_URL=$(terraform output -raw backend_ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
FRONTEND_SERVICE=$(terraform output -raw ecs_service_name)
BACKEND_SERVICE=$(terraform output -raw backend_ecs_service_name)

cd ..

# 2. Xử lý Image Tag
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)

echo "--- Bắt đầu CI/CD cho Tag: $IMAGE_TAG ---"

# 3. Đăng nhập vào AWS ECR
echo "[1/4] Đăng nhập ECR..."
# Chỉ cần đăng nhập bằng 1 trong các repository URL vì chung registry domain
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $FRONTEND_REPO_URL

# 4. Build Docker Images cho cả Frontend và Backend
echo "[2/4] Đang build Docker images..."

# Build Frontend (Dockerfile ở thư mục gốc)
echo "Building Frontend image..."
docker build --platform linux/amd64 -t $FRONTEND_REPO_URL:$IMAGE_TAG -t $FRONTEND_REPO_URL:latest .

# Build Backend (Dockerfile ở thư mục backend/)
echo "Building Backend image..."
docker build --platform linux/amd64 -t $BACKEND_REPO_URL:$IMAGE_TAG -t $BACKEND_REPO_URL:latest -f backend/Dockerfile backend/

# 5. Push cả 2 Image lên ECR
echo "[3/4] Đang push các images lên ECR..."
docker push $FRONTEND_REPO_URL:$IMAGE_TAG
docker push $FRONTEND_REPO_URL:latest
docker push $BACKEND_REPO_URL:$IMAGE_TAG
docker push $BACKEND_REPO_URL:latest

# 6. Cập nhật cả 2 ECS Services
echo "[4/4] Đang cập nhật ECS Services (Deploy)..."
aws ecs update-service --cluster $CLUSTER_NAME --service $FRONTEND_SERVICE --force-new-deployment --region $REGION
aws ecs update-service --cluster $CLUSTER_NAME --service $BACKEND_SERVICE --force-new-deployment --region $REGION

echo "--- ĐÃ TRIỂN KHAI THÀNH CÔNG! ---"
# Lấy link ALB để hiển thị kết quả cuối cùng
ALB_URL=$(cd terraform && terraform output -raw alb_dns_name)
echo "Kiểm tra ứng dụng của bạn tại: $ALB_URL"