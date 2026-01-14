import { ChartConfiguration, ChartOptions } from 'chart.js';

/**
 * Utility class for Chart.js configuration
 */
export class ChartConfigUtil {
  /**
   * Common chart options
   */
  private static readonly commonOptions: Partial<ChartOptions> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
        labels: {
          usePointStyle: true,
          padding: 15,
          font: {
            size: 12
          }
        }
      },
      tooltip: {
        enabled: true,
        mode: 'index',
        intersect: false,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: '#fff',
        bodyColor: '#fff',
        borderColor: '#ddd',
        borderWidth: 1,
        padding: 10,
        displayColors: true
      }
    }
  };

  /**
   * Color palette for charts
   */
  static readonly colors = {
    primary: '#1976d2',
    accent: '#ff4081',
    warn: '#f44336',
    success: '#4caf50',
    info: '#2196f3',
    warning: '#ff9800',
    error: '#f44336',
    debug: '#9e9e9e',
    trace: '#607d8b',
    
    // Chart colors
    blue: 'rgba(33, 150, 243, 0.8)',
    red: 'rgba(244, 67, 54, 0.8)',
    green: 'rgba(76, 175, 80, 0.8)',
    orange: 'rgba(255, 152, 0, 0.8)',
    purple: 'rgba(156, 39, 176, 0.8)',
    teal: 'rgba(0, 150, 136, 0.8)',
    pink: 'rgba(233, 30, 99, 0.8)',
    indigo: 'rgba(63, 81, 181, 0.8)',
    cyan: 'rgba(0, 188, 212, 0.8)',
    lime: 'rgba(205, 220, 57, 0.8)',
    
    // Transparent versions
    blueTransparent: 'rgba(33, 150, 243, 0.2)',
    redTransparent: 'rgba(244, 67, 54, 0.2)',
    greenTransparent: 'rgba(76, 175, 80, 0.2)',
    orangeTransparent: 'rgba(255, 152, 0, 0.2)',
    purpleTransparent: 'rgba(156, 39, 176, 0.2)'
  };

  /**
   * Get line chart configuration for log volume
   */
  static getLogVolumeChartConfig(): ChartConfiguration<'line'> {
    return {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'Log Volume',
          data: [],
          borderColor: this.colors.blue,
          backgroundColor: this.colors.blueTransparent,
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointRadius: 3,
          pointHoverRadius: 5,
          pointBackgroundColor: this.colors.blue,
          pointBorderColor: '#fff',
          pointBorderWidth: 2
        }]
      },
      options: {
        ...this.commonOptions as any,
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: 'Time',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            grid: {
              display: false
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: 'Number of Logs',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          }
        },
        plugins: {
          ...this.commonOptions.plugins as any,
          title: {
            display: true,
            text: 'Log Volume Over Time',
            font: {
              size: 16,
              weight: 'bold'
            },
            padding: {
              top: 10,
              bottom: 20
            }
          }
        }
      }
    };
  }

  /**
   * Get pie chart configuration for log level distribution
   */
  static getLogLevelChartConfig(): ChartConfiguration<'pie'> {
    return {
      type: 'pie',
      data: {
        labels: [],
        datasets: [{
          data: [],
          backgroundColor: [
            this.colors.red,      // ERROR
            this.colors.orange,   // WARN
            this.colors.blue,     // INFO
            this.colors.green,    // DEBUG
            this.colors.purple    // TRACE
          ],
          borderColor: '#fff',
          borderWidth: 2,
          hoverOffset: 10
        }]
      },
      options: {
        ...this.commonOptions as any,
        plugins: {
          ...this.commonOptions.plugins as any,
          title: {
            display: true,
            text: 'Log Level Distribution',
            font: {
              size: 16,
              weight: 'bold'
            },
            padding: {
              top: 10,
              bottom: 20
            }
          },
          legend: {
            display: true,
            position: 'right',
            labels: {
              usePointStyle: true,
              padding: 15,
              font: {
                size: 12
              }
            }
          }
        }
      }
    };
  }

  /**
   * Get bar chart configuration for top services
   */
  static getTopServicesChartConfig(): ChartConfiguration<'bar'> {
    return {
      type: 'bar',
      data: {
        labels: [],
        datasets: [{
          label: 'Log Count',
          data: [],
          backgroundColor: this.colors.teal,
          borderColor: this.colors.teal,
          borderWidth: 1,
          borderRadius: 4,
          hoverBackgroundColor: this.colors.cyan
        }]
      },
      options: {
        ...this.commonOptions as any,
        indexAxis: 'y',
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: 'Number of Logs',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: 'Service Name',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            grid: {
              display: false
            }
          }
        },
        plugins: {
          ...this.commonOptions.plugins as any,
          title: {
            display: true,
            text: 'Top Services by Log Count',
            font: {
              size: 16,
              weight: 'bold'
            },
            padding: {
              top: 10,
              bottom: 20
            }
          },
          legend: {
            display: false
          }
        }
      }
    };
  }

  /**
   * Get scatter chart configuration for anomalies
   */
  static getAnomalyChartConfig(): ChartConfiguration<'scatter'> {
    return {
      type: 'scatter',
      data: {
        datasets: [
          {
            label: 'Normal',
            data: [],
            backgroundColor: this.colors.greenTransparent,
            borderColor: this.colors.green,
            borderWidth: 1,
            pointRadius: 4,
            pointHoverRadius: 6
          },
          {
            label: 'Anomaly',
            data: [],
            backgroundColor: this.colors.redTransparent,
            borderColor: this.colors.red,
            borderWidth: 2,
            pointRadius: 6,
            pointHoverRadius: 8,
            pointStyle: 'triangle'
          }
        ]
      },
      options: {
        ...this.commonOptions as any,
        scales: {
          x: {
            type: 'time' as const,
            time: {
              unit: 'hour',
              displayFormats: {
                hour: 'MMM d, HH:mm'
              }
            },
            title: {
              display: true,
              text: 'Time',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Anomaly Score',
              font: {
                size: 12,
                weight: 'bold'
              }
            },
            beginAtZero: true,
            max: 1,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          }
        },
        plugins: {
          ...this.commonOptions.plugins as any,
          title: {
            display: true,
            text: 'Anomaly Detection Timeline',
            font: {
              size: 16,
              weight: 'bold'
            },
            padding: {
              top: 10,
              bottom: 20
            }
          },
          tooltip: {
            ...this.commonOptions.plugins?.tooltip as any,
            callbacks: {
              label: function(context: any): string {
                const label = context.dataset.label || '';
                const score = context.parsed.y.toFixed(3);
                const time = new Date(context.parsed.x).toLocaleString();
                return `${label}: ${score} at ${time}`;
              }
            }
          }
        }
      }
    };
  }

  /**
   * Format date for chart labels
   */
  static formatDateLabel(date: Date, format: 'time' | 'date' | 'datetime' = 'time'): string {
    const options: Intl.DateTimeFormatOptions = {};
    
    switch (format) {
      case 'time':
        options.hour = '2-digit';
        options.minute = '2-digit';
        break;
      case 'date':
        options.month = 'short';
        options.day = 'numeric';
        break;
      case 'datetime':
        options.month = 'short';
        options.day = 'numeric';
        options.hour = '2-digit';
        options.minute = '2-digit';
        break;
    }
    
    return date.toLocaleString('en-US', options);
  }

  /**
   * Get color by log level
   */
  static getLogLevelColor(level: string): string {
    const levelMap: { [key: string]: string } = {
      'ERROR': this.colors.red,
      'WARN': this.colors.orange,
      'INFO': this.colors.blue,
      'DEBUG': this.colors.green,
      'TRACE': this.colors.purple
    };
    
    return levelMap[level.toUpperCase()] || this.colors.blue;
  }
}

// Made with Bob
