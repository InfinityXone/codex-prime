#!/bin/bash
ROLE="$1"
source /mnt/data/codex-prime-sync/scripts/env_loader.sh $ROLE
KEY=$(curl -s "$SUPABASE_URL/rest/v1/keys?select=key&order=ts.desc&limit=1" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" | jq -r '.[0].key')
echo "Distributed latest key to $ROLE: $KEY"
