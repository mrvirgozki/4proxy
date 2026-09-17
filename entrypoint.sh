#!/bin/sh

# ❌ TINANGGAL ANG set -e — ITO ANG PUMAPATAY SA SCRIPT KANINA!

# Itakda ang default values
PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Napiling Proxy Engine: $PROXY_ENGINE"
echo "✅ Main Port: $PORT"

# Simulan ang Xray sa background — hayaan lang kahit may babala
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &
sleep 2
echo "✅ Xray started in background"

# Piliin at simulan ang napiling proxy
echo "🌐 Sinisimulan ang $PROXY_ENGINE sa port $PORT..."
case "$PROXY_ENGINE" in
  openresty)
    /usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf
    exec /usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf -g "daemon off;"
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
    echo "⚠️ Defaulting to OpenResty"
    /usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf
    exec /usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf -g "daemon off;"
    ;;
esac

