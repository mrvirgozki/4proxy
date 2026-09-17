#!/bin/bash

# Default values
PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"

echo "✅ Proxy: $PROXY_ENGINE | Port: $PORT"

# Siguraduhin ang mga folder
mkdir -p /tmp /var/log

# Simulan Xray sa background
echo "🚀 Starting Xray..."
/usr/local/bin/xray run -c /etc/xray.json &
sleep 1

# Simulan ang napiling proxy
echo "🌐 Starting main service..."
case "$PROXY_ENGINE" in
  openresty)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
  envoy)
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;
  haproxy)
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;
  caddy)
    exec /usr/bin/caddy run --config /etc/Caddyfile --listen :$PORT
    ;;
  *)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
esac

