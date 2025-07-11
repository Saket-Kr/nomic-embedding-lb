#!/bin/bash

# Get configuration from environment variables
NUM_INSTANCES=${NUM_INSTANCES:-6}
START_PORT=${START_PORT:-11001}
NGINX_PORT=${NGINX_PORT:-11000}

echo "Generating nginx configuration for $NUM_INSTANCES Ollama instances starting from port $START_PORT..."

# Generate the upstream block
cat > /etc/nginx/conf.d/ollama_loadbalancer.conf << EOF
upstream ollama_backends {
    least_conn;
EOF

# Add server entries for each instance
for i in $(seq 0 $(($NUM_INSTANCES-1))); do
    PORT=$(($START_PORT + $i))
    echo "    server 127.0.0.1:$PORT;" >> /etc/nginx/conf.d/ollama_loadbalancer.conf
done

# Add the server block
cat >> /etc/nginx/conf.d/ollama_loadbalancer.conf << EOF
}

server {
    listen $NGINX_PORT;
    client_max_body_size 10M;
    
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    
    location / {
        proxy_pass http://ollama_backends;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        proxy_buffering off;
    }
}
EOF

echo "Nginx configuration generated successfully!"
echo "Configuration file: /etc/nginx/conf.d/ollama_loadbalancer.conf" 