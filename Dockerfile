FROM openresty/openresty:alpine

# ✅ 1. DEPENDENCIES
RUN apk update --no-cache && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. ENVOY (fallback kung mabigo download)
RUN wget --timeout=60 --tries=2 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-x86_64" || true && \
    [ -f /usr/local/bin/envoy ] && chmod +x /usr/local/bin/envoy

# ✅ 3. XRAY (siguradong working links)
RUN set -ux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    PRIMARY="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    FALLBACK="https://ghproxy.org/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    wget --timeout=60 --tries=2 --no-check-certificate -qO /tmp/xray.zip "$PRIMARY" || \
    wget --timeout=60 --tries=2 --no-check-certificate -qO /tmp/xray.zip "$FALLBACK"; \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ 4. COPY CONFIGS
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ INAYOS: GAMITIN ANG TAMANG USER (openresty base image gumagamit ng nobody/root, tanggalin na ang chown na nagdudulot ng error)
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx

# ✅ 5. ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]

