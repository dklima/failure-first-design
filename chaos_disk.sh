#!/bin/bash
# Chaos Engineering: Disk Full Simulation
#
# Simulates disk full condition to test how your database/application handles it.
# WARNING: Run only in staging! This will actually fill up disk space.

set -e

TARGET_DIR="${1:-/tmp}"
SIZE_MB="${2:-1000}"
FILENAME="$TARGET_DIR/chaos_fakefile_$(date +%s)"

case "${1:-help}" in
  fill)
    echo "Creating ${SIZE_MB}MB file at $FILENAME..."
    echo "WARNING: This will consume real disk space!"
    read -p "Continue? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      dd if=/dev/zero of="$FILENAME" bs=1M count="$SIZE_MB" status=progress
      echo ""
      echo "File created: $FILENAME"
      echo "Run '$0 cleanup $FILENAME' when done testing"
    else
      echo "Aborted."
    fi
    ;;
  cleanup)
    FILE_TO_REMOVE="$2"
    if [[ -f "$FILE_TO_REMOVE" ]]; then
      echo "Removing $FILE_TO_REMOVE..."
      rm "$FILE_TO_REMOVE"
      echo "Done."
    else
      echo "File not found: $FILE_TO_REMOVE"
      echo ""
      echo "Looking for chaos files..."
      find /tmp -name "chaos_fakefile_*" -type f 2>/dev/null || true
      find /var -name "chaos_fakefile_*" -type f 2>/dev/null || true
    fi
    ;;
  *)
    echo "Chaos Disk Full Simulator"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  fill <target_dir> <size_mb>  Create large file to fill disk"
    echo "  cleanup <filepath>           Remove the chaos file"
    echo ""
    echo "Examples:"
    echo "  $0 fill /var/lib/postgresql 10000  # Create 10GB file"
    echo "  $0 cleanup /var/lib/postgresql/chaos_fakefile_123456"
    ;;
esac
