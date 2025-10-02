#!/bin/bash
cd /root/Invoqs-Deployment
docker compose -p invoqs-prod -f docker-compose.prod.yml --env-file .env.prod up -d