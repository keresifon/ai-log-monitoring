# Security Guidelines

## Overview

This document outlines security best practices for the AI Log Monitoring System. Follow these guidelines to ensure a secure deployment.

## ⚠️ Critical Security Issues

### 1. Default Credentials

**NEVER use default credentials in production!**

The `.env` file contains default passwords that MUST be changed:
- PostgreSQL: `POSTGRES_PASSWORD=changeme`
- RabbitMQ: `RABBITMQ_PASSWORD=changeme`
- All other default passwords

### 2. Environment Variables

**Current Status:**
- ✅ docker-compose.yml uses environment variables (not hardcoded)
- ✅ .env file contains all credentials
- ⚠️ .env file should be in .gitignore
- ⚠️ Default passwords need to be changed

## Production Security Checklist

### Before Deployment

- [ ] **Change ALL default passwords** to strong, unique values
- [ ] **Add .env to .gitignore** (if not already)
- [ ] **Use secrets management** (Docker Secrets, Kubernetes Secrets, HashiCorp Vault)
- [ ] **Enable TLS/SSL** for all services
- [ ] **Configure firewall rules** to restrict access
- [ ] **Enable authentication** on all services
- [ ] **Implement network segmentation**
- [ ] **Enable audit logging**
- [ ] **Set up monitoring and alerting**
- [ ] **Perform security scanning** (vulnerability assessment)

### Database Security (PostgreSQL)

```bash
# Generate strong password
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Update .env file
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env

# Enable SSL connections (production)
# Add to docker-compose.yml:
# command: postgres -c ssl=on -c ssl_cert_file=/etc/ssl/certs/server.crt
```

**Best Practices:**
- Use strong passwords (32+ characters, random)
- Enable SSL/TLS connections
- Restrict network access (use internal networks)
- Regular backups with encryption
- Implement role-based access control (RBAC)
- Enable audit logging
- Regular security updates

### Redis Security

```bash
# Enable password authentication
REDIS_PASSWORD=$(openssl rand -base64 32)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env

# Update docker-compose.yml to use password
# command: redis-server --requirepass ${REDIS_PASSWORD}
```

**Best Practices:**
- Always use password authentication
- Disable dangerous commands (CONFIG, FLUSHALL)
- Use TLS for connections
- Bind to internal network only
- Regular backups

### Elasticsearch Security

```bash
# Enable security features
ES_SECURITY_ENABLED=true

# Set passwords for built-in users
# elastic, kibana_system, etc.
```

**Best Practices:**
- Enable X-Pack security
- Use TLS for HTTP and transport
- Implement role-based access control
- Enable audit logging
- Regular security updates
- Encrypt data at rest

### RabbitMQ Security

```bash
# Change default credentials
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=$(openssl rand -base64 32)
```

**Best Practices:**
- Change default credentials
- Enable TLS for connections
- Implement virtual hosts for isolation
- Use access control lists (ACLs)
- Enable management plugin with authentication
- Regular security updates

### Application Security

#### SMTP Credentials
```bash
# Never commit SMTP credentials
SMTP_USERNAME=your-email@example.com
SMTP_PASSWORD=your-app-specific-password
```

#### API Security
- Implement authentication (JWT, OAuth2)
- Use HTTPS only
- Implement rate limiting
- Validate all inputs
- Sanitize outputs
- Use CORS properly
- Implement CSRF protection

#### Secrets Management

**Development:**
```bash
# Use .env file (never commit)
cp .env.example .env
# Edit .env with your values
```

**Production (Docker Swarm):**
```bash
# Create secrets
echo "strong-password" | docker secret create postgres_password -
echo "strong-password" | docker secret create rabbitmq_password -

# Use in docker-compose.yml:
secrets:
  postgres_password:
    external: true
```

**Production (Kubernetes):**
```bash
# Create secrets
kubectl create secret generic postgres-credentials \
  --from-literal=password='strong-password'

# Use in deployment:
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-credentials
        key: password
```

## Network Security

### Docker Network Isolation

```yaml
# Separate networks for different tiers
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
  database:
    driver: bridge
    internal: true  # No external access
```

### Firewall Rules

```bash
# Allow only necessary ports
# PostgreSQL: 5432 (internal only)
# Redis: 6379 (internal only)
# Elasticsearch: 9200 (internal only)
# RabbitMQ: 5672, 15672 (internal only)
# ML Service: 8000 (internal only)
# Alert Service: 8083 (internal only)
# API Gateway: 8080 (external, with authentication)
```

## Monitoring and Auditing

### Enable Audit Logging

```yaml
# PostgreSQL
command: postgres -c log_statement=all -c log_connections=on

# Elasticsearch
xpack.security.audit.enabled: true

# Application logs
LOG_LEVEL=INFO
AUDIT_ENABLED=true
```

### Security Monitoring

- Monitor failed login attempts
- Track privilege escalation
- Alert on suspicious activities
- Regular security audits
- Vulnerability scanning
- Penetration testing

## Incident Response

### In Case of Security Breach

1. **Immediate Actions:**
   - Isolate affected systems
   - Rotate all credentials
   - Review audit logs
   - Assess damage

2. **Investigation:**
   - Identify attack vector
   - Determine scope of breach
   - Document findings

3. **Remediation:**
   - Patch vulnerabilities
   - Update security controls
   - Restore from clean backups

4. **Post-Incident:**
   - Update security policies
   - Conduct lessons learned
   - Improve monitoring

## Compliance

### Data Protection
- Encrypt data at rest
- Encrypt data in transit
- Implement data retention policies
- Regular data backups
- Secure data disposal

### Access Control
- Principle of least privilege
- Regular access reviews
- Multi-factor authentication (MFA)
- Strong password policies
- Session management

## Security Updates

### Regular Maintenance
```bash
# Update Docker images
docker-compose pull

# Update dependencies
cd backend/alert-service && mvn versions:display-dependency-updates
cd backend/ml-service && pip list --outdated

# Security scanning
docker scan ai-monitoring-alert-service
trivy image ai-monitoring-alert-service
```

### Vulnerability Management
- Subscribe to security advisories
- Regular dependency updates
- Automated vulnerability scanning
- Patch management process

## Contact

For security issues, please contact:
- Security Team: security@example.com
- Emergency: +1-XXX-XXX-XXXX

**DO NOT** disclose security vulnerabilities publicly.

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

---

**Last Updated:** 2026-01-09
**Version:** 1.0