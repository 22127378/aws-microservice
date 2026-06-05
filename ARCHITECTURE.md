# Tài Liệu Giải Thích Các Quyết Định Kỹ Thuật (Architecture Decision Records)

Tài liệu này giải thích **tại sao** chúng ta lựa chọn từng công nghệ, từng cấu hình trong dự án. Mỗi mục sẽ trình bày: vấn đề cần giải quyết, các phương án có thể chọn, phương án được chọn và lý do.

---

## Mục Lục

1. [Tại sao chọn ECS Fargate thay vì EC2?](#1-tại-sao-chọn-ecs-fargate-thay-vì-ec2)
2. [Tại sao chọn DynamoDB thay vì RDS PostgreSQL?](#2-tại-sao-chọn-dynamodb-thay-vì-rds-postgresql)
3. [Tại sao dùng Multi-stage Docker Build?](#3-tại-sao-dùng-multi-stage-docker-build)
4. [Tại sao Frontend dùng Nginx thay vì Node.js serve?](#4-tại-sao-frontend-dùng-nginx-thay-vì-nodejs-serve)
5. [Tại sao đặt Container trong Private Subnet?](#5-tại-sao-đặt-container-trong-private-subnet)
6. [Tại sao dùng ALB Path-based Routing thay vì 2 ALB riêng biệt?](#6-tại-sao-dùng-alb-path-based-routing-thay-vì-2-alb-riêng-biệt)
7. [Tại sao tách riêng Task Execution Role và Task Role?](#7-tại-sao-tách-riêng-task-execution-role-và-task-role)
8. [Tại sao dùng Security Group Chaining?](#8-tại-sao-dùng-security-group-chaining)
9. [Tại sao Frontend gọi API bằng Relative Path `/api/tasks`?](#9-tại-sao-frontend-gọi-api-bằng-relative-path-apitasks)
10. [Tại sao chọn AWS OIDC thay vì IAM Access Key cho CI/CD?](#10-tại-sao-chọn-aws-oidc-thay-vì-iam-access-key-cho-cicd)
11. [Tại sao cần Remote State cho Terraform?](#11-tại-sao-cần-remote-state-cho-terraform)
12. [Tại sao thiết lập ECR Lifecycle Policy và CloudWatch Retention?](#12-tại-sao-thiết-lập-ecr-lifecycle-policy-và-cloudwatch-retention)
13. [Tại sao dùng `desired_count = 2`?](#13-tại-sao-dùng-desired_count--2)
14. [Tại sao dùng Terraform Module cho VPC?](#14-tại-sao-dùng-terraform-module-cho-vpc)
15. [Tại sao Backend chạy Port 5000 và Frontend chạy Port 8080?](#15-tại-sao-backend-chạy-port-5000-và-frontend-chạy-port-8080)

---

## 1. Tại sao chọn ECS Fargate thay vì EC2?

### Vấn đề
Chúng ta cần một nơi để chạy các Docker container trên AWS. Có 2 lựa chọn chính:

| Tiêu chí | EC2 (Máy ảo truyền thống) | ECS Fargate (Serverless Container) |
| :--- | :--- | :--- |
| Quản lý server | Bạn phải tự quản lý, cập nhật bản vá bảo mật, theo dõi dung lượng ổ đĩa | AWS tự động quản lý toàn bộ hạ tầng chạy container |
| Mở rộng (Scaling) | Phải tự cấu hình Auto Scaling Group | Chỉ cần tăng `desired_count`, Fargate tự tìm tài nguyên |
| Chi phí | Phải trả tiền 24/7 cho máy ảo dù không có người truy cập | Chỉ trả tiền theo lượng CPU/RAM thực sự sử dụng |
| Độ phức tạp | Phải cấu hình ECS Agent, Docker daemon, SSH key | Chỉ cần định nghĩa Task Definition, không cần SSH |

### Lựa chọn: **ECS Fargate**
Fargate giúp chúng ta tập trung vào việc viết code và thiết kế hạ tầng bằng Terraform, thay vì phải lo quản trị hệ điều hành của máy ảo. Đây là lựa chọn phổ biến nhất cho các dự án microservice hiện đại vì nó giảm thiểu gánh nặng vận hành (operational overhead) xuống gần như bằng 0.

---

## 2. Tại sao chọn DynamoDB thay vì RDS PostgreSQL?

### Vấn đề
Ứng dụng cần một cơ sở dữ liệu để lưu trữ danh sách task. Có 2 lựa chọn phổ biến trên AWS:

| Tiêu chí | RDS PostgreSQL (SQL) | DynamoDB (NoSQL) |
| :--- | :--- | :--- |
| Kiểu dữ liệu | Bảng có cấu trúc cố định (schema) | Linh hoạt, không cần định nghĩa schema trước |
| Thời gian khởi tạo | 10–15 phút (Terraform phải chờ tạo instance) | Vài giây (chỉ là API call tạo bảng) |
| Chi phí | Phải trả tiền hàng tháng cho instance chạy 24/7 (tối thiểu ~15 USD/tháng) | Miễn phí 100% trong AWS Free Tier (25GB, 25 đơn vị đọc/ghi) |
| Bảo trì | Phải tự backup, cập nhật phiên bản engine | AWS tự động quản lý, không cần bảo trì |
| Kết nối từ ECS | Cần cấu hình username/password và Security Group riêng | Chỉ cần gán IAM Task Role, không cần lưu mật khẩu ở đâu |

### Lựa chọn: **DynamoDB**
Với một ứng dụng Task Manager đơn giản, cấu trúc dữ liệu không phức tạp (chỉ có ID, Name, Description, DueDate, Status). DynamoDB phù hợp hoàn hảo vì:
- **Miễn phí** ở mức sử dụng thấp (rất phù hợp để học và thực hành).
- **Không cần quản lý mật khẩu**: Thay vì phải lưu trữ database password trong biến môi trường (có nguy cơ rò rỉ), chúng ta sử dụng **IAM Task Role** để cấp quyền. Container tự động được AWS cấp quyền truy cập mà không cần bất kỳ thông tin đăng nhập cứng nào.
- **Tạo nhanh bằng Terraform**: Chỉ mất vài giây thay vì 15 phút như RDS.

---

## 3. Tại sao dùng Multi-stage Docker Build?

### Vấn đề
Khi build một ứng dụng React, chúng ta cần Node.js và hàng nghìn gói thư viện (devDependencies) để biên dịch JSX thành HTML/CSS/JS tĩnh. Tuy nhiên, khi chạy thực tế, chúng ta chỉ cần một web server nhẹ để phục vụ các file tĩnh đó.

### Nếu dùng Single-stage (1 tầng):
```dockerfile
FROM node:20
WORKDIR /app
COPY . .
RUN npm install && npm run build
CMD ["npx", "serve", "-s", "build"]
```
**Kết quả**: Image nặng **~1.5 GB** vì chứa cả Node.js, npm, toàn bộ node_modules và mã nguồn gốc.

### Nếu dùng Multi-stage (2 tầng):
```dockerfile
# Tầng 1: Build (chỉ dùng tạm thời)
FROM node:20-alpine AS builder
COPY . . && RUN npm install && npm run build

# Tầng 2: Chạy thực tế (chỉ giữ file tĩnh)
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
```
**Kết quả**: Image chỉ nặng **~30 MB** vì chỉ chứa Nginx và các file HTML/CSS/JS đã biên dịch.

### Lựa chọn: **Multi-stage Build**
Giảm dung lượng image từ ~1.5 GB xuống ~30 MB mang lại 3 lợi ích:
1. **Tiết kiệm chi phí lưu trữ** trên ECR.
2. **Tải image nhanh hơn** khi ECS khởi chạy container mới (thời gian deploy giảm đáng kể).
3. **Tăng bảo mật**: Image sản xuất không chứa công cụ build (npm, node), giảm bề mặt tấn công.

---

## 4. Tại sao Frontend dùng Nginx thay vì Node.js serve?

### Vấn đề
Sau khi React build xong, chúng ta có một thư mục `build/` chứa file tĩnh (HTML, CSS, JS). Cần một web server để phục vụ các file này.

| Tiêu chí | Node.js (`serve` hoặc `express.static`) | Nginx |
| :--- | :--- | :--- |
| Tài nguyên tiêu thụ | Node.js dùng V8 engine, chiếm ~50-100 MB RAM | Nginx dùng event-driven C, chỉ chiếm ~5-10 MB RAM |
| Hiệu suất phục vụ file tĩnh | Trung bình | Rất cao (được thiết kế chuyên biệt cho việc này) |
| Dung lượng image | ~150 MB (node:alpine) | ~10 MB (nginx:alpine) |

### Lựa chọn: **Nginx Alpine**
Nginx là lựa chọn tiêu chuẩn trong ngành để phục vụ các ứng dụng Single Page Application (SPA) như React. Nó nhẹ hơn, nhanh hơn và tiết kiệm tài nguyên hơn Node.js rất nhiều lần khi chỉ cần phục vụ file tĩnh.

---

## 5. Tại sao đặt Container trong Private Subnet?

### Vấn đề
Có 2 cách triển khai container trên AWS:
- **Public Subnet + Public IP**: Container có thể truy cập trực tiếp từ internet.
- **Private Subnet + NAT Gateway**: Container không có IP công khai, hoàn toàn bị ẩn khỏi internet.

### Lựa chọn: **Private Subnet**

```text
Mô hình ĐÚNG (Private Subnet):
Internet → ALB (Public) → Container (Private) → DynamoDB

Mô hình RỦI RO (Public Subnet):
Internet → ALB (Public) → Container (Public) ← Hacker có thể tấn công trực tiếp!
Internet ────────────────→ Container (Public) ← Hacker bypass ALB!
```

Khi container nằm trong Private Subnet:
- **Không ai có thể truy cập trực tiếp** vào container từ internet, kể cả khi biết IP nội bộ của nó.
- Mọi traffic từ người dùng **bắt buộc phải đi qua ALB** (nơi có thể cấu hình WAF, rate limiting, SSL).
- Container vẫn có thể **đi ra internet** (để tải thư viện, kết nối AWS API) thông qua **NAT Gateway** một chiều.

Đây là một nguyên tắc bảo mật cơ bản nhất (Defense in Depth) mà mọi Junior DevOps cần nắm vững.

---

## 6. Tại sao dùng ALB Path-based Routing thay vì 2 ALB riêng biệt?

### Vấn đề
Dự án có 2 service (Frontend và Backend). Làm sao để người dùng truy cập được cả 2 thông qua một địa chỉ duy nhất?

| Phương án | Chi phí | Độ phức tạp |
| :--- | :--- | :--- |
| 2 ALB riêng biệt (1 cho frontend, 1 cho backend) | ~30 USD/tháng (mỗi ALB ~15 USD) | Frontend phải hardcode domain của ALB backend |
| 1 ALB + Path-based Routing | ~15 USD/tháng | Frontend gọi API bằng relative path, không cần biết domain backend |

### Lựa chọn: **1 ALB + Path-based Routing**

```text
http://alb-domain.com/         → Frontend (React UI)
http://alb-domain.com/api/*    → Backend (Express API)
```

Ưu điểm:
1. **Tiết kiệm 50% chi phí** Load Balancer.
2. **Không bị lỗi CORS**: Vì frontend và backend cùng chung một domain (ALB DNS), trình duyệt coi đây là cùng nguồn gốc (same-origin). Nếu dùng 2 ALB, trình duyệt sẽ chặn request cross-origin.
3. **Dễ mở rộng**: Sau này thêm service mới (ví dụ: `/auth/*`, `/admin/*`), chỉ cần thêm 1 Listener Rule mới.

---

## 7. Tại sao tách riêng Task Execution Role và Task Role?

### Vấn đề
Trong ECS, có 2 loại IAM Role hoàn toàn khác nhau:

| Role | Ai sử dụng? | Dùng để làm gì? |
| :--- | :--- | :--- |
| **Task Execution Role** | **Hạ tầng ECS** (AWS nội bộ) | Kéo Docker image từ ECR, ghi log lên CloudWatch |
| **Task Role** | **Code ứng dụng** (chạy bên trong container) | Gọi các dịch vụ AWS khác (DynamoDB, S3, SQS, v.v.) |

### Lựa chọn: **Tách riêng 2 Role**

Nếu chỉ dùng 1 Role chung, ứng dụng backend sẽ vô tình có thêm quyền kéo image từ ECR và ghi log — những quyền mà code ứng dụng **không cần và không nên có**. Điều này vi phạm nguyên tắc **Least Privilege** (Quyền tối thiểu).

Trong dự án này:
- **Task Execution Role** (`ecs-task-execution-role`): Chỉ có quyền kéo image từ ECR và ghi log CloudWatch. Cả frontend và backend đều dùng chung role này.
- **Task Role** (`ecs-task-role`): Chỉ có quyền `Scan`, `GetItem`, `PutItem`, `UpdateItem`, `DeleteItem` trên **đúng 1 bảng DynamoDB**. Chỉ backend mới cần role này.

---

## 8. Tại sao dùng Security Group Chaining?

### Vấn đề
Làm sao để đảm bảo container chỉ nhận traffic hợp lệ từ Load Balancer, chứ không phải từ bất kỳ nguồn nào khác trong VPC?

### Cách thông thường (Không an toàn):
```hcl
ingress {
  from_port   = 8080
  cidr_blocks = ["10.0.0.0/16"]  # Cho phép toàn bộ VPC truy cập
}
```
→ Bất kỳ tài nguyên nào trong VPC (kể cả một EC2 bị hack) đều có thể truy cập trực tiếp vào container.

### Cách dùng Security Group Chaining (An toàn):
```hcl
ingress {
  from_port       = 8080
  security_groups = [aws_security_group.alb_sg.id]  # CHỈ cho phép traffic từ ALB
}
```
→ Chỉ có traffic đi qua ALB Security Group mới được phép vào container. Mọi nguồn traffic khác đều bị từ chối.

### Lựa chọn: **Security Group Chaining**
Đây là best practice tiêu chuẩn trong thiết kế hạ tầng AWS, giúp tạo ra một chuỗi tin cậy (chain of trust): `Internet → ALB SG → ECS SG → DynamoDB (qua IAM)`.

---

## 9. Tại sao Frontend gọi API bằng Relative Path `/api/tasks`?

### Vấn đề
Frontend React cần gọi API của Backend. Có 2 cách:

| Cách | Ví dụ | Vấn đề |
| :--- | :--- | :--- |
| Absolute URL | `http://backend-service:5000/tasks` | Hardcode domain, bị lỗi CORS, khó thay đổi môi trường |
| Relative Path | `/api/tasks` | Tự động gửi request về cùng domain đang truy cập |

### Lựa chọn: **Relative Path `/api/tasks`**

Khi người dùng truy cập `http://alb-domain.com` và React gọi `fetch("/api/tasks")`, trình duyệt tự động gửi request tới `http://alb-domain.com/api/tasks`. ALB nhận được request này và dựa vào Listener Rule để chuyển tiếp sang Backend Target Group.

Ưu điểm:
1. **Không bị lỗi CORS** vì request cùng domain.
2. **Không cần thay đổi code** khi chuyển đổi môi trường (dev, staging, production) — chỉ cần thay đổi DNS của ALB.
3. **Không lộ thông tin** domain nội bộ của backend ra phía trình duyệt người dùng.

---

## 10. Tại sao chọn AWS OIDC thay vì IAM Access Key cho CI/CD?

### Vấn đề
GitHub Actions cần quyền truy cập AWS để push image và deploy. Có 2 cách cấp quyền:

| Cách | Bảo mật | Quản lý |
| :--- | :--- | :--- |
| **IAM Access Key** (lưu trong GitHub Secrets) | Rủi ro cao — key tĩnh, không hết hạn, nếu bị rò rỉ thì hacker có toàn quyền | Phải tự xoay vòng (rotate) key định kỳ |
| **AWS OIDC** (OpenID Connect) | An toàn cao — token tạm thời, tự hết hạn sau vài phút, chỉ có hiệu lực cho đúng repository được chỉ định | AWS tự quản lý, không có key cố định để rò rỉ |

### Lựa chọn: **AWS OIDC**

Cơ chế hoạt động:
1. GitHub Actions yêu cầu AWS: "Tôi là repository `user/repo`, nhánh `main`, hãy cấp cho tôi quyền tạm thời".
2. AWS kiểm tra: "Repository này có nằm trong danh sách tin cậy của IAM Role không?"
3. Nếu hợp lệ, AWS trả về một **token tạm thời** chỉ có hiệu lực trong vài phút.
4. GitHub Actions dùng token này để thực hiện triển khai, sau đó token tự hủy.

→ Kể cả nếu ai đó hack được GitHub Actions log, họ cũng không thể tái sử dụng token đã hết hạn.

---

## 11. Tại sao cần Remote State cho Terraform?

### Vấn đề
Terraform lưu trạng thái hạ tầng (state) vào file `terraform.tfstate`. Mặc định, file này nằm trên máy cá nhân.

| Lưu State ở đâu? | Rủi ro |
| :--- | :--- |
| **Local** (trên máy cá nhân) | Mất máy = mất state = mất kiểm soát hạ tầng. 2 người chạy cùng lúc = ghi đè lẫn nhau |
| **Remote** (S3 + DynamoDB Lock) | State được mã hóa trên đám mây, có cơ chế khoá (locking) tránh 2 người chạy đồng thời |

### Lựa chọn: **Remote State trên S3** (đã cấu hình mẫu sẵn)

Trong dự án, file `backend.tf` đã được tạo sẵn cấu hình mẫu (đang ở trạng thái comment). Khi bạn sẵn sàng làm việc nhóm hoặc đưa dự án lên môi trường thực tế, chỉ cần bỏ comment và điền tên S3 bucket.

---

## 12. Tại sao thiết lập ECR Lifecycle Policy và CloudWatch Retention?

### Vấn đề
Mỗi lần deploy, chúng ta push một Docker image mới lên ECR và tạo thêm log mới trên CloudWatch. Nếu không kiểm soát, các tài nguyên cũ sẽ tích tụ và gây tốn phí lưu trữ.

### Lựa chọn:
- **ECR Lifecycle Policy**: Chỉ giữ lại **5 image mới nhất**, tự động xóa các image cũ hơn. Điều này đảm bảo bạn vẫn có thể rollback về 4 phiên bản trước đó nếu cần, nhưng không phải trả tiền lưu trữ cho hàng trăm image cũ.
- **CloudWatch Log Retention = 7 ngày**: Log cũ hơn 1 tuần thường không còn giá trị debug. Giữ 7 ngày đủ để phát hiện và xử lý sự cố.

---

## 13. Tại sao dùng `desired_count = 2`?

### Vấn đề
`desired_count` quyết định số lượng container chạy song song cho mỗi service.

| desired_count | Ưu điểm | Nhược điểm |
| :--- | :--- | :--- |
| 1 | Tiết kiệm chi phí nhất | Nếu container bị crash hoặc đang update, ứng dụng sẽ gián đoạn hoàn toàn (downtime) |
| 2 | Luôn có ít nhất 1 container hoạt động khi container kia đang được cập nhật hoặc gặp sự cố | Chi phí gấp đôi |

### Lựa chọn: **`desired_count = 2`**
Với 2 container chạy ở 2 Availability Zones khác nhau (`ap-southeast-1a` và `ap-southeast-1b`):
- Khi deploy phiên bản mới, ECS sẽ tạo container mới trước, kiểm tra sức khỏe, rồi mới tắt container cũ (**Zero-downtime deployment**).
- Nếu một datacenter (AZ) của AWS gặp sự cố, container ở AZ còn lại vẫn phục vụ bình thường (**High Availability**).

---

## 14. Tại sao dùng Terraform Module cho VPC?

### Vấn đề
Việc tạo VPC hoàn chỉnh (gồm VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables) yêu cầu khoảng 15–20 resource Terraform riêng lẻ. Viết thủ công sẽ rất dài và dễ sai.

### Lựa chọn: **Module `terraform-aws-modules/vpc/aws`**
Module này được cộng đồng Terraform phát triển và duy trì, có hơn **10 triệu lượt tải xuống**. Nó đóng gói toàn bộ logic tạo VPC phức tạp vào chỉ ~20 dòng cấu hình.

Ưu điểm:
1. **Giảm thiểu lỗi**: Module đã được kiểm thử kỹ lưỡng bởi cộng đồng.
2. **Dễ đọc**: Chỉ cần nhìn vào 20 dòng config là hiểu toàn bộ thiết kế mạng.
3. **Best practice sẵn có**: Module tự động xử lý các edge case như tạo route table cho từng subnet, gắn NAT Gateway đúng cách.

---

## 15. Tại sao Backend chạy Port 5000 và Frontend chạy Port 8080?

### Vấn đề
Tại sao không dùng port mặc định 80 cho cả hai?

### Lựa chọn:
- **Frontend dùng port 8080**: Trong Fargate, container chạy với user không có quyền root. Các port dưới 1024 (như 80, 443) là **privileged ports** — yêu cầu quyền root để bind. Port 8080 là port phổ biến nhất để thay thế port 80 trong môi trường container.
- **Backend dùng port 5000**: Đây là port mặc định phổ biến nhất cho các ứng dụng Node.js/Express. Việc dùng port khác nhau cho mỗi service giúp dễ dàng phân biệt khi debug log và cấu hình Security Group.

> **Lưu ý quan trọng**: Người dùng cuối **không bao giờ thấy** các port này. Họ chỉ truy cập port 80 của ALB. ALB chịu trách nhiệm chuyển tiếp traffic nội bộ tới đúng port của từng container.
