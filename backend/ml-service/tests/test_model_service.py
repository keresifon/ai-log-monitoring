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
    
    @pytest.fixture
    def trained_model_service(self):
        """Create a trained ModelService instance for testing"""
        service = ModelService()
        # Create simple training data
        training_data = [
            {"message_length": 50, "level": "INFO", "service": "test", "has_exception": False, "has_timeout": False, "has_connection_error": False},
            {"message_length": 45, "level": "INFO", "service": "test", "has_exception": False, "has_timeout": False, "has_connection_error": False},
            {"message_length": 55, "level": "INFO", "service": "test", "has_exception": False, "has_timeout": False, "has_connection_error": False},
            {"message_length": 200, "level": "ERROR", "service": "test", "has_exception": True, "has_timeout": False, "has_connection_error": False},
        ]
        service.train(training_data, contamination=0.25)
        return service
    
    def test_extract_features(self, model_service):
        """Test feature extraction from log data"""
        log_data = {
            "message_length": 100,
            "level": "ERROR",
            "service": "api-service",
            "has_exception": True,
            "has_timeout": False,
            "has_connection_error": False
        }
        
        features = model_service._extract_features(log_data)
        
        assert isinstance(features, np.ndarray)
        assert features.shape == (1, 6)  # 6 features
    
    def test_predict_with_trained_model(self, trained_model_service):
        """Test prediction with a trained model"""
        log_data = {
            "message_length": 50,
            "level": "INFO",
            "service": "test-service",
            "has_exception": False,
            "has_timeout": False,
            "has_connection_error": False
        }
        
        result = trained_model_service.predict(log_data)
        
        assert "is_anomaly" in result
        assert "anomaly_score" in result
        assert "confidence" in result
        assert isinstance(result["is_anomaly"], bool)
        assert 0 <= result["anomaly_score"] <= 1
        assert 0 <= result["confidence"] <= 1
    
    def test_predict_without_training_raises_error(self, model_service):
        """Test that prediction without training raises an error"""
        log_data = {"message_length": 50, "level": "INFO", "service": "test"}
        
        with pytest.raises(ValueError, match="Model not trained"):
            model_service.predict(log_data)
    
    def test_model_version(self, model_service):
        """Test that model has a version"""
        assert model_service.model_version == "1.0.0"

# Made with Bob
