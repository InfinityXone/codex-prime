#!/bin/bash
# ♾ Codex Prime Autonomous Bootstrap
# This sets up key/wallet rotation, distribution, and logging

set -e

SCRIPTS_DIR="/mnt/data/codex-prime-sync/scripts"
LOG_DIR="/mnt/data/codex-prime-sync/logs/keys"
mkdir -p "$SCRIPTS_DIR" "$LOG_DIR"

# 1. Key Rotation
cat << 'EOF' > "$SCRIPTS_DIR/key_rotate.sh"
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
EOF

# 2. Wallet Creation + Rotation
cat << 'EOF' > "$SCRIPTS_DIR/wallet_create_rotate.sh"
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
EOF

# 3. Black Wallet (failsafe)
cat << 'EOF' > "$SCRIPTS_DIR/black_wallet.sh"
#!/bin/bash
echo "🛑 BLACK WALLET MODE ENABLED"
touch /mnt/data/codex-prime-sync/.blackwallet.lock
EOF

# 4. Key Distributor
cat << 'EOF' > "$SCRIPTS_DIR/key_distribute.sh"
#!/bin/bash
ROLE="$1"
source /mnt/data/codex-prime-sync/scripts/env_loader.sh $ROLE
KEY=$(curl -s "$SUPABASE_URL/rest/v1/keys?select=key&order=ts.desc&limit=1" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" | jq -r '.[0].key')
echo "Distributed latest key to $ROLE: $KEY"
EOF

# Make them executable
chmod +x "$SCRIPTS_DIR/"*.sh

echo "✅ All scripts installed to $SCRIPTS_DIR"
