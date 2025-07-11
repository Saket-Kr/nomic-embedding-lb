#!/bin/bash

# Get configuration from environment variables
NGINX_PORT=${NGINX_PORT:-11000}

echo "Setting up Nginx load balancer on port $NGINX_PORT..."

# Remove default nginx site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Test nginx configuration
echo "Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid"
    echo "Nginx load balancer will be started by supervisor"
else
    echo "Nginx configuration test failed. Please check the configuration manually."
    exit 1
fi

echo "Nginx setup complete!"