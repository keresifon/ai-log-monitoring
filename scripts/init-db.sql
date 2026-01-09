-- AI Log Monitoring System - Database Initialization Script
-- This script creates all necessary schemas and tables

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth_service;
CREATE SCHEMA IF NOT EXISTS log_service;
CREATE SCHEMA IF NOT EXISTS alert_service;
CREATE SCHEMA IF NOT EXISTS ml_service;

-- ============================================================================
-- AUTH SERVICE SCHEMA
-- ============================================================================

-- Users table
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

-- Roles table
CREATE TABLE auth_service.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- User roles mapping
CREATE TABLE auth_service.user_roles (
    user_id BIGINT REFERENCES auth_service.users(id) ON DELETE CASCADE,
    role_id INT REFERENCES auth_service.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- API tokens
CREATE TABLE auth_service.api_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES auth_service.users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);

-- Insert default roles
INSERT INTO auth_service.roles (name, description) VALUES
    ('ADMIN', 'Full system access'),
    ('USER', 'Standard user access'),
    ('VIEWER', 'Read-only access');

-- Insert default admin user (password: admin123)
-- Password hash generated with BCrypt
INSERT INTO auth_service.users (username, email, password_hash, full_name) VALUES
    ('admin', 'admin@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'System Administrator');

-- Assign admin role to default user
INSERT INTO auth_service.user_roles (user_id, role_id) VALUES (1, 1);

-- ============================================================================
-- LOG SERVICE SCHEMA
-- ============================================================================

-- Log sources
CREATE TABLE log_service.log_sources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('api', 'file', 'k8s_pod', 'syslog')),
    configuration JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Log ingestion metrics
CREATE TABLE log_service.ingestion_metrics (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT REFERENCES log_service.log_sources(id),
    timestamp TIMESTAMP NOT NULL,
    logs_received INT DEFAULT 0,
    logs_processed INT DEFAULT 0,
    logs_failed INT DEFAULT 0,
    avg_processing_time_ms DECIMAL(10,2)
);

-- Create indexes for performance
CREATE INDEX idx_ingestion_metrics_timestamp ON log_service.ingestion_metrics(timestamp DESC);
CREATE INDEX idx_ingestion_metrics_source ON log_service.ingestion_metrics(source_id);

-- Insert default API log source
INSERT INTO log_service.log_sources (name, type, configuration, is_active) VALUES
    ('API Ingestion', 'api', '{"endpoint": "/api/v1/logs"}', true);

-- ============================================================================
-- ALERT SERVICE SCHEMA
-- ============================================================================

-- Alert rules
CREATE TABLE alert_service.alert_rules (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    type VARCHAR(20) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    conditions JSONB,
    anomaly_threshold DOUBLE PRECISION,
    time_window_minutes INTEGER,
    threshold_count INTEGER,
    threshold INTEGER,
    services VARCHAR(500),
    service_name VARCHAR(100),
    log_levels VARCHAR(100),
    log_level VARCHAR(20),
    cooldown_minutes INTEGER DEFAULT 15,
    notify_on_recovery BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(100),
    last_triggered_at TIMESTAMP,
    trigger_count BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_type CHECK (type IN ('ANOMALY_DETECTION', 'THRESHOLD', 'PATTERN_MATCH', 'ERROR_RATE', 'CUSTOM')),
    CONSTRAINT chk_severity CHECK (severity IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- Notification channels
CREATE TABLE alert_service.notification_channels (
    id BIGSERIAL PRIMARY KEY,
    alert_rule_id BIGINT,
    type VARCHAR(20) NOT NULL,
    name VARCHAR(100),
    description VARCHAR(500),
    enabled BOOLEAN NOT NULL DEFAULT true,
    config JSONB NOT NULL,
    configuration JSONB,
    recipients VARCHAR(500),
    slack_channel VARCHAR(200),
    webhook_url VARCHAR(500),
    webhook_method VARCHAR(10),
    webhook_headers JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    last_used_at TIMESTAMP,
    last_success_at TIMESTAMP,
    last_failure_at TIMESTAMP,
    success_count BIGINT NOT NULL DEFAULT 0,
    failure_count BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_notification_channel_rule FOREIGN KEY (alert_rule_id) REFERENCES alert_service.alert_rules(id) ON DELETE CASCADE,
    CONSTRAINT chk_channel_type CHECK (type IN ('EMAIL', 'SLACK', 'WEBHOOK'))
);

-- Alert history
CREATE TABLE alert_service.alerts (
    id BIGSERIAL PRIMARY KEY,
    alert_rule_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    anomaly_detection_id VARCHAR(255),
    log_id VARCHAR(255),
    service VARCHAR(100),
    context JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    acknowledged_at TIMESTAMP,
    acknowledged_by VARCHAR(100),
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    notification_sent BOOLEAN NOT NULL DEFAULT false,
    notification_sent_at TIMESTAMP,
    notification_failure_count INTEGER NOT NULL DEFAULT 0,
    last_notification_error TEXT,
    CONSTRAINT fk_alert_rule FOREIGN KEY (alert_rule_id) REFERENCES alert_service.alert_rules(id) ON DELETE CASCADE,
    CONSTRAINT chk_alert_status CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'FALSE_POSITIVE')),
    CONSTRAINT chk_alert_severity CHECK (severity IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- Create indexes for performance
CREATE INDEX idx_alert_rules_enabled ON alert_service.alert_rules(enabled);
CREATE INDEX idx_alert_rules_type ON alert_service.alert_rules(type);
CREATE INDEX idx_alert_rules_severity ON alert_service.alert_rules(severity);
CREATE INDEX idx_alerts_rule ON alert_service.alerts(alert_rule_id);
CREATE INDEX idx_alerts_status ON alert_service.alerts(status);
CREATE INDEX idx_alerts_created_at ON alert_service.alerts(created_at);
CREATE INDEX idx_alerts_anomaly_id ON alert_service.alerts(anomaly_detection_id);
CREATE INDEX idx_alerts_service ON alert_service.alerts(service);
CREATE INDEX idx_alerts_severity ON alert_service.alerts(severity);
CREATE INDEX idx_alerts_notification_sent ON alert_service.alerts(notification_sent);
CREATE INDEX idx_notification_channels_rule ON alert_service.notification_channels(alert_rule_id);
CREATE INDEX idx_notification_channels_type ON alert_service.notification_channels(type);
CREATE INDEX idx_notification_channels_enabled ON alert_service.notification_channels(enabled);

-- ============================================================================
-- ML SERVICE SCHEMA
-- ============================================================================

-- ML models
CREATE TABLE ml_service.ml_models (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    model_type VARCHAR(50) NOT NULL CHECK (model_type IN ('isolation_forest', 'lstm', 'autoencoder')),
    model_path VARCHAR(255) NOT NULL,
    metrics JSONB,
    is_active BOOLEAN DEFAULT false,
    trained_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name, version)
);

-- Anomaly detections
CREATE TABLE ml_service.anomaly_detections (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT REFERENCES ml_service.ml_models(id),
    log_id VARCHAR(255) NOT NULL,
    anomaly_score DOUBLE PRECISION NOT NULL,
    is_anomaly BOOLEAN NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    model_version VARCHAR(50),
    features JSONB,
    detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    level VARCHAR(20),
    message TEXT,
    service VARCHAR(100),
    log_timestamp TIMESTAMP
);

-- Model training history
CREATE TABLE ml_service.training_history (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT REFERENCES ml_service.ml_models(id),
    training_data_size INT NOT NULL,
    training_duration_seconds INT,
    metrics JSONB,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('running', 'completed', 'failed'))
);

-- Create indexes for performance
CREATE INDEX idx_anomaly_detections_detected_at ON ml_service.anomaly_detections(detected_at DESC);
CREATE INDEX idx_anomaly_detections_is_anomaly ON ml_service.anomaly_detections(is_anomaly);
CREATE INDEX idx_anomaly_detections_log_id ON ml_service.anomaly_detections(log_id);
CREATE INDEX idx_anomaly_detections_model_id ON ml_service.anomaly_detections(model_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON auth_service.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_log_sources_updated_at BEFORE UPDATE ON log_service.log_sources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alert_rules_updated_at BEFORE UPDATE ON alert_service.alert_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- View for active alerts summary
CREATE OR REPLACE VIEW alert_service.active_alerts_summary AS
SELECT
    severity,
    COUNT(*) as count,
    MIN(created_at) as oldest_alert,
    MAX(created_at) as newest_alert
FROM alert_service.alerts
WHERE status = 'OPEN'
GROUP BY severity;

-- View for anomaly detection summary
CREATE OR REPLACE VIEW ml_service.anomaly_summary AS
SELECT 
    DATE(detected_at) as detection_date,
    COUNT(*) as total_detections,
    SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) as anomaly_count,
    AVG(anomaly_score) as avg_anomaly_score
FROM ml_service.anomaly_detections
GROUP BY DATE(detected_at)
ORDER BY detection_date DESC;

-- ============================================================================
-- GRANTS (for application users)
-- ============================================================================

-- Note: In production, create separate users for each service with limited permissions
-- For development, the admin user has full access

-- Grant usage on schemas
GRANT USAGE ON SCHEMA auth_service TO admin;
GRANT USAGE ON SCHEMA log_service TO admin;
GRANT USAGE ON SCHEMA alert_service TO admin;
GRANT USAGE ON SCHEMA ml_service TO admin;

-- Grant all privileges on all tables (development only)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth_service TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA log_service TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA alert_service TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ml_service TO admin;

-- Grant all privileges on all sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth_service TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA log_service TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA alert_service TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ml_service TO admin;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'AI Log Monitoring System - Database Initialization Complete';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Schemas created: auth_service, log_service, alert_service, ml_service';
    RAISE NOTICE 'Default admin user: admin / admin123';
    RAISE NOTICE 'Database is ready for application services';
    RAISE NOTICE '=================================================================';
END $$;

-- Made with Bob
