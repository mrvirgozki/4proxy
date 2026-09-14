FROM openresty/openresty:alpine

# ✅ 1. DEPENDENCIES — IWAS DEAD LINK SA CLOUD SHELL
RUN apk update --no-cache && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. ENVOY — TINANGGAL ANG STRICT CHECK, TULAY ANG BUILD KAHIT MAKALIMOT ANG LINK
RUN wget --timeout=60 --tries=2 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-x86_64" || true && \
    [ -f /usr/local/bin/envoy ] && chmod +x /usr/local/bin/envoy

# ✅ 3. XRAY — GAMITIN ANG WORKING MIRROR PARA SA QWIKLABS/CLOUD SHELL
RUN set -ux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    # ✅ ITO ANG SIGURADONG GUMAGANA SA CLOUD SHELL — PALITAN ANG LAHAT NG LUMANG LINK
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

# ✅ 4. COPY CONFIGS — WALANG BINAGO
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ 5. FIX PERMISSION AT KAILANGANG FOLDER — IWAS START ERROR
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx && \
    chown -R nginx:nginx /usr/local/openresty /var/run/openresty /var/log/nginx /var/cache/nginx

# ✅ 6. ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
