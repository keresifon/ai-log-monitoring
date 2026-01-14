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
        assert data["status"] == "UP"
        assert "service" in data
        assert data["service"] == "ml-service"
    
    def test_readiness_check(self):
        """Test readiness endpoint"""
        response = client.get("/ready")
        
        assert response.status_code == 200
        data = response.json()
        assert "ready" in data
        assert "timestamp" in data


class TestModelInfo:
    """Test cases for model info endpoint"""
    
    def test_get_model_info(self):
        """Test getting model information"""
        response = client.get("/api/v1/anomaly/model/info")
        
        assert response.status_code == 200
        data = response.json()
        assert "status" in data

# Made with Bob
