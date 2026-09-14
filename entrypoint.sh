#!/bin/sh

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Napiling Proxy Engine: $PROXY_ENGINE"
echo "✅ Main port: $PORT"

# Simulan Xray (hindi titigil kahit may warning)
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /dev/stdout 2>&1 &
sleep 3

# Check OpenResty config
echo "🔍 Sinusuri ang OpenResty config..."
/usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf || exit 1

# Simulan main proxy
echo "🌐 Sinisimulan ang $PROXY_ENGINE sa 0.0.0.0:$PORT..."
case "$PROXY_ENGINE" in
  openresty)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
  envoy)
    export LISTEN_PORT=$PORT
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;
  haproxy)
    export LISTEN_PORT=$PORT
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;
  caddy)
    exec /usr/local/bin/caddy run --config /etc/Caddyfile --listen 0.0.0.0:$PORT
    ;;
  *)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
esac
