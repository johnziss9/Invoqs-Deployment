#!/bin/bash
set -e  # Exit on error

COMPONENT=$1  # 'api' or 'blazor'
VERSION=$2    # e.g., 'v1.2.0'

if [ -z "$VERSION" ]; then
    echo "❌ Error: Version required!"
    echo "Usage: ./deploy-production.sh [api|blazor] v1.2.0"
    exit 1
fi

echo "=========================================="
echo "🚀 PRODUCTION DEPLOYMENT STARTED"
echo "Component: $COMPONENT"
echo "Version: $VERSION"
echo "Time: $(date)"
echo "=========================================="

# Backup database before deployment
echo "💾 Creating database backup..."
cd /root/Invoqs-Deployment
./backup-database.sh
echo "✅ Backup completed"

# Merge staging to main and tag
if [ "$COMPONENT" = "api" ] || [ -z "$COMPONENT" ]; then
    echo "📥 Updating API to $VERSION..."
    cd /root/Invoqs.API
    git fetch origin
    git checkout main
    git merge origin/staging -m "Deploy $VERSION to production"
    git tag "deployed-api-$VERSION-$(date +%Y%m%d-%H%M%S)"
    git push origin main --tags
    echo "✅ API updated and tagged"
fi

if [ "$COMPONENT" = "blazor" ] || [ -z "$COMPONENT" ]; then
    echo "📥 Updating Blazor to $VERSION..."
    cd /root/Invoqs
    git fetch origin
    git checkout main
    git merge origin/staging -m "Deploy $VERSION to production"
    git tag "deployed-blazor-$VERSION-$(date +%Y%m%d-%H%M%S)"
    git push origin main --tags
    echo "✅ Blazor updated and tagged"
fi

# Zero-downtime deployment
echo "🔨 Deploying with zero downtime..."
cd /root/Invoqs-Deployment

if [ "$COMPONENT" = "api" ]; then
    # Deploy API first
    docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d --build --no-deps api
    sleep 5
elif [ "$COMPONENT" = "blazor" ]; then
    # Deploy Blazor
    docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d --build --no-deps blazor
    sleep 5
else
    # Deploy both (API first, then Blazor)
    docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d --build --no-deps api
    sleep 5
    docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d --build --no-deps blazor
    sleep 5
fi

# Health check
echo "🏥 Running health checks..."
HEALTH_CHECK_PASSED=true

if curl -f -s https://api.invoqs.com/api/health > /dev/null 2>&1; then
    echo "✅ API health check passed"
elif curl -f -s http://localhost:7000/api/health > /dev/null 2>&1; then
    echo "✅ API health check passed (localhost)"
else
    echo "❌ API health check FAILED"
    HEALTH_CHECK_PASSED=false
fi

if curl -f -s https://invoqs.com > /dev/null 2>&1; then
    echo "✅ Blazor health check passed"
elif curl -f -s http://localhost:6000 > /dev/null 2>&1; then
    echo "✅ Blazor health check passed (localhost)"
else
    echo "❌ Blazor health check FAILED"
    HEALTH_CHECK_PASSED=false
fi

if [ "$HEALTH_CHECK_PASSED" = false ]; then
    echo "=========================================="
    echo "❌ DEPLOYMENT FAILED - ROLLING BACK"
    echo "=========================================="
    ./rollback-production.sh
    exit 1
fi

echo "=========================================="
echo "✅ PRODUCTION DEPLOYMENT COMPLETED"
echo "Version: $VERSION"
echo "API: https://api.invoqs.com"
echo "Blazor: https://invoqs.com"
echo "=========================================="