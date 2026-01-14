package com.ibm.aimonitoring.ingestion.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for LogLevel enum
 */
class LogLevelTest {

    @Test
    void shouldHaveAllLogLevels() {
        // Act
        LogLevel[] levels = LogLevel.values();

        // Assert
        assertThat(levels).hasSize(5);
        assertThat(levels).containsExactly(
                LogLevel.ERROR,
                LogLevel.WARN,
                LogLevel.INFO,
                LogLevel.DEBUG,
                LogLevel.TRACE
        );
    }

    @Test
    void shouldConvertStringToLogLevel() {
        // Act & Assert
        assertThat(LogLevel.valueOf("ERROR")).isEqualTo(LogLevel.ERROR);
        assertThat(LogLevel.valueOf("WARN")).isEqualTo(LogLevel.WARN);
        assertThat(LogLevel.valueOf("INFO")).isEqualTo(LogLevel.INFO);
        assertThat(LogLevel.valueOf("DEBUG")).isEqualTo(LogLevel.DEBUG);
        assertThat(LogLevel.valueOf("TRACE")).isEqualTo(LogLevel.TRACE);
    }

    @Test
    void shouldHaveCorrectEnumNames() {
        // Assert
        assertThat(LogLevel.ERROR.name()).isEqualTo("ERROR");
        assertThat(LogLevel.WARN.name()).isEqualTo("WARN");
        assertThat(LogLevel.INFO.name()).isEqualTo("INFO");
        assertThat(LogLevel.DEBUG.name()).isEqualTo("DEBUG");
        assertThat(LogLevel.TRACE.name()).isEqualTo("TRACE");
    }

    @Test
    void shouldHaveCorrectOrdinalValues() {
        // Assert - ordinals should match declaration order
        assertThat(LogLevel.ERROR.ordinal()).isEqualTo(0);
        assertThat(LogLevel.WARN.ordinal()).isEqualTo(1);
        assertThat(LogLevel.INFO.ordinal()).isEqualTo(2);
        assertThat(LogLevel.DEBUG.ordinal()).isEqualTo(3);
        assertThat(LogLevel.TRACE.ordinal()).isEqualTo(4);
    }

    @Test
    void shouldSupportEnumComparison() {
        // Assert - ERROR has highest severity (lowest ordinal)
        assertThat(LogLevel.ERROR.ordinal()).isLessThan(LogLevel.WARN.ordinal());
        assertThat(LogLevel.WARN.ordinal()).isLessThan(LogLevel.INFO.ordinal());
        assertThat(LogLevel.INFO.ordinal()).isLessThan(LogLevel.DEBUG.ordinal());
        assertThat(LogLevel.DEBUG.ordinal()).isLessThan(LogLevel.TRACE.ordinal());
    }

    @Test
    void shouldBeUsableInSwitchStatement() {
        // Arrange
        LogLevel level = LogLevel.ERROR;
        String result;

        // Act
        switch (level) {
            case ERROR:
                result = "Error level";
                break;
            case WARN:
                result = "Warning level";
                break;
            case INFO:
                result = "Info level";
                break;
            case DEBUG:
                result = "Debug level";
                break;
            case TRACE:
                result = "Trace level";
                break;
            default:
                result = "Unknown";
        }

        // Assert
        assertThat(result).isEqualTo("Error level");
    }
}

// Made with Bob