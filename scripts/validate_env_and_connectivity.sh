#!/bin/bash
# validate_env_and_connectivity.sh
# Validates env files and tests core service connectivity for Codex Prime

LOG_DIR="/mnt/data/codex-prime-sync/logs"
LOG_FILE="$LOG_DIR/systemd_sync.log"
SCHEMA_FILE="/mnt/data/codex-prime-sync/supabase/schema.sql"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

log "=== Codex Prime Level 10 Validation Start ==="

# ---------- STEP 1: Load ENV Files ----------
for ENV_FILE in master.env supabase.env vercel.env wallets.env; do
  if [[ -f "/mnt/data/codex-prime-sync/$ENV_FILE" ]]; then
    export $(grep -v '^#' "/mnt/data/codex-prime-sync/$ENV_FILE" | xargs)
    log "✅ Loaded $ENV_FILE"
  else
    log "❌ Missing $ENV_FILE"
  fi
done

# ---------- STEP 2: Verify Critical Secrets ----------
check_secret() {
  local VAR_NAME=$1
  if [[ -z "${!VAR_NAME}" ]]; then
    log "❌ Missing secret: $VAR_NAME"
  else
    log "✅ Found secret: $VAR_NAME"
  fi
}

log "--- Checking Required Secrets ---"
check_secret SUPABASE_URL
check_secret SUPABASE_SERVICE_ROLE_KEY
check_secret GITHUB_TOKEN
check_secret VERCEL_TOKEN
check_secret GOOGLE_CLOUD_KEY
check_secret WALLET_SEED

# ---------- STEP 3: Test Connectivity ----------

## Supabase
if [[ -f "$SCHEMA_FILE" ]]; then
  log "🔎 Testing Supabase connectivity..."
  PGPASSWORD="$SUPABASE_SERVICE_ROLE_KEY" psql "$SUPABASE_URL" -f "$SCHEMA_FILE" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    log "✅ Supabase schema verified and accessible."
  else
    log "⚠️ Supabase schema test failed."
  fi
else
  log "⚠️ schema.sql not found at $SCHEMA_FILE"
fi

## GitHub
log "🔎 Testing GitHub push/pull..."
cd /mnt/data/codex-prime-sync || exit
git fetch origin && git status >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  log "✅ GitHub repo access OK."
else
  log "⚠️ GitHub test failed. Check SSH keys and token."
fi

## Vercel
if [[ -n "$VERCEL_TOKEN" ]]; then
  log "🔎 Testing Vercel deploy endpoint..."
  curl -s -H "Authorization: Bearer $VERCEL_TOKEN" "https://api.vercel.com/v9/projects" | grep -q "projects"
  if [[ $? -eq 0 ]]; then
    log "✅ Vercel API reachable."
  else
    log "⚠️ Vercel API test failed."
  fi
else
  log "⚠️ No VERCEL_TOKEN found."
fi

## Google Cloud
if [[ -n "$GOOGLE_CLOUD_KEY" ]]; then
  log "🔎 Testing Google Cloud CLI..."
  gcloud auth activate-service-account --key-file="$GOOGLE_CLOUD_KEY" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    log "✅ Google Cloud auth OK."
  else
    log "⚠️ Google Cloud auth failed."
  fi
else
  log "⚠️ GOOGLE_CLOUD_KEY missing or not configured."
fi

log "=== Codex Prime Validation Complete ==="
