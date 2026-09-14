#!/bin/sh
set -e

# Gamitin ang napiling proxy mula sa env var (default: openresty)
PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Napiling Proxy Engine: $PROXY_ENGINE"
echo "✅ Main port: $PORT"

# ✅ Laging simulan ang Xray (nasa likod lang)
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json &
XRAY_PID=$!

# ✅ Simulan LANG ang napiling proxy — walang conflict!
case "$PROXY_ENGINE" in
  openresty)
    echo "🌐 Sinisimulan ang OpenResty..."
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
  envoy)
    echo "🚀 Sinisimulan ang Envoy..."
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;
  haproxy)
    echo "🚀 Sinisimulan ang HAProxy..."
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;
  caddy)
    echo "🚀 Sinisimulan ang Caddy..."
    exec /usr/local/bin/caddy run --config /etc/Caddyfile
    ;;
  *)
    echo "⚠️ Hindi kilalang proxy: $PROXY_ENGINE — gagamitin ang default na OpenResty"
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
esac
