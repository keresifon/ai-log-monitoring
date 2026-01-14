import { Component, OnInit, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule, NavigationEnd } from '@angular/router';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDividerModule } from '@angular/material/divider';
import { filter } from 'rxjs/operators';

import { AuthService } from '../../../core/services/auth.service';

interface NavItem {
  label: string;
  icon: string;
  route: string;
  roles?: string[];
  badge?: number;
}

/**
 * Sidebar navigation component
 */
@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatListModule,
    MatIconModule,
    MatTooltipModule,
    MatDividerModule
  ],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent implements OnInit {
  @Input() isOpen = true;

  activeRoute = '';

  navItems: NavItem[] = [
    {
      label: 'Dashboard',
      icon: 'dashboard',
      route: '/dashboard'
    },
    {
      label: 'Logs',
      icon: 'description',
      route: '/logs'
    },
    {
      label: 'Alerts',
      icon: 'notifications_active',
      route: '/alerts',
      badge: 5
    },
    {
      label: 'Analytics',
      icon: 'analytics',
      route: '/analytics'
    },
    {
      label: 'Reports',
      icon: 'assessment',
      route: '/reports'
    }
  ];

  adminItems: NavItem[] = [
    {
      label: 'Users',
      icon: 'people',
      route: '/admin/users',
      roles: ['ADMIN']
    },
    {
      label: 'Settings',
      icon: 'settings',
      route: '/admin/settings',
      roles: ['ADMIN']
    }
  ];

  constructor(
    private router: Router,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    // Set initial active route
    this.activeRoute = this.router.url;

    // Listen to route changes
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: any) => {
        this.activeRoute = event.url;
      });
  }

  /**
   * Check if route is active
   */
  isActive(route: string): boolean {
    return this.activeRoute === route || this.activeRoute.startsWith(route + '/');
  }

  /**
   * Check if user can access nav item
   */
  canAccess(item: NavItem): boolean {
    if (!item.roles || item.roles.length === 0) {
      return true;
    }
    return this.authService.hasAnyRole(item.roles);
  }

  /**
   * Get filtered nav items based on user roles
   */
  getVisibleNavItems(): NavItem[] {
    return this.navItems.filter(item => this.canAccess(item));
  }

  /**
   * Get filtered admin items based on user roles
   */
  getVisibleAdminItems(): NavItem[] {
    return this.adminItems.filter(item => this.canAccess(item));
  }

  /**
   * Check if user has admin access
   */
  hasAdminAccess(): boolean {
    return this.authService.hasRole('ADMIN');
  }

  /**
   * Navigate to route
   */
  navigate(route: string): void {
    this.router.navigate([route]);
  }
}

// Made with Bob
