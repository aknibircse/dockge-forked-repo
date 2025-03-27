#!/bin/sh
# Generate self-signed SSL certificates for Nginx

# Create directory for certificates
mkdir -p /etc/nginx/ssl

# Generate a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo "Self-signed SSL certificates generated successfully"
