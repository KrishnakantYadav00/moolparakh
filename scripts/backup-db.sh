#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/backup-db.sh
# Daily PostgreSQL backup — keeps the last 30 dumps.
# Cron entry (added by setup-ec2.sh):
#   0 2 * * * /home/ec2-user/moolparakh/scripts/backup-db.sh >> /home/ec2-user/backups/backup.log 2>&1
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKUP_DIR="/home/ec2-user/backups"
CONTAINER="moolparakh_postgres"
DB_USER="postgres"
DB_NAME="fproject2026"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/db_${TIMESTAMP}.sql"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "[$(date -Iseconds)] Starting backup → $FILE"
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$FILE"

SIZE=$(du -sh "$FILE" | cut -f1)
echo "[$(date -Iseconds)] Backup complete. Size: $SIZE"

# Remove dumps older than RETENTION_DAYS
DELETED=$(find "$BACKUP_DIR" -name "db_*.sql" -mtime "+${RETENTION_DAYS}" -print -delete | wc -l)
echo "[$(date -Iseconds)] Cleaned $DELETED old backup(s) (>${RETENTION_DAYS} days)."
