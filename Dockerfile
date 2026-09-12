# Base: OpenResty Alpine
FROM openresty/openresty:alpine

# Install all dependencies + other proxies
RUN apk add --no-cache ca-certificates wget unzip tini curl \
    envoy haproxy caddy

# ✅ Fixed Xray download (no "unsupported file type" error)
RUN wget --timeout=120 --no-check-certificate -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# Copy all configs
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# Fix OpenResty port for Cloud Run
RUN sed -i 's/listen\s*[0-9]*;/listen ${PORT:-8080} http2;/g' /usr/local/openresty/nginx/conf/nginx.conf || true

# Startup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE ${PORT:-8080} 9090 8443

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
