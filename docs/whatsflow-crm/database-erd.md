# WhatsFlow CRM Database ERD

This document contains two views of the PostgreSQL schema used by WhatsFlow CRM:

- Full ERD: the complete schema structure
- MVP-only ERD: the smaller operational core for the first delivery slice

## Full ERD

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        text timezone
        char currency_code
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        text phone_number
        text password_hash
        boolean is_system_admin
        boolean is_active
        timestamptz last_login_at
        timestamptz created_at
        timestamptz updated_at
    }

    business_memberships {
        uuid id PK
        uuid business_id FK
        uuid user_id FK
        uuid invited_by_user_id FK
        text status
        timestamptz joined_at
        timestamptz last_active_at
        timestamptz created_at
        timestamptz updated_at
    }

    roles {
        uuid id PK
        uuid business_id FK
        text name
        text scope
        text description
        timestamptz created_at
        timestamptz updated_at
    }

    permissions {
        uuid id PK
        citext code
        text description
        timestamptz created_at
    }

    membership_roles {
        uuid membership_id FK
        uuid role_id FK
        timestamptz created_at
    }

    role_permissions {
        uuid role_id FK
        uuid permission_id FK
        timestamptz created_at
    }

    subscription_plans {
        uuid id PK
        citext code
        text name
        text billing_cycle
        numeric monthly_price
        numeric annual_price
        integer max_users
        integer max_customers
        jsonb features_json
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    subscriptions {
        uuid id PK
        uuid business_id FK
        uuid plan_id FK
        text status
        text billing_cycle
        timestamptz started_at
        timestamptz trial_ends_at
        timestamptz renews_at
        timestamptz canceled_at
        text coupon_code
        numeric gst_rate
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    refresh_tokens {
        uuid id PK
        uuid user_id FK
        uuid business_id FK
        text token_hash
        timestamptz expires_at
        timestamptz revoked_at
        uuid replaced_by_token_id FK
        inet ip_address
        text user_agent
        timestamptz created_at
    }

    businesses ||--o{ business_memberships : has
    users ||--o{ business_memberships : joins
    businesses ||--o{ roles : defines
    business_memberships ||--o{ membership_roles : assigned
    roles ||--o{ membership_roles : contains
    roles ||--o{ role_permissions : grants
    permissions ||--o{ role_permissions : included_in
    businesses ||--|| subscriptions : subscribes
    subscription_plans ||--o{ subscriptions : selected_by
    users ||--o{ refresh_tokens : owns
    businesses ||--o{ refresh_tokens : scopes
```

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        text phone_number
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    lead_pipeline_stages {
        uuid id PK
        uuid business_id FK
        text name
        integer sort_order
        boolean is_default
        boolean is_closed_won
        boolean is_closed_lost
        timestamptz created_at
        timestamptz updated_at
    }

    customers {
        uuid id PK
        uuid business_id FK
        uuid owner_user_id FK
        uuid assigned_to_user_id FK
        uuid current_stage_id FK
        text display_name
        text company_name
        text phone_number
        text whatsapp_number
        citext email
        text city
        text state
        text source_channel
        text status
        text lead_status
        timestamptz last_contacted_at
        timestamptz next_follow_up_at
        text lost_reason
        text notes_summary
        text external_reference
        jsonb metadata_json
        timestamptz created_at
        timestamptz updated_at
    }

    customer_labels {
        uuid id PK
        uuid business_id FK
        text name
        char color_hex
        timestamptz created_at
        timestamptz updated_at
    }

    customer_label_links {
        uuid customer_id FK
        uuid label_id FK
        timestamptz created_at
    }

    customer_notes {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid author_user_id FK
        text note_text
        boolean is_pinned
        timestamptz created_at
        timestamptz updated_at
    }

    customer_stage_history {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid from_stage_id FK
        uuid to_stage_id FK
        uuid changed_by_user_id FK
        text reason
        timestamptz changed_at
    }

    customer_timeline_events {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        text event_type
        text subject
        text body
        jsonb payload_json
        uuid created_by_user_id FK
        timestamptz occurred_at
        timestamptz created_at
    }

    tasks {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid conversation_id FK
        uuid assigned_to_user_id FK
        uuid created_by_user_id FK
        text title
        text description
        text status
        text priority
        timestamptz due_at
        timestamptz completed_at
        timestamptz created_at
        timestamptz updated_at
    }

    reminders {
        uuid id PK
        uuid business_id FK
        uuid task_id FK
        uuid customer_id FK
        uuid created_by_user_id FK
        text delivery_channel
        timestamptz reminder_at
        text status
        timestamptz sent_at
        text delivery_status
        jsonb payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    appointments {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid assigned_to_user_id FK
        text title
        text description
        timestamptz start_at
        timestamptz end_at
        text location
        text status
        integer reminder_minutes_before
        timestamptz created_at
        timestamptz updated_at
    }

    customer_lead_scores {
        uuid customer_id PK,FK
        uuid business_id FK
        integer current_score
        text score_band
        timestamptz last_calculated_at
        timestamptz updated_at
    }

    lead_score_rules {
        uuid id PK
        uuid business_id FK
        text name
        text rule_type
        integer score_delta
        jsonb criteria_json
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    lead_score_events {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        text source_type
        integer score_delta
        text reason
        jsonb payload_json
        timestamptz created_at
    }

    customers ||--o{ customer_labels : uses
    customer_labels ||--o{ customer_label_links : applied_to
    customers ||--o{ customer_label_links : tagged
    customers ||--o{ customer_notes : has
    users ||--o{ customer_notes : writes
    lead_pipeline_stages ||--o{ customers : current_stage
    customers ||--o{ customer_stage_history : moves
    lead_pipeline_stages ||--o{ customer_stage_history : from_stage
    lead_pipeline_stages ||--o{ customer_stage_history : to_stage
    users ||--o{ customer_stage_history : changes
    customers ||--o{ customer_timeline_events : timeline
    users ||--o{ customer_timeline_events : creates
    customers ||--o{ tasks : has
    customers ||--o{ reminders : gets
    customers ||--o{ appointments : books
    customers ||--|| customer_lead_scores : scored
    businesses ||--o{ lead_pipeline_stages : configures
    businesses ||--o{ customers : owns
    users ||--o{ customers : owns_or_assigned
```

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    file_uploads {
        uuid id PK
        uuid business_id FK
        uuid uploaded_by_user_id FK
        text file_name
        text storage_provider
        text storage_key
        text content_type
        bigint byte_size
        text checksum_sha256
        text purpose
        boolean is_deleted
        timestamptz created_at
        timestamptz updated_at
    }

    conversations {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid assigned_to_user_id FK
        text provider
        text provider_thread_id
        text status
        timestamptz last_message_at
        integer unread_count
        timestamptz created_at
        timestamptz updated_at
    }

    messages {
        uuid id PK
        uuid business_id FK
        uuid conversation_id FK
        uuid sender_user_id FK
        text direction
        text message_type
        text body_text
        text media_url
        text provider_message_id
        timestamptz sent_at
        timestamptz delivered_at
        timestamptz read_at
        jsonb payload_json
        timestamptz created_at
    }

    message_attachments {
        uuid id PK
        uuid business_id FK
        uuid message_id FK
        uuid file_upload_id FK
        text attachment_type
        timestamptz created_at
    }

    templates {
        uuid id PK
        uuid business_id FK
        text provider_template_id
        text name
        text category
        text language_code
        text body_text
        text status
        integer variable_count
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    template_variables {
        uuid id PK
        uuid template_id FK
        text variable_key
        text sample_value
        integer sort_order
        timestamptz created_at
    }

    broadcast_campaigns {
        uuid id PK
        uuid business_id FK
        uuid created_by_user_id FK
        uuid template_id FK
        text name
        text status
        integer audience_count
        timestamptz scheduled_at
        timestamptz sent_at
        jsonb payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    businesses ||--o{ file_uploads : stores
    businesses ||--o{ conversations : owns
    conversations ||--o{ messages : contains
    users ||--o{ messages : sends
    messages ||--o{ message_attachments : attaches
    file_uploads ||--o{ message_attachments : stored_as
    businesses ||--o{ templates : owns
    templates ||--o{ template_variables : uses
    businesses ||--o{ broadcast_campaigns : runs
    templates ||--o{ broadcast_campaigns : uses
```

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    products {
        uuid id PK
        uuid business_id FK
        text sku
        text name
        text description
        numeric unit_price
        numeric tax_rate
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    services {
        uuid id PK
        uuid business_id FK
        text sku
        text name
        text description
        numeric rate
        numeric tax_rate
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    quotations {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid quoted_by_user_id FK
        text quote_number
        text status
        date issue_date
        date expiry_date
        numeric subtotal
        numeric tax_amount
        numeric discount_amount
        numeric total_amount
        text notes
        jsonb payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    quotation_items {
        uuid id PK
        uuid quotation_id FK
        uuid product_id FK
        uuid service_id FK
        text description
        numeric quantity
        numeric unit_price
        numeric tax_rate
        numeric line_total
        timestamptz created_at
    }

    invoices {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid quotation_id FK
        text invoice_number
        text status
        date issue_date
        date due_date
        numeric subtotal
        numeric tax_amount
        numeric discount_amount
        numeric total_amount
        numeric balance_due
        char currency_code
        text notes
        jsonb payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    invoice_items {
        uuid id PK
        uuid invoice_id FK
        uuid product_id FK
        uuid service_id FK
        text description
        numeric quantity
        numeric unit_price
        numeric tax_rate
        numeric line_total
        timestamptz created_at
    }

    payments {
        uuid id PK
        uuid business_id FK
        uuid invoice_id FK
        text payment_reference
        text provider
        text method
        numeric amount
        char currency_code
        text status
        timestamptz paid_at
        jsonb raw_payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    subscription_plans {
        uuid id PK
        citext code
        text name
        text billing_cycle
        numeric monthly_price
        numeric annual_price
        integer max_users
        integer max_customers
        jsonb features_json
        boolean is_active
    }

    subscriptions {
        uuid id PK
        uuid business_id FK
        uuid plan_id FK
        text status
        text billing_cycle
        timestamptz started_at
        timestamptz trial_ends_at
        timestamptz renews_at
        timestamptz canceled_at
        text coupon_code
        numeric gst_rate
        text notes
    }

    document_sequences {
        uuid id PK
        uuid business_id FK
        text document_type
        text prefix
        bigint next_number
        timestamptz created_at
        timestamptz updated_at
    }

    businesses ||--o{ products : offers
    businesses ||--o{ services : offers
    businesses ||--o{ quotations : issues
    users ||--o{ quotations : creates
    quotations ||--o{ quotation_items : includes
    products ||--o{ quotation_items : source
    services ||--o{ quotation_items : source
    businesses ||--o{ invoices : issues
    quotations ||--o{ invoices : converts_to
    invoices ||--o{ invoice_items : includes
    products ||--o{ invoice_items : source
    services ||--o{ invoice_items : source
    invoices ||--o{ payments : receives
    businesses ||--|| subscriptions : subscribes
    subscription_plans ||--o{ subscriptions : selected_by
    businesses ||--o{ document_sequences : sequences
```

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    business_settings {
        uuid business_id FK
        citext setting_key
        text setting_value
        uuid updated_by_user_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    settings_audit_trail {
        uuid id PK
        uuid business_id FK
        citext setting_key
        text old_value
        text new_value
        uuid changed_by_user_id FK
        timestamptz changed_at
    }

    integrations {
        uuid id PK
        uuid business_id FK
        text provider
        text name
        text status
        text external_account_id
        jsonb config_json
        bytea secrets_json_encrypted
        timestamptz last_synced_at
        timestamptz created_at
        timestamptz updated_at
    }

    support_tickets {
        uuid id PK
        uuid business_id FK
        uuid created_by_user_id FK
        uuid assigned_to_user_id FK
        text ticket_number
        text subject
        text description
        text status
        text priority
        text source
        timestamptz closed_at
        timestamptz created_at
        timestamptz updated_at
    }

    audit_logs {
        uuid id PK
        uuid business_id FK
        uuid actor_user_id FK
        text action
        text entity_type
        uuid entity_id
        text severity
        jsonb old_values
        jsonb new_values
        inet ip_address
        text user_agent
        timestamptz occurred_at
    }

    lead_score_rules {
        uuid id PK
        uuid business_id FK
        text name
        text rule_type
        integer score_delta
        jsonb criteria_json
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    lead_score_events {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        text source_type
        integer score_delta
        text reason
        jsonb payload_json
        timestamptz created_at
    }

    ai_assistant_sessions {
        uuid id PK
        uuid business_id FK
        uuid user_id FK
        uuid customer_id FK
        text title
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    faq_entries {
        uuid id PK
        uuid business_id FK
        text question
        text answer
        text[] tags
        boolean is_active
        uuid created_by_user_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    businesses ||--o{ business_settings : configures
    users ||--o{ business_settings : updates
    businesses ||--o{ settings_audit_trail : audits
    users ||--o{ settings_audit_trail : changes
    businesses ||--o{ integrations : owns
    businesses ||--o{ support_tickets : owns
    users ||--o{ support_tickets : creates
    users ||--o{ support_tickets : assigned
    businesses ||--o{ audit_logs : records
    users ||--o{ audit_logs : acts
    businesses ||--o{ lead_score_rules : defines
    businesses ||--o{ lead_score_events : tracks
    businesses ||--o{ ai_assistant_sessions : hosts
    users ||--o{ ai_assistant_sessions : opens
    businesses ||--o{ faq_entries : owns
    users ||--o{ faq_entries : creates
```

## MVP-only ERD

This version keeps only the first delivery slice: authentication, business onboarding, customer management, dashboard metrics, tasks, reminders, conversations, and audit logging.

```mermaid
erDiagram
    businesses {
        uuid id PK
        text name
        citext slug
        text status
        text timezone
        char currency_code
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        citext email
        text full_name
        text phone_number
        text password_hash
        boolean is_system_admin
        boolean is_active
        timestamptz last_login_at
        timestamptz created_at
        timestamptz updated_at
    }

    business_memberships {
        uuid id PK
        uuid business_id FK
        uuid user_id FK
        uuid invited_by_user_id FK
        text status
        timestamptz joined_at
        timestamptz last_active_at
        timestamptz created_at
        timestamptz updated_at
    }

    roles {
        uuid id PK
        uuid business_id FK
        text name
        text scope
        text description
        timestamptz created_at
        timestamptz updated_at
    }

    permissions {
        uuid id PK
        citext code
        text description
        timestamptz created_at
    }

    membership_roles {
        uuid membership_id FK
        uuid role_id FK
        timestamptz created_at
    }

    role_permissions {
        uuid role_id FK
        uuid permission_id FK
        timestamptz created_at
    }

    lead_pipeline_stages {
        uuid id PK
        uuid business_id FK
        text name
        integer sort_order
        boolean is_default
        boolean is_closed_won
        boolean is_closed_lost
        timestamptz created_at
        timestamptz updated_at
    }

    customers {
        uuid id PK
        uuid business_id FK
        uuid owner_user_id FK
        uuid assigned_to_user_id FK
        uuid current_stage_id FK
        text display_name
        text company_name
        text phone_number
        text whatsapp_number
        citext email
        text city
        text state
        text source_channel
        text status
        text lead_status
        timestamptz last_contacted_at
        timestamptz next_follow_up_at
        text lost_reason
        text notes_summary
        text external_reference
        jsonb metadata_json
        timestamptz created_at
        timestamptz updated_at
    }

    customer_labels {
        uuid id PK
        uuid business_id FK
        text name
        char color_hex
        timestamptz created_at
        timestamptz updated_at
    }

    customer_label_links {
        uuid customer_id FK
        uuid label_id FK
        timestamptz created_at
    }

    customer_notes {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid author_user_id FK
        text note_text
        boolean is_pinned
        timestamptz created_at
        timestamptz updated_at
    }

    customer_timeline_events {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        text event_type
        text subject
        text body
        jsonb payload_json
        uuid created_by_user_id FK
        timestamptz occurred_at
        timestamptz created_at
    }

    conversations {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid assigned_to_user_id FK
        text provider
        text provider_thread_id
        text status
        timestamptz last_message_at
        integer unread_count
        timestamptz created_at
        timestamptz updated_at
    }

    messages {
        uuid id PK
        uuid business_id FK
        uuid conversation_id FK
        uuid sender_user_id FK
        text direction
        text message_type
        text body_text
        text media_url
        text provider_message_id
        timestamptz sent_at
        timestamptz delivered_at
        timestamptz read_at
        jsonb payload_json
        timestamptz created_at
    }

    tasks {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid conversation_id FK
        uuid assigned_to_user_id FK
        uuid created_by_user_id FK
        text title
        text description
        text status
        text priority
        timestamptz due_at
        timestamptz completed_at
        timestamptz created_at
        timestamptz updated_at
    }

    reminders {
        uuid id PK
        uuid business_id FK
        uuid task_id FK
        uuid customer_id FK
        uuid created_by_user_id FK
        text delivery_channel
        timestamptz reminder_at
        text status
        timestamptz sent_at
        text delivery_status
        jsonb payload_json
        timestamptz created_at
        timestamptz updated_at
    }

    appointments {
        uuid id PK
        uuid business_id FK
        uuid customer_id FK
        uuid assigned_to_user_id FK
        text title
        text description
        timestamptz start_at
        timestamptz end_at
        text location
        text status
        integer reminder_minutes_before
        timestamptz created_at
        timestamptz updated_at
    }

    audit_logs {
        uuid id PK
        uuid business_id FK
        uuid actor_user_id FK
        text action
        text entity_type
        uuid entity_id
        text severity
        jsonb old_values
        jsonb new_values
        inet ip_address
        text user_agent
        timestamptz occurred_at
    }

    businesses ||--o{ business_memberships : has
    users ||--o{ business_memberships : joins
    businesses ||--o{ roles : defines
    business_memberships ||--o{ membership_roles : assigned
    roles ||--o{ membership_roles : contains
    roles ||--o{ role_permissions : grants
    permissions ||--o{ role_permissions : included_in
    businesses ||--o{ lead_pipeline_stages : configures
    businesses ||--o{ customers : owns
    users ||--o{ customers : owns_or_assigned
    lead_pipeline_stages ||--o{ customers : current_stage
    customers ||--o{ customer_labels : uses
    customer_labels ||--o{ customer_label_links : applied_to
    customers ||--o{ customer_label_links : tagged
    customers ||--o{ customer_notes : has
    users ||--o{ customer_notes : writes
    customers ||--o{ customer_timeline_events : timeline
    users ||--o{ customer_timeline_events : creates
    businesses ||--o{ conversations : owns
    conversations ||--o{ messages : contains
    users ||--o{ messages : sends
    customers ||--o{ tasks : has
    customers ||--o{ reminders : gets
    customers ||--o{ appointments : books
    businesses ||--o{ audit_logs : records
    users ||--o{ audit_logs : acts
```

## Notes

- The full ERD reflects the complete PostgreSQL schema in `db/postgres/whatsflow_schema.sql`.
- The MVP ERD is the smallest useful operational core for the current delivery slice.
- Both diagrams are Mermaid-compatible and can be rendered directly in Markdown viewers that support Mermaid.
