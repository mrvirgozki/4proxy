#!/bin/sh

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Proxy: $PROXY_ENGINE | Port: $PORT"

# ✅ Simulan Xray — dagdag na oras para siguradong ready
echo "🚀 Starting Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /dev/stdout 2>&1 &
sleep 5

# ✅ AYOS: HUWAG GAMITIN ANG `-c /buong/path` — gamitin ang default na paghahanap ng OpenResty
echo "🔍 Checking OpenResty config..."
/usr/local/openresty/nginx/sbin/nginx -t || exit 1

echo "🌐 Starting OpenResty sa 0.0.0.0:$PORT..."
case "$PROXY_ENGINE" in
  openresty)
    # ✅ Siguradong naka-listen sa tamang port, naka-foreground
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off; listen 0.0.0.0:8080 http2;"
    ;;
  envoy)
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;
  haproxy)
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;
  caddy)
    exec /usr/local/bin/caddy run --config /etc/Caddyfile
    ;;
  *)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off; listen 0.0.0.0:8080 http2;"
    ;;
esac

