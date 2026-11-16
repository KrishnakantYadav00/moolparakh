#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/install-cron.sh
# Standalone helper to (re-)install the backup cron without running full setup.
# Run on EC2 as ec2-user.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="${APP_DIR:-/home/ec2-user/moolparakh}"
SCRIPT="$APP_DIR/scripts/backup-db.sh"
LOG_DIR="/home/ec2-user/backups"

chmod +x "$SCRIPT"
mkdir -p "$LOG_DIR"

# Remove existing MoolParakh backup entry (if any), then re-add
FILTERED=$(crontab -l 2>/dev/null | grep -v "backup-db.sh" || true)
(echo "$FILTERED"; echo "0 2 * * * $SCRIPT >> $LOG_DIR/backup.log 2>&1") | crontab -

echo "✅ Backup cron installed:"
crontab -l | grep backup-db
