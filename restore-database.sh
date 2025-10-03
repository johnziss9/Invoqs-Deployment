#!/bin/bash
set -e

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Available backups:"
    ls -lh /root/Invoqs-DB-Backups/
    echo ""
    echo "Usage: ./restore-database.sh /root/Invoqs-DB-Backups/prod-backup-YYYYMMDD-HHMMSS.sql.gz"
    exit 1
fi

echo "=========================================="
echo "⚠️  DATABASE RESTORE"
echo "This will overwrite the current database!"
echo "Backup file: $BACKUP_FILE"
echo "=========================================="
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 1
fi

echo "🛑 Stopping application containers..."
cd /root/Invoqs-Deployment
docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod stop api blazor

echo "💾 Restoring database..."
gunzip -c $BACKUP_FILE | docker exec -i invoqs-postgres-prod psql -U johnz -d invoqs_prod

echo "🔨 Restarting containers..."
docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod start api blazor

echo "=========================================="
echo "✅ DATABASE RESTORE COMPLETED"
echo "=========================================="