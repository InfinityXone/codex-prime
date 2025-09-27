#!/bin/bash
source /mnt/data/codex-prime-sync/scripts/env_loader.sh guardian
NEW_KEY=$(openssl rand -hex 32)
curl -s -X POST "$SUPABASE_URL/rest/v1/keys" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"role\":\"wallet\",\"key\":\"$NEW_KEY\"}" > /dev/null
echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"type\":\"key_rotate\",\"value\":\"$NEW_KEY\"}" >> "$LOG_DIR/rotate.log"
echo "✅ Rotated key: $NEW_KEY"
