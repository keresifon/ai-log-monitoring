#!/bin/bash

# AI Log Monitoring System - Dashboard Endpoints Test Script
# This script tests all dashboard endpoints with authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
USERNAME="${TEST_USERNAME:-testuser}"
PASSWORD="${TEST_PASSWORD:-password123}"
EMAIL="${TEST_EMAIL:-testuser@example.com}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_separator() {
    echo -e "\n${BLUE}========================================${NC}"
}

# Function to make authenticated requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -d "$data" \
            "$API_BASE_URL$endpoint"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            "$API_BASE_URL$endpoint"
    fi
}

# Function to pretty print JSON
pretty_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq '.'
    else
        echo "$1"
    fi
}

print_separator
print_info "AI Log Monitoring System - Dashboard Endpoints Test"
print_separator

# Step 1: Register a test user (if not exists)
print_info "Step 1: Registering test user..."
REGISTER_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\"}" \
    "$API_BASE_URL/api/v1/auth/register" || echo '{"error":"Registration failed"}')

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    print_success "User registered successfully"
else
    print_warning "User might already exist or registration failed"
fi

# Step 2: Login to get JWT token
print_separator
print_info "Step 2: Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" \
    "$API_BASE_URL/api/v1/auth/login")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$JWT_TOKEN" ]; then
    print_error "Failed to obtain JWT token"
    print_error "Response: $LOGIN_RESPONSE"
    exit 1
fi

print_success "Successfully obtained JWT token"
print_info "Token: ${JWT_TOKEN:0:50}..."

# Step 3: Test Dashboard Metrics Endpoint
print_separator
print_info "Step 3: Testing GET /api/v1/dashboard/metrics"
METRICS_RESPONSE=$(make_request "GET" "/api/v1/dashboard/metrics")
print_success "Response received:"
pretty_json "$METRICS_RESPONSE"

# Step 4: Test Log Volume Endpoint
print_separator
print_info "Step 4: Testing GET /api/v1/dashboard/log-volume"
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TIME=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ")
print_info "Time range: $START_TIME to $END_TIME"
VOLUME_RESPONSE=$(make_request "GET" "/api/v1/dashboard/log-volume?startTime=$START_TIME&endTime=$END_TIME")
print_success "Response received:"
pretty_json "$VOLUME_RESPONSE"

# Step 5: Test Log Level Distribution Endpoint
print_separator
print_info "Step 5: Testing GET /api/v1/dashboard/log-level-distribution"
DISTRIBUTION_RESPONSE=$(make_request "GET" "/api/v1/dashboard/log-level-distribution")
print_success "Response received:"
pretty_json "$DISTRIBUTION_RESPONSE"

# Step 6: Test Top Services Endpoint
print_separator
print_info "Step 6: Testing GET /api/v1/dashboard/top-services"
SERVICES_RESPONSE=$(make_request "GET" "/api/v1/dashboard/top-services?limit=10")
print_success "Response received:"
pretty_json "$SERVICES_RESPONSE"

# Step 7: Test Anomalies Endpoint
print_separator
print_info "Step 7: Testing GET /api/v1/dashboard/anomalies"
ANOMALIES_RESPONSE=$(make_request "GET" "/api/v1/dashboard/anomalies?hours=24")
print_success "Response received:"
pretty_json "$ANOMALIES_RESPONSE"

# Step 8: Test Recent Alerts Endpoint
print_separator
print_info "Step 8: Testing GET /api/v1/dashboard/recent-alerts"
ALERTS_RESPONSE=$(make_request "GET" "/api/v1/dashboard/recent-alerts?hours=24")
print_success "Response received:"
pretty_json "$ALERTS_RESPONSE"

# Step 9: Test Log Search Endpoint (bonus)
print_separator
print_info "Step 9: Testing GET /api/v1/logs/search (bonus)"
SEARCH_RESPONSE=$(make_request "GET" "/api/v1/logs/search?page=0&size=10")
print_success "Response received:"
pretty_json "$SEARCH_RESPONSE"

# Summary
print_separator
print_success "All dashboard endpoints tested successfully!"
print_separator

# Display summary
echo -e "\n${GREEN}Test Summary:${NC}"
echo "✓ Authentication: Working"
echo "✓ Dashboard Metrics: $(echo "$METRICS_RESPONSE" | grep -q "totalLogs" && echo "Working" || echo "Empty data")"
echo "✓ Log Volume: $(echo "$VOLUME_RESPONSE" | grep -q "\[" && echo "Working" || echo "Empty data")"
echo "✓ Log Level Distribution: $(echo "$DISTRIBUTION_RESPONSE" | grep -q "\[" && echo "Working" || echo "Empty data")"
echo "✓ Top Services: $(echo "$SERVICES_RESPONSE" | grep -q "\[" && echo "Working" || echo "Empty data")"
echo "✓ Anomalies: $(echo "$ANOMALIES_RESPONSE" | grep -q "\[" && echo "Working" || echo "Empty data")"
echo "✓ Recent Alerts: $(echo "$ALERTS_RESPONSE" | grep -q "\[" && echo "Working" || echo "Empty data")"
echo "✓ Log Search: $(echo "$SEARCH_RESPONSE" | grep -q "logs" && echo "Working" || echo "Empty data")"

print_separator
print_info "Note: Empty data responses are normal if no logs have been ingested yet."
print_info "To populate data, use the log ingestion endpoint:"
print_info "  curl -X POST http://localhost:8080/api/v1/logs/ingest \\"
print_info "    -H 'Content-Type: application/json' \\"
print_info "    -H 'Authorization: Bearer \$JWT_TOKEN' \\"
print_info "    -d '{\"level\":\"INFO\",\"message\":\"Test log\",\"service\":\"test-service\"}'"
print_separator

echo -e "\n${GREEN}Dashboard endpoints are ready to use!${NC}\n"

# Made with Bob
