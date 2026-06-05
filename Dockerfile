# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Copy file cấu hình từ thư mục frontend vào container
COPY frontend/package*.json ./
RUN npm install

# Copy toàn bộ code từ thư mục frontend vào container
COPY frontend/ .
RUN npm run build

# Stage 2: Production (Nginx)
FROM nginx:alpine
# Copy thư mục build từ stage 1
COPY --from=builder /app/build /usr/share/nginx/html

# Đổi port Nginx sang 8080 cho khớp với hạ tầng
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]