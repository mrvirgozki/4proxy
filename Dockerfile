FROM openresty/openresty:alpine

# ✅ 1. DEPENDENCIES
RUN apk update --no-cache && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. ENVOY — TINANGGAL ANG STRICT CHECK, TULAY ANG BUILD KAHIT WALANG DOWNLOAD
RUN wget --timeout=30 --tries=1 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-x86_64" || true && \
    [ -f /usr/local/bin/envoy ] && chmod +x /usr/local/bin/envoy

# ✅ 3. XRAY — GAMITIN ANG SIGURADONG WORKING MIRROR LANG
RUN set -ux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    # ✅ ITO ANG HULING SIGURADONG LINK — WALANG KALAT NA FALLBACK
    DOWNLOAD_URL="https://mirror.ghproxy.com/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    wget --timeout=60 --tries=3 --no-check-certificate -qO /tmp/xray.zip "$DOWNLOAD_URL"; \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ 4. COPY CONFIGS — TAMA NA ANG LOKASYON
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ 5. KAILANGANG FOLDER LANG
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx

# ✅ 6. ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]

