# AI Log Monitoring System - Testing Scripts

This directory contains scripts for testing and populating the AI Log Monitoring System.

## Available Scripts

### 1. test-dashboard-endpoints.sh
Tests all dashboard API endpoints with authentication.

**Usage:**
```bash
# Run with default settings
./scripts/test-dashboard-endpoints.sh

# Run with custom configuration
API_BASE_URL=http://localhost:8080 \
TEST_USERNAME=myuser \
TEST_PASSWORD=mypass \
./scripts/test-dashboard-endpoints.sh
```

**What it tests:**
- ✅ User registration and login
- ✅ JWT token authentication
- ✅ Dashboard metrics endpoint
- ✅ Log volume over time
- ✅ Log level distribution
- ✅ Top services by log count
- ✅ Recent anomalies
- ✅ Recent alerts
- ✅ Log search functionality

**Requirements:**
- `curl` command
- `jq` (optional, for pretty JSON output)
- Running AI Log Monitoring System

### 2. generate-sample-logs.sh
Generates and ingests sample log data for testing dashboard visualizations.

**Usage:**
```bash
# Generate 100 sample logs (default)
./scripts/generate-sample-logs.sh

# Generate 500 sample logs
NUM_LOGS=500 ./scripts/generate-sample-logs.sh

# Custom configuration
API_BASE_URL=http://localhost:8080 \
TEST_USERNAME=myuser \
TEST_PASSWORD=mypass \
NUM_LOGS=1000 \
./scripts/generate-sample-logs.sh
```

**What it does:**
- Authenticates with the system
- Generates realistic log entries with:
  - Multiple log levels (INFO, WARN, ERROR, DEBUG, TRACE)
  - Various services (auth-service, log-processor, api-gateway, etc.)
  - Random metadata (userId, requestId, duration)
  - Trace IDs and span IDs
- Sends logs to the ingestion endpoint
- Verifies data appears in dashboard

**Log Distribution:**
- INFO: 60%
- WARN: 20%
- ERROR: 15%
- DEBUG: 4%
- TRACE: 1%

### 3. Other Utility Scripts

#### build-alert-service.sh
Builds the alert service Docker image.

#### deploy-all-services.sh
Deploys all services using docker-compose.

## Quick Start Guide

### Step 1: Start the System
```bash
cd /home/kere/ai-monitoring
docker-compose up -d
```

### Step 2: Wait for Services to Start
```bash
# Check service health
docker-compose ps

# Wait until all services are healthy (about 30 seconds)
```

### Step 3: Test Dashboard Endpoints
```bash
# This will create a test user and test all endpoints
./scripts/test-dashboard-endpoints.sh
```

Expected output:
```
========================================
[INFO] AI Log Monitoring System - Dashboard Endpoints Test
========================================
[INFO] Step 1: Registering test user...
[SUCCESS] User registered successfully
[INFO] Step 2: Logging in to get JWT token...
[SUCCESS] Successfully obtained JWT token
...
[SUCCESS] All dashboard endpoints tested successfully!
```

### Step 4: Generate Sample Data
```bash
# Generate 100 sample logs
./scripts/generate-sample-logs.sh
```

Expected output:
```
========================================
[INFO] AI Log Monitoring System - Sample Log Generator
========================================
[INFO] Step 1: Logging in to get JWT token...
[SUCCESS] Successfully obtained JWT token
[INFO] Step 2: Generating and sending 100 sample logs...
Progress: 100/100 logs sent (Success: 100, Failed: 0)
[SUCCESS] Log generation complete!
```

### Step 5: Verify Dashboard Data
```bash
# Test endpoints again to see populated data
./scripts/test-dashboard-endpoints.sh
```

### Step 6: View in Frontend
Open your browser and navigate to:
- Frontend: http://localhost:4200
- Login with: testuser / password123

## Environment Variables

### Common Variables
- `API_BASE_URL` - Base URL of the API Gateway (default: http://localhost:8080)
- `TEST_USERNAME` - Username for testing (default: testuser)
- `TEST_PASSWORD` - Password for testing (default: password123)
- `TEST_EMAIL` - Email for registration (default: testuser@example.com)

### Script-Specific Variables
- `NUM_LOGS` - Number of logs to generate (default: 100)

## Troubleshooting

### Issue: "Failed to obtain JWT token"
**Solution:** 
1. Ensure all services are running: `docker-compose ps`
2. Check auth-service logs: `docker-compose logs auth-service`
3. Verify API Gateway is accessible: `curl http://localhost:8080/actuator/health`

### Issue: "Connection refused"
**Solution:**
1. Check if services are running: `docker-compose ps`
2. Restart services: `docker-compose restart`
3. Check port conflicts: `netstat -an | grep 8080`

### Issue: "Empty data in dashboard"
**Solution:**
1. Run the sample data generator: `./scripts/generate-sample-logs.sh`
2. Wait a few seconds for processing
3. Check Elasticsearch: `curl http://localhost:9200/logs/_count`

### Issue: "jq: command not found"
**Solution:**
The scripts work without jq, but JSON output won't be pretty-printed.
To install jq:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

## Advanced Usage

### Generate Large Dataset
```bash
# Generate 10,000 logs for load testing
NUM_LOGS=10000 ./scripts/generate-sample-logs.sh
```

### Test with Different User
```bash
# Create and test with a different user
TEST_USERNAME=admin \
TEST_PASSWORD=admin123 \
TEST_EMAIL=admin@example.com \
./scripts/test-dashboard-endpoints.sh
```

### Continuous Log Generation
```bash
# Generate logs continuously (useful for testing)
while true; do
    NUM_LOGS=50 ./scripts/generate-sample-logs.sh
    sleep 10
done
```

### Extract Specific Metrics
```bash
# Get just the total log count
./scripts/test-dashboard-endpoints.sh 2>/dev/null | \
    grep -A 20 "dashboard/metrics" | \
    grep "totalLogs"
```

## API Endpoint Reference

All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

### Dashboard Endpoints
- `GET /api/v1/dashboard/metrics` - Overall system metrics
- `GET /api/v1/dashboard/log-volume?startTime=<ISO8601>&endTime=<ISO8601>` - Log volume over time
- `GET /api/v1/dashboard/log-level-distribution` - Log level breakdown
- `GET /api/v1/dashboard/top-services?limit=<number>` - Top services
- `GET /api/v1/dashboard/anomalies?hours=<number>` - Recent anomalies
- `GET /api/v1/dashboard/recent-alerts?hours=<number>` - Recent alerts

### Log Endpoints
- `POST /api/v1/logs/ingest` - Ingest a log entry
- `GET /api/v1/logs/search` - Search logs with filters

### Auth Endpoints
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login and get JWT token
- `POST /api/v1/auth/refresh` - Refresh JWT token

## Contributing

When adding new test scripts:
1. Follow the existing naming convention
2. Include colored output for better readability
3. Add error handling and validation
4. Document usage in this README
5. Make scripts executable: `chmod +x script-name.sh`

## Support

For issues or questions:
1. Check the main project README
2. Review service logs: `docker-compose logs <service-name>`
3. Verify service health: `docker-compose ps`
4. Check API Gateway routes: `curl http://localhost:8080/actuator/gateway/routes`