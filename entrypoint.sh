#!/bin/sh

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Napiling Proxy Engine: $PROXY_ENGINE"
echo "✅ Main port: $PORT"

# ✅ SIMULAN ANG XRAY — HAYAAN LANG KAHIT MAY BABALA
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &
XRAY_PID=$!
sleep 3
echo "✅ Xray started with PID: $XRAY_PID"

# ✅ I-CHECK MUNA ANG OPENRESTY CONFIG BAGO PATAKBUHIN
echo "🔍 Sinusuri ang OpenResty config..."
/usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf || exit 1

# ✅ SIMULAN ANG MAIN PROXY
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

# ✅ HINDI NA KAILANGAN — KAPAG GUMAMIT KA NG exec, NAGIGING PID 1 ANG NGINX AT HINDI MAG-SASARA

