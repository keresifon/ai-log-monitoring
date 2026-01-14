package com.ibm.aimonitoring.ingestion;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.datasource.url=jdbc:postgresql://localhost:5432/aimonitoring",
    "spring.datasource.username=postgres",
    "spring.datasource.password=postgres",
    "spring.rabbitmq.host=localhost",
    "spring.rabbitmq.port=5672",
    "spring.jpa.hibernate.ddl-auto=create-drop"
})
class LogIngestionServiceApplicationTests {

    @Test
    void contextLoads() {
    }
}

// Made with Bob
