#!/bin/bash

# Script to check if dashboard data is available
# This helps diagnose why charts are empty

set -e

API_URL="${API_GATEWAY_URL:-http://localhost:8080}"

echo "=========================================="
echo "Dashboard Data Diagnostic"
echo "=========================================="
echo ""

# Check metrics
echo "1. Checking Dashboard Metrics..."
METRICS=$(curl -s "${API_URL}/api/v1/dashboard/metrics" 2>/dev/null || echo "{}")
echo "$METRICS" | python3 -m json.tool 2>/dev/null || echo "$METRICS"
echo ""

# Check log volume
echo "2. Checking Log Volume (last 24 hours)..."
LOG_VOLUME=$(curl -s "${API_URL}/api/v1/dashboard/log-volume?hours=24" 2>/dev/null || echo "[]")
VOLUME_COUNT=$(echo "$LOG_VOLUME" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
echo "Log volume data points: $VOLUME_COUNT"
if [ "$VOLUME_COUNT" -gt 0 ]; then
    echo "First 3 data points:"
    echo "$LOG_VOLUME" | python3 -m json.tool 2>/dev/null | head -20
else
    echo "⚠️  No log volume data found"
fi
echo ""

# Check log level distribution
echo "3. Checking Log Level Distribution..."
LOG_LEVELS=$(curl -s "${API_URL}/api/v1/dashboard/log-level-distribution" 2>/dev/null || echo "[]")
LEVEL_COUNT=$(echo "$LOG_LEVELS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
echo "Log level data points: $LEVEL_COUNT"
if [ "$LEVEL_COUNT" -gt 0 ]; then
    echo "$LOG_LEVELS" | python3 -m json.tool 2>/dev/null
else
    echo "⚠️  No log level distribution data found"
fi
echo ""

# Check top services
echo "4. Checking Top Services..."
TOP_SERVICES=$(curl -s "${API_URL}/api/v1/dashboard/top-services?limit=10" 2>/dev/null || echo "[]")
SERVICE_COUNT=$(echo "$TOP_SERVICES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
echo "Top services data points: $SERVICE_COUNT"
if [ "$SERVICE_COUNT" -gt 0 ]; then
    echo "$TOP_SERVICES" | python3 -m json.tool 2>/dev/null
else
    echo "⚠️  No top services data found"
fi
echo ""

# Check anomalies
echo "5. Checking Anomalies (last 24 hours)..."
ANOMALIES=$(curl -s "${API_URL}/api/v1/dashboard/anomalies?hours=24" 2>/dev/null || echo "[]")
ANOMALY_COUNT=$(echo "$ANOMALIES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
echo "Anomaly data points: $ANOMALY_COUNT"
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Metrics: ✓ (should always return data)"
echo "Log Volume: $([ "$VOLUME_COUNT" -gt 0 ] && echo "✓" || echo "✗") ($VOLUME_COUNT points)"
echo "Log Levels: $([ "$LEVEL_COUNT" -gt 0 ] && echo "✓" || echo "✗") ($LEVEL_COUNT points)"
echo "Top Services: $([ "$SERVICE_COUNT" -gt 0 ] && echo "✓" || echo "✗") ($SERVICE_COUNT points)"
echo "Anomalies: $([ "$ANOMALY_COUNT" -gt 0 ] && echo "✓" || echo "✗") ($ANOMALY_COUNT points)"
echo ""

if [ "$VOLUME_COUNT" -eq 0 ] && [ "$LEVEL_COUNT" -eq 0 ] && [ "$SERVICE_COUNT" -eq 0 ]; then
    echo "⚠️  No chart data found. Possible reasons:"
    echo "   1. Logs haven't been ingested yet"
    echo "   2. Logs haven't been processed/indexed to Elasticsearch"
    echo "   3. Elasticsearch is not running or not accessible"
    echo "   4. Log processor service is not running"
    echo ""
    echo "Next steps:"
    echo "   1. Check if logs were ingested: docker-compose logs log-ingestion --tail 20"
    echo "   2. Check if logs were processed: docker-compose logs log-processor --tail 20"
    echo "   3. Check Elasticsearch: curl http://localhost:9200/_cat/indices/logs"
    echo "   4. Try ingesting logs: USE_DIRECT=true ./scripts/populate-logs.sh 50"
fi
