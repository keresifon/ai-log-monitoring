import { Component, OnInit, OnDestroy, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { Chart, ChartConfiguration, registerables } from 'chart.js';
import 'chartjs-adapter-date-fns';

import { DashboardService } from '../../core/services/dashboard.service';
import {
  DashboardMetrics,
  LogVolumeData,
  LogLevelDistribution,
  ServiceLogCount,
  AnomalyPoint,
  RecentAlert
} from '../../shared/models/dashboard.model';
import { ChartConfigUtil } from '../../shared/utils/chart-config.util';

// Register Chart.js components
Chart.register(...registerables);

/**
 * Dashboard component with real-time monitoring visualizations
 */
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatChipsModule,
    MatTooltipModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit, OnDestroy, AfterViewInit {
  // Canvas references for charts
  @ViewChild('logVolumeCanvas') logVolumeCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('logLevelCanvas') logLevelCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('topServicesCanvas') topServicesCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('anomalyCanvas') anomalyCanvas!: ElementRef<HTMLCanvasElement>;

  // Chart instances
  private logVolumeChart?: Chart;
  private logLevelChart?: Chart;
  private topServicesChart?: Chart;
  private anomalyChart?: Chart;

  // Component state
  isLoading = true;
  error: string | null = null;
  metrics: DashboardMetrics | null = null;
  recentAlerts: RecentAlert[] = [];

  // Auto-refresh
  private readonly REFRESH_INTERVAL = 30000; // 30 seconds
  private destroy$ = new Subject<void>();

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadDashboardData();
    this.startAutoRefresh();
  }

  ngAfterViewInit(): void {
    // Initialize charts after view is ready
    setTimeout(() => {
      this.initializeCharts();
    }, 100);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.destroyCharts();
  }

  /**
   * Load all dashboard data
   */
  private loadDashboardData(): void {
    this.isLoading = true;
    this.error = null;

    // Load metrics
    this.dashboardService.getMetrics()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (metrics) => {
          this.metrics = metrics;
          this.isLoading = false;
        },
        error: (error) => {
          this.error = 'Failed to load dashboard metrics';
          this.isLoading = false;
          console.error('Error loading metrics:', error);
        }
      });

    // Load recent alerts
    this.dashboardService.getRecentAlerts(10)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (alerts) => {
          this.recentAlerts = alerts;
        },
        error: (error) => {
          console.error('Error loading alerts:', error);
        }
      });

    // Load chart data
    this.loadChartData();
  }

  /**
   * Load data for all charts
   */
  private loadChartData(): void {
    // Load log volume data
    this.dashboardService.getLogVolume(24)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => this.updateLogVolumeChart(data),
        error: (error) => console.error('Error loading log volume:', error)
      });

    // Load log level distribution
    this.dashboardService.getLogLevelDistribution()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => this.updateLogLevelChart(data),
        error: (error) => console.error('Error loading log levels:', error)
      });

    // Load top services
    this.dashboardService.getTopServices(10)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => this.updateTopServicesChart(data),
        error: (error) => console.error('Error loading top services:', error)
      });

    // Load anomalies
    this.dashboardService.getAnomalies(24)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => this.updateAnomalyChart(data),
        error: (error) => console.error('Error loading anomalies:', error)
      });
  }

  /**
   * Initialize all charts
   */
  private initializeCharts(): void {
    if (!this.logVolumeCanvas || !this.logLevelCanvas || 
        !this.topServicesCanvas || !this.anomalyCanvas) {
      return;
    }

    // Initialize log volume chart
    const logVolumeConfig = ChartConfigUtil.getLogVolumeChartConfig();
    this.logVolumeChart = new Chart(
      this.logVolumeCanvas.nativeElement,
      logVolumeConfig
    );

    // Initialize log level chart
    const logLevelConfig = ChartConfigUtil.getLogLevelChartConfig();
    this.logLevelChart = new Chart(
      this.logLevelCanvas.nativeElement,
      logLevelConfig
    );

    // Initialize top services chart
    const topServicesConfig = ChartConfigUtil.getTopServicesChartConfig();
    this.topServicesChart = new Chart(
      this.topServicesCanvas.nativeElement,
      topServicesConfig
    );

    // Initialize anomaly chart
    const anomalyConfig = ChartConfigUtil.getAnomalyChartConfig();
    this.anomalyChart = new Chart(
      this.anomalyCanvas.nativeElement,
      anomalyConfig
    );
  }

  /**
   * Update log volume chart with new data
   */
  private updateLogVolumeChart(data: LogVolumeData[]): void {
    if (!this.logVolumeChart) return;

    const labels = data.map(d => ChartConfigUtil.formatDateLabel(new Date(d.timestamp), 'time'));
    const values = data.map(d => d.count);

    this.logVolumeChart.data.labels = labels;
    this.logVolumeChart.data.datasets[0].data = values;
    this.logVolumeChart.update();
  }

  /**
   * Update log level chart with new data
   */
  private updateLogLevelChart(data: LogLevelDistribution[]): void {
    if (!this.logLevelChart) return;

    const labels = data.map(d => d.level);
    const values = data.map(d => d.count);

    this.logLevelChart.data.labels = labels;
    this.logLevelChart.data.datasets[0].data = values;
    this.logLevelChart.update();
  }

  /**
   * Update top services chart with new data
   */
  private updateTopServicesChart(data: ServiceLogCount[]): void {
    if (!this.topServicesChart) return;

    const labels = data.map(d => d.service);
    const values = data.map(d => d.count);

    this.topServicesChart.data.labels = labels;
    this.topServicesChart.data.datasets[0].data = values;
    this.topServicesChart.update();
  }

  /**
   * Update anomaly chart with new data
   */
  private updateAnomalyChart(data: AnomalyPoint[]): void {
    if (!this.anomalyChart) return;

    const normalPoints = data
      .filter(d => !d.isAnomaly)
      .map(d => ({ x: new Date(d.timestamp).getTime(), y: d.score }));

    const anomalyPoints = data
      .filter(d => d.isAnomaly)
      .map(d => ({ x: new Date(d.timestamp).getTime(), y: d.score }));

    this.anomalyChart.data.datasets[0].data = normalPoints;
    this.anomalyChart.data.datasets[1].data = anomalyPoints;
    this.anomalyChart.update();
  }

  /**
   * Destroy all chart instances
   */
  private destroyCharts(): void {
    this.logVolumeChart?.destroy();
    this.logLevelChart?.destroy();
    this.topServicesChart?.destroy();
    this.anomalyChart?.destroy();
  }

  /**
   * Start auto-refresh interval
   */
  private startAutoRefresh(): void {
    interval(this.REFRESH_INTERVAL)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (!this.isLoading) {
          this.loadDashboardData();
        }
      });
  }

  /**
   * Manual refresh
   */
  refresh(): void {
    this.loadDashboardData();
  }

  /**
   * Get severity color for alerts
   */
  getSeverityColor(severity: string): string {
    const colorMap: { [key: string]: string } = {
      'CRITICAL': 'warn',
      'HIGH': 'warn',
      'MEDIUM': 'accent',
      'LOW': 'primary',
      'INFO': 'primary'
    };
    return colorMap[severity.toUpperCase()] || 'primary';
  }

  /**
   * Get status color for alerts
   */
  getStatusColor(status: string): string {
    const colorMap: { [key: string]: string } = {
      'ACTIVE': 'warn',
      'ACKNOWLEDGED': 'accent',
      'RESOLVED': 'primary'
    };
    return colorMap[status.toUpperCase()] || 'primary';
  }

  /**
   * Format timestamp for display
   */
  formatTimestamp(timestamp: string): string {
    return new Date(timestamp).toLocaleString();
  }

  /**
   * Format large numbers with K/M suffix
   */
  formatNumber(num: number): string {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M';
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
  }
}

// Made with Bob
