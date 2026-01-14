#!/bin/bash

# Test script for Log Ingestion Service
# Usage: ./scripts/test-log-ingestion.sh

set -e

BASE_URL="http://localhost:8081"
API_URL="${BASE_URL}/api/v1/logs"

echo "=========================================="
echo "Testing Log Ingestion Service"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
response=$(curl -s -w "\n%{http_code}" "${API_URL}/health")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Health check failed (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

# Test 2: Ingest Valid Log
echo -e "${YELLOW}Test 2: Ingest Valid Log (INFO level)${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "Test log message from script",
    "service": "test-service",
    "host": "localhost",
    "environment": "development",
    "metadata": {
      "testId": "test-001",
      "source": "bash-script"
    }
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 202 ]; then
    echo -e "${GREEN}✓ Log ingestion successful${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Log ingestion failed (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

# Test 3: Ingest Error Log
echo -e "${YELLOW}Test 3: Ingest Error Log${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "message": "Database connection failed",
    "service": "user-service",
    "host": "prod-server-01",
    "environment": "production",
    "metadata": {
      "errorCode": "DB_CONN_001",
      "retryCount": 3
    }
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 202 ]; then
    echo -e "${GREEN}✓ Error log ingestion successful${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Error log ingestion failed (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

# Test 4: Invalid Log (Missing Required Field)
echo -e "${YELLOW}Test 4: Invalid Log - Missing Service Name${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "Test message without service"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 400 ]; then
    echo -e "${GREEN}✓ Validation correctly rejected invalid log${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Validation failed to reject invalid log (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

# Test 5: Invalid Log Level
echo -e "${YELLOW}Test 5: Invalid Log Level${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INVALID_LEVEL",
    "message": "Test message",
    "service": "test-service"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 400 ]; then
    echo -e "${GREEN}✓ Validation correctly rejected invalid log level${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Validation failed to reject invalid log level (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

# Test 6: Log with Trace ID (Distributed Tracing)
echo -e "${YELLOW}Test 6: Log with Trace ID${NC}"
response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "DEBUG",
    "message": "Processing user request",
    "service": "api-gateway",
    "traceId": "trace-123-456-789",
    "spanId": "span-abc-def",
    "metadata": {
      "userId": "user-001",
      "endpoint": "/api/users"
    }
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 202 ]; then
    echo -e "${GREEN}✓ Log with trace ID ingestion successful${NC}"
    echo "Response: $body"
else
    echo -e "${RED}✗ Log with trace ID ingestion failed (HTTP $http_code)${NC}"
    echo "Response: $body"
fi
echo ""

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "All tests completed. Check results above."
echo ""
echo "To view Swagger UI, visit: ${BASE_URL}/swagger-ui.html"
echo "To view API docs, visit: ${BASE_URL}/v3/api-docs"

# Made with Bob
