#!/usr/bin/env bash
# 🧪 Codex Prime - Full System Diagnostic

TARGET="/mnt/data/codex-prime-sync"
ENV_FILE="$TARGET/.env"
LOG_DIR="$TARGET/logs"
LOG_FILE="$LOG_DIR/diagnostic_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== Starting Codex Prime Diagnostic ==="
log "Target directory: $TARGET"
log "Log file: $LOG_FILE"
echo

########################################
# 1. ENVIRONMENT FILE CHECK
########################################
if [[ -f "$ENV_FILE" ]]; then
  log "✅ Found .env file at $ENV_FILE"
  log "--- Required Keys Check ---"
  REQUIRED_KEYS=(SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY GITHUB_TOKEN VERCEL_TOKEN GOOGLE_APPLICATION_CREDENTIALS WALLET_SEED)
  for key in "${REQUIRED_KEYS[@]}"; do
    if grep -q "^$key=" "$ENV_FILE"; then
      log "✅ $key present"
    else
      log "❌ $key MISSING"
    fi
  done
else
  log "❌ .env file NOT FOUND at $ENV_FILE"
  exit 1
fi

########################################
# 2. PERMISSIONS CHECK
########################################
log "--- Permissions Check ---"
for dir in "$TARGET" "$TARGET/scripts" "$LOG_DIR"; do
  if [[ -d "$dir" ]]; then
    log "Checking permissions for: $dir"
    ls -ld "$dir" | tee -a "$LOG_FILE"
  else
    log "❌ Missing directory: $dir"
  fi
done

########################################
# 3. GITHUB CONNECTIVITY
########################################
log "--- GitHub Connectivity ---"
cd "$TARGET" || exit 1

if git status >/dev/null 2>&1; then
  log "✅ Git repo initialized."
else
  log "❌ No git repository detected."
  exit 1
fi

GITHUB_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
log "GitHub remote: $GITHUB_REMOTE"

if [[ "$GITHUB_REMOTE" != "git@github.com:InfinityXone/codex-prime.git" ]]; then
  log "❌ Incorrect remote. Expected: git@github.com:InfinityXone/codex-prime.git"
else
  log "✅ Remote matches expected."
fi

log "Testing SSH to GitHub..."
ssh -T git@github.com 2>&1 | tee -a "$LOG_FILE"

########################################
# 4. SUPABASE CONNECTIVITY
########################################
SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2-)
SUPABASE_KEY=$(grep "^SUPABASE_SERVICE_ROLE_KEY=" "$ENV_FILE" | cut -d '=' -f2-)

log "--- Supabase Check ---"
if [[ -n "$SUPABASE_URL" && -n "$SUPABASE_KEY" ]]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/rest/v1" -H "apikey: $SUPABASE_KEY")
  if [[ "$code" == "200" ]]; then
    log "✅ Supabase API reachable."
  else
    log "❌ Supabase API returned HTTP $code. Check URL/key."
  fi
else
  log "❌ Missing Supabase credentials in .env"
fi

########################################
# 5. VERCEL DEPLOYMENT TEST
########################################
VERCEL_TOKEN=$(grep "^VERCEL_TOKEN=" "$ENV_FILE" | cut -d '=' -f2-)

log "--- Vercel Check ---"
if [[ -n "$VERCEL_TOKEN" ]]; then
  vcode=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.vercel.com/v2/projects" \
    -H "Authorization: Bearer $VERCEL_TOKEN")
  if [[ "$vcode" == "200" ]]; then
    log "✅ Vercel API reachable."
  else
    log "❌ Vercel API returned HTTP $vcode. Check token."
  fi
else
  log "❌ Missing VERCEL_TOKEN in .env"
fi

########################################
# 6. GOOGLE CLOUD KEY TEST
########################################
log "--- Google Cloud Check ---"
GOOGLE_CRED_PATH=$(grep "^GOOGLE_APPLICATION_CREDENTIALS=" "$ENV_FILE" | cut -d '=' -f2-)

if [[ -f "$GOOGLE_CRED_PATH" ]]; then
  log "✅ Found Google service JSON at $GOOGLE_CRED_PATH"
  head -n 5 "$GOOGLE_CRED_PATH" | tee -a "$LOG_FILE"
else
  log "❌ Google service JSON NOT FOUND at $GOOGLE_CRED_PATH"
fi

########################################
# 7. WALLET AGENT TEST
########################################
WALLET_SEED=$(grep "^WALLET_SEED=" "$ENV_FILE" | cut -d '=' -f2-)

log "--- Wallet Check ---"
if [[ -n "$WALLET_SEED" ]]; then
  log "✅ Wallet seed exists."
else
  log "❌ WALLET_SEED missing!"
fi

########################################
# 8. SCRIPT VALIDATION
########################################
log "--- Scripts Presence ---"
REQUIRED_SCRIPTS=("validate_env_and_connectivity.sh" "infinity_recursive_sync.sh" "codex_watchdog.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [[ -x "$TARGET/scripts/$script" ]]; then
    log "✅ $script found and executable."
  else
    log "❌ $script missing or not executable."
  fi
done

########################################
# 9. LOG SUMMARY
########################################
log "--- Logs Directory Check ---"
ls -lh "$LOG_DIR" | tee -a "$LOG_FILE"

########################################
# 10. FINAL STATUS
########################################
log "=== Diagnostic Complete ==="
log "View full log at: $LOG_FILE"
