#!/bin/bash

# Function to display usage
show_usage() {
    echo "Usage: docker run -p 11000:11000 [OPTIONS] your-image-name"
    echo ""
    echo "Environment Variables:"
    echo "  NUM_INSTANCES    Number of Ollama instances to start (default: 6)"
    echo "  START_PORT       Starting port for Ollama instances (default: 11001)"
    echo "  NGINX_PORT       Port for nginx load balancer (default: 11000)"
    echo ""
    echo "Example:"
    echo "  docker run -p 11000:11000 -e NUM_INSTANCES=4 your-image-name"
    echo "  docker run -p 11000:11000 -e NUM_INSTANCES=8 -e START_PORT=12001 your-image-name"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

echo "=== Nomic Embedding Load Balancer Setup ==="
echo "Number of Ollama instances: ${NUM_INSTANCES:-6}"
echo "Starting port: ${START_PORT:-11001}"
echo "Nginx port: ${NGINX_PORT:-11000}"
echo ""

# Generate nginx configuration based on number of instances
echo "Generating nginx configuration..."
/usr/local/bin/generate_nginx_config.sh

# Start Ollama instances
echo "Starting Ollama instances..."
/usr/local/bin/set_up_ollama.sh

# Start nginx
echo "Starting nginx..."
/usr/local/bin/set_up_nginx.sh

# Start supervisor to manage all processes
echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf 