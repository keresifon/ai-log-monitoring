# AI Log Monitoring System

A production-grade, microservices-based log monitoring and anomaly detection system built with Spring Boot, Python/FastAPI, and Angular.

## 🎯 Project Overview

This system provides real-time log ingestion, ML-powered anomaly detection, and intelligent alerting capabilities designed for cloud-native deployment on Kubernetes.

### Key Features

- **Real-time Log Ingestion**: REST API, file watchers, Kubernetes pod log collection
- **ML-Powered Anomaly Detection**: Isolation Forest algorithm for intelligent pattern recognition
- **Intelligent Alerting**: Multi-channel notifications (Email, Slack, Webhook)
- **Advanced Search**: Elasticsearch-powered full-text search with filters
- **Modern Dashboard**: Angular-based UI with real-time visualizations
- **Cloud-Native**: Kubernetes-ready with auto-scaling and resilience

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                       │
│                                                                   │
│  ┌──────────────┐         ┌─────────────────────────────────┐  │
│  │   Ingress    │────────▶│       API Gateway               │  │
│  │   (NGINX)    │         │    (Spring Boot)                │  │
│  └──────────────┘         └────────┬────────────────────────┘  │
│                                     │                            │
│         ┌───────────────────────────┼────────────────────┐      │
│         │                           │                    │      │
│         ▼                           ▼                    ▼      │
│  ┌─────────────┐           ┌──────────────┐    ┌──────────────┐│
│  │Log Ingestion│           │Alert Service │    │  Frontend    ││
│  │  Service    │           │(Spring Boot) │    │  (Angular)   ││
│  │(Spring Boot)│           └──────────────┘    └──────────────┘│
│  └──────┬──────┘                                                │
│         │ publish                                                │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │  RabbitMQ   │                                                │
│  └──────┬──────┘                                                │
│         │ consume                                                │
│         ▼                                                        │
│  ┌─────────────┐           ┌──────────────┐                    │
│  │Log Processor│──────────▶│  ML Service  │                    │
│  │  Service    │   REST    │  (FastAPI)   │                    │
│  │(Spring Boot)│           └──────────────┘                    │
│  └──────┬──────┘                                                │
│         │ index                                                  │
│         ▼                                                        │
│  ┌─────────────┐           ┌──────────────┐    ┌──────────────┐│
│  │Elasticsearch│           │ PostgreSQL   │    │    Redis     ││
│  └─────────────┘           └──────────────┘    └──────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop 4.25+
- Java 17 (OpenJDK or Temurin)
- Maven 3.9+
- Node.js 20+ & npm
- Python 3.11+
- kubectl

### Get Started in 3 Steps

```bash
# 1. Clone the repository
git clone https://github.com/your-username/ai-log-monitor-application.git
cd ai-log-monitor-application

# 2. Start local dependencies
docker-compose up -d

# 3. Start all services
./scripts/deploy-all-services.sh
```

## 📚 Documentation

### Getting Started
1. **Environment Setup**: Copy `.env.example` to `.env` and configure your environment variables
2. **Start Services**: Run `./scripts/deploy-all-services.sh` to start all services
3. **Access the Application**: 
   - Frontend: http://localhost:80
   - API Gateway: http://localhost:8080
   - Health Checks: http://localhost:8080/actuator/health

### Service Documentation
Each service has its own README with detailed documentation:
- `backend/api-gateway/README.md` - API Gateway service
- `backend/auth-service/README.md` - Authentication service
- `backend/log-ingestion/README.md` - Log ingestion service
- `backend/log-processor/README.md` - Log processing service
- `backend/alert-service/README.md` - Alert service
- `backend/ml-service/README.md` - ML/Anomaly detection service

## 🛠️ Technology Stack

### Backend Services
- **Spring Boot 3.2+** (Java 17) - API Gateway, Log Ingestion, Log Processor, Alert Service
- **Python 3.11 + FastAPI** - ML/Anomaly Detection Service

### Frontend
- **Angular 17+** - Modern TypeScript-based SPA
- **Angular Material** - UI component library
- **Chart.js** - Data visualization

### Data Stores
- **PostgreSQL 15** - Relational data (users, alerts, configurations)
- **Elasticsearch 8** - Log storage and search
- **Redis 7** - Caching and session management

### Infrastructure
- **RabbitMQ 3** - Message queue for async processing
- **Docker** - Containerization
- **Kubernetes** - Orchestration and deployment
- **GitHub Actions** - CI/CD pipeline

## 📅 Development Timeline

**Total Duration**: 12 weeks (MVP by Week 4)

### Phase 1: Foundation (Week 1)
- Repository setup and project structure
- Local development environment
- All services initialized

### Phase 2: MVP (Weeks 2-4) ⭐
- Log ingestion and processing
- Elasticsearch integration
- Basic frontend with search
- **Deliverable**: Working end-to-end log monitoring

### Phase 3: ML Integration (Weeks 5-6)
- Anomaly detection service
- Alert service with notifications
- ML model training and deployment

### Phase 4: Frontend (Weeks 7-8)
- Dashboard with visualizations
- Alert configuration UI
- User management

### Phase 5: Advanced Features (Weeks 9-10)
- Multiple log sources (files, K8s pods)
- Performance optimization
- Caching and scaling

### Phase 6: Production Ready (Weeks 11-12)
- Comprehensive testing (80%+ coverage)
- Complete documentation
- Kubernetes manifests
- CI/CD pipeline

**Development Timeline**: See the project structure and service READMEs for detailed implementation guides.

## 🎯 Success Metrics

### Performance
- ✅ 10,000+ logs/second throughput
- ✅ <500ms search query latency (p95)
- ✅ <2 seconds anomaly detection per log
- ✅ 99.9% uptime

### Quality
- ✅ 80%+ backend code coverage
- ✅ 70%+ frontend code coverage
- ✅ Zero critical security vulnerabilities
- ✅ Complete API documentation

## 🤝 Contributing

This is a learning project, but contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📖 Learning Resources

### Spring Boot
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Baeldung Spring Boot Tutorials](https://www.baeldung.com/spring-boot)

### Angular
- [Angular Documentation](https://angular.dev/)
- [Angular Material](https://material.angular.io/)

### Python/FastAPI
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Scikit-learn Documentation](https://scikit-learn.org/)

### Kubernetes
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Patterns](https://k8spatterns.io/)

## 🔧 Development Commands

```bash
# Start all dependencies
docker-compose up -d

# Start backend services
cd backend/log-ingestion && ./mvnw spring-boot:run
cd backend/log-processor && ./mvnw spring-boot:run
cd backend/api-gateway && ./mvnw spring-boot:run
cd backend/alert-service && ./mvnw spring-boot:run

# Start ML service
cd backend/ml-service && python -m uvicorn main:app --reload

# Start frontend
cd frontend && npm start

# Run tests
./mvnw test                    # Spring Boot
pytest                         # Python
npm test                       # Angular

# Build Docker images
docker build -t log-ingestion:latest backend/log-ingestion
docker build -t ml-service:latest backend/ml-service
docker build -t frontend:latest frontend
```

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
- Check that all required environment variables are set in `.env`
- Verify Docker is running: `docker ps`
- Check service logs: `docker-compose logs <service-name>`

**Port conflicts:**
- Ensure ports 80, 8080, 8082, 8083, 8084, 5432, 6379, 9200, 5672 are available
- Modify port mappings in `docker-compose.yml` if needed

**Database connection errors:**
- Wait for PostgreSQL to be healthy: `docker-compose ps postgres`
- Check database credentials in `.env`

**CORS errors:**
- Ensure `CORS_ALLOWED_ORIGINS` is set in `.env`
- Verify the frontend URL is included in the allowed origins list

## 📊 Project Status

**Current Phase**: Development in Progress 🚀

**Getting Started**:
1. Configure environment variables in `.env`
2. Start all services: `./scripts/deploy-all-services.sh`
3. Access the frontend at http://localhost:80
4. Check service health: `docker-compose ps`

**Progress Tracking**: See GitHub Issues and Project Board

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 👤 Author

**Your Name**
- GitHub: [@your-username](https://github.com/your-username)
- LinkedIn: [Your Profile](https://linkedin.com/in/your-profile)

## 🙏 Acknowledgments

- Spring Boot team for excellent framework
- FastAPI for modern Python web framework
- Angular team for powerful frontend framework
- Scikit-learn for ML capabilities
- Oracle Cloud for free tier infrastructure

---

**Ready to start?** 🚀

1. Configure your `.env` file with required environment variables
2. Run `./scripts/deploy-all-services.sh` to start all services
3. Access the application at http://localhost:80

For questions or issues, please open a GitHub issue or refer to the service-specific README files in each backend service directory.