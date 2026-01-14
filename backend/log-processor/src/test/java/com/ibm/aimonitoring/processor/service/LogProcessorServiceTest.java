package com.ibm.aimonitoring.processor.service;

import com.ibm.aimonitoring.processor.dto.LogEntryDTO;
import com.ibm.aimonitoring.processor.dto.MLPredictionRequest;
import com.ibm.aimonitoring.processor.dto.MLPredictionResponse;
import com.ibm.aimonitoring.processor.model.AnomalyDetection;
import com.ibm.aimonitoring.processor.repository.AnomalyDetectionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for LogProcessorService
 */
@ExtendWith(MockitoExtension.class)
class LogProcessorServiceTest {

    @Mock
    private ElasticsearchService elasticsearchService;

    @Mock
    private MLServiceClient mlServiceClient;

    @Mock
    private AnomalyDetectionRepository anomalyDetectionRepository;

    @InjectMocks
    private LogProcessorService logProcessorService;

    private LogEntryDTO testLogEntry;
    private Map<String, Object> testMetadata;

    @BeforeEach
    void setUp() {
        testMetadata = new HashMap<>();
        testMetadata.put("userId", "user123");
        testMetadata.put("requestId", "req-456");

        testLogEntry = LogEntryDTO.builder()
                .id("log-123")
                .timestamp(Instant.now())
                .level("ERROR")
                .message("Database connection timeout occurred")
                .service("test-service")
                .host("localhost")
                .environment("production")
                .metadata(testMetadata)
                .build();
    }

    @Test
    void shouldProcessLogSuccessfully() {
        // Arrange
        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-123")
                .isAnomaly(false)
                .anomalyScore(0.3)
                .confidence(0.85)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(testLogEntry);

        // Assert
        verify(elasticsearchService, times(1)).indexLog(eq("log-123"), anyMap());
        verify(mlServiceClient, times(1)).predictAnomaly(any(MLPredictionRequest.class));
        verify(anomalyDetectionRepository, never()).save(any(AnomalyDetection.class));
    }

    @Test
    void shouldDetectAnomalyAndSaveToDatabase() {
        // Arrange
        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-123")
                .isAnomaly(true)
                .anomalyScore(0.95)
                .confidence(0.92)
                .modelVersion("v1.0.0")
                .build();

        AnomalyDetection savedAnomaly = AnomalyDetection.builder()
                .id("anomaly-789")
                .logId("log-123")
                .service("test-service")
                .anomalyScore(0.95)
                .confidence(0.92)
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        when(anomalyDetectionRepository.save(any(AnomalyDetection.class))).thenReturn(savedAnomaly);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(testLogEntry);

        // Assert
        verify(elasticsearchService, times(1)).indexLog(eq("log-123"), anyMap());
        verify(mlServiceClient, times(1)).predictAnomaly(any(MLPredictionRequest.class));
        verify(anomalyDetectionRepository, times(1)).save(any(AnomalyDetection.class));
    }

    @Test
    void shouldExtractFeaturesCorrectly() {
        // Arrange
        LogEntryDTO logWithException = LogEntryDTO.builder()
                .id("log-456")
                .timestamp(Instant.now())
                .level("ERROR")
                .message("NullPointerException: Cannot invoke method on null object")
                .service("test-service")
                .host("localhost")
                .build();

        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-456")
                .isAnomaly(false)
                .anomalyScore(0.4)
                .confidence(0.8)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(logWithException);

        // Assert
        verify(mlServiceClient, times(1)).predictAnomaly(argThat(request -> {
            Map<String, Object> features = request.getFeatures();
            return features.get("has_exception").equals(true) &&
                   features.get("message_length").equals(logWithException.getMessage().length()) &&
                   features.get("level").equals("ERROR");
        }));
    }

    @Test
    void shouldDetectTimeoutInMessage() {
        // Arrange
        LogEntryDTO logWithTimeout = LogEntryDTO.builder()
                .id("log-789")
                .timestamp(Instant.now())
                .level("WARN")
                .message("Request timeout after 30 seconds")
                .service("test-service")
                .host("localhost")
                .build();

        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-789")
                .isAnomaly(false)
                .anomalyScore(0.5)
                .confidence(0.75)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(logWithTimeout);

        // Assert
        verify(mlServiceClient, times(1)).predictAnomaly(argThat(request -> {
            Map<String, Object> features = request.getFeatures();
            return features.get("has_timeout").equals(true);
        }));
    }

    @Test
    void shouldDetectConnectionErrorInMessage() {
        // Arrange
        LogEntryDTO logWithConnectionError = LogEntryDTO.builder()
                .id("log-101")
                .timestamp(Instant.now())
                .level("ERROR")
                .message("Connection refused to database server")
                .service("test-service")
                .host("localhost")
                .build();

        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-101")
                .isAnomaly(false)
                .anomalyScore(0.6)
                .confidence(0.8)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(logWithConnectionError);

        // Assert
        verify(mlServiceClient, times(1)).predictAnomaly(argThat(request -> {
            Map<String, Object> features = request.getFeatures();
            return features.get("has_connection_error").equals(true);
        }));
    }

    @Test
    void shouldHandleMLServiceFailureGracefully() {
        // Arrange
        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class)))
                .thenThrow(new RuntimeException("ML Service unavailable"));
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act & Assert - should not throw exception
        assertDoesNotThrow(() -> logProcessorService.processLog(testLogEntry));

        // Verify log was still indexed even though ML prediction failed
        verify(elasticsearchService, times(1)).indexLog(eq("log-123"), anyMap());
        verify(anomalyDetectionRepository, never()).save(any(AnomalyDetection.class));
    }

    @Test
    void shouldHandleElasticsearchFailureGracefully() {
        // Arrange
        doThrow(new RuntimeException("Elasticsearch unavailable"))
                .when(elasticsearchService).indexLog(anyString(), anyMap());

        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-123")
                .isAnomaly(false)
                .anomalyScore(0.3)
                .confidence(0.85)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);

        // Act & Assert - should not throw exception
        assertDoesNotThrow(() -> logProcessorService.processLog(testLogEntry));

        // Verify ML prediction was still attempted
        verify(mlServiceClient, times(1)).predictAnomaly(any(MLPredictionRequest.class));
    }

    @Test
    void shouldIncludeMetadataInIndexedLog() {
        // Arrange
        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-123")
                .isAnomaly(false)
                .anomalyScore(0.3)
                .confidence(0.85)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(testLogEntry);

        // Assert
        verify(elasticsearchService, times(1)).indexLog(eq("log-123"), argThat(logData -> {
            Map<String, Object> metadata = (Map<String, Object>) logData.get("metadata");
            return metadata != null &&
                   metadata.get("userId").equals("user123") &&
                   metadata.get("requestId").equals("req-456");
        }));
    }

    @Test
    void shouldSetDefaultEnvironmentWhenMissing() {
        // Arrange
        LogEntryDTO logWithoutEnv = LogEntryDTO.builder()
                .id("log-202")
                .timestamp(Instant.now())
                .level("INFO")
                .message("Test message")
                .service("test-service")
                .host("localhost")
                .build();

        MLPredictionResponse mlResponse = MLPredictionResponse.builder()
                .logId("log-202")
                .isAnomaly(false)
                .anomalyScore(0.2)
                .confidence(0.9)
                .modelVersion("v1.0.0")
                .build();

        when(mlServiceClient.predictAnomaly(any(MLPredictionRequest.class))).thenReturn(mlResponse);
        doNothing().when(elasticsearchService).indexLog(anyString(), anyMap());

        // Act
        logProcessorService.processLog(logWithoutEnv);

        // Assert
        verify(elasticsearchService, times(1)).indexLog(eq("log-202"), argThat(logData ->
                logData.get("environment").equals("unknown")
        ));
    }
}

// Made with Bob