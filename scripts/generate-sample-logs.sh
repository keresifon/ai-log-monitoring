#!/bin/bash

# AI Log Monitoring System - Sample Log Data Generator
# This script generates sample log data for testing dashboard visualizations

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
NUM_LOGS="${NUM_LOGS:-100}"

# Log levels and their weights (higher = more frequent)
declare -A LOG_LEVELS=(
    ["INFO"]=60
    ["WARN"]=20
    ["ERROR"]=15
    ["DEBUG"]=4
    ["TRACE"]=1
)

# Sample services
SERVICES=("auth-service" "log-processor" "api-gateway" "ml-service" "alert-service" "log-ingestion")

# Sample messages
INFO_MESSAGES=(
    "Request processed successfully"
    "User logged in"
    "Data synchronized"
    "Cache updated"
    "Configuration loaded"
    "Health check passed"
    "Metrics collected"
    "Task completed"
)

WARN_MESSAGES=(
    "High memory usage detected"
    "Slow query detected"
    "Rate limit approaching"
    "Deprecated API used"
    "Connection retry attempted"
    "Cache miss rate high"
)

ERROR_MESSAGES=(
    "Database connection failed"
    "Authentication failed"
    "Timeout occurred"
    "Invalid request format"
    "Service unavailable"
    "Permission denied"
    "Resource not found"
)

DEBUG_MESSAGES=(
    "Processing request with ID"
    "Executing query"
    "Validating input"
    "Parsing configuration"
    "Initializing component"
)

TRACE_MESSAGES=(
    "Entering method"
    "Exiting method"
    "Variable value"
    "Loop iteration"
)

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

print_separator() {
    echo -e "\n${BLUE}========================================${NC}"
}

# Function to get random element from array
get_random_element() {
    local arr=("$@")
    local rand_index=$((RANDOM % ${#arr[@]}))
    echo "${arr[$rand_index]}"
}

# Function to get weighted random log level
get_random_log_level() {
    local total_weight=0
    for weight in "${LOG_LEVELS[@]}"; do
        ((total_weight += weight))
    done
    
    local rand=$((RANDOM % total_weight))
    local cumulative=0
    
    for level in "${!LOG_LEVELS[@]}"; do
        ((cumulative += LOG_LEVELS[$level]))
        if [ $rand -lt $cumulative ]; then
            echo "$level"
            return
        fi
    done
}

# Function to get message for log level
get_message_for_level() {
    local level=$1
    case $level in
        INFO)
            get_random_element "${INFO_MESSAGES[@]}"
            ;;
        WARN)
            get_random_element "${WARN_MESSAGES[@]}"
            ;;
        ERROR)
            get_random_element "${ERROR_MESSAGES[@]}"
            ;;
        DEBUG)
            get_random_element "${DEBUG_MESSAGES[@]}"
            ;;
        TRACE)
            get_random_element "${TRACE_MESSAGES[@]}"
            ;;
    esac
}

print_separator
print_info "AI Log Monitoring System - Sample Log Generator"
print_separator

# Step 1: Login to get JWT token
print_info "Step 1: Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" \
    "$API_BASE_URL/api/v1/auth/login")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$JWT_TOKEN" ]; then
    print_error "Failed to obtain JWT token. Please run test-dashboard-endpoints.sh first to create a user."
    exit 1
fi

print_success "Successfully obtained JWT token"

# Step 2: Generate and send sample logs
print_separator
print_info "Step 2: Generating and sending $NUM_LOGS sample logs..."

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in $(seq 1 $NUM_LOGS); do
    # Generate random log data
    LEVEL=$(get_random_log_level)
    MESSAGE=$(get_message_for_level "$LEVEL")
    SERVICE=$(get_random_element "${SERVICES[@]}")
    
    # Add some variation to messages
    MESSAGE="$MESSAGE (ID: $RANDOM)"
    
    # Create log entry JSON
    LOG_JSON=$(cat <<EOF
{
    "level": "$LEVEL",
    "message": "$MESSAGE",
    "service": "$SERVICE",
    "host": "host-$(( (RANDOM % 5) + 1 ))",
    "environment": "development",
    "traceId": "trace-$RANDOM-$RANDOM",
    "spanId": "span-$RANDOM",
    "metadata": {
        "userId": "user-$(( (RANDOM % 100) + 1 ))",
        "requestId": "req-$RANDOM",
        "duration": $(( (RANDOM % 1000) + 10 ))
    }
}
EOF
)
    
    # Send log to ingestion endpoint
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d "$LOG_JSON" \
        "$API_BASE_URL/api/v1/logs/ingest")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        ((SUCCESS_COUNT++))
        echo -ne "\r${GREEN}Progress: $i/$NUM_LOGS logs sent (Success: $SUCCESS_COUNT, Failed: $FAIL_COUNT)${NC}"
    else
        ((FAIL_COUNT++))
        echo -ne "\r${RED}Progress: $i/$NUM_LOGS logs sent (Success: $SUCCESS_COUNT, Failed: $FAIL_COUNT)${NC}"
    fi
    
    # Small delay to avoid overwhelming the system
    sleep 0.05
done

echo "" # New line after progress

print_separator
print_success "Log generation complete!"
print_info "Total logs sent: $NUM_LOGS"
print_info "Successful: $SUCCESS_COUNT"
print_info "Failed: $FAIL_COUNT"

# Step 3: Wait for processing
print_separator
print_info "Step 3: Waiting for logs to be processed (5 seconds)..."
sleep 5

# Step 4: Verify data in dashboard
print_separator
print_info "Step 4: Verifying dashboard data..."

METRICS_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" \
    "$API_BASE_URL/api/v1/dashboard/metrics")

TOTAL_LOGS=$(echo "$METRICS_RESPONSE" | grep -o '"totalLogs":[0-9]*' | cut -d':' -f2)

if [ -n "$TOTAL_LOGS" ] && [ "$TOTAL_LOGS" -gt 0 ]; then
    print_success "Dashboard shows $TOTAL_LOGS total logs"
else
    print_error "Dashboard shows no logs. Data might still be processing."
fi

print_separator
print_success "Sample data generation complete!"
print_separator

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Run the test script to verify all endpoints:"
echo "   ./scripts/test-dashboard-endpoints.sh"
echo ""
echo "2. Open the frontend dashboard:"
echo "   http://localhost:4200"
echo ""
echo "3. View logs in Elasticsearch:"
echo "   curl http://localhost:9200/logs/_search?pretty"
echo ""
echo "4. Generate more logs by running this script again with:"
echo "   NUM_LOGS=500 ./scripts/generate-sample-logs.sh"
print_separator

# Made with Bob
