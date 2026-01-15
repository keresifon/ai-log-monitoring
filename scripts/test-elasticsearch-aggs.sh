#!/bin/bash

# Test Elasticsearch aggregations directly

echo "Testing Elasticsearch Aggregations..."
echo ""

# Test log level distribution
echo "1. Log Level Distribution:"
curl -s -X POST "http://localhost:9200/logs/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "level_distribution": {
        "terms": {
          "field": "level"
        }
      }
    }
  }' | python3 -c "import sys, json; d=json.load(sys.stdin); aggs=d.get('aggregations', {}); ld=aggs.get('level_distribution', {}); buckets=ld.get('buckets', []); print(f'Found {len(buckets)} buckets:'); [print(f'  {b[\"key\"]}: {b[\"doc_count\"]}') for b in buckets]"
echo ""

# Test top services
echo "2. Top Services:"
curl -s -X POST "http://localhost:9200/logs/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "top_services": {
        "terms": {
          "field": "service",
          "size": 10
        }
      }
    }
  }' | python3 -c "import sys, json; d=json.load(sys.stdin); aggs=d.get('aggregations', {}); ts=aggs.get('top_services', {}); buckets=ts.get('buckets', []); print(f'Found {len(buckets)} buckets:'); [print(f'  {b[\"key\"]}: {b[\"doc_count\"]}') for b in buckets]"
echo ""

# Test log volume (date histogram)
echo "3. Log Volume (Last 24 hours):"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
HOURS_AGO=$(date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -v-24H +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || echo "")

if [ -z "$HOURS_AGO" ]; then
    # Fallback: use epoch time
    NOW_EPOCH=$(date +%s)000
    HOURS_AGO_EPOCH=$((NOW_EPOCH - 86400000))
    HOURS_AGO=$(date -u -d "@$((HOURS_AGO_EPOCH / 1000))" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || echo "")
fi

curl -s -X POST "http://localhost:9200/logs/_search" \
  -H "Content-Type: application/json" \
  -d "{
    \"size\": 0,
    \"query\": {
      \"range\": {
        \"timestamp\": {
          \"gte\": \"$HOURS_AGO\",
          \"lte\": \"$NOW\"
        }
      }
    },
    \"aggs\": {
      \"volume_over_time\": {
        \"date_histogram\": {
          \"field\": \"timestamp\",
          \"fixed_interval\": \"1h\",
          \"min_doc_count\": 0
        }
      }
    }
  }" | python3 -c "import sys, json; d=json.load(sys.stdin); aggs=d.get('aggregations', {}); v=aggs.get('volume_over_time', {}); buckets=v.get('buckets', []); print(f'Found {len(buckets)} buckets:'); [print(f'  {b.get(\"key_as_string\", b.get(\"key\"))}: {b[\"doc_count\"]}') for b in buckets[:5]]"
echo ""
