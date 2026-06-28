# WhatsFlow CRM Architecture

## High-Level Stack
- Frontend: Angular 20, Angular Material, TailwindCSS, RxJS, Signals, standalone components
- Backend: ASP.NET Core 9 Web API, JWT auth, Swagger, Serilog, background services
- Database: PostgreSQL with migrations and indexed query paths
- Cache: Redis for hot reads and session/token support where needed
- Infra: Docker, Docker Compose, Nginx, GitHub Actions

## Application Layers
- Presentation: Angular dashboard
- API: ASP.NET Core controllers/endpoints
- Application: business use cases, validation, orchestration
- Domain: entities, policies, business rules
- Infrastructure: database access, external integrations, messaging

## Initial Modules
- Auth
- Business profile
- Customers
- Conversations
- Tasks and reminders
- Dashboard metrics
- WhatsApp integration abstraction
- Audit logs

## Data Strategy
- Use PostgreSQL as the primary system of record
- Add indexes for customer lookup, conversation timestamps, task due dates, and lead status
- Store external integration payloads separately from core business entities where possible

## Integration Strategy
- WhatsApp API behind an adapter interface
- Email and notifications behind provider abstractions
- Background jobs for reminder dispatch and sync tasks

## Security Baseline
- JWT access tokens
- Refresh tokens
- Role-based authorization
- Input validation and request logging
- Rate limiting on public endpoints
- Secure secret management via environment variables

## First Delivery Slice
1. Authentication and business onboarding
2. Customer management
3. Basic dashboard metrics
4. Follow-up reminders
5. WhatsApp integration placeholder service
