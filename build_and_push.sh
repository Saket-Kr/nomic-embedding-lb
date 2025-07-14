#!/bin/bash

# Build and Push Script for Nomic Embedding Load Balancer

set -e

# Configuration
IMAGE_NAME="nomic-embedding-lb"
DEFAULT_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username USERNAME    Docker Hub username"
    echo "  -t, --tag TAG              Image tag (default: latest)"
    echo "  -b, --build-only           Only build, don't push"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -u myusername                    # Build and push with latest tag"
    echo "  $0 -u myusername -t v1.0.0         # Build and push with specific tag"
    echo "  $0 -u myusername -b                 # Only build, don't push"
}

# Parse command line arguments
DOCKER_USERNAME=""
TAG="$DEFAULT_TAG"
BUILD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$DOCKER_USERNAME" && "$BUILD_ONLY" == false ]]; then
    print_error "Docker Hub username is required unless using --build-only"
    show_usage
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Starting build process..."

# Build the image for multiple platforms
print_status "Building Docker image for multiple platforms..."

# Create buildx builder if it doesn't exist
if ! docker buildx ls | grep -q "multiplatform"; then
    print_status "Creating multiplatform builder..."
    docker buildx create --name multiplatform --use
fi

# Use existing or created builder
docker buildx use multiplatform

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "$IMAGE_NAME:$TAG" \
    --load \
    .

if [ $? -eq 0 ]; then
    print_status "✅ Docker image built successfully: $IMAGE_NAME:$TAG"
else
    print_error "❌ Docker build failed"
    exit 1
fi

# Push to Docker Hub if not build-only
if [[ "$BUILD_ONLY" == false && -n "$DOCKER_USERNAME" ]]; then
    FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$TAG"
    print_status "Building and pushing multi-platform image to Docker Hub: $FULL_IMAGE_NAME"
    
    # Build and push multi-platform image directly
    # Note: Docker will handle authentication automatically
    # If not logged in, the push will fail with a clear error message
    
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t "$FULL_IMAGE_NAME" \
        --push \
        .
    
    if [ $? -eq 0 ]; then
        print_status "✅ Multi-platform image pushed successfully to Docker Hub: $FULL_IMAGE_NAME"
        print_status "   Supported architectures: linux/amd64 (Ubuntu/x86_64), linux/arm64 (Mac M1/M2)"
    else
        print_error "❌ Failed to push multi-platform image to Docker Hub"
        exit 1
    fi
else
    # Tag for local use if username provided but build-only
    if [[ -n "$DOCKER_USERNAME" ]]; then
        FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$TAG"
        print_status "Tagging image for Docker Hub: $FULL_IMAGE_NAME"
        docker tag "$IMAGE_NAME:$TAG" "$FULL_IMAGE_NAME"
    fi
fi

print_status "Build process completed successfully!"

# Show usage instructions
if [[ "$BUILD_ONLY" == false && -n "$DOCKER_USERNAME" ]]; then
    echo ""
    echo "🎉 Your multi-platform image is now available on Docker Hub!"
    echo "   Compatible with: Mac (ARM64), Ubuntu/Linux (AMD64), and other architectures"
    echo ""
    echo "Usage examples:"
    echo "  # Basic usage (6 instances)"
    echo "  docker run -d -p 11000:11000 --name nomic-lb $FULL_IMAGE_NAME"
    echo ""
    echo "  # Custom configuration (4 instances)"
    echo "  docker run -d -p 11000:11000 \\"
    echo "    -e NUM_INSTANCES=4 \\"
    echo "    --name nomic-lb-4 \\"
    echo "    $FULL_IMAGE_NAME"
    echo ""
    echo "  # Test the service"
    echo "  python3 test_setup.py"
fi 
