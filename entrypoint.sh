#!/bin/bash
set -e

PROXY_ENGINE="${PROXY_ENGINE:-openresty}"
PORT="${PORT:-8080}"

echo "================================="
echo "Proxy: $PROXY_ENGINE"
echo "Port: $PORT"
echo "================================="

mkdir -p /tmp /var/log

echo "🚀 Starting Xray..."
/usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

sleep 1

if ! kill -0 "$XRAY_PID" 2>/dev/null; then
    echo "❌ ERROR: Xray failed to start"
    exit 1
fi

echo "🌐 Starting main service: $PROXY_ENGINE"

case "$PROXY_ENGINE" in

  openresty)
    echo "🔍 Checking OpenResty configuration..."
    /usr/local/openresty/nginx/sbin/nginx \
      -t -c /usr/local/openresty/nginx/conf/nginx.conf

    echo "✅ Starting OpenResty on port $PORT..."
    exec /usr/local/openresty/nginx/sbin/nginx \
      -c /usr/local/openresty/nginx/conf/nginx.conf \
      -g "daemon off;"
    ;;

  envoy)
    echo "🔍 Checking Envoy configuration..."
    /usr/local/bin/envoy --mode validate -c /etc/envoy.yaml

    echo "✅ Starting Envoy..."
    exec /usr/local/bin/envoy -c /etc/envoy.yaml
    ;;

  haproxy)
    echo "🔍 Checking HAProxy configuration..."
    /usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg

    echo "✅ Starting HAProxy..."
    exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
    ;;

  caddy)
    echo "🔍 Checking Caddy configuration..."
    /usr/bin/caddy validate --config /etc/Caddyfile

    echo "✅ Starting Caddy on port $PORT..."
    exec /usr/bin/caddy run \
      --config /etc/Caddyfile \
      --adapter caddyfile
    ;;

  *)
    echo "❌ Unknown PROXY_ENGINE: $PROXY_ENGINE"
    echo "Available: openresty, envoy, haproxy, caddy"
    exit 1
    ;;

esac
