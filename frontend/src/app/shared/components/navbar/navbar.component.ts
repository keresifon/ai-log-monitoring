import { Component, OnInit, OnDestroy, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatBadgeModule } from '@angular/material/badge';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDividerModule } from '@angular/material/divider';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import { AuthService } from '../../../core/services/auth.service';
import { User } from '../../models/auth.model';

/**
 * Navigation bar component with user menu and notifications
 */
@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatMenuModule,
    MatBadgeModule,
    MatTooltipModule,
    MatDividerModule
  ],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit, OnDestroy {
  @Output() toggleSidebar = new EventEmitter<void>();

  currentUser: User | null = null;
  notificationCount = 0;
  private destroy$ = new Subject<void>();

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Subscribe to current user
    this.authService.currentUser$
      .pipe(takeUntil(this.destroy$))
      .subscribe(user => {
        this.currentUser = user;
      });

    // TODO: Subscribe to notification service for count
    // For now, using mock data
    this.notificationCount = 3;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Toggle sidebar visibility
   */
  onToggleSidebar(): void {
    this.toggleSidebar.emit();
  }

  /**
   * Navigate to profile page
   */
  goToProfile(): void {
    this.router.navigate(['/profile']);
  }

  /**
   * Navigate to settings page
   */
  goToSettings(): void {
    this.router.navigate(['/settings']);
  }

  /**
   * Navigate to notifications page
   */
  goToNotifications(): void {
    this.router.navigate(['/notifications']);
  }

  /**
   * Logout user
   */
  logout(): void {
    this.authService.logout();
  }

  /**
   * Get user initials for avatar
   */
  getUserInitials(): string {
    if (!this.currentUser) {
      return 'U';
    }

    const firstInitial = this.currentUser.firstName?.charAt(0) || '';
    const lastInitial = this.currentUser.lastName?.charAt(0) || '';
    
    return (firstInitial + lastInitial).toUpperCase() || 'U';
  }

  /**
   * Get user display name
   */
  getUserDisplayName(): string {
    if (!this.currentUser) {
      return 'User';
    }

    return `${this.currentUser.firstName} ${this.currentUser.lastName}`.trim() || 
           this.currentUser.username;
  }

  /**
   * Check if user has admin role
   */
  isAdmin(): boolean {
    return this.authService.hasRole('ADMIN');
  }
}

// Made with Bob
