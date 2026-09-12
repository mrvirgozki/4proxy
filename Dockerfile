FROM openresty/openresty:alpine

# ✅ 1. REPO + DEPENDENSIYA (WALA NANG MALI)
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.20/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache ca-certificates wget unzip tini curl haproxy caddy

# ✅ 2. ENVOY: GAMITIN ANG TAMANG STABLE LINK O KUNG AYAW MO, TANGGALIN MUNA PERO ITO ANG SIGURADO:
RUN wget --timeout=300 --tries=5 --no-check-certificate -qO /usr/local/bin/envoy \
    "https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-x86_64" || true && \
    if [ -f /usr/local/bin/envoy ]; then chmod +x /usr/local/bin/envoy; fi

# ✅ 3. XRAY: GAMITIN ANG GITHUB CDN AT SIGURADONG VALID LINKS (WALANG MALING FORMAT)
RUN set -eux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    # ✅ GAMITIN ANG SIGURADONG MIRROR NA HINDI NA-BLOCK SA GCP
    PRIMARY="https://ghproxy.net/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    SECONDARY="https://mirror.ghproxy.com/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    \
    wget --timeout=300 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$PRIMARY" || \
    wget --timeout=300 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$SECONDARY"; \
    \
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

# ✅ 5. PORT FIX
RUN sed -i 's/listen\s*[0-9]\+;/listen 8080 http2;/g' /usr/local/openresty/nginx/conf/nginx.conf

# ✅ 6. ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
