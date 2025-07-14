FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV START_PORT=11001
ENV NUM_INSTANCES=6
ENV NGINX_PORT=11000

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    net-tools \
    lsof \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama with retries and fallback for better reliability in multi-platform builds
RUN set -e && \
    OLLAMA_INSTALLED=false && \
    # Try script-based installation first (3 attempts)
    for i in 1 2 3; do \
        echo "Script installation attempt $i..." && \
        if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 600 \
            https://ollama.com/install.sh | sh; then \
            OLLAMA_INSTALLED=true && break; \
        else \
            echo "Script installation attempt $i failed" && sleep 10; \
        fi; \
    done && \
    # Fallback: Manual installation if script failed
    if [ "$OLLAMA_INSTALLED" = "false" ]; then \
        echo "Script installation failed, trying manual installation..." && \
        ARCH=$(uname -m) && \
        case $ARCH in \
            x86_64) OLLAMA_ARCH="amd64" ;; \
            aarch64|arm64) OLLAMA_ARCH="arm64" ;; \
            *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
        esac && \
        curl -fsSL --retry 5 --retry-delay 3 --connect-timeout 30 --max-time 600 \
            "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-${OLLAMA_ARCH}" \
            -o /usr/local/bin/ollama && \
        chmod +x /usr/local/bin/ollama; \
    fi && \
    # Verify installation
    if ! command -v ollama >/dev/null 2>&1; then \
        echo "Ollama installation failed completely" && exit 1; \
    else \
        echo "Ollama installed successfully: $(ollama --version)"; \
    fi

# Create directories
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

# Copy scripts
COPY set_up_ollama.sh /usr/local/bin/
COPY set_up_nginx.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY generate_nginx_config.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/set_up_ollama.sh \
    && chmod +x /usr/local/bin/set_up_nginx.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/generate_nginx_config.sh

# Create supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 11000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11000/api/tags || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 
