FROM openresty/openresty:alpine

# ✅ I-install lahat ng kailangan
RUN apk update --no-cache && apk add --no-cache \
    ca-certificates wget unzip tini curl haproxy caddy

# ✅ Ayos na Envoy Download (direkta, walang kumplikadong fallback)
RUN set -eux; \
    wget --timeout=300 --tries=5 --no-check-certificate \
    -O /usr/local/bin/envoy \
    https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-1.31.0-linux-x86_64; \
    chmod +x /usr/local/bin/envoy

# ✅ Ayos na Xray Download (inuna ang folder)
RUN set -eux; \
    wget --timeout=300 --tries=5 --no-check-certificate \
    -O /tmp/xray.zip \
    https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip; \
    unzip -q /tmp/xray.zip -d /tmp/xray/; \
    mkdir -p /usr/local/share/xray /etc/haproxy; \
    mv /tmp/xray/xray /usr/local/bin/; \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/; \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/; \
    chmod +x /usr/local/bin/xray; \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ KOPYA DIREKTA SA TAMANG LOKASYON — WALANG .TEMPLATE!
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY envoy.yaml /etc/envoy.yaml
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY Caddyfile /etc/Caddyfile
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ Ayusin ang mga folder at pahintulot
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx /var/log/xray /var/log/envoy; \
    chown -R root:root /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp; \
    chmod -R 755 /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp

# ✅ Entrypoint setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# ✅ Environment variables
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

USER root:root
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
