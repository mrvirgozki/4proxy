# ✅ GAMITIN ANG TAMANG EXISTING VERSION (ALPINE VARIANT AY NASA V1.30.0)
FROM envoyproxy/envoy:v1.30.0-alpine AS envoy-source

# Base: OpenResty Alpine
FROM openresty/openresty:alpine

# ✅ 1. I-INSTALL ANG TAMANG REPO AT DEPENDENSIYA
RUN apk add --no-cache ca-certificates wget unzip tini curl && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories && \
    apk add --no-cache haproxy caddy

# ✅ 2. KOPYAHIN LANG ANG ENVOY — WALANG DOWNLOAD ERROR
COPY --from=envoy-source /usr/local/bin/envoy /usr/local/bin/envoy
RUN chmod +x /usr/local/bin/envoy

# ✅ 3. FIXED Xray download — may dagdag na mirror backup kung ma-block ang GitHub
RUN wget --timeout=180 --retry-connrefused --tries=3 -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip || \
    wget --timeout=180 --retry-connrefused --tries=3 -qO /tmp/xray.zip https://ghp.ci/https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ 4. COPY LAHAT NG CONFIGS — SIGURADUHIN NANDOON SA FOLDER
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ 5. FIX OPENRESTY PORT PARA SA CLOUD RUN
RUN sed -i 's/listen\s*[0-9]\+;/listen ${PORT:-8080} http2;/g' /usr/local/openresty/nginx/conf/nginx.conf

# ✅ 6. ENTRYPOINT AT PERMISSIONS
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE ${PORT:-8080} 9090 8443

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
