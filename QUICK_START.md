# Quick Start Guide - AI Log Monitoring System

## Prerequisites

### Required Software

```bash
# Container & Orchestration
- Docker Desktop 4.25+ (with Kubernetes enabled)
- kubectl 1.28+

# Backend Development
- Java 17 (OpenJDK or Eclipse Temurin)
- Maven 3.9+
- Python 3.11+

# Frontend Development
- Node.js 20+ LTS
- npm 10+

# Optional but Recommended
- Git 2.40+
- VS Code with extensions:
  - Spring Boot Extension Pack
  - Angular Language Service
  - Python
  - Docker
  - Kubernetes
```

### Installation Commands

**macOS (Homebrew):**
```bash
brew install openjdk@17 maven node python@3.11 kubectl
brew install --cask docker
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openjdk-17-jdk maven nodejs npm python3.11 kubectl
# Install Docker Desktop from https://docs.docker.com/desktop/install/linux-install/
```

**Windows:**
```powershell
# Using Chocolatey
choco install openjdk17 maven nodejs python311 kubernetes-cli docker-desktop
```

---

## First 3 Tasks (Start Immediately)

### Task 1: Repository Setup (2 hours)

```bash
# 1. Create and clone repository
mkdir ai-log-monitor-application
cd ai-log-monitor-application
git init

# 2. Create directory structure
mkdir -p backend/{api-gateway,log-ingestion,log-processor,ml-service,alert-service}
mkdir -p frontend
mkdir -p kubernetes/{base/{databases,applications},overlays/{dev,prod}}
mkdir -p docs
mkdir -p scripts

# 3. Create .gitignore
cat > .gitignore << 'EOF'
# Java
target/
*.class
*.jar
*.war
*.ear
.mvn/
mvnw
mvnw.cmd

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
.env
*.pkl
*.joblib

# Node
node_modules/
dist/
.angular/
npm-debug.log*

# IDE
.idea/
.vscode/
*.iml
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/
EOF

# 4. Create README
cat > README.md << 'EOF'
# AI Log Monitoring System

Microservices-based log monitoring with ML-powered anomaly detection.

## Architecture

- **API Gateway** (Spring Boot) - Central entry point
- **Log Ingestion Service** (Spring Boot) - Receives logs
- **Log Processor Service** (Spring Boot) - Processes and indexes logs
- **ML Service** (Python/FastAPI) - Anomaly detection
- **Alert Service** (Spring Boot) - Notifications
- **Frontend** (Angular 17+) - Dashboard UI

## Quick Start

See [QUICK_START.md](QUICK_START.md) for detailed setup instructions.

## Documentation

- [Project Plan](PROJECT_PLAN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Development Guide](docs/DEVELOPMENT.md)

## License

MIT
EOF

# 5. Initial commit
git add .
git commit -m "chore: initial repository setup"

# 6. Create remote and push (replace with your repo URL)
# git remote add origin https://github.com/your-username/ai-log-monitor-application.git
# git push -u origin main
```

### Task 2: Docker Compose for Local Development (2 hours)

```bash
# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ai-monitoring-postgres
    environment:
      POSTGRES_DB: ai_monitoring
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin -d ai_monitoring"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: ai-monitoring-redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: ai-monitoring-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: ai-monitoring-rabbitmq
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin123
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  postgres_data:
  redis_data:
  es_data:
  rabbitmq_data:
EOF

# Create database initialization script
mkdir -p scripts
cat > scripts/init-db.sql << 'EOF'
-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth_service;
CREATE SCHEMA IF NOT EXISTS log_service;
CREATE SCHEMA IF NOT EXISTS alert_service;
CREATE SCHEMA IF NOT EXISTS ml_service;

-- Auth Service Tables
CREATE TABLE auth_service.users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_service.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE auth_service.user_roles (
    user_id BIGINT REFERENCES auth_service.users(id) ON DELETE CASCADE,
    role_id INT REFERENCES auth_service.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Insert default roles
INSERT INTO auth_service.roles (name, description) VALUES
    ('ADMIN', 'Full system access'),
    ('USER', 'Standard user access'),
    ('VIEWER', 'Read-only access');

-- Insert default admin user (password: admin123)
INSERT INTO auth_service.users (username, email, password_hash, full_name) VALUES
    ('admin', 'admin@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'System Administrator');

INSERT INTO auth_service.user_roles (user_id, role_id) VALUES (1, 1);

-- Log Service Tables
CREATE TABLE log_service.log_sources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    configuration JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alert Service Tables
CREATE TABLE alert_service.alert_rules (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    condition JSONB NOT NULL,
    severity VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alert_service.notification_channels (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    configuration JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alert_service.alerts (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES alert_service.alert_rules(id),
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    metadata JSONB,
    status VARCHAR(20) DEFAULT 'open',
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP
);

-- ML Service Tables
CREATE TABLE ml_service.ml_models (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    model_type VARCHAR(50) NOT NULL,
    model_path VARCHAR(255) NOT NULL,
    metrics JSONB,
    is_active BOOLEAN DEFAULT false,
    trained_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name, version)
);

CREATE TABLE ml_service.anomaly_detections (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT REFERENCES ml_service.ml_models(id),
    log_id VARCHAR(255) NOT NULL,
    anomaly_score DECIMAL(5,4) NOT NULL,
    is_anomaly BOOLEAN NOT NULL,
    features JSONB,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_alerts_triggered_at ON alert_service.alerts(triggered_at DESC);
CREATE INDEX idx_alerts_status ON alert_service.alerts(status);
CREATE INDEX idx_anomaly_detections_detected_at ON ml_service.anomaly_detections(detected_at DESC);
EOF

# Start services
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 30

# Verify services
echo "Verifying services..."
curl -f http://localhost:9200 && echo "✓ Elasticsearch is ready"
curl -f http://localhost:15672 && echo "✓ RabbitMQ Management is ready"
docker exec ai-monitoring-postgres pg_isready -U admin && echo "✓ PostgreSQL is ready"
docker exec ai-monitoring-redis redis-cli ping && echo "✓ Redis is ready"

echo "All services are running!"
echo "Access RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "Access Elasticsearch: http://localhost:9200"
```

### Task 3: Initialize Spring Boot Projects (3 hours)

```bash
# Install Spring Boot CLI (optional but helpful)
# macOS: brew install springboot
# Or use Spring Initializr web interface: https://start.spring.io/

# Create Log Ingestion Service
cd backend/log-ingestion

# Using curl to download from Spring Initializr
curl https://start.spring.io/starter.zip \
  -d dependencies=web,actuator,amqp,data-jpa,postgresql,lombok,validation \
  -d type=maven-project \
  -d language=java \
  -d bootVersion=3.2.1 \
  -d baseDir=. \
  -d groupId=com.ibm.aimonitoring \
  -d artifactId=log-ingestion \
  -d name=LogIngestionService \
  -d packageName=com.ibm.aimonitoring.ingestion \
  -d javaVersion=17 \
  -o temp.zip && unzip temp.zip && rm temp.zip

# Create application.yml
cat > src/main/resources/application.yml << 'EOF'
spring:
  application:
    name: log-ingestion-service
  
  datasource:
    url: jdbc:postgresql://localhost:5432/ai_monitoring
    username: admin
    password: admin123
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
  
  rabbitmq:
    host: localhost
    port: 5672
    username: admin
    password: admin123

server:
  port: 8081

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always

logging:
  level:
    com.ibm.aimonitoring: DEBUG
    org.springframework: INFO
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
EOF

# Create a simple REST controller
mkdir -p src/main/java/com/ibm/aimonitoring/ingestion/controller
cat > src/main/java/com/ibm/aimonitoring/ingestion/controller/LogController.java << 'EOF'
package com.ibm.aimonitoring.ingestion.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    @PostMapping
    public ResponseEntity<Map<String, Object>> ingestLog(@RequestBody Map<String, Object> logEntry) {
        log.info("Received log: {}", logEntry);
        
        String logId = UUID.randomUUID().toString();
        
        return ResponseEntity.accepted().body(Map.of(
            "id", logId,
            "status", "accepted",
            "timestamp", Instant.now().toString()
        ));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP"));
    }
}
EOF

# Build and test
./mvnw clean install
./mvnw spring-boot:run &

# Wait for service to start
sleep 15

# Test the endpoint
curl -X POST http://localhost:8081/api/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "Hello World from AI Monitoring!",
    "service": "test-service"
  }'

# Stop the service
pkill -f "spring-boot:run"

echo "✓ Log Ingestion Service is working!"
```

---

## "Hello World" Milestone

By the end of Week 1, you should have:

### ✅ Checklist

- [ ] Repository structure created
- [ ] Docker Compose running all dependencies
- [ ] PostgreSQL with initialized schemas
- [ ] Redis accessible
- [ ] Elasticsearch accessible
- [ ] RabbitMQ accessible with management UI
- [ ] Log Ingestion Service builds successfully
- [ ] Can POST a log to `/api/v1/logs` endpoint
- [ ] Service returns 202 Accepted with log ID
- [ ] Health check endpoint working

### Test Commands

```bash
# 1. Verify Docker services
docker-compose ps

# Expected output: All services should be "Up" and "healthy"

# 2. Test PostgreSQL
docker exec ai-monitoring-postgres psql -U admin -d ai_monitoring -c "\dn"

# Expected: Should list schemas (auth_service, log_service, alert_service, ml_service)

# 3. Test Elasticsearch
curl http://localhost:9200/_cluster/health?pretty

# Expected: "status": "green" or "yellow"

# 4. Test RabbitMQ
curl -u admin:admin123 http://localhost:15672/api/overview

# Expected: JSON response with RabbitMQ overview

# 5. Test Log Ingestion Service
cd backend/log-ingestion
./mvnw spring-boot:run &
sleep 15

curl -X POST http://localhost:8081/api/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "message": "Test error message",
    "service": "test-service",
    "metadata": {
      "error_code": "TEST_001"
    }
  }'

# Expected: {"id":"<uuid>","status":"accepted","timestamp":"<iso-date>"}

# 6. Check health endpoint
curl http://localhost:8081/actuator/health

# Expected: {"status":"UP"}
```

---

## Development Workflow

### Daily Development Routine

```bash
# 1. Start dependencies
docker-compose up -d

# 2. Start backend services (in separate terminals)
cd backend/log-ingestion && ./mvnw spring-boot:run
cd backend/log-processor && ./mvnw spring-boot:run
cd backend/api-gateway && ./mvnw spring-boot:run

# 3. Start ML service
cd backend/ml-service && python -m uvicorn main:app --reload

# 4. Start frontend
cd frontend && npm start

# 5. Access applications
# - Frontend: http://localhost:4200
# - API Gateway: http://localhost:8080
# - Log Ingestion: http://localhost:8081
# - Log Processor: http://localhost:8082
# - ML Service: http://localhost:8000
# - RabbitMQ Management: http://localhost:15672
# - Elasticsearch: http://localhost:9200
```

### Stopping Services

```bash
# Stop all Spring Boot services
pkill -f "spring-boot:run"

# Stop ML service
pkill -f "uvicorn"

# Stop frontend
# Press Ctrl+C in the terminal running npm start

# Stop Docker services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

```bash
# Find process using port
lsof -i :8081  # macOS/Linux
netstat -ano | findstr :8081  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### 2. Docker Services Not Starting

```bash
# Check logs
docker-compose logs postgres
docker-compose logs elasticsearch

# Restart specific service
docker-compose restart postgres

# Rebuild and restart
docker-compose up -d --force-recreate postgres
```

#### 3. Maven Build Failures

```bash
# Clean and rebuild
./mvnw clean install -U

# Skip tests
./mvnw clean install -DskipTests

# Clear Maven cache
rm -rf ~/.m2/repository
```

#### 4. Elasticsearch Yellow Status

```bash
# This is normal for single-node development
# To fix, reduce replica count:
curl -X PUT "localhost:9200/_settings" -H 'Content-Type: application/json' -d'
{
  "index": {
    "number_of_replicas": 0
  }
}
'
```

---

## Next Steps

After completing the Quick Start:

1. **Review the [PROJECT_PLAN.md](PROJECT_PLAN.md)** for the complete 12-week roadmap
2. **Start Week 2 tasks** - Build out the Log Ingestion Service
3. **Set up CI/CD** - Configure GitHub Actions
4. **Create remaining services** - Log Processor, ML Service, etc.

---

## Useful Commands Reference

### Docker

```bash
# View logs
docker-compose logs -f [service-name]

# Execute command in container
docker exec -it ai-monitoring-postgres psql -U admin -d ai_monitoring

# Check resource usage
docker stats

# Prune unused resources
docker system prune -a
```

### Maven

```bash
# Run tests
./mvnw test

# Run specific test
./mvnw test -Dtest=LogControllerTest

# Generate coverage report
./mvnw jacoco:report

# Check for dependency updates
./mvnw versions:display-dependency-updates
```

### Git

```bash
# Create feature branch
git checkout -b feature/log-ingestion-api

# Commit with conventional commits
git commit -m "feat(ingestion): add log validation"

# Push and create PR
git push -u origin feature/log-ingestion-api
```

---

## Resources

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Angular Documentation](https://angular.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## Support

For issues or questions:
1. Check the [PROJECT_PLAN.md](PROJECT_PLAN.md) for detailed guidance
2. Review the [docs/](docs/) directory for specific topics
3. Open an issue on GitHub
4. Consult the official documentation for each technology

Happy coding! 🚀