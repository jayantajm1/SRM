import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render title', async () => {
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();

    const httpMock = TestBed.inject(HttpTestingController);
    httpMock.expectOne('/api/business/profile').flush({
      businessName: 'Asha Wellness Studio',
      ownerName: 'Meera Shah',
      industry: 'Fitness & Wellness',
      city: 'Mumbai',
      primaryPhoneNumber: '+91 98765 43210',
      timezone: 'Asia/Kolkata',
      planName: 'Growth',
      teamSize: 6,
      onboardedAtUtc: '2026-06-10T08:00:00+00:00',
    });
    httpMock.expectOne('/api/dashboard/summary').flush({
      todayFollowUps: 14,
      upcomingAppointments: 7,
      monthlyRevenue: 284500,
      pendingPayments: 92800,
      activeCustomers: 148,
      newLeads: 37,
      broadcastStatus: '2 campaigns scheduled',
      leadConversionRate: 18.4,
      customerGrowthRate: 12.7,
      recentCustomers: [
        {
          id: 1,
          name: 'Asha Fitness',
          industry: 'Gym',
          city: 'Mumbai',
          phoneNumber: '+91 98765 43210',
          status: 'Hot Lead',
          lastContactedAtUtc: '2026-06-27T08:00:00+00:00',
          labels: ['Hot Lead', 'Follow-up'],
        },
      ],
      recentActivities: [
        { message: 'WhatsApp follow-up sent to Asha Fitness', occurredAtUtc: '2026-06-27T08:10:00+00:00' },
      ],
    });

    fixture.detectChanges();
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('WhatsFlow CRM');
    expect(compiled.textContent).toContain('Asha Wellness Studio');
    expect(compiled.textContent).toContain('Today\'s follow-ups');
  });
});
