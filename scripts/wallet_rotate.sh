#!/bin/bash
# ♾ Wallet Rotation Script (Cloud-first)
# Inserts new wallet directly into Supabase via REST API and logs event

source /mnt/data/codex-prime-sync/scripts/env_loader.sh wallet

NEW_ADDR=$(openssl rand -hex 20)
NEW_KEY=$(openssl rand -hex 64)

# Insert wallet via Supabase REST API
curl -s -X POST "$SUPABASE_URL/rest/v1/wallets" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"address\":\"$NEW_ADDR\",\"private_key\":\"$NEW_KEY\"}" \
  > /dev/null

# Log via Supabase REST API
CATEGORY="wallet"
AGENT="WalletAgent"
LEVEL="INFO"
MESSAGE="Rotated wallet"
PAYLOAD="{\"address\":\"$NEW_ADDR\"}"

curl -s -X POST "$SUPABASE_URL/rest/v1/logs" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"category\":\"$CATEGORY\",\"agent\":\"$AGENT\",\"level\":\"$LEVEL\",\"message\":\"$MESSAGE\",\"payload\":$PAYLOAD}" \
  > /dev/null || true

# Local JSON backup log
LOG_DIR="/mnt/data/codex-prime-sync/logs/wallet"
mkdir -p "$LOG_DIR"
echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"category\":\"$CATEGORY\",\"agent\":\"$AGENT\",\"level\":\"$LEVEL\",\"message\":\"$MESSAGE\",\"payload\":$PAYLOAD}" \
  >> "$LOG_DIR/wallet.log"

echo "✅ New wallet rotated (cloud-insert): $NEW_ADDR"
