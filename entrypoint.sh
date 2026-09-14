#!/bin/sh
# ❌ TINANGGAL ANG "set -e" — HINDI NA MAMATAY ANG CONTAINER KAPAG MAY WARNING LANG SA XRAY

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"
export PORT

echo "✅ Napiling Proxy Engine: $PROXY_ENGINE"
echo "✅ Main port: $PORT"

# ✅ SIMULAN ANG XRAY — HAYAAN LANG KAHIT MAY BABALA
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /dev/stdout 2>&1 &
sleep 3 # Bigyan ng oras mag-init

# ✅ I-CHECK MUNA ANG OPENRESTY CONFIG BAGO PATAKBUHIN
echo "🔍 Sinusuri ang OpenResty config..."
/usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/openresty/nginx/conf/nginx.conf || exit 1

# ✅ SIMULAN ANG MAIN PROXY — EXEC PARA MAGING PID 1 (HINDI MAG-SASARA)
echo "🌐 Sinisimulan ang OpenResty sa 0.0.0.0:$PORT..."
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
    exec /usr/local/bin/caddy run --config /etc/Caddyfile
    ;;
  *)
    exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
    ;;
esac
