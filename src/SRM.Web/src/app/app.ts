import { DecimalPipe } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import { BusinessProfile, DashboardSummary, WhatsFlowApiService } from './whatsflow-api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [DecimalPipe],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private readonly whatsFlowApiService = inject(WhatsFlowApiService);

  protected readonly title = signal('WhatsFlow CRM');
  protected readonly profile = signal<BusinessProfile | null>(null);
  protected readonly summary = signal<DashboardSummary | null>(null);
  protected readonly loading = signal(true);
  protected readonly error = signal<string | null>(null);
  protected readonly highlights = [
    'WhatsApp-first customer workflows',
    'Indian SMB-focused SaaS admin panel',
    'Ready for customers, reminders, and conversations',
  ];

  ngOnInit(): void {
    this.loadStatus();
  }

  protected loadStatus(): void {
    this.loading.set(true);
    this.error.set(null);

    forkJoin({
      profile: this.whatsFlowApiService.getBusinessProfile(),
      summary: this.whatsFlowApiService.getDashboardSummary(),
    }).subscribe({
      next: ({ profile, summary }) => {
        this.profile.set(profile);
        this.summary.set(summary);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('The WhatsFlow dashboard API is not reachable yet.');
        this.loading.set(false);
      }
    });
  }
}
