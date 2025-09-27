#!/bin/bash
# ♾ Codex Prime Env Loader
# Usage: ./env_loader.sh <role>
# Roles: faucet, wallet, profit, guardian, picky

ROLE=$1
BASE_DIR="/mnt/data/codex-prime-sync"

set -a
# Core env always loads first
if [ -f "$BASE_DIR/core.env" ]; then
  source "$BASE_DIR/core.env"
fi

case $ROLE in
  faucet)
    source "$BASE_DIR/wallets.env"
    source "$BASE_DIR/supabase.env"
    ;;
  wallet)
    source "$BASE_DIR/wallets.env"
    source "$BASE_DIR/supabase.env"
    ;;
  profit)
    source "$BASE_DIR/finance.env"
    source "$BASE_DIR/supabase.env"
    ;;
  guardian)
    source "$BASE_DIR/auth.env"
    source "$BASE_DIR/supabase.env"
    ;;
  picky)
    source "$BASE_DIR/core.env"
    ;;
  *)
    echo "⚠️ Unknown role: $ROLE"
    ;;
esac
set +a

echo "✅ Environment loaded for role: $ROLE"
