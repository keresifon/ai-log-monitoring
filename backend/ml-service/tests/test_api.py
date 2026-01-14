"""
Integration tests for ML Service API endpoints
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock
from main import app
from app.services.model_service import ModelService


# Create a mock model service for testing
@pytest.fixture(scope="module")
def test_client():
    """Create test client with mocked model service"""
    # Create a mock model service
    mock_model_service = Mock(spec=ModelService)
    mock_model_service.model = None  # No model loaded by default
    mock_model_service.model_version = "test-v1.0.0"
    mock_model_service.trained_at = "2024-01-01T00:00:00"
    mock_model_service.contamination = 0.1
    
    # Set it in app state
    app.state.model_service = mock_model_service
    
    # Create test client
    with TestClient(app) as client:
        yield client


class TestRootEndpoint:
    """Test cases for root endpoint"""
    
    def test_root(self, test_client):
        """Test root endpoint"""
        response = test_client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "service" in data
        assert "version" in data
        assert "status" in data


class TestHealthEndpoint:
    """Test cases for health check endpoint"""
    
    def test_health_check(self, test_client):
        """Test that health endpoint returns 200 OK"""
        response = test_client.get("/api/v1/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "UP"
        assert "service" in data
        assert data["service"] == "ml-service"
        assert "model" in data
        assert data["model"]["status"] == "not_loaded"
    
    def test_readiness_check(self, test_client):
        """Test readiness endpoint"""
        response = test_client.get("/api/v1/ready")
        
        assert response.status_code == 200
        data = response.json()
        assert "ready" in data
        assert data["ready"] is False  # Model not loaded
        assert "timestamp" in data


class TestModelInfo:
    """Test cases for model info endpoint"""
    
    def test_get_model_info(self, test_client):
        """Test getting model information"""
        response = test_client.get("/api/v1/anomaly/model/info")
        
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        # Model won't be loaded in tests, so status should be "not_loaded"
        assert data["status"] == "not_loaded"
        assert "message" in data

# Made with Bob
