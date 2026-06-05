# Ngat script neu co loi xay ra
$ErrorActionPreference = "Stop"

Write-Host "--- Lay thong tin ha tang tu Terraform ---"

if (-not (Test-Path "terraform")) {
    Write-Error "Loi: Khong tim thay thu muc terraform!"
    exit 1
}

# 1. Tu dong lay bien tu Terraform
cd terraform

$region = (terraform output -raw region)
$frontend_repo = (terraform output -raw ecr_repository_url)
$backend_repo = (terraform output -raw backend_ecr_repository_url)
$cluster_name = (terraform output -raw ecs_cluster_name)
$frontend_service = (terraform output -raw ecs_service_name)
$backend_service = (terraform output -raw backend_ecs_service_name)

cd ..

# 2. Xu ly Image Tag
$image_tag = (git rev-parse --short HEAD 2>$null)
if (-not $image_tag) {
    $image_tag = (Get-Date -Format "yyyyMMddHHmmss")
}

Write-Host "--- Bat dau CI/CD cho Tag: $image_tag ---"

# 3. Dang nhap vao AWS ECR
Write-Host "[1/4] Dang nhap ECR..."
$password = (aws ecr get-login-password --region $region)
$password | docker login --username AWS --password-stdin $frontend_repo

# 4. Build Docker Images cho ca Frontend va Backend
Write-Host "[2/4] Dang build Docker images..."

Write-Host "Building Frontend image..."
docker build --platform linux/amd64 -t "${frontend_repo}:${image_tag}" -t "${frontend_repo}:latest" .

Write-Host "Building Backend image..."
docker build --platform linux/amd64 -t "${backend_repo}:${image_tag}" -t "${backend_repo}:latest" -f backend/Dockerfile backend/

# 5. Push ca 2 Image len ECR
Write-Host "[3/4] Dang push cac images len ECR..."
docker push "${frontend_repo}:${image_tag}"
docker push "${frontend_repo}:latest"
docker push "${backend_repo}:${image_tag}"
docker push "${backend_repo}:latest"

# 6. Cap nhat ca 2 ECS Services
Write-Host "[4/4] Dang cap nhat ECS Services (Deploy)..."
aws ecs update-service --cluster $cluster_name --service $frontend_service --force-new-deployment --region $region
aws ecs update-service --cluster $cluster_name --service $backend_service --force-new-deployment --region $region

Write-Host "--- DA TRIEN KHAI THANH CONG! ---"
cd terraform
$alb_url = (terraform output -raw alb_dns_name)
Write-Host "Kiem tra ung dung cua ban tai: $alb_url"
cd ..
