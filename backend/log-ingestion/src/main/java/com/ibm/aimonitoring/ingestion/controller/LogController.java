package com.ibm.aimonitoring.ingestion.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    @PostMapping
    public ResponseEntity<Map<String, Object>> ingestLog(@RequestBody Map<String, Object> logEntry) {
        log.info("Received log: {}", logEntry);
        
        String logId = UUID.randomUUID().toString();
        
        return ResponseEntity.accepted().body(Map.of(
            "id", logId,
            "status", "accepted",
            "timestamp", Instant.now().toString()
        ));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "log-ingestion"));
    }
}
