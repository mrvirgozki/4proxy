# ✅ TAMANG VERSION NA UMIIRAL — HINDI NA MAGKAKA-MISSING MANIFEST
FROM openresty/openresty:alpine

# ✅ 1. DEPENDENCIES — WALANG BINAGO
RUN apk update --no-cache && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. AYOS NA ENVOY DOWNLOAD
RUN wget --timeout=90 --tries=3 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-v1.31.0-linux-x86_64" || \
    wget --timeout=90 --tries=3 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://ghproxy.org/https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-v1.31.0-linux-x86_64" || true && \
    if [ -f /usr/local/bin/envoy ]; then chmod +x /usr/local/bin/envoy; fi

# ✅ 3. AYOS NA XRAY DOWNLOAD
RUN set -x; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    PRIMARY="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    FALLBACK="https://ghproxy.org/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    (wget --timeout=120 --tries=3 --no-check-certificate -qO /tmp/xray.zip "$PRIMARY" || \
     wget --timeout=120 --tries=3 --no-check-certificate -qO /tmp/xray.zip "$FALLBACK") && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ 4. COPY CONFIGS — WALANG BINAGO
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ 5. PERMISSION FIX — WALANG BINAGO
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx
RUN chown -R root:root /usr/local/openresty /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx
RUN chmod -R 755 /usr/local/openresty /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx
RUN chmod -R 777 /var/log/nginx /var/cache/nginx /var/run/openresty

# ✅ 6. ENTRYPOINT — WALANG BINAGO
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# ✅ 7. CLOUD RUN REQUIREMENTS
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
ENV LISTEN_PORT=8080
EXPOSE 8080

USER root:root

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
