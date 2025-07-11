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

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

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