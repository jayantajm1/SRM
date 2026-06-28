# WhatsFlow CRM PostgreSQL Schema

This folder contains the SQL bootstrap for the WhatsFlow CRM database.

## Files
- `whatsflow_schema.sql`: complete tenant-aware schema, indexes, helper functions, and reporting views.

## Apply Order
1. Create a PostgreSQL database named `whatsflow_crm`.
2. Run `whatsflow_schema.sql` against that database.
3. Seed lookup rows such as permissions, default roles, and pipeline stages from your app or a seed script.

## Notes
- The schema uses a dedicated `whatsflow` schema namespace.
- Core helper functions are included for onboarding, timeline events, stage movement, document numbering, lead scoring, and dashboard metrics.
- The schema is designed to be the foundation for a later EF Core or Dapper repository layer.
