FROM openresty/openresty:alpine

# ✅ I-install lahat ng kailangan (walang palya)
RUN apk update --no-cache && apk add --no-cache \
    ca-certificates wget unzip tini curl haproxy caddy gettext

# ✅ INAYOS NA ENVOY DOWNLOAD (tama ang pangalan, simpleng paraan)
RUN set -eux; \
    wget --timeout=300 --tries=3 --no-check-certificate \
    -O /usr/local/bin/envoy \
    https://github.com/envoyproxy/envoy/releases/download/v1.31.0/envoy-1.31.0-linux-x86_64; \
    chmod +x /usr/local/bin/envoy

# ✅ INAYOS NA XRAY DOWNLOAD (tama ang pangalan at file)
RUN set -eux; \
    wget --timeout=300 --tries=3 --no-check-certificate \
    -O /tmp/xray.zip \
    https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip; \
    unzip -q /tmp/xray.zip -d /tmp/xray/; \
    mv /tmp/xray/xray /usr/local/bin/; \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/; \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/; \
    mkdir -p /usr/local/share/xray /etc/haproxy; \
    chmod +x /usr/local/bin/xray; \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ COPY NG FILES (tugma sa setup mo)
COPY config.json /etc/xray.json
COPY nginx.conf /etc/nginx.conf.template
COPY envoy.yaml /etc/envoy.yaml.template
COPY haproxy.cfg /etc/haproxy/haproxy.cfg.template
COPY Caddyfile /etc/Caddyfile.template
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ Ayos ng folder at permissions
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx /var/log/xray /var/log/envoy; \
    chown -R root:root /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp; \
    chmod -R 755 /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp

# ✅ Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

USER root:root
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]

