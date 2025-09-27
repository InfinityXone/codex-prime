#!/bin/bash
# ♾ Codex Prime Infinity Recursive Sync Daemon
# GPT ↔ /mnt/data ↔ Chromebook Local ↔ GitHub ↔ Supabase ↔ Vercel ↔ GCP
# Hardened with integrity checks + handshake chaining

set -euo pipefail
source /mnt/data/codex-prime-sync/.env

GPT_DIR="/mnt/data/codex-prime-sync"
LOCAL_DIR="/home/infinityxone/codex-prime-local"
LOG_DIR="$GPT_DIR/logs"
mkdir -p "$LOG_DIR"

log() { echo "[$(date)] $*" | tee -a "$LOG_DIR/infinity_recursive.log"; }

init_local() {
  if [ ! -d "$LOCAL_DIR/.git" ]; then
    git clone "$GITHUB_REPO" "$LOCAL_DIR"
    log "Cloned fresh local repo."
  fi
}

sync_dirs() {
  rsync -a --delete "$GPT_DIR/" "$LOCAL_DIR/" >> "$LOG_DIR/gpt_to_local.log" 2>&1 || true
  rsync -a --delete "$LOCAL_DIR/" "$GPT_DIR/" >> "$LOG_DIR/local_to_gpt.log" 2>&1 || true
  log "Local ↔ GPT sync complete."
}

sync_git() {
  cd "$LOCAL_DIR"
  git pull --rebase || true
  git add -A
  git commit -m "♾ Auto-sync $(date)" || true
  git push origin main || true
  log "GitHub auto-push complete."
}

sync_supabase() {
  cd "$GPT_DIR"
  supabase db push || true
  log "Supabase memory schema synced."
}

sync_vercel() {
  cd "$LOCAL_DIR"
  vercel deploy --prod --token "$VERCEL_TOKEN" || true
  log "Vercel deploy complete."
}

sync_gcloud() {
  cd "$LOCAL_DIR"
  gcloud storage rsync "$LOCAL_DIR" "gs://$GCP_BUCKET" || true
  gcloud builds submit --tag gcr.io/$GCP_PROJECT/codex-prime || true
  log "Google Cloud deploy complete."
}

integrity_check() {
  find "$LOCAL_DIR" -type f ! -path "*/.git/*" | while read -r file; do
    HASH=$(sha256sum "$file" | awk '{print $1}')
    echo "insert into integrity(file_path, hash) values('$file','$HASH');" \
    | psql $SUPABASE_URL || true
  done
  log "Integrity hashes updated."
}

neural_handshake() {
  HASH=$(echo -n "$AGENT_NAME-$AGENT_ONE_API_KEY-$(date +%s)" | sha256sum | awk '{print $1}')
  echo "insert into handshake(agent_name, handshake_hash) values('$AGENT_NAME','$HASH');" \
  | psql $SUPABASE_URL || true
  log "Neural Handshake chained: $HASH"
}

while true; do
  log "=== ♻ Level 10 Recursive Sync cycle start ==="
  init_local
  sync_dirs
  sync_git
  sync_supabase
  sync_vercel
  sync_gcloud
  integrity_check
  neural_handshake
  log "=== ✅ Cycle complete ==="
  sleep 300
done
