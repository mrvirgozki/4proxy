#!/bin/sh
set -e

PORT=${PORT:-8080}
echo "✅ Main port: $PORT"

# Start Xray
echo "🚀 Starting Xray..."
/usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

# Start Envoy (load balancing/grpc support)
echo "🚀 Starting Envoy..."
envoy -c /etc/envoy.yaml &
ENVOY_PID=$!

# Start HAProxy (high availability)
echo "🚀 Starting HAProxy..."
haproxy -f /etc/haproxy/haproxy.cfg &
HAPROXY_PID=$!

# Start Caddy (TLS/edge fallback)
echo "🚀 Starting Caddy..."
caddy run --config /etc/Caddyfile &
CADDY_PID=$!

# Start OpenResty (main entry)
echo "🌐 Starting OpenResty on port $PORT..."
exec /usr/local/openresty/bin/openresty -g "daemon off;" &
NGINX_PID=$!

# Restart any stopped service
wait -n
echo "⚠️ Service stopped, restarting all..."
kill $XRAY_PID $ENVOY_PID $HAPROXY_PID $CADDY_PID $NGINX_PID 2>/dev/null || true
exec "$0"
