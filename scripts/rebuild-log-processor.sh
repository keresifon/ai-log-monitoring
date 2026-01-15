#!/bin/bash

# Quick script to rebuild just the log-processor service

set -e

echo "Rebuilding log-processor service..."

cd backend/log-processor

echo "Building with Maven..."
mvn clean package -DskipTests

echo "Restarting log-processor service..."
cd ../..
docker-compose restart log-processor

echo "Waiting for service to be ready..."
sleep 10

echo "Checking health..."
curl -s http://localhost:8082/api/v1/processor/health | python3 -m json.tool || echo "Service not ready yet"

echo "Done! Check logs with: docker-compose logs log-processor --tail 50"
