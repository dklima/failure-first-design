#!/bin/bash
# Chaos Engineering: Network Simulation with tc (traffic control)
#
# tc is part of iproute2 package, pre-installed on most distros.
# Install if needed:
#   Ubuntu/Debian: sudo apt install iproute2
#   Fedora: sudo dnf install iproute
#
# Usage: Run these commands to simulate network issues in staging.
# Always remove rules when done testing!

set -e

INTERFACE="${1:-eth0}"

case "${2:-help}" in
  latency)
    echo "Adding 500ms latency to $INTERFACE..."
    sudo tc qdisc add dev "$INTERFACE" root netem delay 500ms
    ;;
  latency-variable)
    echo "Adding variable latency (200ms +/- 100ms) to $INTERFACE..."
    sudo tc qdisc add dev "$INTERFACE" root netem delay 200ms 100ms
    ;;
  packet-loss)
    echo "Adding 10% packet loss to $INTERFACE..."
    sudo tc qdisc add dev "$INTERFACE" root netem loss 10%
    ;;
  reset)
    echo "Removing all tc rules from $INTERFACE..."
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null || echo "No rules to remove"
    ;;
  status)
    echo "Current tc rules on $INTERFACE:"
    sudo tc qdisc show dev "$INTERFACE"
    ;;
  *)
    echo "Chaos Network Simulator"
    echo ""
    echo "Usage: $0 <interface> <command>"
    echo ""
    echo "Commands:"
    echo "  latency          Add 500ms fixed latency"
    echo "  latency-variable Add 200ms +/- 100ms variable latency"
    echo "  packet-loss      Add 10% packet loss"
    echo "  reset            Remove all tc rules"
    echo "  status           Show current tc rules"
    echo ""
    echo "Example: $0 eth0 latency"
    ;;
esac
