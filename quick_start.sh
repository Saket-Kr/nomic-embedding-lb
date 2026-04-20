#!/bin/bash

# Quick Start Script for Local Testing

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose not found. Using 'docker compose' instead..."
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

print_status "Starting Nomic Embedding Load Balancer..."

# Create logs directory if it doesn't exist
mkdir -p logs

# Start the service
$COMPOSE_CMD up -d

print_status "✅ Service started successfully!"

# Wait for service to be ready
print_status "Waiting for service to be ready (this may take a few minutes)..."
sleep 30

# Check if service is healthy
print_status "Checking service health..."
if $COMPOSE_CMD ps | grep -q "healthy"; then
    print_status "✅ Service is healthy and ready!"
else
    print_warning "Service may still be starting up. This is normal for the first run."
fi

echo ""
echo "🎉 Nomic Embedding Load Balancer is running!"
echo ""
echo "Service URL: http://localhost:11000"
echo ""
echo "To test the service:"
echo "  python3 test_setup.py"
echo ""
echo "To view logs:"
echo "  $COMPOSE_CMD logs -f"
echo ""
echo "To stop the service:"
echo "  $COMPOSE_CMD down"
echo ""
echo "To restart:"
echo "  $COMPOSE_CMD restart" 