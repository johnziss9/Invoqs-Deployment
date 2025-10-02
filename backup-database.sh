#!/bin/bash
set -e

BACKUP_DIR="/root/Invoqs-DB-Backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/prod-backup-$TIMESTAMP.sql"

echo "💾 Creating database backup..."

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup production database
docker exec invoqs-postgres-prod pg_dump -U invoqs_user invoqs_production > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

echo "✅ Backup created: $BACKUP_FILE.gz"

# Keep only last 10 backups
cd $BACKUP_DIR
ls -t prod-backup-*.sql.gz | tail -n +11 | xargs -r rm

echo "✅ Old backups cleaned up (keeping last 10)"