FROM ollama/ollama:0.21.0

ENV DEBIAN_FRONTEND=noninteractive

RUN ollama --version

RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    net-tools \
    lsof \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

COPY set_up_ollama.sh /usr/local/bin/
COPY set_up_nginx.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY generate_nginx_config.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/set_up_ollama.sh \
    && chmod +x /usr/local/bin/set_up_nginx.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/generate_nginx_config.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV NUM_INSTANCES=1
ENV START_PORT=11001
ENV NGINX_PORT=11000

EXPOSE 11000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11000/api/tags || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
