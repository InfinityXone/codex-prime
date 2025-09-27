#!/bin/bash
# ♾ Codex Prime Logger
# Usage: ./logger.sh CATEGORY AGENT LEVEL "message" '{"optional":"json"}'

set -euo pipefail
source /mnt/data/codex-prime-sync/.env

CATEGORY=$1
AGENT=$2
LEVEL=$3
MESSAGE=$4
PAYLOAD=${5:-"{}"}

LOG_DIR="/mnt/data/codex-prime-sync/logs/$CATEGORY"
mkdir -p "$LOG_DIR"

# 1. Local log (per category + agent)
LOG_FILE="$LOG_DIR/${AGENT}_$(date +%F).json"
echo "{\"ts\":\"$(date -Is)\",\"category\":\"$CATEGORY\",\"agent\":\"$AGENT\",\"level\":\"$LEVEL\",\"message\":\"$MESSAGE\",\"payload\":$PAYLOAD}" >> "$LOG_FILE"

# 2. Supabase insert
echo "insert into logs(category, agent, level, message, payload) values('$CATEGORY','$AGENT','$LEVEL','$(echo $MESSAGE | sed "s/'/''/g")','$PAYLOAD');" \
| psql $SUPABASE_URL || true
