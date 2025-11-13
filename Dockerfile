# Stage 1: Build
FROM golang:alpine AS builder

# Install build dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /build

# Copy Go dependency files
COPY src/go.mod src/go.sum ./
RUN go mod download

# Copy all source code
COPY src/ ./

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o m3u_gen_acestream m3u_gen_acestream.go

# Stage 2: Runtime with Nginx
FROM alpine:latest

# Install crond, nginx, gettext (for envsubst), and supervisor
RUN apk add --no-cache dcron tzdata gettext nginx supervisor

# Create necessary directories
RUN mkdir -p /app /app/out /srv/m3u /run/nginx /var/log/supervisor

# Copy binary from build stage
COPY --from=builder /build/m3u_gen_acestream /app/m3u_gen_acestream
RUN chmod +x /app/m3u_gen_acestream

# Copy Docker configuration
COPY m3u_gen_acestream.docker.yaml /app/m3u_gen_acestream.yaml

# Copy scripts
COPY entrypoint.sh /app/entrypoint.sh
COPY generate.sh /app/generate.sh
RUN chmod +x /app/entrypoint.sh /app/generate.sh

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisord.conf

# Expose nginx port
EXPOSE 8080

WORKDIR /app

# Run supervisor to manage both services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
