#!/bin/bash
set -e  # Exit on error

COMPONENT=$1  # 'api' or 'blazor'

echo "=========================================="
echo "🚀 STAGING DEPLOYMENT STARTED"
echo "Component: $COMPONENT"
echo "Time: $(date)"
echo "=========================================="

# Pull latest code
if [ "$COMPONENT" = "api" ] || [ -z "$COMPONENT" ]; then
    echo "📥 Pulling latest API code..."
    cd /root/Invoqs.API-Staging
    git fetch origin
    git reset --hard origin/staging
    echo "✅ API code updated"
fi

if [ "$COMPONENT" = "blazor" ] || [ -z "$COMPONENT" ]; then
    echo "📥 Pulling latest Blazor code..."
    cd /root/Invoqs-Staging
    git fetch origin
    git reset --hard origin/staging
    echo "✅ Blazor code updated"
fi

# Rebuild and restart containers
echo "🔨 Rebuilding containers..."
cd /root/Invoqs-Deployment

if [ "$COMPONENT" = "api" ]; then
    docker compose -p invoqs-staging -f docker-compose.staging.yml --env-file .env.staging up -d --build --no-deps api
elif [ "$COMPONENT" = "blazor" ]; then
    docker compose -p invoqs-staging -f docker-compose.staging.yml --env-file .env.staging up -d --build --no-deps blazor
else
    docker compose -p invoqs-staging -f docker-compose.staging.yml --env-file .env.staging up -d --build
fi

# Wait for containers to be healthy
echo "⏳ Waiting for containers to start..."
sleep 10

# Health check
echo "🏥 Running health checks..."
if curl -f -s http://localhost:7001/api/health > /dev/null 2>&1; then
    echo "✅ API health check passed"
else
    echo "⚠️  API health check failed (endpoint may not exist yet)"
fi

if curl -f -s http://localhost:6001 > /dev/null 2>&1; then
    echo "✅ Blazor health check passed"
else
    echo "⚠️  Blazor health check failed"
fi

echo "=========================================="
echo "✅ STAGING DEPLOYMENT COMPLETED"
echo "API: http://api-staging.invoqs.com"
echo "Blazor: http://staging.invoqs.com"
echo "=========================================="