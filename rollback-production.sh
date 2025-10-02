#!/bin/bash
set -e

echo "=========================================="
echo "🔙 ROLLBACK INITIATED"
echo "Time: $(date)"
echo "=========================================="

# Find the last successful deployment tag
cd /root/Invoqs.API
LAST_API_TAG=$(git tag -l "deployed-api-*" --sort=-creatordate | head -n 2 | tail -n 1)

cd /root/Invoqs
LAST_BLAZOR_TAG=$(git tag -l "deployed-blazor-*" --sort=-creatordate | head -n 2 | tail -n 1)

echo "📌 Rolling back to:"
echo "   API: $LAST_API_TAG"
echo "   Blazor: $LAST_BLAZOR_TAG"

# Checkout previous versions
echo "📥 Checking out previous versions..."
cd /root/Invoqs.API
git checkout $LAST_API_TAG

cd /root/Invoqs
git checkout $LAST_BLAZOR_TAG

# Rebuild containers with old version
echo "🔨 Rebuilding containers..."
cd /root/Invoqs-Deployment
docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Wait for containers
sleep 10

# Health check
echo "🏥 Verifying rollback..."
if curl -f -s http://localhost:7000/health > /dev/null 2>&1 || curl -f -s http://localhost:6000 > /dev/null 2>&1; then
    echo "✅ Rollback successful"
    echo "=========================================="
    echo "✅ ROLLBACK COMPLETED"
    echo "=========================================="
else
    echo "❌ Rollback verification failed"
    echo "⚠️  Manual intervention required!"
    exit 1
fi