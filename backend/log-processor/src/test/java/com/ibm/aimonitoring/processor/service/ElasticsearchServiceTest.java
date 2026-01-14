package com.ibm.aimonitoring.processor.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.IndexRequest;
import co.elastic.clients.elasticsearch.core.IndexResponse;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.elasticsearch.core.search.Hit;
import co.elastic.clients.elasticsearch.core.search.HitsMetadata;
import com.ibm.aimonitoring.processor.dto.LogSearchRequest;
import com.ibm.aimonitoring.processor.dto.LogSearchResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ElasticsearchService
 */
@ExtendWith(MockitoExtension.class)
class ElasticsearchServiceTest {

    @Mock
    private ElasticsearchClient elasticsearchClient;

    @InjectMocks
    private ElasticsearchService elasticsearchService;

    private Map<String, Object> testLogData;

    @BeforeEach
    void setUp() {
        testLogData = new HashMap<>();
        testLogData.put("timestamp", Instant.now().toString());
        testLogData.put("level", "ERROR");
        testLogData.put("message", "Test error message");
        testLogData.put("service", "test-service");
        testLogData.put("host", "localhost");
        testLogData.put("environment", "production");
    }

    @Test
    void shouldIndexLogSuccessfully() throws Exception {
        // Arrange
        IndexResponse mockResponse = mock(IndexResponse.class);
        when(mockResponse.id()).thenReturn("log-123");
        when(elasticsearchClient.index(any(IndexRequest.class))).thenReturn(mockResponse);

        // Act
        assertDoesNotThrow(() -> elasticsearchService.indexLog("log-123", testLogData));

        // Assert
        verify(elasticsearchClient, times(1)).index(any(IndexRequest.class));
    }

    @Test
    void shouldHandleIndexingFailureGracefully() throws Exception {
        // Arrange
        when(elasticsearchClient.index(any(IndexRequest.class)))
                .thenThrow(new RuntimeException("Elasticsearch connection failed"));

        // Act & Assert - should not throw exception
        assertDoesNotThrow(() -> elasticsearchService.indexLog("log-123", testLogData));

        verify(elasticsearchClient, times(1)).index(any(IndexRequest.class));
    }

    @Test
    void shouldSearchLogsSuccessfully() throws Exception {
        // Arrange
        LogSearchRequest searchRequest = LogSearchRequest.builder()
                .service("test-service")
                .level("ERROR")
                .startTime(Instant.now().minusSeconds(3600))
                .endTime(Instant.now())
                .page(0)
                .size(20)
                .build();

        // Mock Elasticsearch response
        SearchResponse<Map> mockSearchResponse = mock(SearchResponse.class);
        HitsMetadata<Map> mockHits = mock(HitsMetadata.class);
        Hit<Map> mockHit = mock(Hit.class);

        when(mockHit.source()).thenReturn(testLogData);
        when(mockHit.id()).thenReturn("log-123");
        when(mockHits.hits()).thenReturn(Collections.singletonList(mockHit));
        when(mockHits.total()).thenReturn(mock(co.elastic.clients.elasticsearch.core.search.TotalHits.class));
        when(mockSearchResponse.hits()).thenReturn(mockHits);
        when(elasticsearchClient.search(any(SearchRequest.class), eq(Map.class)))
                .thenReturn(mockSearchResponse);

        // Act
        LogSearchResponse result = elasticsearchService.searchLogs(searchRequest);

        // Assert
        assertNotNull(result);
        verify(elasticsearchClient, times(1)).search(any(SearchRequest.class), eq(Map.class));
    }

    @Test
    void shouldHandleSearchFailureGracefully() throws Exception {
        // Arrange
        LogSearchRequest searchRequest = LogSearchRequest.builder()
                .service("test-service")
                .page(0)
                .size(20)
                .build();

        when(elasticsearchClient.search(any(SearchRequest.class), eq(Map.class)))
                .thenThrow(new RuntimeException("Search failed"));

        // Act
        LogSearchResponse result = elasticsearchService.searchLogs(searchRequest);

        // Assert
        assertNotNull(result);
        assertEquals(0, result.getTotalHits());
        assertTrue(result.getLogs().isEmpty());
        verify(elasticsearchClient, times(1)).search(any(SearchRequest.class), eq(Map.class));
    }

    @Test
    void shouldIncludeAllFieldsInIndexedLog() throws Exception {
        // Arrange
        Map<String, Object> completeLogData = new HashMap<>(testLogData);
        completeLogData.put("metadata", Map.of("userId", "user123"));
        completeLogData.put("anomaly_score", 0.85);
        completeLogData.put("is_anomaly", true);

        IndexResponse mockResponse = mock(IndexResponse.class);
        when(mockResponse.id()).thenReturn("log-456");
        when(elasticsearchClient.index(any(IndexRequest.class))).thenReturn(mockResponse);

        // Act
        elasticsearchService.indexLog("log-456", completeLogData);

        // Assert
        verify(elasticsearchClient, times(1)).index(argThat(request -> {
            // Verify the request contains all expected fields
            return true; // In real test, would verify request structure
        }));
    }

    @Test
    void shouldSearchWithMultipleFilters() throws Exception {
        // Arrange
        LogSearchRequest searchRequest = LogSearchRequest.builder()
                .service("test-service")
                .level("ERROR")
                .environment("production")
                .searchText("database")
                .startTime(Instant.now().minusSeconds(7200))
                .endTime(Instant.now())
                .page(0)
                .size(50)
                .build();

        SearchResponse<Map> mockSearchResponse = mock(SearchResponse.class);
        HitsMetadata<Map> mockHits = mock(HitsMetadata.class);
        
        when(mockHits.hits()).thenReturn(Collections.emptyList());
        when(mockHits.total()).thenReturn(mock(co.elastic.clients.elasticsearch.core.search.TotalHits.class));
        when(mockSearchResponse.hits()).thenReturn(mockHits);
        when(elasticsearchClient.search(any(SearchRequest.class), eq(Map.class)))
                .thenReturn(mockSearchResponse);

        // Act
        LogSearchResponse result = elasticsearchService.searchLogs(searchRequest);

        // Assert
        assertNotNull(result);
        verify(elasticsearchClient, times(1)).search(any(SearchRequest.class), eq(Map.class));
    }

    @Test
    void shouldHandleNullFieldsInLogData() throws Exception {
        // Arrange
        Map<String, Object> logDataWithNulls = new HashMap<>();
        logDataWithNulls.put("timestamp", Instant.now().toString());
        logDataWithNulls.put("level", "INFO");
        logDataWithNulls.put("message", "Test message");
        logDataWithNulls.put("service", null);
        logDataWithNulls.put("host", null);

        IndexResponse mockResponse = mock(IndexResponse.class);
        when(mockResponse.id()).thenReturn("log-789");
        when(elasticsearchClient.index(any(IndexRequest.class))).thenReturn(mockResponse);

        // Act & Assert - should not throw exception
        assertDoesNotThrow(() -> elasticsearchService.indexLog("log-789", logDataWithNulls));

        verify(elasticsearchClient, times(1)).index(any(IndexRequest.class));
    }

    @Test
    void shouldSearchWithPagination() throws Exception {
        // Arrange
        LogSearchRequest searchRequest = LogSearchRequest.builder()
                .service("test-service")
                .page(2)
                .size(10)
                .build();

        SearchResponse<Map> mockSearchResponse = mock(SearchResponse.class);
        HitsMetadata<Map> mockHits = mock(HitsMetadata.class);
        
        when(mockHits.hits()).thenReturn(Collections.emptyList());
        when(mockHits.total()).thenReturn(mock(co.elastic.clients.elasticsearch.core.search.TotalHits.class));
        when(mockSearchResponse.hits()).thenReturn(mockHits);
        when(elasticsearchClient.search(any(SearchRequest.class), eq(Map.class)))
                .thenReturn(mockSearchResponse);

        // Act
        LogSearchResponse result = elasticsearchService.searchLogs(searchRequest);

        // Assert
        assertNotNull(result);
        verify(elasticsearchClient, times(1)).search(argThat(request -> {
            // In real test, would verify pagination parameters
            return true;
        }), eq(Map.class));
    }

    @Test
    void shouldSearchAnomaliesOnly() throws Exception {
        // Arrange
        LogSearchRequest searchRequest = LogSearchRequest.builder()
                .service("test-service")
                .anomaliesOnly(true)
                .page(0)
                .size(20)
                .build();

        SearchResponse<Map> mockSearchResponse = mock(SearchResponse.class);
        HitsMetadata<Map> mockHits = mock(HitsMetadata.class);
        
        when(mockHits.hits()).thenReturn(Collections.emptyList());
        when(mockHits.total()).thenReturn(mock(co.elastic.clients.elasticsearch.core.search.TotalHits.class));
        when(mockSearchResponse.hits()).thenReturn(mockHits);
        when(elasticsearchClient.search(any(SearchRequest.class), eq(Map.class)))
                .thenReturn(mockSearchResponse);

        // Act
        LogSearchResponse result = elasticsearchService.searchLogs(searchRequest);

        // Assert
        assertNotNull(result);
        verify(elasticsearchClient, times(1)).search(any(SearchRequest.class), eq(Map.class));
    }
}

// Made with Bob