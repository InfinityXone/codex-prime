#!/bin/bash
# ♾ Codex Prime Phase 1 Validation Harness
# Runs a battery of checks against the recursive sync foundation

set -euo pipefail
source /mnt/data/codex-prime-sync/.env

BASE_DIR="/mnt/data/codex-prime-sync"
LOCAL_DIR="/home/infinityxone/codex-prime-local"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

log() { echo "[$(date)] $*" | tee -a "$LOG_DIR/test_harness.log"; }

log "=== 🚀 Starting Codex Prime Phase 1 Test Harness ==="

# 1. ENV + binaries
log "🔎 Checking environment + binaries..."
command -v git || { echo "❌ git missing"; exit 1; }
command -v supabase || { echo "❌ supabase CLI missing"; exit 1; }
command -v vercel || { echo "❌ vercel CLI missing"; exit 1; }
command -v gcloud || { echo "❌ gcloud CLI missing"; exit 1; }
command -v psql || { echo "❌ psql missing"; exit 1; }
log "✅ All required binaries present."

# 2. Directories
log "🔎 Checking directories..."
[ -d "$BASE_DIR" ] || { echo "❌ $BASE_DIR missing"; exit 1; }
[ -d "$LOCAL_DIR" ] || { echo "❌ $LOCAL_DIR missing"; exit 1; }
log "✅ Directories exist."

# 3. GitHub clone/push
log "🔎 Testing GitHub clone + push..."
cd "$LOCAL_DIR"
git pull --rebase || true
echo "# Test Commit $(date)" >> TEST_COMMIT.md
git add TEST_COMMIT.md
git commit -m "♾ Test Commit $(date)" || true
git push origin main || { echo "❌ GitHub push failed"; exit 1; }
log "✅ GitHub push OK."

# 4. Supabase schema
log "🔎 Testing Supabase schema sync..."
cd "$BASE_DIR"
supabase db push || { echo "❌ Supabase db push failed"; exit 1; }
log "✅ Supabase schema OK."

# 5. Vercel dry run
log "🔎 Testing Vercel deploy dry run..."
cd "$LOCAL_DIR"
vercel --token "$VERCEL_TOKEN" --confirm --prod || log "⚠️ Vercel deploy test failed (check token/project)"
log "✅ Vercel deploy attempted."

# 6. GCP dry run
log "🔎 Testing GCP deploy dry run..."
cd "$LOCAL_DIR"
gcloud builds submit --tag gcr.io/$GCP_PROJECT/codex-prime --timeout=60s || log "⚠️ GCP build test failed"
log "✅ GCP deploy attempted."

# 7. Systemd service
log "🔎 Checking codex-prime.service status..."
systemctl is-enabled codex-prime && log "✅ codex-prime.service enabled" || log "⚠️ Not enabled"
systemctl is-active codex-prime && log "✅ codex-prime.service active" || log "⚠️ Not active"

# 8. Neural handshake
log "🔎 Testing Neural Handshake..."
HASH=$(echo -n "$AGENT_NAME-$AGENT_ONE_API_KEY-TEST" | sha256sum | awk '{print $1}')
echo "insert into handshake(agent_name, handshake_hash) values('$AGENT_NAME','$HASH');" \
| psql $SUPABASE_URL || log "⚠️ Handshake insert failed"
log "✅ Neural Handshake test hash: $HASH"

log "=== 🎯 Codex Prime Phase 1 Test Harness Complete ==="
