#!/bin/sh

PORT="${PORT:-8080}"
export PORT

echo "✅ Main port: $PORT"

# ✅ SIMULAN ANG XRAY
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &
sleep 3
echo "✅ Xray started"

# ✅ I-CHECK ANG NGINX CONFIG
echo "🔍 Sinusuri ang Nginx config..."
/usr/local/openresty/nginx/sbin/nginx -t || exit 1

# ✅ SIMULAN ANG NGINX — SIGURADONG NAKIKINIG SA 0.0.0.0:8080
echo "🌐 Sinisimulan ang Nginx..."
exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
