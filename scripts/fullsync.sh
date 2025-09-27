#!/bin/bash
set -u
GPT_DIR="/mnt/data/codex-prime-sync"
LOCAL_DIR="$HOME/codex-prime-local"
LOG_DIR="$GPT_DIR/logs"; mkdir -p "$LOG_DIR"
log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG_DIR/fullsync.log"; }

log "=== ♻ Codex Full Sync ==="
rsync -a --delete "$GPT_DIR/" "$LOCAL_DIR/" || true
cd "$LOCAL_DIR"
git fetch origin || true
git reset --hard origin/main || true
git add -A || true
git diff --cached --quiet || git commit -m "Codex auto-sync $(date '+%F %T')" || true
git push origin main || log "⚠️ Git push failed"

if command -v supabase >/dev/null; then
  supabase db push >> "$LOG_DIR/supabase.log" 2>&1 || log "⚠️ Supabase push failed"
fi
if command -v vercel >/dev/null; then
  vercel --prod --token "$VERCEL_TOKEN" --yes >> "$LOG_DIR/vercel.log" 2>&1 || log "⚠️ Vercel deploy failed"
fi
if command -v gcloud >/dev/null; then
  gcloud config set project "$GCP_PROJECT" >> "$LOG_DIR/gcloud.log" 2>&1 || true
  gcloud builds submit "$LOCAL_DIR" --tag "gcr.io/$GCP_PROJECT/codex-prime:latest" >> "$LOG_DIR/gcloud.log" 2>&1 || log "⚠️ GCP build failed"
  gcloud container clusters get-credentials codex-cluster --zone us-central1-a --project "$GCP_PROJECT" || true
  kubectl set image deployment/codex-prime codex-prime=gcr.io/$GCP_PROJECT/codex-prime:latest --record || log "⚠️ GKE deploy failed"
fi

# === GPT Handshake ===
SNAPSHOT="$GPT_DIR/logs/state_snapshot.json"
$GPT_DIR/scripts/state_snapshot.py || true
if [ -n "${GPT_API_KEY:-}" ]; then
  RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $GPT_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"gpt-5\",
      \"messages\": [
        {\"role\": \"system\", \"content\": \"You are Codex Prime’s architect. Mutate this system for self-healing recursion.\"},
        {\"role\": \"user\", \"content\": \"$(jq -Rs . < $SNAPSHOT)\"}
      ]
    }" | jq -r '.choices[0].message.content')
  echo "$RESPONSE" > "$GPT_DIR/logs/gpt_patch_$(date +%s).txt"
  echo "$RESPONSE" | bash || log "⚠️ GPT patch failed"
fi
log "✅ Full sync + deploy complete."
