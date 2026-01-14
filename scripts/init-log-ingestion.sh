#!/bin/bash

# Initialize Log Ingestion Service
echo "Initializing Log Ingestion Service..."

cd ~/ai-monitoring/backend/log-ingestion

# Download Spring Boot project from Spring Initializr
curl https://start.spring.io/starter.zip \
  -d dependencies=web,actuator,amqp,data-jpa,postgresql,lombok,validation \
  -d type=maven-project \
  -d language=java \
  -d bootVersion=3.2.1 \
  -d groupId=com.ibm.aimonitoring \
  -d artifactId=log-ingestion \
  -d name=LogIngestionService \
  -d packageName=com.ibm.aimonitoring.ingestion \
  -d javaVersion=17 \
  -o temp.zip

# Extract the project
unzip -o temp.zip
rm temp.zip
rm .gitkeep

echo "✓ Spring Boot project created"

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
        default_schema: log_service
  
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

echo "✓ application.yml created"

# Create LogController
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
        return ResponseEntity.ok(Map.of("status", "UP", "service", "log-ingestion"));
    }
}
EOF

echo "✓ LogController created"

echo ""
echo "Log Ingestion Service initialized successfully!"
echo ""
echo "Next steps:"
echo "1. Build: ./mvnw clean install"
echo "2. Run: ./mvnw spring-boot:run"
echo "3. Test: curl -X POST http://localhost:8081/api/v1/logs -H 'Content-Type: application/json' -d '{\"level\":\"INFO\",\"message\":\"Test\"}'"

# Made with Bob
