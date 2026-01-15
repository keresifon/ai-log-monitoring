#!/bin/bash

# Script to populate the system with sample logs for testing
# Usage: ./scripts/populate-logs.sh [count]
# Default: 100 logs

set -e

API_URL="${API_GATEWAY_URL:-http://localhost:8080}"
# Allow direct connection to log ingestion service if API Gateway has auth issues
INGESTION_URL="${LOG_INGESTION_URL:-http://localhost:8081}"
USE_DIRECT="${USE_DIRECT:-false}"
LOG_COUNT="${1:-100}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Populating System with Sample Logs${NC}"
echo -e "${BLUE}========================================${NC}"
if [ "$USE_DIRECT" = "true" ]; then
    echo -e "Using Direct Ingestion Service: ${INGESTION_URL}"
else
    echo -e "Using API Gateway: ${API_URL}"
fi
echo -e "Log Count: ${LOG_COUNT}"
echo ""

# Check if API Gateway is accessible
echo -e "${YELLOW}Checking API Gateway health...${NC}"
if ! curl -s -f "${API_URL}/actuator/health" > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: API Gateway health check failed. Continuing anyway...${NC}"
fi

# Services to use
SERVICES=("auth-service" "user-service" "payment-service" "order-service" "api-gateway" "log-service" "notification-service" "database-service")

# Log levels
LEVELS=("ERROR" "WARN" "INFO" "DEBUG")

# Environments
ENVIRONMENTS=("production" "staging" "development")

# Hosts
HOSTS=("prod-server-01" "prod-server-02" "staging-server-01" "dev-server-01" "dev-server-02")

# Error messages
ERROR_MESSAGES=(
    "Database connection failed"
    "Timeout while connecting to external service"
    "Authentication token expired"
    "Invalid request parameters"
    "Service unavailable"
    "Memory limit exceeded"
    "Disk space running low"
    "Network connection lost"
    "Failed to process payment"
    "User not found"
    "Permission denied"
    "Rate limit exceeded"
)

# Warning messages
WARN_MESSAGES=(
    "High memory usage detected"
    "Slow query detected"
    "Cache miss rate increased"
    "Response time above threshold"
    "Deprecated API endpoint used"
    "SSL certificate expiring soon"
    "Backup job running longer than expected"
)

# Info messages
INFO_MESSAGES=(
    "User successfully logged in"
    "Order processed successfully"
    "Payment received"
    "Cache updated"
    "Scheduled task completed"
    "Configuration reloaded"
    "Service started"
    "Health check passed"
    "Database backup completed"
    "New user registered"
)

# Debug messages
DEBUG_MESSAGES=(
    "Processing request"
    "Cache lookup"
    "Database query executed"
    "Validation passed"
    "Request parameters parsed"
)

# Function to generate a random log entry
generate_log() {
    local index=$1
    local total=$2
    
    # Calculate timestamp (spread over last 24 hours)
    local hours_ago=$((RANDOM % 24))
    local minutes_ago=$((RANDOM % 60))
    local seconds_ago=$((RANDOM % 60))
    local timestamp=$(date -u -d "${hours_ago} hours ${minutes_ago} minutes ${seconds_ago} seconds ago" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || \
                      date -u -v-${hours_ago}H -v-${minutes_ago}M -v-${seconds_ago}S +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || \
                      date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    # Random selections
    local service=${SERVICES[$RANDOM % ${#SERVICES[@]}]}
    local level=${LEVELS[$RANDOM % ${#LEVELS[@]}]}
    local environment=${ENVIRONMENTS[$RANDOM % ${#ENVIRONMENTS[@]}]}
    local host=${HOSTS[$RANDOM % ${#HOSTS[@]}]}
    
    # Select message based on level
    local message=""
    case $level in
        "ERROR")
            message=${ERROR_MESSAGES[$RANDOM % ${#ERROR_MESSAGES[@]}]}
            ;;
        "WARN")
            message=${WARN_MESSAGES[$RANDOM % ${#WARN_MESSAGES[@]}]}
            ;;
        "INFO")
            message=${INFO_MESSAGES[$RANDOM % ${#INFO_MESSAGES[@]}]}
            ;;
        "DEBUG")
            message=${DEBUG_MESSAGES[$RANDOM % ${#DEBUG_MESSAGES[@]}]}
            ;;
    esac
    
    # Add some variation to messages
    if [ $((RANDOM % 3)) -eq 0 ]; then
        message="${message} (Request ID: ${RANDOM}${RANDOM})"
    fi
    
    # Generate trace ID
    local trace_id="trace-$(printf "%04x" $RANDOM)-$(printf "%04x" $RANDOM)"
    local span_id="span-$(printf "%04x" $RANDOM)"
    
    # Build JSON payload
    local payload=$(cat <<EOF
{
  "timestamp": "${timestamp}",
  "level": "${level}",
  "message": "${message}",
  "service": "${service}",
  "host": "${host}",
  "environment": "${environment}",
  "metadata": {
    "requestId": "${RANDOM}${RANDOM}",
    "userId": "$((RANDOM % 1000))",
    "sessionId": "session-${RANDOM}"
  },
  "traceId": "${trace_id}",
  "spanId": "${span_id}"
}
EOF
)
    
    echo "$payload"
}

# Function to send a log entry
send_log() {
    local payload=$1
    local url="${API_URL}/api/v1/logs"
    
    # Use direct ingestion service if USE_DIRECT is true
    if [ "$USE_DIRECT" = "true" ]; then
        url="${INGESTION_URL}/api/v1/logs"
    fi
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 202 ] || [ "$http_code" -eq 200 ]; then
        return 0
    else
        echo "Error: HTTP $http_code - $body" >&2
        return 1
    fi
}

# Main loop
echo -e "${YELLOW}Sending ${LOG_COUNT} log entries...${NC}"
echo ""

success_count=0
error_count=0

for i in $(seq 1 $LOG_COUNT); do
    payload=$(generate_log $i $LOG_COUNT)
    
    if send_log "$payload"; then
        success_count=$((success_count + 1))
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Sent $i/$LOG_COUNT logs..."
        fi
    else
        error_count=$((error_count + 1))
        echo -e "${YELLOW}✗${NC} Failed to send log $i"
    fi
    
    # Small delay to avoid overwhelming the system
    sleep 0.1
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Success:${NC} $success_count"
echo -e "${YELLOW}Errors:${NC} $error_count"
echo ""

if [ $success_count -gt 0 ]; then
    echo -e "${GREEN}✓ Logs are being processed. Wait a few seconds for them to appear in the dashboard.${NC}"
    echo ""
    echo "You can check the dashboard at: http://localhost:4200/dashboard"
    echo "Or check logs at: http://localhost:4200/logs"
fi

if [ $error_count -gt 0 ]; then
    echo -e "${YELLOW}Warning: Some logs failed to send. Check:${NC}"
    echo "  - API Gateway is running: ${API_URL}"
    echo "  - Log Ingestion Service is running"
    echo "  - RabbitMQ is running"
fi
