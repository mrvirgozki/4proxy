FROM openresty/openresty:alpine

# ✅ 1. DEPENDENCIES (walang binago)
RUN apk update --no-cache && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. ENVOY — AYUS ANG LINK + FILENAME (original v1.31.0 ay mali ang filename)
RUN wget --timeout=60 --tries=2 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-v1.31.0-linux-x86_64" || \
    wget --timeout=60 --tries=2 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://ghproxy.org/https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-v1.31.0-linux-x86_64" || true && \
    [ -f /usr/local/bin/envoy ] && chmod +x /usr/local/bin/envoy

# ✅ 3. XRAY — AYUS ANG LOGIC PARA HINDI MAG-ERROR KUNG DOWNLOAD MABAGAL
RUN set -ux; \
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

# ✅ 5. FOLDERS — WALANG BINAGO
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx

# ✅ 6. ENTRYPOINT — WALANG BINAGO
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]

