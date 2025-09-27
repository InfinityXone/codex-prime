#!/bin/bash
source /mnt/data/codex-prime-sync/scripts/env_loader.sh wallet
NEW_ADDR=$(openssl rand -hex 20)
NEW_PRIV=$(openssl rand -hex 64)
curl -s -X POST "$SUPABASE_URL/rest/v1/wallets" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"address\":\"$NEW_ADDR\",\"private_key\":\"$NEW_PRIV\"}" > /dev/null
echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"type\":\"wallet_create\",\"addr\":\"$NEW_ADDR\"}" >> "$LOG_DIR/wallets.log"
echo "✅ Wallet created + stored: $NEW_ADDR"
