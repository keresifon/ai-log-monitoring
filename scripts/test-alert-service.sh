#!/bin/bash

# Test Alert Service
# This script tests all alert service endpoints

set -e

echo "=========================================="
echo "Testing Alert Service"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="http://localhost:8083"
FAILED=0
PASSED=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo -e "${BLUE}Testing: $description${NC}"
    echo "  $method $endpoint"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ PASSED (HTTP $http_code)${NC}"
        ((PASSED++))
        if [ ! -z "$body" ]; then
            echo "$body" | jq '.' 2>/dev/null || echo "$body"
        fi
    else
        echo -e "${RED}✗ FAILED (HTTP $http_code)${NC}"
        echo "$body"
        ((FAILED++))
    fi
    echo ""
}

# Wait for service to be ready
echo -e "${YELLOW}Waiting for Alert Service to be ready...${NC}"
for i in {1..30}; do
    if curl -s "$BASE_URL/actuator/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Alert Service is ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Test Health Endpoints
echo "=========================================="
echo "1. Health & Monitoring Endpoints"
echo "=========================================="

test_endpoint "GET" "/actuator/health" "Actuator Health Check"
test_endpoint "GET" "/api/v1/monitoring/health" "System Health"
test_endpoint "GET" "/api/v1/monitoring/statistics" "Alert Statistics"
test_endpoint "GET" "/api/v1/monitoring/alerts/by-status" "Alerts by Status"
test_endpoint "GET" "/api/v1/monitoring/alerts/by-severity" "Alerts by Severity"

# Test Alert Rule Endpoints
echo "=========================================="
echo "2. Alert Rule Endpoints"
echo "=========================================="

test_endpoint "GET" "/api/v1/alert-rules" "List All Alert Rules"
test_endpoint "GET" "/api/v1/alert-rules/enabled" "List Enabled Rules"

# Create a test alert rule
RULE_DATA='{
  "name": "Test High Error Rate",
  "description": "Test rule for high error rate detection",
  "type": "ERROR_RATE",
  "severity": "HIGH",
  "enabled": true,
  "threshold": 10,
  "timeWindowMinutes": 5,
  "cooldownMinutes": 15
}'

test_endpoint "POST" "/api/v1/alert-rules" "Create Alert Rule" "$RULE_DATA"

# Test Notification Channel Endpoints
echo "=========================================="
echo "3. Notification Channel Endpoints"
echo "=========================================="

test_endpoint "GET" "/api/v1/channels" "List All Channels"
test_endpoint "GET" "/api/v1/channels/enabled" "List Enabled Channels"

# Create a test webhook channel
CHANNEL_DATA='{
  "type": "WEBHOOK",
  "name": "Test Webhook",
  "description": "Test webhook for alerts",
  "configuration": "{\"url\": \"https://webhook.site/test\", \"method\": \"POST\"}",
  "enabled": true
}'

test_endpoint "POST" "/api/v1/channels" "Create Notification Channel" "$CHANNEL_DATA"

# Test Alert Endpoints
echo "=========================================="
echo "4. Alert Endpoints"
echo "=========================================="

test_endpoint "GET" "/api/v1/alerts" "List All Alerts"
test_endpoint "GET" "/api/v1/alerts/open" "List Open Alerts"
test_endpoint "GET" "/api/v1/alerts/recent" "List Recent Alerts"
test_endpoint "GET" "/api/v1/alerts/statistics" "Alert Statistics"

# Test Monitoring Endpoints
echo "=========================================="
echo "5. Additional Monitoring Endpoints"
echo "=========================================="

test_endpoint "GET" "/api/v1/monitoring/alerts/trend" "Alert Trend Data"
test_endpoint "GET" "/api/v1/monitoring/anomalies/metrics" "Anomaly Metrics"
test_endpoint "GET" "/api/v1/monitoring/channels/statistics" "Channel Statistics"
test_endpoint "GET" "/api/v1/monitoring/rules/statistics" "Rule Statistics"

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi

# Made with Bob
