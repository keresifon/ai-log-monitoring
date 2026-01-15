#!/bin/bash

# =============================================================================
# Deploy All Services Script
# =============================================================================
# This script builds and deploys all microservices in the AI Monitoring System
#
# Usage: ./scripts/deploy-all-services.sh [options]
# Options:
#   --rebuild    Force rebuild of all images
#   --clean      Clean up everything and start fresh
#   --logs       Follow logs after deployment
#
# Made with Bob
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
REBUILD=false
CLEAN=false
FOLLOW_LOGS=false

for arg in "$@"; do
    case $arg in
        --rebuild)
            REBUILD=true
            ;;
        --clean)
            CLEAN=true
            ;;
        --logs)
            FOLLOW_LOGS=true
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Usage: $0 [--rebuild] [--clean] [--logs]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AI Log Monitoring System - Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Clean up if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Step 1: Cleaning up existing containers and volumes...${NC}"
    docker-compose down -v
    echo -e "${GREEN}✓ Cleanup complete${NC}"
    echo ""
fi

# Stop existing containers
echo -e "${YELLOW}Step 2: Stopping existing containers...${NC}"
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

# Build services
if [ "$REBUILD" = true ] || [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Step 3: Building all services (this may take several minutes)...${NC}"
    docker-compose build --no-cache
    echo -e "${GREEN}✓ All services built${NC}"
else
    echo -e "${YELLOW}Step 3: Building services (using cache)...${NC}"
    docker-compose build
    echo -e "${GREEN}✓ Services built${NC}"
fi
echo ""

# Start infrastructure services first
echo -e "${YELLOW}Step 4: Starting infrastructure services...${NC}"
docker-compose up -d postgres redis elasticsearch rabbitmq
echo -e "${GREEN}✓ Infrastructure services started${NC}"
echo ""

# Wait for infrastructure to be healthy
echo -e "${YELLOW}Step 5: Waiting for infrastructure to be healthy (30 seconds)...${NC}"
sleep 30
echo -e "${GREEN}✓ Infrastructure ready${NC}"
echo ""

# Start ML service
echo -e "${YELLOW}Step 6: Starting ML Service...${NC}"
docker-compose up -d ml-service
echo -e "${GREEN}✓ ML Service started${NC}"
echo ""

# Wait for ML service to be healthy
echo -e "${YELLOW}Step 7: Waiting for ML Service to be healthy (30 seconds)...${NC}"
sleep 30
echo -e "${GREEN}✓ ML Service ready${NC}"
echo ""

# Start application services
echo -e "${YELLOW}Step 8: Starting application services...${NC}"
docker-compose up -d auth-service log-ingestion log-processor api-gateway alert-service
echo -e "${GREEN}✓ Application services started${NC}"
echo ""

# Wait for services to start
echo -e "${YELLOW}Step 9: Waiting for services to initialize (60 seconds)...${NC}"
sleep 60
echo ""

# Start frontend (depends on API Gateway)
echo -e "${YELLOW}Step 10: Starting frontend...${NC}"
docker-compose up -d frontend
echo -e "${GREEN}✓ Frontend started${NC}"
echo ""

# Check service status
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Service Status${NC}"
echo -e "${BLUE}========================================${NC}"
docker-compose ps
echo ""

# Test service health
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Health Check Results${NC}"
echo -e "${BLUE}========================================${NC}"

services=(
    "PostgreSQL:5432"
    "Redis:6379"
    "Elasticsearch:9200"
    "RabbitMQ:15672"
    "ML Service:8000/api/v1/health"
    "Auth Service:8084/actuator/health"
    "Log Ingestion:8080/actuator/health"
    "Log Processor:8082/actuator/health"
    "API Gateway:8080/actuator/health"
    "Alert Service:8083/actuator/health"
    "Frontend:80/health"
)

for service in "${services[@]}"; do
    name="${service%%:*}"
    endpoint="${service#*:}"
    
    if [[ $endpoint == *"/"* ]]; then
        # HTTP endpoint
        if curl -sf "http://localhost:$endpoint" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $name - ${GREEN}Healthy${NC}"
        else
            echo -e "${RED}✗${NC} $name - ${RED}Unhealthy${NC}"
        fi
    else
        # Port check
        if nc -z localhost "${endpoint%%/*}" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $name - ${GREEN}Running${NC}"
        else
            echo -e "${RED}✗${NC} $name - ${RED}Not Running${NC}"
        fi
    fi
done
echo ""

# Display access information
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Service Access Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Web Application:${NC}"
echo "  • Frontend:       http://localhost:80"
echo ""
echo -e "${GREEN}API Endpoints:${NC}"
echo "  • API Gateway:    http://localhost:8080"
echo "  • Auth Service:   http://localhost:8084"
echo "  • Log Ingestion:  http://localhost:8080"
echo "  • Log Processor:  http://localhost:8082"
echo "  • Alert Service:  http://localhost:8083"
echo "  • ML Service:     http://localhost:8000"
echo ""
echo -e "${GREEN}Infrastructure:${NC}"
echo "  • PostgreSQL:     localhost:5432"
echo "  • Elasticsearch:  http://localhost:9200"
echo "  • RabbitMQ UI:    http://localhost:15672 (guest/guest)"
echo "  • Redis:          localhost:6379"
echo ""
echo -e "${GREEN}Health Checks:${NC}"
echo "  • curl http://localhost:80/health"
echo "  • curl http://localhost:8080/actuator/health"
echo "  • curl http://localhost:8082/actuator/health"
echo "  • curl http://localhost:8083/actuator/health"
echo "  • curl http://localhost:8084/actuator/health"
echo "  • curl http://localhost:8000/api/v1/health"
echo ""

# Follow logs if requested
if [ "$FOLLOW_LOGS" = true ]; then
    echo -e "${YELLOW}Following logs (Ctrl+C to exit)...${NC}"
    echo ""
    docker-compose logs -f
else
    echo -e "${YELLOW}To view logs, run:${NC} docker-compose logs -f"
    echo -e "${YELLOW}To stop services, run:${NC} docker-compose down"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"