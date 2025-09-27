# /mnt/data/codex-prime-sync/scripts/codex_watchdog.sh
#!/bin/bash
# ♾ Codex Watchdog: Recursive Auto-Validator + Restart + Reporter

LOG="/mnt/data/codex-prime-sync/logs/watchdog.log"
echo "[$(date)] ♻️ Running watchdog..." | tee -a $LOG

# ✅ Check envs
/mnt/data/codex-prime-sync/scripts/test_envs.sh >> $LOG

# ✅ Check git sync
cd /mnt/data/codex-prime-sync
git pull origin main >> $LOG 2>&1
git push origin main >> $LOG 2>&1

# ✅ Rerun agent swarm
/mnt/data/codex-prime-sync/scripts/agent_swarm.sh >> $LOG 2>&1

# ✅ Validate memory + Supabase
/mnt/data/codex-prime-sync/scripts/test_infinity_system.sh >> $LOG 2>&1

echo "[$(date)] ✅ Watchdog complete" | tee -a $LOG
