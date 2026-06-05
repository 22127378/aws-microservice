# Stage 1: Install dependencies
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install

# Stage 2: Production
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
# Chỉ cài đặt các dependencies thực tế chạy production (tiết kiệm dung lượng)
RUN npm install --only=production
COPY index.js ./

EXPOSE 5000
ENV PORT=5000
ENV NODE_ENV=production

CMD ["node", "index.js"]
