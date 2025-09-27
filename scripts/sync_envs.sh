#!/bin/bash
# ♾ Sync or link all .env files from /mnt/data into codex-prime-sync/

SRC_DIR="/mnt/data"
DEST_DIR="/mnt/data/codex-prime-sync"

mkdir -p "$DEST_DIR/config"

for f in "$SRC_DIR"/*.env; do
  if [ -f "$f" ]; then
    base=$(basename "$f")
    echo "🔗 Linking $base into $DEST_DIR"
    ln -sf "$f" "$DEST_DIR/$base"
  fi
done

echo "✅ Env files synced"
