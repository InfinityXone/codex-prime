#!/bin/bash
# ♾ Codex Prime Agent Swarm Launcher
# Spawns multiple placeholder agents with segregated env + structured logging
# Agents will just log "heartbeat" messages until real logic is plugged in.

AGENTS=("FaucetAgent1" "FaucetAgent2" "WalletAgent" "ProfitAgent" "ScraperAgent")

for AGENT in "${AGENTS[@]}"; do
  (
    # Load agent-specific env if it exists
    ENV_FILE="/mnt/data/codex-prime-sync/config/${AGENT,,}.env"
    if [ -f "$ENV_FILE" ]; then
      source "$ENV_FILE"
    fi

    # Infinite loop heartbeat
    while true; do
      /mnt/data/codex-prime-sync/scripts/logger.sh agent "$AGENT" INFO "$AGENT heartbeat" "{}"
      sleep 60
    done
  ) &
done

wait
