# AI Code Generation Prompts

This document contains effective prompts for generating code using AI tools (Claude, ChatGPT, GitHub Copilot) for the AI Log Monitoring System project.

## How to Use These Prompts

1. **Copy the entire prompt** including context and requirements
2. **Customize** placeholders (package names, specific requirements)
3. **Review generated code** carefully before using
4. **Test thoroughly** - AI-generated code needs validation
5. **Iterate** - Refine prompts based on results

---

## Spring Boot Service Prompts

### 1. REST Controller with Validation

```
Create a Spring Boot REST controller for log ingestion with these requirements:

Context:
- Package: com.ibm.aimonitoring.ingestion.controller
- Spring Boot 3.2+, Java 17
- Part of microservices architecture

Requirements:
- Endpoint: POST /api/v1/logs
- Accept JSON with fields: timestamp (ISO 8601), level (ERROR/WARN/INFO/DEBUG), message (required), service (required), host (optional), metadata (JSON object, optional)
- Validate: level must be valid enum, message and service are required, message max 10000 chars
- Return: 202 Accepted with response containing id (UUID), status ("accepted"), timestamp
- Error handling: 400 for validation errors with detailed messages, 500 for server errors
- Logging: Log all requests at DEBUG level
- Use Lombok for DTOs
- Include OpenAPI/Swagger annotations
- Follow Spring Boot best practices

Generate:
1. LogController class
2. LogEntryDTO (request)
3. LogResponseDTO (response)
4. Custom validation annotations if needed
5. Exception handler
```

### 2. JPA Entity with Relationships

```
Create JPA entities for the alert service with these requirements:

Context:
- Package: com.ibm.aimonitoring.alert.entity
- PostgreSQL database with schema: alert_service
- Spring Data JPA

Requirements:
- AlertRule entity:
  * id (Long, auto-generated)
  * name (String, max 100, not null)
  * description (Text, nullable)
  * condition (JSON stored as String, not null)
  * severity (Enum: CRITICAL, HIGH, MEDIUM, LOW)
  * isActive (Boolean, default true)
  * createdBy (Long, foreign key to users)
  * createdAt, updatedAt (timestamps)
  * One-to-many relationship with Alert
  * Many-to-many relationship with NotificationChannel

- Alert entity:
  * id (Long, auto-generated)
  * ruleId (foreign key to AlertRule)
  * severity, title, message, metadata (JSON)
  * status (Enum: OPEN, ACKNOWLEDGED, RESOLVED)
  * triggeredAt, acknowledgedAt, resolvedAt (timestamps)
  * Many-to-one relationship with AlertRule

- NotificationChannel entity:
  * id (Long, auto-generated)
  * type (Enum: EMAIL, SLACK, WEBHOOK, SMS)
  * name, configuration (JSON)
  * isActive (Boolean)
  * Many-to-many relationship with AlertRule

Generate:
1. All entity classes with proper annotations
2. Enums for severity, status, channel type
3. Proper indexes (@Table annotations)
4. Lombok annotations
5. Bidirectional relationships properly configured
```

### 3. Service Layer with Business Logic

```
Create a service class for log processing with these requirements:

Context:
- Package: com.ibm.aimonitoring.processor.service
- Consumes logs from RabbitMQ, processes, and indexes to Elasticsearch
- Spring Boot 3.2+

Requirements:
- Class: LogProcessorService
- Dependencies: ElasticsearchClient, MLServiceClient (REST), AlertService
- Methods:
  * processLog(LogEntry log): Parse, normalize, enrich
  * indexToElasticsearch(ProcessedLog log): Bulk indexing support
  * checkForAnomalies(ProcessedLog log): Call ML service
  * triggerAlertsIfNeeded(ProcessedLog log, AnomalyResult anomaly)
- Error handling: Retry logic with exponential backoff for transient failures
- Logging: Structured logging with correlation IDs
- Metrics: Track processing time, success/failure rates
- Use @Transactional where appropriate
- Follow SOLID principles

Generate:
1. LogProcessorService class
2. Required DTOs (ProcessedLog, AnomalyResult)
3. Custom exceptions
4. Retry configuration
5. Unit test skeleton
```

### 4. RabbitMQ Configuration

```
Create RabbitMQ configuration for the log monitoring system:

Context:
- Package: com.ibm.aimonitoring.config
- Spring Boot 3.2+ with Spring AMQP
- Multiple services producing/consuming messages

Requirements:
- Exchange: "logs.exchange" (topic exchange)
- Queues:
  * "logs.raw" - receives all ingested logs
  * "logs.processed" - receives processed logs
  * "logs.dlq" - dead letter queue for failed messages
- Routing keys:
  * "logs.raw" -> logs.raw queue
  * "logs.processed" -> logs.processed queue
- Message converter: Jackson2JsonMessageConverter
- Retry policy: 3 retries with 5s delay
- Prefetch count: 10 messages
- Acknowledgment mode: Manual
- Connection factory with connection pooling

Generate:
1. RabbitMQConfig class
2. Queue, Exchange, Binding declarations
3. RabbitTemplate configuration
4. SimpleRabbitListenerContainerFactory configuration
5. Error handler for failed messages
```

---

## Python/FastAPI Prompts

### 5. FastAPI ML Service Structure

```
Create a FastAPI service for anomaly detection with these requirements:

Context:
- Python 3.11, FastAPI 0.104+
- ML model: Isolation Forest (scikit-learn)
- Deployed as microservice in Kubernetes

Requirements:
- Endpoints:
  * POST /api/v1/ml/train - Train new model
  * POST /api/v1/ml/predict - Predict anomaly
  * GET /api/v1/ml/models - List models
  * GET /api/v1/ml/models/{id} - Get model details
  * POST /api/v1/ml/models/{id}/activate - Activate model
  * GET /health - Health check
- Features to extract from logs:
  * Message length
  * Keyword presence (error, exception, timeout, etc.)
  * Time-based features (hour, day of week)
  * Service name encoding
  * Log level encoding
- Model persistence: Save to disk with joblib
- Async endpoints where appropriate
- Pydantic models for request/response validation
- Proper error handling with HTTP status codes
- CORS enabled
- Logging with structlog

Generate:
1. main.py with FastAPI app
2. models.py with Pydantic models
3. ml_service.py with ML logic
4. feature_engineering.py
5. requirements.txt
6. Dockerfile
```

### 6. Isolation Forest Implementation

```
Create an Isolation Forest anomaly detection implementation:

Context:
- Python 3.11, scikit-learn
- Detect anomalies in log data
- Real-time prediction with pre-trained model

Requirements:
- Class: AnomalyDetector
- Methods:
  * train(logs: List[Dict]) -> Model: Train on historical logs
  * predict(log: Dict) -> AnomalyResult: Predict single log
  * predict_batch(logs: List[Dict]) -> List[AnomalyResult]: Batch prediction
  * save_model(path: str): Persist model
  * load_model(path: str): Load model
- Features:
  * Extract from log message, level, service, timestamp
  * TF-IDF for message text
  * One-hot encoding for categorical features
  * Normalize numerical features
- Hyperparameters:
  * contamination=0.1 (10% anomalies expected)
  * n_estimators=100
  * max_samples=256
- Return anomaly score (0-1) and boolean is_anomaly
- Handle missing features gracefully
- Include feature importance analysis

Generate:
1. AnomalyDetector class
2. FeatureExtractor class
3. AnomalyResult dataclass
4. Training pipeline
5. Unit tests with sample data
```

---

## Angular Prompts

### 7. Angular Component with Material

```
Create an Angular component for displaying logs with these requirements:

Context:
- Angular 17+ standalone component
- Angular Material for UI
- TypeScript strict mode

Requirements:
- Component: LogViewerComponent
- Features:
  * Display logs in Material table (mat-table)
  * Columns: timestamp, level, service, message, actions
  * Color-code log levels (ERROR=red, WARN=orange, INFO=blue, DEBUG=gray)
  * Pagination (mat-paginator) - 50 rows per page
  * Sorting (mat-sort) - all columns sortable
  * Filtering:
    - Level dropdown (mat-select)
    - Service autocomplete (mat-autocomplete)
    - Date range picker (mat-date-range-picker)
    - Search box for message text
  * Click row to view details in dialog (mat-dialog)
  * Export button (CSV/JSON)
  * Real-time updates via polling (30s interval)
- State management: Component-level (no NgRx for now)
- Responsive design: Mobile-friendly
- Loading states: Skeleton loaders
- Error handling: Display error messages with mat-snackbar
- Accessibility: ARIA labels, keyboard navigation

Generate:
1. log-viewer.component.ts
2. log-viewer.component.html
3. log-viewer.component.scss
4. log-viewer.component.spec.ts
5. log.service.ts (HTTP service)
6. log.model.ts (interfaces)
```

### 8. Angular Service with RxJS

```
Create an Angular service for log operations with these requirements:

Context:
- Angular 17+ service
- RxJS for reactive programming
- HTTP client for API calls

Requirements:
- Service: LogService
- Methods:
  * searchLogs(filters: LogFilter): Observable<LogSearchResult>
  * getLogById(id: string): Observable<Log>
  * streamLogs(): Observable<Log> - Server-Sent Events
  * exportLogs(filters: LogFilter, format: 'csv' | 'json'): Observable<Blob>
- Features:
  * Caching with shareReplay for frequent queries
  * Error handling with retry logic (3 retries, exponential backoff)
  * Loading state management
  * Request cancellation on component destroy
  * Type-safe interfaces for all DTOs
- Base URL from environment config
- JWT token from AuthService in headers
- Proper HTTP error handling with user-friendly messages

Generate:
1. log.service.ts
2. log.model.ts (interfaces)
3. log.service.spec.ts
4. HTTP interceptor for auth token
5. Error handling utility
```

### 9. Angular Dashboard with Charts

```
Create a dashboard component with visualizations:

Context:
- Angular 17+ standalone component
- Chart.js via ng2-charts
- Angular Material for layout

Requirements:
- Component: DashboardComponent
- Layout: Material grid (mat-grid-list) - responsive
- Widgets:
  * Log volume chart (line chart) - last 24 hours
  * Log level distribution (pie chart)
  * Top services by log count (bar chart)
  * Anomaly timeline (scatter plot)
  * Metrics cards (total logs, anomalies, alerts)
  * Recent alerts list (mat-list)
- Features:
  * Real-time updates (WebSocket or polling)
  * Date range selector
  * Refresh button
  * Auto-refresh toggle
  * Dark mode support
- State management: Component-level with BehaviorSubject
- Loading states for each widget
- Error handling per widget (don't break entire dashboard)

Generate:
1. dashboard.component.ts
2. dashboard.component.html
3. dashboard.component.scss
4. dashboard.service.ts
5. Chart configuration utilities
6. Responsive breakpoints
```

---

## Dockerfile Prompts

### 10. Multi-Stage Spring Boot Dockerfile

```
Create an optimized multi-stage Dockerfile for Spring Boot:

Requirements:
- Base image: Eclipse Temurin 17
- Build stage: Maven 3.9 with dependency caching
- Runtime stage: JRE-only Alpine image
- Security: Non-root user
- Health check: /actuator/health endpoint
- Optimizations:
  * Layer caching for dependencies
  * Minimal final image size (<200MB)
  * JVM tuning for containers
- Labels: version, maintainer, description
- Expose port 8080
- Environment variables for configuration

Generate complete Dockerfile with comments explaining each step.
```

### 11. Python FastAPI Dockerfile

```
Create an optimized Dockerfile for FastAPI ML service:

Requirements:
- Base image: Python 3.11-slim
- Multi-stage build to reduce size
- Install: fastapi, uvicorn, scikit-learn, pandas, numpy
- Security: Non-root user
- Health check: /health endpoint
- Optimizations:
  * Pip cache for faster builds
  * Minimal dependencies
  * Remove build tools in final image
- Working directory: /app
- Expose port 8000
- CMD: uvicorn with proper workers

Generate complete Dockerfile with best practices.
```

---

## Kubernetes Manifest Prompts

### 12. Complete K8s Deployment

```
Create Kubernetes manifests for log-ingestion service:

Requirements:
- Deployment:
  * 2 replicas
  * Rolling update strategy
  * Resource requests: 250m CPU, 512Mi memory
  * Resource limits: 500m CPU, 1Gi memory
  * Liveness probe: /actuator/health/liveness
  * Readiness probe: /actuator/health/readiness
  * Environment variables from ConfigMap and Secret
- Service:
  * ClusterIP type
  * Port 8080
  * Selector matches deployment labels
- ConfigMap:
  * Database URL
  * RabbitMQ host
  * Log level
- Secret:
  * Database password
  * RabbitMQ password
- HorizontalPodAutoscaler:
  * Min 2, max 10 replicas
  * Target CPU: 70%
  * Target memory: 80%

Generate all YAML files with proper labels and annotations.
```

---

## Testing Prompts

### 13. Spring Boot Unit Tests

```
Create comprehensive unit tests for LogIngestionService:

Context:
- JUnit 5, Mockito, Spring Boot Test
- Service has dependencies: RabbitTemplate, LogSourceRepository

Requirements:
- Test class: LogIngestionServiceTest
- Test cases:
  * shouldIngestLogSuccessfully - happy path
  * shouldEnrichLogWithMetadata - verify enrichment
  * shouldPublishToRabbitMQ - verify message sent
  * shouldRejectInvalidLevel - validation
  * shouldRejectMissingRequiredFields - validation
  * shouldHandleRabbitMQFailure - error handling
  * shouldGenerateUniqueLogId - ID generation
  * shouldAddTimestampIfMissing - timestamp handling
- Use @MockBean for dependencies
- Use ArgumentCaptor to verify message content
- Test coverage: 80%+
- Follow AAA pattern (Arrange, Act, Assert)

Generate complete test class with all test methods.
```

### 14. Integration Tests with Testcontainers

```
Create integration tests using Testcontainers:

Context:
- Spring Boot 3.2+, Testcontainers
- Test full flow: API -> RabbitMQ -> Processor -> Elasticsearch

Requirements:
- Test class: LogProcessingIntegrationTest
- Containers:
  * PostgreSQL 15
  * RabbitMQ 3
  * Elasticsearch 8
- Test scenarios:
  * End-to-end log flow
  * Bulk processing
  * Error handling and retry
  * Dead letter queue
- Use @DynamicPropertySource for container URLs
- Clean up between tests
- Verify data in Elasticsearch
- Check RabbitMQ queue states

Generate complete integration test class.
```

---

## Tips for Effective AI Code Generation

### Do's ✅
- Provide complete context (package names, dependencies, architecture)
- Specify exact requirements and constraints
- Request specific patterns (SOLID, DRY, etc.)
- Ask for tests along with implementation
- Request comments and documentation
- Specify error handling requirements

### Don'ts ❌
- Don't accept code without reviewing
- Don't skip testing AI-generated code
- Don't use without understanding
- Don't ignore security implications
- Don't forget to customize for your needs
- Don't trust complex business logic without verification

### Iteration Strategy
1. Start with simple prompt
2. Review generated code
3. Refine prompt with specific issues
4. Regenerate with improvements
5. Repeat until satisfactory

---

## Example Workflow

```bash
# 1. Generate code with AI
# Copy prompt from this document, customize, paste to AI tool

# 2. Save generated code
# Create file and paste code

# 3. Review and customize
# Read through, understand, modify as needed

# 4. Test
./mvnw test  # Spring Boot
pytest       # Python
npm test     # Angular

# 5. Iterate if needed
# Refine prompt and regenerate if issues found

# 6. Commit
git add .
git commit -m "feat: add log ingestion controller"
```

---

## Additional Resources

- [Spring Boot Best Practices](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Angular Style Guide](https://angular.dev/style-guide)
- [Effective Prompting Guide](https://www.promptingguide.ai/)

---

**Remember**: AI is a tool to accelerate development, not replace understanding. Always review, test, and understand the code you use!