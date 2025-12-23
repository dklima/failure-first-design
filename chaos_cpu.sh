#!/bin/bash
# Chaos Engineering: CPU Stress Simulation
#
# Requires stress-ng:
#   Ubuntu/Debian: sudo apt install stress-ng
#   Fedora: sudo dnf install stress-ng
#
# Use this to test how your application behaves under CPU pressure.

set -e

CORES="${1:-4}"
DURATION="${2:-60}"
LOAD="${3:-100}"

case "${1:-help}" in
  full)
    echo "Stressing $CORES cores at 100% for ${DURATION}s..."
    stress-ng --cpu "$CORES" --timeout "${DURATION}s"
    ;;
  partial)
    echo "Stressing $CORES cores at ${LOAD}% for ${DURATION}s..."
    stress-ng --cpu "$CORES" --cpu-load "$LOAD" --timeout "${DURATION}s"
    ;;
  *)
    echo "Chaos CPU Stress Simulator"
    echo ""
    echo "Usage: $0 <mode> [cores] [duration_seconds] [load_percent]"
    echo ""
    echo "Modes:"
    echo "  full <cores> <duration>        100% CPU on N cores"
    echo "  partial <cores> <duration> <load>  Specific load % on N cores"
    echo ""
    echo "Examples:"
    echo "  $0 full 4 60        # 100% on 4 cores for 60s"
    echo "  $0 partial 2 30 80  # 80% on 2 cores for 30s"
    ;;
esac
