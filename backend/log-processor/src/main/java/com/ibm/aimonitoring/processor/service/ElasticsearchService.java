package com.ibm.aimonitoring.processor.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.Result;
import co.elastic.clients.elasticsearch.core.IndexResponse;
import co.elastic.clients.elasticsearch.indices.CreateIndexResponse;
import co.elastic.clients.elasticsearch.indices.ExistsRequest;
import co.elastic.clients.transport.endpoints.BooleanResponse;
import com.ibm.aimonitoring.processor.dto.LogEntryDTO;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for Elasticsearch operations
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ElasticsearchService {

    private final ElasticsearchClient elasticsearchClient;

    @Value("${elasticsearch.index.name:logs}")
    private String indexName;

    @Value("${elasticsearch.index.shards:1}")
    private int numberOfShards;

    @Value("${elasticsearch.index.replicas:0}")
    private int numberOfReplicas;

    /**
     * Initialize Elasticsearch index on startup
     */
    @PostConstruct
    public void init() {
        try {
            createIndexIfNotExists();
            log.info("Elasticsearch service initialized successfully");
        } catch (Exception e) {
            log.error("Failed to initialize Elasticsearch service: {}", e.getMessage(), e);
        }
    }

    /**
     * Create index if it doesn't exist
     */
    private void createIndexIfNotExists() throws IOException {
        BooleanResponse exists = elasticsearchClient.indices()
                .exists(ExistsRequest.of(e -> e.index(indexName)));

        if (!exists.value()) {
            log.info("Creating Elasticsearch index: {}", indexName);
            
            CreateIndexResponse response = elasticsearchClient.indices()
                    .create(c -> c
                            .index(indexName)
                            .settings(s -> s
                                    .numberOfShards(String.valueOf(numberOfShards))
                                    .numberOfReplicas(String.valueOf(numberOfReplicas))
                            )
                            .mappings(m -> m
                                    .properties("timestamp", p -> p.date(d -> d.format("strict_date_optional_time")))
                                    .properties("level", p -> p.keyword(k -> k))
                                    .properties("message", p -> p.text(t -> t.analyzer("standard")))
                                    .properties("service", p -> p.keyword(k -> k))
                                    .properties("host", p -> p.keyword(k -> k))
                                    .properties("environment", p -> p.keyword(k -> k))
                                    .properties("traceId", p -> p.keyword(k -> k))
                                    .properties("spanId", p -> p.keyword(k -> k))
                                    .properties("metadata", p -> p.object(o -> o.enabled(true)))
                            )
                    );

            log.info("Index created: {}, acknowledged: {}", indexName, response.acknowledged());
        } else {
            log.info("Index already exists: {}", indexName);
        }
    }

    /**
     * Index a log entry to Elasticsearch
     *
     * @param logEntry the log entry to index
     * @return the document ID
     */
    public String indexLog(LogEntryDTO logEntry) {
        try {
            // Convert DTO to Map for indexing
            Map<String, Object> document = convertToDocument(logEntry);

            // Index the document
            IndexResponse response = elasticsearchClient.index(i -> i
                    .index(indexName)
                    .document(document)
            );

            if (response.result() == Result.Created || response.result() == Result.Updated) {
                log.debug("Log indexed successfully: {}", response.id());
                return response.id();
            } else {
                log.warn("Unexpected index result: {}", response.result());
                return null;
            }

        } catch (IOException e) {
            log.error("Failed to index log to Elasticsearch: {}", e.getMessage(), e);
            throw new ElasticsearchIndexException("Failed to index log", e);
        }
    }

    /**
     * Convert LogEntryDTO to a Map for Elasticsearch
     */
    private Map<String, Object> convertToDocument(LogEntryDTO logEntry) {
        Map<String, Object> document = new HashMap<>();
        
        document.put("timestamp", logEntry.getTimestamp() != null ? 
                logEntry.getTimestamp().toString() : null);
        document.put("level", logEntry.getLevel());
        document.put("message", logEntry.getMessage());
        document.put("service", logEntry.getService());
        document.put("host", logEntry.getHost());
        document.put("environment", logEntry.getEnvironment());
        document.put("traceId", logEntry.getTraceId());
        document.put("spanId", logEntry.getSpanId());
        
        if (logEntry.getMetadata() != null) {
            document.put("metadata", logEntry.getMetadata());
        }
        
        return document;
    }

    /**
     * Check if Elasticsearch is available
     */
    public boolean isAvailable() {
        try {
            return elasticsearchClient.ping().value();
        } catch (IOException e) {
            log.error("Elasticsearch ping failed: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Custom exception for Elasticsearch indexing errors
     */
    public static class ElasticsearchIndexException extends RuntimeException {
        public ElasticsearchIndexException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}

// Made with Bob
