# --- Cấu hình Remote Backend cho Terraform ---
# Khi bạn đã có sẵn 1 S3 Bucket và 1 bảng DynamoDB trên AWS để quản lý State, 
# hãy bỏ comment đoạn code dưới đây và điền thông tin tương ứng, sau đó chạy `terraform init` để chuyển state lên Cloud.

# terraform {
#   backend "s3" {
#     bucket         = "ten-bucket-s3-cua-ban"       # Ví dụ: "my-terraform-state-bucket"
#     key            = "dev/terraform.tfstate"
#     region         = "ap-southeast-1"
#     dynamodb_table = "ten-bang-dynamodb-lock"      # Ví dụ: "terraform-state-locks" (Partition key phải là LockID dạng String)
#     encrypt        = true
#   }
# }
