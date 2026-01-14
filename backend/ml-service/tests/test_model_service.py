"""
Unit tests for ML Model Service
"""
import pytest
import numpy as np
from app.services.model_service import ModelService


class TestModelService:
    """Test cases for ModelService"""
    
    @pytest.fixture
    def model_service(self):
        """Create a ModelService instance for testing"""
        return ModelService()
    
    def test_predict_anomaly_normal_log(self, model_service):
        """Test anomaly prediction for a normal log entry"""
        log_data = {
            "message": "Application started successfully",
            "level": "INFO",
            "service": "test-service"
        }
        
        result = model_service.predict_anomaly(log_data)
        
        assert "is_anomaly" in result
        assert "anomaly_score" in result
        assert "confidence" in result
        assert "model_version" in result
        assert isinstance(result["is_anomaly"], bool)
        assert 0 <= result["anomaly_score"] <= 1
        assert 0 <= result["confidence"] <= 1
    
    def test_predict_anomaly_error_log(self, model_service):
        """Test anomaly prediction for an error log entry"""
        log_data = {
            "message": "NullPointerException: Object reference not set",
            "level": "ERROR",
            "service": "test-service"
        }
        
        result = model_service.predict_anomaly(log_data)
        
        assert result["is_anomaly"] is True
        assert result["anomaly_score"] > 0.5
    
    def test_predict_anomaly_missing_fields(self, model_service):
        """Test anomaly prediction with missing fields"""
        log_data = {
            "message": "Test message"
        }
        
        result = model_service.predict_anomaly(log_data)
        
        assert "is_anomaly" in result
        assert "anomaly_score" in result
    
    def test_extract_features(self, model_service):
        """Test feature extraction from log data"""
        log_data = {
            "message": "Connection timeout after 30 seconds",
            "level": "ERROR",
            "service": "api-service"
        }
        
        features = model_service._extract_features(log_data)
        
        assert isinstance(features, np.ndarray)
        assert len(features) > 0
    
    def test_model_version(self, model_service):
        """Test that model version is returned"""
        log_data = {"message": "test", "level": "INFO"}
        result = model_service.predict_anomaly(log_data)
        
        assert result["model_version"] == "1.0.0"

# Made with Bob
