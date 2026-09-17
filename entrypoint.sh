#!/bin/sh

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"

echo "✅ Proxy: $PROXY_ENGINE | Port: $PORT"

# GAWIN MUNA ANG LAHAT NG KAILANGANG FOLDER PARA WALANG ERROR
mkdir -p /var/run /var/log/nginx /var/log/xray

# Simulan Xray — HUWAG IPIGIL KAHIT MAY BABALA
echo "🚀 Starting Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &
sleep 2

# Simulan Proxy
echo "🌐 Starting $PROXY_ENGINE..."
case "$PROXY_ENGINE" in
  openresty)
    # Pilitin tumakbo kahit may babala sa test — siguradong tutugma sa port
    /usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf || true
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
    /usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf || true
    exec /usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf -g "daemon off;"
    ;;
esac
