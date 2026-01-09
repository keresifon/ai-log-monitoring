-- Alert Service Database Schema
-- Creates tables for alert_service schema

-- Create alert_service schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS alert_service;

-- Set search path
SET search_path TO alert_service;

-- ============================================================================
-- Table: alert_rules
-- Stores alert rule definitions
-- ============================================================================
CREATE TABLE IF NOT EXISTS alert_rules (
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
    services VARCHAR(500),
    log_levels VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(100),
    last_triggered_at TIMESTAMP,
    trigger_count BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_type CHECK (type IN ('ANOMALY_DETECTION', 'THRESHOLD', 'PATTERN_MATCH', 'ERROR_RATE', 'CUSTOM')),
    CONSTRAINT chk_severity CHECK (severity IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- Indexes for alert_rules
CREATE INDEX IF NOT EXISTS idx_alert_rules_type ON alert_rules(type);
CREATE INDEX IF NOT EXISTS idx_alert_rules_enabled ON alert_rules(enabled);
CREATE INDEX IF NOT EXISTS idx_alert_rules_type_enabled ON alert_rules(type, enabled);

-- ============================================================================
-- Table: notification_channels
-- Stores notification channel configurations
-- ============================================================================
CREATE TABLE IF NOT EXISTS notification_channels (
    id BIGSERIAL PRIMARY KEY,
    alert_rule_id BIGINT NOT NULL,
    type VARCHAR(20) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    config JSONB NOT NULL,
    recipients VARCHAR(500),
    slack_channel VARCHAR(200),
    webhook_url VARCHAR(500),
    webhook_method VARCHAR(10),
    webhook_headers JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    last_used_at TIMESTAMP,
    success_count BIGINT NOT NULL DEFAULT 0,
    failure_count BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_notification_channel_rule FOREIGN KEY (alert_rule_id) 
        REFERENCES alert_rules(id) ON DELETE CASCADE,
    CONSTRAINT chk_channel_type CHECK (type IN ('EMAIL', 'SLACK', 'WEBHOOK'))
);

-- Indexes for notification_channels
CREATE INDEX IF NOT EXISTS idx_notification_channels_rule ON notification_channels(alert_rule_id);
CREATE INDEX IF NOT EXISTS idx_notification_channels_type ON notification_channels(type);
CREATE INDEX IF NOT EXISTS idx_notification_channels_enabled ON notification_channels(enabled);

-- ============================================================================
-- Table: alerts
-- Stores alert instances
-- ============================================================================
CREATE TABLE IF NOT EXISTS alerts (
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
    CONSTRAINT fk_alert_rule FOREIGN KEY (alert_rule_id) 
        REFERENCES alert_rules(id) ON DELETE CASCADE,
    CONSTRAINT chk_alert_status CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'FALSE_POSITIVE')),
    CONSTRAINT chk_alert_severity CHECK (severity IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- Indexes for alerts
CREATE INDEX IF NOT EXISTS idx_alerts_rule ON alerts(alert_rule_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at);
CREATE INDEX IF NOT EXISTS idx_alerts_anomaly_id ON alerts(anomaly_detection_id);
CREATE INDEX IF NOT EXISTS idx_alerts_service ON alerts(service);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_notification_sent ON alerts(notification_sent);

-- ============================================================================
-- Insert Sample Data (Optional - for testing)
-- ============================================================================

-- Sample Alert Rule: High Confidence Anomaly Detection
INSERT INTO alert_rules (name, description, type, severity, enabled, anomaly_threshold, services)
VALUES (
    'High Confidence Anomaly Alert',
    'Triggers when ML service detects anomalies with confidence > 80%',
    'ANOMALY_DETECTION',
    'HIGH',
    true,
    0.8,
    NULL
) ON CONFLICT (name) DO NOTHING;

-- Sample Alert Rule: Critical Anomaly Detection
INSERT INTO alert_rules (name, description, type, severity, enabled, anomaly_threshold, services)
VALUES (
    'Critical Anomaly Alert',
    'Triggers when ML service detects critical anomalies with confidence > 90%',
    'ANOMALY_DETECTION',
    'CRITICAL',
    true,
    0.9,
    NULL
) ON CONFLICT (name) DO NOTHING;

-- Sample Alert Rule: Service-Specific Anomaly
INSERT INTO alert_rules (name, description, type, severity, enabled, anomaly_threshold, services)
VALUES (
    'Payment Service Anomaly',
    'Monitors anomalies specifically in payment-service',
    'ANOMALY_DETECTION',
    'HIGH',
    true,
    0.7,
    'payment-service'
) ON CONFLICT (name) DO NOTHING;

-- Sample Notification Channel: Email for High Confidence Rule
INSERT INTO notification_channels (alert_rule_id, type, enabled, config, recipients)
SELECT 
    id,
    'EMAIL',
    true,
    '{"template": "default"}',
    'admin@example.com,ops@example.com'
FROM alert_rules 
WHERE name = 'High Confidence Anomaly Alert'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Grants (adjust as needed for your security requirements)
-- ============================================================================

-- Grant permissions to admin user
GRANT ALL PRIVILEGES ON SCHEMA alert_service TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA alert_service TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA alert_service TO admin;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON SCHEMA alert_service IS 'Alert Service schema for AI Log Monitoring System';
COMMENT ON TABLE alert_rules IS 'Alert rule definitions with conditions and thresholds';
COMMENT ON TABLE notification_channels IS 'Notification channel configurations (Email, Slack, Webhook)';
COMMENT ON TABLE alerts IS 'Alert instances with complete lifecycle tracking';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Verify tables were created
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'alert_service'
ORDER BY tablename;

-- Verify sample data
SELECT 
    'alert_rules' as table_name,
    COUNT(*) as row_count
FROM alert_rules
UNION ALL
SELECT 
    'notification_channels',
    COUNT(*)
FROM notification_channels
UNION ALL
SELECT 
    'alerts',
    COUNT(*)
FROM alerts;

-- Display sample alert rules
SELECT 
    id,
    name,
    type,
    severity,
    enabled,
    anomaly_threshold
FROM alert_rules
ORDER BY id;

COMMIT;

-- Made with Bob
