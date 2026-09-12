# ✅ TANGGALIN NA ANG ENVOY SOURCE — DIREKTA NA LANG ANG PAG-INSTALL
FROM openresty/openresty:alpine

# ✅ 1. DEPENDENSIYA + ENVOY (DIREKTA SA ALPINE REPO — WALANG ERROR)
RUN apk add --no-cache ca-certificates wget unzip tini curl envoy && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories && \
    apk add --no-cache haproxy caddy

# ✅ 2. SIGURADUHIN NAKA-EXECUTE ANG ENVOY
RUN chmod +x /usr/bin/envoy

# ✅ 3. XRAY DOWNLOAD — MAY TRIPLE FALLBACK PARA HINDI MA-FAIL
RUN set -eux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    PRIMARY="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    SECONDARY="https://gh.ddlc.top/${PRIMARY}"; \
    TERTIARY="https://hub.fastgit.xyz/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    \
    wget --timeout=240 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$PRIMARY" || \
    wget --timeout=240 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$SECONDARY" || \
    wget --timeout=240 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$TERTIARY"; \
    \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ 4. KOPYAHIN ANG LAHAT NG CONFIG
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ 5. PORT SETUP PARA SA CLOUD RUN
RUN sed -i 's/listen\s*[0-9]\+;/listen 8080 http2;/g' /usr/local/openresty/nginx/conf/nginx.conf

# ✅ 6. ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
