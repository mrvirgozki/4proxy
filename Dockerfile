FROM openresty/openresty:alpine

# Install required packages
RUN apk add --no-cache \
    ca-certificates \
    wget \
    unzip \
    tini \
    haproxy \
    caddy

# Download Envoy
RUN wget --timeout=300 --tries=5 --no-check-certificate \
    -O /usr/local/bin/envoy \
    https://ghfast.top/https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-1.31.0-linux-x86_64 \
    && chmod +x /usr/local/bin/envoy

# Download Xray
RUN wget --timeout=300 --tries=5 --no-check-certificate \
    -O /tmp/xray.zip \
    https://ghfast.top/https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip \
    && unzip -q /tmp/xray.zip -d /tmp/xray/ \
    && mkdir -p /usr/local/share/xray /etc/haproxy \
    && mv /tmp/xray/xray /usr/local/bin/xray \
    && mv /tmp/xray/geoip.dat /usr/local/share/xray/ \
    && mv /tmp/xray/geosite.dat /usr/local/share/xray/ \
    && chmod +x /usr/local/bin/xray \
    && rm -rf /tmp/xray /tmp/xray.zip

# Copy configuration files
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html
COPY entrypoint.sh /entrypoint.sh

# Permissions
RUN chmod 755 /entrypoint.sh \
    && chmod +x /usr/local/bin/xray \
    && chmod +x /usr/local/bin/envoy

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "/entrypoint.sh"]
