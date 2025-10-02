#!/bin/bash
cd /root/Invoqs-Deployment
docker compose -p invoqs-staging -f docker-compose.staging.yml --env-file .env.staging up -d