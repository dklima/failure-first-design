#!/bin/bash
# Chaos Engineering: Database Latency Simulation with Toxiproxy
#
# Toxiproxy sits between your app and the database, injecting failures.
#
# Install:
#   Ubuntu/Debian:
#     wget https://github.com/Shopify/toxiproxy/releases/download/v2.9.0/toxiproxy_2.9.0_linux_amd64.deb
#     sudo dpkg -i toxiproxy_2.9.0_linux_amd64.deb
#   Fedora:
#     sudo dnf install toxiproxy
#
# Your app connects to localhost:15432 instead of localhost:5432.
# Toxiproxy forwards the connection while injecting chaos.

set -e

PROXY_NAME="postgres_proxy"
LISTEN_PORT="${LISTEN_PORT:-15432}"
UPSTREAM_PORT="${UPSTREAM_PORT:-5432}"

case "${1:-help}" in
  setup)
    echo "Creating proxy: localhost:$LISTEN_PORT -> localhost:$UPSTREAM_PORT"
    toxiproxy-cli create "$PROXY_NAME" -l "localhost:$LISTEN_PORT" -u "localhost:$UPSTREAM_PORT"
    echo ""
    echo "Proxy created. Update your app to connect to port $LISTEN_PORT"
    ;;
  latency)
    LATENCY="${2:-2000}"
    echo "Adding ${LATENCY}ms latency to $PROXY_NAME..."
    toxiproxy-cli toxic add -t latency -a "latency=$LATENCY" "$PROXY_NAME"
    ;;
  latency-variable)
    LATENCY="${2:-2500}"
    JITTER="${3:-2500}"
    echo "Adding variable latency (${LATENCY}ms +/- ${JITTER}ms) to $PROXY_NAME..."
    echo "This will break poorly configured timeouts!"
    toxiproxy-cli toxic add -t latency -a "latency=$LATENCY" -a "jitter=$JITTER" "$PROXY_NAME"
    ;;
  disconnect)
    TIMEOUT="${2:-1000}"
    echo "Simulating connection resets after ${TIMEOUT}ms..."
    toxiproxy-cli toxic add -t reset_peer -a "timeout=$TIMEOUT" "$PROXY_NAME"
    ;;
  reset)
    echo "Removing all toxics from $PROXY_NAME..."
    toxiproxy-cli toxic delete -t latency "$PROXY_NAME" 2>/dev/null || true
    toxiproxy-cli toxic delete -t reset_peer "$PROXY_NAME" 2>/dev/null || true
    echo "Done."
    ;;
  destroy)
    echo "Destroying proxy $PROXY_NAME..."
    toxiproxy-cli delete "$PROXY_NAME"
    ;;
  status)
    echo "Proxy status:"
    toxiproxy-cli list
    echo ""
    echo "Active toxics on $PROXY_NAME:"
    toxiproxy-cli inspect "$PROXY_NAME" 2>/dev/null || echo "Proxy not found"
    ;;
  *)
    echo "Toxiproxy PostgreSQL Chaos Simulator"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  setup                        Create proxy (app -> :$LISTEN_PORT -> :$UPSTREAM_PORT)"
    echo "  latency <ms>                 Add fixed latency (default: 2000ms)"
    echo "  latency-variable <ms> <jitter>  Add variable latency (default: 2500 +/- 2500ms)"
    echo "  disconnect <timeout_ms>      Simulate connection resets"
    echo "  reset                        Remove all toxics"
    echo "  destroy                      Delete the proxy"
    echo "  status                       Show proxy and toxic status"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 latency 3000              # 3 second latency"
    echo "  $0 latency-variable 1000 500 # 500-1500ms variable latency"
    echo "  $0 reset"
    ;;
esac
