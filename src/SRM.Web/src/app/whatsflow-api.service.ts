import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

export interface RecentCustomer {
  id: number;
  name: string;
  industry: string;
  city: string;
  phoneNumber: string;
  status: string;
  lastContactedAtUtc: string;
  labels: string[];
}

export interface RecentActivity {
  message: string;
  occurredAtUtc: string;
}

export interface BusinessProfile {
  businessName: string;
  ownerName: string;
  industry: string;
  city: string;
  primaryPhoneNumber: string;
  timezone: string;
  planName: string;
  teamSize: number;
  onboardedAtUtc: string;
}

export interface DashboardSummary {
  todayFollowUps: number;
  upcomingAppointments: number;
  monthlyRevenue: number;
  pendingPayments: number;
  activeCustomers: number;
  newLeads: number;
  broadcastStatus: string;
  leadConversionRate: number;
  customerGrowthRate: number;
  recentCustomers: RecentCustomer[];
  recentActivities: RecentActivity[];
}

@Injectable({ providedIn: 'root' })
export class WhatsFlowApiService {
  private readonly http = inject(HttpClient);

  getBusinessProfile(): Observable<BusinessProfile> {
    return this.http.get<BusinessProfile>('/api/business/profile');
  }

  getDashboardSummary(): Observable<DashboardSummary> {
    return this.http.get<DashboardSummary>('/api/dashboard/summary');
  }
}