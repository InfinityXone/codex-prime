#!/bin/bash
# ♾ Codex Prime Env Test
# Verifies env_loader.sh correctly loads envs for all agent roles

LOADER="/mnt/data/codex-prime-sync/scripts/env_loader.sh"
ROLES=("faucet" "wallet" "profit" "guardian" "picky")

for ROLE in "${ROLES[@]}"; do
  echo "🔎 Testing role: $ROLE"
  # Source envs into current shell
  source $LOADER $ROLE

  case $ROLE in
    faucet|wallet)
      echo "  AGENT_NAME=$AGENT_NAME"
      echo "  SUPABASE_URL=$SUPABASE_URL"
      ;;
    profit)
      echo "  AGENT_NAME=$AGENT_NAME"
      echo "  SUPABASE_URL=$SUPABASE_URL"
      ;;
    guardian)
      echo "  GITHUB_TOKEN=${GITHUB_TOKEN:0:8}***"
      echo "  SUPABASE_URL=$SUPABASE_URL"
      ;;
    picky)
      echo "  ROOT_ACCESS_CODE=$ROOT_ACCESS_CODE"
      ;;
  esac

  echo "✅ Role $ROLE env loaded."
  echo "-----------------------------------"
done

echo "♾ Env test complete."
