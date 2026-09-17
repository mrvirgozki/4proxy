#!/bin/sh

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"

echo "✅ Napiling Proxy: $PROXY_ENGINE"
echo "✅ Port: $PORT"

# Simulan Xray (mabilis lang)
/usr/local/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &
sleep 1

# Simulan ang napiling proxy
case "$PROXY_ENGINE" in
  openresty)
    /usr/local/openresty/nginx/sbin/nginx -t || exit 1
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
  envoy)
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;
  haproxy)
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;
  caddy)
    exec /usr/bin/caddy run --config /etc/Caddyfile --listen 0.0.0.0:$PORT
    ;;
  *)
    /usr/local/openresty/nginx/sbin/nginx -t || exit 1
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
esac
