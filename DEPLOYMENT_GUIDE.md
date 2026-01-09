# Deployment Guide - AI Log Monitoring System

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Java 17+ (for local builds)
- Maven 3.8+ (for local builds)
- 8GB RAM minimum
- 20GB disk space

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd ai-monitoring

# Review and update environment variables
cp .env.example .env  # If .env doesn't exist
nano .env  # Update passwords and credentials
```

### 2. Build Alert Service

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Build alert service
./scripts/build-alert-service.sh
```

### 3. Start All Services

```bash
# Start complete stack
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Verify Deployment

```bash
# Test alert service
./scripts/test-alert-service.sh

# Check individual services
curl http://localhost:8083/actuator/health  # Alert Service
curl http://localhost:8000/api/v1/health    # ML Service
curl http://localhost:9200/_cluster/health  # Elasticsearch
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache |
| Elasticsearch | 9200 | Log storage |
| RabbitMQ | 5672, 15672 | Message queue |
| ML Service | 8000 | Anomaly detection |
| Alert Service | 8083 | Alert management |

## Environment Configuration

### Required Variables

```bash
# Database
POSTGRES_DB=ai_monitoring
POSTGRES_USER=admin
POSTGRES_PASSWORD=<strong-password>

# RabbitMQ
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=<strong-password>

# Alert Service
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=<your-email>
SMTP_PASSWORD=<app-password>
```

### Optional Variables

```bash
# Redis (enable for production)
REDIS_PASSWORD=<strong-password>

# Elasticsearch (enable for production)
ES_SECURITY_ENABLED=true

# Service Ports
ML_SERVICE_PORT=8000
ALERT_SERVICE_PORT=8083
```

## Build Commands

### Alert Service

```bash
cd backend/alert-service

# Clean build
mvn clean install

# Skip tests
mvn clean install -DskipTests

# Run tests only
mvn test

# Package without tests
mvn package -DskipTests
```

### ML Service

```bash
cd backend/ml-service

# Install dependencies
pip install -r requirements.txt

# Run locally
python main.py

# Run tests
pytest
```

## Docker Commands

### Start Services

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d alert-service

# Start with rebuild
docker-compose up -d --build
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Stop specific service
docker-compose stop alert-service
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f alert-service

# Last 100 lines
docker-compose logs --tail=100 alert-service
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart alert-service
```

## Database Management

### Initialize Database

```bash
# Database is automatically initialized on first start
# Scripts: scripts/init-db.sql, scripts/init-alert-service.sql
```

### Connect to Database

```bash
# Using docker
docker-compose exec postgres psql -U admin -d ai_monitoring

# Using local psql
psql -h localhost -U admin -d ai_monitoring
```

### Backup Database

```bash
# Backup
docker-compose exec postgres pg_dump -U admin ai_monitoring > backup.sql

# Restore
docker-compose exec -T postgres psql -U admin ai_monitoring < backup.sql
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs alert-service

# Check service status
docker-compose ps

# Restart service
docker-compose restart alert-service

# Rebuild and restart
docker-compose up -d --build alert-service
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Verify credentials in .env
cat .env | grep POSTGRES
```

### Port Conflicts

```bash
# Check what's using the port
lsof -i :8083  # Linux/Mac
netstat -ano | findstr :8083  # Windows

# Change port in .env
ALERT_SERVICE_PORT=8084
```

### Out of Memory

```bash
# Check Docker resources
docker stats

# Increase Docker memory limit
# Docker Desktop -> Settings -> Resources -> Memory

# Reduce Elasticsearch memory
ES_JAVA_OPTS=-Xms256m -Xmx256m
```

## Health Checks

### Alert Service

```bash
# Actuator health
curl http://localhost:8083/actuator/health

# System health
curl http://localhost:8083/api/v1/monitoring/health

# Statistics
curl http://localhost:8083/api/v1/monitoring/statistics
```

### ML Service

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Model status
curl http://localhost:8000/api/v1/model/status
```

### Elasticsearch

```bash
# Cluster health
curl http://localhost:9200/_cluster/health

# Node info
curl http://localhost:9200/_nodes
```

### RabbitMQ

```bash
# Management UI
open http://localhost:15672
# Login: admin / <password-from-.env>

# API health
curl -u admin:<password> http://localhost:15672/api/health/checks/alarms
```

## Testing

### Run All Tests

```bash
# Alert Service tests
cd backend/alert-service
mvn test

# ML Service tests
cd backend/ml-service
pytest

# Integration tests
./scripts/test-alert-service.sh
```

### Manual API Testing

```bash
# Create alert rule
curl -X POST http://localhost:8083/api/v1/alert-rules \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Rule",
    "type": "ANOMALY_DETECTION",
    "severity": "HIGH",
    "enabled": true
  }'

# List alerts
curl http://localhost:8083/api/v1/alerts

# Get statistics
curl http://localhost:8083/api/v1/monitoring/statistics
```

## Production Deployment

### Security Checklist

- [ ] Change all default passwords in .env
- [ ] Enable Redis password authentication
- [ ] Enable Elasticsearch security
- [ ] Configure SMTP credentials
- [ ] Use HTTPS/TLS for all connections
- [ ] Implement network segmentation
- [ ] Enable audit logging
- [ ] Set up monitoring and alerting
- [ ] Perform security scanning
- [ ] Review SECURITY.md

### Performance Tuning

```bash
# Increase Elasticsearch heap
ES_JAVA_OPTS=-Xms2g -Xmx2g

# Increase PostgreSQL connections
# Add to docker-compose.yml:
command: postgres -c max_connections=200

# Enable Redis persistence
# Add to docker-compose.yml:
command: redis-server --appendonly yes --save 60 1000
```

### Monitoring

```bash
# Prometheus metrics
curl http://localhost:8083/actuator/prometheus

# Application metrics
curl http://localhost:8083/actuator/metrics

# Health indicators
curl http://localhost:8083/actuator/health
```

## Backup and Recovery

### Backup Strategy

```bash
# Daily database backup
0 2 * * * docker-compose exec postgres pg_dump -U admin ai_monitoring > /backups/db-$(date +\%Y\%m\%d).sql

# Weekly full backup
0 3 * * 0 tar -czf /backups/full-$(date +\%Y\%m\%d).tar.gz /var/lib/docker/volumes
```

### Recovery

```bash
# Stop services
docker-compose down

# Restore database
docker-compose up -d postgres
docker-compose exec -T postgres psql -U admin ai_monitoring < backup.sql

# Start all services
docker-compose up -d
```

## Scaling

### Horizontal Scaling

```bash
# Scale alert service
docker-compose up -d --scale alert-service=3

# Use load balancer (nginx, traefik)
# Configure in docker-compose.yml
```

### Vertical Scaling

```bash
# Increase container resources
# Add to docker-compose.yml:
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

## Maintenance

### Update Services

```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build

# Check versions
docker-compose exec alert-service java -version
```

### Clean Up

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove everything
docker system prune -a --volumes
```

## Support

For issues and questions:
- Check logs: `docker-compose logs -f`
- Review SECURITY.md for security issues
- Check troubleshooting section above
- Contact: support@example.com

## Next Steps

1. Complete integration testing
2. Set up monitoring and alerting
3. Configure backup strategy
4. Implement CI/CD pipeline
5. Deploy to production environment

---

**Last Updated:** 2026-01-09
**Version:** 1.0