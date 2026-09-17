FROM openresty/openresty:alpine

# Magdagdag ng mga kailangang pakete
RUN apk update --no-cache && apk add --no-cache \
    ca-certificates wget unzip tini curl haproxy caddy gettext

# ✅ AYOS NA LINK: pinalitan ang ghproxy.com ng gumaganang ghfast.top
RUN set -eux; \
    ENVOY_VER="v1.31.0"; \
    FILE_NAME="envoy-v1.31.0-linux-x86_64"; \
    PRIMARY="https://github.com/envoyproxy/envoy/releases/download/${ENVOY_VER}/${FILE_NAME}"; \
    FALLBACK="https://ghfast.top/https://github.com/envoyproxy/envoy/releases/download/${ENVOY_VER}/${FILE_NAME}"; \
    (wget --timeout=120 --tries=5 --no-check-certificate -qO /usr/local/bin/envoy "$PRIMARY" || \
     wget --timeout=120 --tries=5 --no-check-certificate -qO /usr/local/bin/envoy "$FALLBACK"); \
    chmod +x /usr/local/bin/envoy

# ✅ AYOS NA LINK: parehong palitan sa Xray download
RUN set -eux; \
    XRAY_VER="v24.10.31"; \
    FILE_NAME="Xray-linux-64.zip"; \
    PRIMARY="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    FALLBACK="https://ghfast.top/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${FILE_NAME}"; \
    (wget --timeout=120 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$PRIMARY" || \
     wget --timeout=120 --tries=5 --no-check-certificate -qO /tmp/xray.zip "$FALLBACK"); \
    unzip -q /tmp/xray.zip -d /tmp/xray/; \
    mv /tmp/xray/xray /usr/local/bin/; \
    mkdir -p /usr/local/share/xray/ /etc/haproxy/; \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/; \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/; \
    chmod +x /usr/local/bin/xray; \
    rm -rf /tmp/xray /tmp/xray.zip

# ✅ TAMA NA ITO: kinokopya ang nginx.conf mula sa folder papunta bilang template
COPY config.json /etc/xray.json
COPY nginx.conf /etc/nginx.conf.template
COPY envoy.yaml /etc/envoy.yaml.template
COPY haproxy.cfg /etc/haproxy/haproxy.cfg.template
COPY Caddyfile /etc/Caddyfile.template
COPY index.html /usr/local/openresty/nginx/html/index.html

# Gumawa ng mga direktoryo at ayusin ang mga pahintulot
RUN mkdir -p /var/run/openresty /var/log/nginx /var/cache/nginx /var/lib/nginx /tmp/nginx /var/log/xray /var/log/envoy; \
    chown -R root:root /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp; \
    chmod -R 755 /usr/local/openresty /var/run /var/log /var/cache /var/lib /tmp

# Kopyahin ang entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Mga Environment Variable (sumusunod sa Cloud Run standard)
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE 8080

USER root:root

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
