"""
Integration tests for ML Service API endpoints
"""
import pytest
from fastapi.testclient import TestClient
from main import app


client = TestClient(app)


class TestHealthEndpoint:
    """Test cases for health check endpoint"""
    
    def test_health_check(self):
        """Test that health endpoint returns 200 OK"""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "service" in data
        assert data["service"] == "ml-service"


class TestAnomalyEndpoint:
    """Test cases for anomaly detection endpoint"""
    
    def test_predict_anomaly_success(self):
        """Test successful anomaly prediction"""
        log_data = {
            "log_id": "test-123",
            "message": "Application started successfully",
            "level": "INFO",
            "service": "test-service",
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        response = client.post("/api/v1/anomaly/predict", json=log_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "log_id" in data
        assert "is_anomaly" in data
        assert "anomaly_score" in data
        assert "confidence" in data
        assert "model_version" in data
        assert data["log_id"] == "test-123"
    
    def test_predict_anomaly_error_log(self):
        """Test anomaly prediction for error log"""
        log_data = {
            "log_id": "test-456",
            "message": "NullPointerException occurred",
            "level": "ERROR",
            "service": "test-service"
        }
        
        response = client.post("/api/v1/anomaly/predict", json=log_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_anomaly"] is True
    
    def test_predict_anomaly_missing_required_fields(self):
        """Test anomaly prediction with missing required fields"""
        log_data = {
            "message": "Test message"
        }
        
        response = client.post("/api/v1/anomaly/predict", json=log_data)
        
        # Should still work with default values
        assert response.status_code in [200, 422]
    
    def test_predict_anomaly_invalid_json(self):
        """Test anomaly prediction with invalid JSON"""
        response = client.post(
            "/api/v1/anomaly/predict",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status_code == 422

# Made with Bob
