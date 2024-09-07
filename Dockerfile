# stage1: build
FROM node:22.7.0 AS builder
WORKDIR /app
# install pnpm
RUN npm install -g pnpm
RUN npm install --save-dev postcss-import
 
# Copy package.json and pnpm-lock.yaml to the container 
COPY package*.json pnpm-lock.yaml  ./
 
# use pnpm to install dependencies
RUN pnpm install
 
# Copy the rest of the application code to the container
COPY . .
 
# Build the application
RUN pnpm build

# stage2: deploy to nginx
FROM nginx:latest
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
# start Nginx
CMD ["nginx", "-g", "daemon off;"]
