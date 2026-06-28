-- WhatsFlow CRM PostgreSQL schema
-- Core SaaS schema for multi-tenant CRM, messaging, billing, and auditability.

CREATE SCHEMA IF NOT EXISTS whatsflow;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

SET search_path = whatsflow, public;

CREATE OR REPLACE FUNCTION whatsflow.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS businesses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    legal_name text,
    slug citext NOT NULL UNIQUE,
    tax_id text,
    gst_number text,
    timezone text NOT NULL DEFAULT 'Asia/Kolkata',
    currency_code char(3) NOT NULL DEFAULT 'INR',
    status text NOT NULL DEFAULT 'trial' CHECK (status IN ('trial', 'active', 'past_due', 'suspended', 'archived')),
    onboarding_completed_at timestamptz,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email citext NOT NULL UNIQUE,
    full_name text NOT NULL,
    phone_number text,
    password_hash text NOT NULL,
    is_system_admin boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    last_login_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS business_memberships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'invited' CHECK (status IN ('invited', 'active', 'suspended', 'left')),
    joined_at timestamptz,
    last_active_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_business_membership UNIQUE (business_id, user_id)
);

CREATE TABLE IF NOT EXISTS roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
    name text NOT NULL,
    scope text NOT NULL DEFAULT 'business' CHECK (scope IN ('system', 'business')),
    description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_roles_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code citext NOT NULL UNIQUE,
    description text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS membership_roles (
    membership_id uuid NOT NULL REFERENCES business_memberships(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (membership_id, role_id)
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS subscription_plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code citext NOT NULL UNIQUE,
    name text NOT NULL,
    billing_cycle text NOT NULL CHECK (billing_cycle IN ('monthly', 'annual')),
    monthly_price numeric(14,2) NOT NULL DEFAULT 0,
    annual_price numeric(14,2) NOT NULL DEFAULT 0,
    max_users integer,
    max_customers integer,
    features_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    plan_id uuid NOT NULL REFERENCES subscription_plans(id),
    status text NOT NULL DEFAULT 'trialing' CHECK (status IN ('trialing', 'active', 'past_due', 'canceled', 'expired')),
    billing_cycle text NOT NULL CHECK (billing_cycle IN ('monthly', 'annual')),
    started_at timestamptz NOT NULL DEFAULT now(),
    trial_ends_at timestamptz,
    renews_at timestamptz,
    canceled_at timestamptz,
    coupon_code text,
    gst_rate numeric(5,2) NOT NULL DEFAULT 18.00,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_subscription_business UNIQUE (business_id)
);

CREATE TABLE IF NOT EXISTS business_settings (
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    setting_key citext NOT NULL,
    setting_value text NOT NULL,
    updated_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (business_id, setting_key)
);

CREATE TABLE IF NOT EXISTS integrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    provider text NOT NULL CHECK (provider IN ('whatsapp', 'email', 'sms', 'openai', 'razorpay', 'stripe', 'firebase')),
    name text NOT NULL,
    status text NOT NULL DEFAULT 'inactive' CHECK (status IN ('inactive', 'active', 'error', 'disabled')),
    external_account_id text,
    config_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    secrets_json_encrypted bytea,
    last_synced_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_integrations_business_provider_name UNIQUE (business_id, provider, name)
);

CREATE TABLE IF NOT EXISTS lead_pipeline_stages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name text NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    is_default boolean NOT NULL DEFAULT false,
    is_closed_won boolean NOT NULL DEFAULT false,
    is_closed_lost boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_stages_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS customers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    assigned_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    current_stage_id uuid REFERENCES lead_pipeline_stages(id) ON DELETE SET NULL,
    display_name text NOT NULL,
    company_name text,
    phone_number text,
    whatsapp_number text,
    email citext,
    city text,
    state text,
    source_channel text CHECK (source_channel IN ('manual', 'whatsapp', 'instagram', 'facebook', 'website', 'call', 'referral', 'other')),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('lead', 'active', 'inactive', 'blocked')),
    lead_status text NOT NULL DEFAULT 'new' CHECK (lead_status IN ('new', 'qualified', 'proposal', 'won', 'lost')),
    last_contacted_at timestamptz,
    next_follow_up_at timestamptz,
    lost_reason text,
    notes_summary text,
    external_reference text,
    metadata_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_customers_business_phone UNIQUE (business_id, phone_number)
);

CREATE INDEX IF NOT EXISTS ix_customers_business_name ON customers (business_id, display_name);
CREATE INDEX IF NOT EXISTS ix_customers_business_status ON customers (business_id, status);
CREATE INDEX IF NOT EXISTS ix_customers_business_stage ON customers (business_id, current_stage_id);
CREATE INDEX IF NOT EXISTS ix_customers_next_follow_up_at ON customers (business_id, next_follow_up_at);

CREATE TABLE IF NOT EXISTS customer_labels (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name text NOT NULL,
    color_hex char(7) NOT NULL DEFAULT '#1f9d55',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_customer_labels_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS customer_label_links (
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    label_id uuid NOT NULL REFERENCES customer_labels(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, label_id)
);

CREATE TABLE IF NOT EXISTS customer_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    author_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    note_text text NOT NULL,
    is_pinned boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_stage_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    from_stage_id uuid REFERENCES lead_pipeline_stages(id) ON DELETE SET NULL,
    to_stage_id uuid REFERENCES lead_pipeline_stages(id) ON DELETE SET NULL,
    changed_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    reason text,
    changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_timeline_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    event_type text NOT NULL,
    subject text NOT NULL,
    body text,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_customer_timeline_events_business_customer_time ON customer_timeline_events (business_id, customer_id, occurred_at DESC);

CREATE TABLE IF NOT EXISTS conversations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    assigned_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    provider text NOT NULL CHECK (provider IN ('whatsapp', 'email', 'sms', 'manual')),
    provider_thread_id text,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'pending', 'resolved', 'archived')),
    last_message_at timestamptz,
    unread_count integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_conversation_provider_thread UNIQUE (provider, provider_thread_id)
);

CREATE INDEX IF NOT EXISTS ix_conversations_business_customer ON conversations (business_id, customer_id);
CREATE INDEX IF NOT EXISTS ix_conversations_business_status_last_message ON conversations (business_id, status, last_message_at DESC);

CREATE TABLE IF NOT EXISTS file_uploads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    uploaded_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    file_name text NOT NULL,
    storage_provider text NOT NULL DEFAULT 'local',
    storage_key text NOT NULL,
    content_type text,
    byte_size bigint NOT NULL DEFAULT 0,
    checksum_sha256 text,
    purpose text,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    direction text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    message_type text NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'audio', 'video', 'template', 'system')),
    body_text text,
    media_url text,
    provider_message_id text,
    sent_at timestamptz,
    delivered_at timestamptz,
    read_at timestamptz,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_messages_provider_message_id UNIQUE (provider_message_id)
);

CREATE INDEX IF NOT EXISTS ix_messages_business_conversation_sent_at ON messages (business_id, conversation_id, sent_at DESC);

CREATE TABLE IF NOT EXISTS message_attachments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    message_id uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    file_upload_id uuid NOT NULL REFERENCES file_uploads(id) ON DELETE CASCADE,
    attachment_type text NOT NULL DEFAULT 'file' CHECK (attachment_type IN ('file', 'image', 'video', 'audio', 'document')),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_message_attachments UNIQUE (message_id, file_upload_id)
);

CREATE TABLE IF NOT EXISTS templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    provider_template_id text,
    name text NOT NULL,
    category text,
    language_code text NOT NULL DEFAULT 'en',
    body_text text NOT NULL,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'approved', 'rejected', 'archived')),
    variable_count integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_templates_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS template_variables (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id uuid NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    variable_key text NOT NULL,
    sample_value text,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_template_variables UNIQUE (template_id, variable_key)
);

CREATE TABLE IF NOT EXISTS tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
    conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
    assigned_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'done', 'canceled')),
    priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    due_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_tasks_business_due_at ON tasks (business_id, due_at);
CREATE INDEX IF NOT EXISTS ix_tasks_business_status_assignee ON tasks (business_id, status, assigned_to_user_id);

CREATE TABLE IF NOT EXISTS reminders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    task_id uuid REFERENCES tasks(id) ON DELETE SET NULL,
    customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    delivery_channel text NOT NULL CHECK (delivery_channel IN ('whatsapp', 'email', 'sms', 'push')),
    reminder_at timestamptz NOT NULL,
    status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'queued', 'sent', 'failed', 'canceled')),
    sent_at timestamptz,
    delivery_status text,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_reminders_business_reminder_at ON reminders (business_id, reminder_at);
CREATE INDEX IF NOT EXISTS ix_reminders_business_status ON reminders (business_id, status);

CREATE TABLE IF NOT EXISTS appointments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
    assigned_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    start_at timestamptz NOT NULL,
    end_at timestamptz NOT NULL,
    location text,
    status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'canceled', 'no_show')),
    reminder_minutes_before integer NOT NULL DEFAULT 30,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_appointments_business_start_at ON appointments (business_id, start_at);

CREATE TABLE IF NOT EXISTS products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    sku text,
    name text NOT NULL,
    description text,
    unit_price numeric(14,2) NOT NULL DEFAULT 0,
    tax_rate numeric(5,2) NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_products_business_sku UNIQUE (business_id, sku)
);

CREATE TABLE IF NOT EXISTS services (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    sku text,
    name text NOT NULL,
    description text,
    rate numeric(14,2) NOT NULL DEFAULT 0,
    tax_rate numeric(5,2) NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_services_business_sku UNIQUE (business_id, sku)
);

CREATE TABLE IF NOT EXISTS quotations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    quoted_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    quote_number text NOT NULL,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'expired', 'cancelled')),
    issue_date date NOT NULL DEFAULT current_date,
    expiry_date date,
    subtotal numeric(14,2) NOT NULL DEFAULT 0,
    tax_amount numeric(14,2) NOT NULL DEFAULT 0,
    discount_amount numeric(14,2) NOT NULL DEFAULT 0,
    total_amount numeric(14,2) NOT NULL DEFAULT 0,
    notes text,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_quotations_business_number UNIQUE (business_id, quote_number)
);

CREATE TABLE IF NOT EXISTS quotation_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_id uuid NOT NULL REFERENCES quotations(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE SET NULL,
    service_id uuid REFERENCES services(id) ON DELETE SET NULL,
    description text NOT NULL,
    quantity numeric(14,2) NOT NULL DEFAULT 1,
    unit_price numeric(14,2) NOT NULL DEFAULT 0,
    tax_rate numeric(5,2) NOT NULL DEFAULT 0,
    line_total numeric(14,2) NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    quotation_id uuid REFERENCES quotations(id) ON DELETE SET NULL,
    invoice_number text NOT NULL,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'part_paid', 'paid', 'overdue', 'void')),
    issue_date date NOT NULL DEFAULT current_date,
    due_date date,
    subtotal numeric(14,2) NOT NULL DEFAULT 0,
    tax_amount numeric(14,2) NOT NULL DEFAULT 0,
    discount_amount numeric(14,2) NOT NULL DEFAULT 0,
    total_amount numeric(14,2) NOT NULL DEFAULT 0,
    balance_due numeric(14,2) NOT NULL DEFAULT 0,
    currency_code char(3) NOT NULL DEFAULT 'INR',
    notes text,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_invoices_business_number UNIQUE (business_id, invoice_number)
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE SET NULL,
    service_id uuid REFERENCES services(id) ON DELETE SET NULL,
    description text NOT NULL,
    quantity numeric(14,2) NOT NULL DEFAULT 1,
    unit_price numeric(14,2) NOT NULL DEFAULT 0,
    tax_rate numeric(5,2) NOT NULL DEFAULT 0,
    line_total numeric(14,2) NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    payment_reference text,
    provider text NOT NULL CHECK (provider IN ('razorpay', 'stripe', 'cash', 'bank_transfer', 'upi', 'other')),
    method text,
    amount numeric(14,2) NOT NULL DEFAULT 0,
    currency_code char(3) NOT NULL DEFAULT 'INR',
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded', 'partially_refunded')),
    paid_at timestamptz,
    raw_payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS broadcast_campaigns (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    template_id uuid REFERENCES templates(id) ON DELETE SET NULL,
    name text NOT NULL,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed', 'cancelled')),
    audience_count integer NOT NULL DEFAULT 0,
    scheduled_at timestamptz,
    sent_at timestamptz,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_broadcast_campaign_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS broadcast_recipients (
    campaign_id uuid NOT NULL REFERENCES broadcast_campaigns(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    message_id uuid REFERENCES messages(id) ON DELETE SET NULL,
    delivery_status text NOT NULL DEFAULT 'queued' CHECK (delivery_status IN ('queued', 'sent', 'failed', 'delivered', 'read')),
    delivered_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (campaign_id, customer_id)
);

CREATE TABLE IF NOT EXISTS notification_deliveries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    channel text NOT NULL CHECK (channel IN ('in_app', 'email', 'sms', 'whatsapp', 'push')),
    title text NOT NULL,
    body text,
    status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'delivered', 'failed', 'read')),
    scheduled_at timestamptz,
    sent_at timestamptz,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS support_tickets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    assigned_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    ticket_number text NOT NULL,
    subject text NOT NULL,
    description text,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'waiting_customer', 'resolved', 'closed')),
    priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    source text NOT NULL DEFAULT 'portal' CHECK (source IN ('portal', 'email', 'whatsapp', 'api', 'system')),
    closed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_support_tickets_business_number UNIQUE (business_id, ticket_number)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
    actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    severity text NOT NULL DEFAULT 'info' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
    old_values jsonb NOT NULL DEFAULT '{}'::jsonb,
    new_values jsonb NOT NULL DEFAULT '{}'::jsonb,
    ip_address inet,
    user_agent text,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_audit_logs_business_occurred_at ON audit_logs (business_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS ix_audit_logs_entity_lookup ON audit_logs (entity_type, entity_id, occurred_at DESC);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
    token_hash text NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    replaced_by_token_id uuid REFERENCES refresh_tokens(id) ON DELETE SET NULL,
    ip_address inet,
    user_agent text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_refresh_tokens_user_expires ON refresh_tokens (user_id, expires_at DESC);

CREATE TABLE IF NOT EXISTS document_sequences (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    document_type text NOT NULL CHECK (document_type IN ('quotation', 'invoice', 'support_ticket', 'broadcast_campaign')),
    prefix text NOT NULL,
    next_number bigint NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_document_sequences_business_type UNIQUE (business_id, document_type)
);

CREATE TABLE IF NOT EXISTS customer_lead_scores (
    customer_id uuid PRIMARY KEY REFERENCES customers(id) ON DELETE CASCADE,
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    current_score integer NOT NULL DEFAULT 0,
    score_band text NOT NULL DEFAULT 'cold' CHECK (score_band IN ('cold', 'warm', 'hot', 'critical')),
    last_calculated_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lead_score_rules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name text NOT NULL,
    rule_type text NOT NULL CHECK (rule_type IN ('stage', 'task', 'reminder', 'message', 'appointment', 'note')),
    score_delta integer NOT NULL DEFAULT 0,
    criteria_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_lead_score_rules_business_name UNIQUE (business_id, name)
);

CREATE TABLE IF NOT EXISTS lead_score_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    source_type text NOT NULL,
    score_delta integer NOT NULL,
    reason text NOT NULL,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_assistant_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
    title text NOT NULL,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_assistant_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES ai_assistant_sessions(id) ON DELETE CASCADE,
    sender_role text NOT NULL CHECK (sender_role IN ('user', 'assistant', 'system')),
    content text NOT NULL,
    payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS faq_entries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    question text NOT NULL,
    answer text NOT NULL,
    tags text[] NOT NULL DEFAULT '{}'::text[],
    is_active boolean NOT NULL DEFAULT true,
    created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_faq_entries_business_active ON faq_entries (business_id, is_active);

CREATE TABLE IF NOT EXISTS settings_audit_trail (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    setting_key citext NOT NULL,
    old_value text,
    new_value text,
    changed_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_settings_audit_trail_business_changed_at ON settings_audit_trail (business_id, changed_at DESC);

CREATE TABLE IF NOT EXISTS customer_task_links (
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, task_id)
);

CREATE TABLE IF NOT EXISTS customer_reminder_links (
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    reminder_id uuid NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, reminder_id)
);

CREATE TABLE IF NOT EXISTS customer_appointment_links (
    customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, appointment_id)
);

CREATE OR REPLACE FUNCTION whatsflow.log_audit_event(
    p_business_id uuid,
    p_actor_user_id uuid,
    p_action text,
    p_entity_type text,
    p_entity_id uuid,
    p_severity text DEFAULT 'info',
    p_old_values jsonb DEFAULT '{}'::jsonb,
    p_new_values jsonb DEFAULT '{}'::jsonb,
    p_ip_address inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_audit_id uuid;
BEGIN
    INSERT INTO whatsflow.audit_logs (
        business_id,
        actor_user_id,
        action,
        entity_type,
        entity_id,
        severity,
        old_values,
        new_values,
        ip_address,
        user_agent
    )
    VALUES (
        p_business_id,
        p_actor_user_id,
        p_action,
        p_entity_type,
        p_entity_id,
        p_severity,
        COALESCE(p_old_values, '{}'::jsonb),
        COALESCE(p_new_values, '{}'::jsonb),
        p_ip_address,
        p_user_agent
    )
    RETURNING id INTO v_audit_id;

    RETURN v_audit_id;
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.create_business_with_owner(
    p_business_name text,
    p_business_slug text,
    p_owner_email citext,
    p_owner_full_name text,
    p_owner_password_hash text,
    p_owner_phone_number text DEFAULT NULL,
    p_timezone text DEFAULT 'Asia/Kolkata',
    p_currency_code char(3) DEFAULT 'INR'
)
RETURNS TABLE (
    business_id uuid,
    user_id uuid,
    membership_id uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_business_id uuid;
    v_user_id uuid;
    v_membership_id uuid;
    v_role_id uuid;
BEGIN
    INSERT INTO whatsflow.businesses (name, slug, timezone, currency_code, status)
    VALUES (p_business_name, p_business_slug, p_timezone, p_currency_code, 'trial')
    RETURNING id INTO v_business_id;

    INSERT INTO whatsflow.users (email, full_name, phone_number, password_hash, is_system_admin, is_active)
    VALUES (p_owner_email, p_owner_full_name, p_owner_phone_number, p_owner_password_hash, false, true)
    ON CONFLICT (email)
    DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        password_hash = EXCLUDED.password_hash,
        updated_at = now()
    RETURNING id INTO v_user_id;

    INSERT INTO whatsflow.business_memberships (business_id, user_id, status, joined_at)
    VALUES (v_business_id, v_user_id, 'active', now())
    RETURNING id INTO v_membership_id;

    INSERT INTO whatsflow.roles (business_id, name, scope, description)
    VALUES (v_business_id, 'Owner', 'business', 'Business owner role')
    RETURNING id INTO v_role_id;

    INSERT INTO whatsflow.membership_roles (membership_id, role_id)
    VALUES (v_membership_id, v_role_id);

    RETURN QUERY SELECT v_business_id, v_user_id, v_membership_id;
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.create_customer_timeline_event(
    p_business_id uuid,
    p_customer_id uuid,
    p_event_type text,
    p_subject text,
    p_body text DEFAULT NULL,
    p_payload jsonb DEFAULT '{}'::jsonb,
    p_created_by_user_id uuid DEFAULT NULL,
    p_occurred_at timestamptz DEFAULT now()
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_event_id uuid;
BEGIN
    INSERT INTO whatsflow.customer_timeline_events (
        business_id,
        customer_id,
        event_type,
        subject,
        body,
        payload_json,
        created_by_user_id,
        occurred_at
    )
    VALUES (
        p_business_id,
        p_customer_id,
        p_event_type,
        p_subject,
        p_body,
        COALESCE(p_payload, '{}'::jsonb),
        p_created_by_user_id,
        p_occurred_at
    )
    RETURNING id INTO v_event_id;

    UPDATE whatsflow.customers
    SET last_contacted_at = GREATEST(COALESCE(last_contacted_at, p_occurred_at), p_occurred_at)
    WHERE id = p_customer_id;

    RETURN v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.move_customer_stage(
    p_customer_id uuid,
    p_new_stage_id uuid,
    p_changed_by_user_id uuid DEFAULT NULL,
    p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_business_id uuid;
    v_old_stage_id uuid;
BEGIN
    SELECT business_id, current_stage_id
    INTO v_business_id, v_old_stage_id
    FROM whatsflow.customers
    WHERE id = p_customer_id;

    UPDATE whatsflow.customers
    SET current_stage_id = p_new_stage_id,
        lead_status = CASE
            WHEN EXISTS (
                SELECT 1
                FROM whatsflow.lead_pipeline_stages
                WHERE id = p_new_stage_id AND is_closed_won
            ) THEN 'won'
            WHEN EXISTS (
                SELECT 1
                FROM whatsflow.lead_pipeline_stages
                WHERE id = p_new_stage_id AND is_closed_lost
            ) THEN 'lost'
            ELSE 'qualified'
        END
    WHERE id = p_customer_id;

    INSERT INTO whatsflow.customer_stage_history (
        business_id,
        customer_id,
        from_stage_id,
        to_stage_id,
        changed_by_user_id,
        reason,
        changed_at
    )
    VALUES (
        v_business_id,
        p_customer_id,
        v_old_stage_id,
        p_new_stage_id,
        p_changed_by_user_id,
        p_reason,
        now()
    );
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.upsert_business_setting(
    p_business_id uuid,
    p_setting_key citext,
    p_setting_value text,
    p_changed_by_user_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO whatsflow.business_settings (business_id, setting_key, setting_value, updated_by_user_id)
    VALUES (p_business_id, p_setting_key, p_setting_value, p_changed_by_user_id)
    ON CONFLICT (business_id, setting_key)
    DO UPDATE SET
        setting_value = EXCLUDED.setting_value,
        updated_by_user_id = EXCLUDED.updated_by_user_id,
        updated_at = now();

    INSERT INTO whatsflow.settings_audit_trail (
        business_id,
        setting_key,
        old_value,
        new_value,
        changed_by_user_id,
        changed_at
    )
    VALUES (
        p_business_id,
        p_setting_key,
        NULL,
        p_setting_value,
        p_changed_by_user_id,
        now()
    );
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.next_document_number(
    p_business_id uuid,
    p_document_type text,
    p_prefix text
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_next_number bigint;
    v_prefix text;
BEGIN
    INSERT INTO whatsflow.document_sequences (business_id, document_type, prefix, next_number)
    VALUES (p_business_id, p_document_type, p_prefix, 1)
    ON CONFLICT (business_id, document_type)
    DO UPDATE SET next_number = whatsflow.document_sequences.next_number + 1
    RETURNING next_number, prefix INTO v_next_number, v_prefix;

    RETURN format('%s-%s-%s', v_prefix, to_char(current_date, 'YYYYMM'), lpad(v_next_number::text, 5, '0'));
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.recalculate_customer_lead_score(
    p_customer_id uuid
)
RETURNS TABLE (
    current_score integer,
    score_band text,
    calculated_at timestamptz
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_business_id uuid;
    v_stage_id uuid;
    v_score integer := 50;
    v_last_contacted_at timestamptz;
    v_open_tasks integer := 0;
    v_band text;
BEGIN
    SELECT business_id, current_stage_id, last_contacted_at
    INTO v_business_id, v_stage_id, v_last_contacted_at
    FROM whatsflow.customers
    WHERE id = p_customer_id;

    SELECT COUNT(*)
    INTO v_open_tasks
    FROM whatsflow.tasks
    WHERE customer_id = p_customer_id
      AND status IN ('open', 'in_progress');

    IF v_stage_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM whatsflow.lead_pipeline_stages WHERE id = v_stage_id AND is_closed_won) THEN
            v_score := v_score + 30;
        ELSIF EXISTS (SELECT 1 FROM whatsflow.lead_pipeline_stages WHERE id = v_stage_id AND is_closed_lost) THEN
            v_score := v_score - 40;
        ELSE
            v_score := v_score + 10;
        END IF;
    END IF;

    IF v_last_contacted_at IS NULL THEN
        v_score := v_score - 10;
    ELSIF v_last_contacted_at >= now() - interval '3 days' THEN
        v_score := v_score + 15;
    ELSIF v_last_contacted_at <= now() - interval '14 days' THEN
        v_score := v_score - 15;
    END IF;

    v_score := v_score - (v_open_tasks * 3);
    v_score := GREATEST(0, LEAST(100, v_score));

    v_band := CASE
        WHEN v_score >= 85 THEN 'critical'
        WHEN v_score >= 70 THEN 'hot'
        WHEN v_score >= 45 THEN 'warm'
        ELSE 'cold'
    END;

    INSERT INTO whatsflow.customer_lead_scores (
        customer_id,
        business_id,
        current_score,
        score_band,
        last_calculated_at,
        updated_at
    )
    VALUES (
        p_customer_id,
        v_business_id,
        v_score,
        v_band,
        now(),
        now()
    )
    ON CONFLICT (customer_id)
    DO UPDATE SET
        business_id = EXCLUDED.business_id,
        current_score = EXCLUDED.current_score,
        score_band = EXCLUDED.score_band,
        last_calculated_at = EXCLUDED.last_calculated_at,
        updated_at = EXCLUDED.updated_at;

    RETURN QUERY SELECT v_score, v_band, now();
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.get_dashboard_metrics(
    p_business_id uuid
)
RETURNS TABLE (
    today_followups integer,
    upcoming_appointments integer,
    monthly_revenue numeric(14,2),
    pending_payments numeric(14,2),
    active_customers integer,
    new_leads integer,
    broadcast_status text,
    lead_conversion_rate numeric(5,2),
    customer_growth_rate numeric(5,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_month_start timestamptz := date_trunc('month', now());
    v_next_month_start timestamptz := date_trunc('month', now()) + interval '1 month';
    v_previous_month_start timestamptz := date_trunc('month', now()) - interval '1 month';
    v_previous_month_end timestamptz := date_trunc('month', now());
    v_broadcast_status text;
    v_won integer;
    v_closed integer;
    v_current_month_customers integer;
    v_previous_month_customers integer;
BEGIN
    SELECT COALESCE(string_agg(status || ': ' || count::text, ', '), 'No campaigns yet')
    INTO v_broadcast_status
    FROM (
        SELECT status, COUNT(*)
        FROM whatsflow.broadcast_campaigns
        WHERE business_id = p_business_id
        GROUP BY status
        ORDER BY status
    ) s(status, count);

    SELECT COUNT(*)
    INTO v_won
    FROM whatsflow.customers
    WHERE business_id = p_business_id AND lead_status = 'won';

    SELECT COUNT(*)
    INTO v_closed
    FROM whatsflow.customers
    WHERE business_id = p_business_id AND lead_status IN ('won', 'lost');

    SELECT COUNT(*)
    INTO v_current_month_customers
    FROM whatsflow.customers
    WHERE business_id = p_business_id
      AND created_at >= v_current_month_start
      AND created_at < v_next_month_start;

    SELECT COUNT(*)
    INTO v_previous_month_customers
    FROM whatsflow.customers
    WHERE business_id = p_business_id
      AND created_at >= v_previous_month_start
      AND created_at < v_previous_month_end;

    RETURN QUERY
    SELECT
        (
            SELECT COUNT(*)
            FROM whatsflow.tasks
            WHERE business_id = p_business_id
              AND status IN ('open', 'in_progress')
              AND due_at::date = current_date
        ) AS today_followups,
        (
            SELECT COUNT(*)
            FROM whatsflow.appointments
            WHERE business_id = p_business_id
              AND status IN ('scheduled', 'confirmed')
              AND start_at >= now()
              AND start_at < now() + interval '7 days'
        ) AS upcoming_appointments,
        COALESCE((
            SELECT SUM(total_amount)
            FROM whatsflow.invoices
            WHERE business_id = p_business_id
              AND status IN ('paid', 'part_paid')
              AND issue_date >= current_date - interval '30 days'
        ), 0)::numeric(14,2) AS monthly_revenue,
        COALESCE((
            SELECT SUM(balance_due)
            FROM whatsflow.invoices
            WHERE business_id = p_business_id
              AND status IN ('sent', 'part_paid', 'overdue')
        ), 0)::numeric(14,2) AS pending_payments,
        (
            SELECT COUNT(*)
            FROM whatsflow.customers
            WHERE business_id = p_business_id
              AND status = 'active'
        ) AS active_customers,
        (
            SELECT COUNT(*)
            FROM whatsflow.customers
            WHERE business_id = p_business_id
              AND lead_status = 'new'
              AND created_at >= current_date - interval '30 days'
        ) AS new_leads,
        v_broadcast_status AS broadcast_status,
        CASE
            WHEN v_closed = 0 THEN 0
            ELSE ROUND((v_won::numeric * 100.0) / v_closed, 2)
        END AS lead_conversion_rate,
        CASE
            WHEN v_previous_month_customers = 0 THEN
                CASE
                    WHEN v_current_month_customers = 0 THEN 0
                    ELSE 100
                END
            ELSE ROUND(((v_current_month_customers - v_previous_month_customers)::numeric * 100.0) / v_previous_month_customers, 2)
        END AS customer_growth_rate;
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.get_recent_customers(
    p_business_id uuid,
    p_limit integer DEFAULT 5
)
RETURNS TABLE (
    id uuid,
    display_name text,
    company_name text,
    city text,
    phone_number text,
    status text,
    last_contacted_at timestamptz,
    labels text[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.display_name,
        c.company_name,
        c.city,
        c.phone_number,
        c.status,
        c.last_contacted_at,
        COALESCE(array_agg(cl.name ORDER BY cl.name) FILTER (WHERE cl.name IS NOT NULL), '{}'::text[]) AS labels
    FROM whatsflow.customers c
    LEFT JOIN whatsflow.customer_label_links cll ON cll.customer_id = c.id
    LEFT JOIN whatsflow.customer_labels cl ON cl.id = cll.label_id
    WHERE c.business_id = p_business_id
    GROUP BY c.id
    ORDER BY c.updated_at DESC, c.created_at DESC
    LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION whatsflow.get_recent_activities(
    p_business_id uuid,
    p_limit integer DEFAULT 10
)
RETURNS TABLE (
    message text,
    occurred_at timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.subject || COALESCE(': ' || e.body, '') AS message,
        e.occurred_at
    FROM whatsflow.customer_timeline_events e
    WHERE e.business_id = p_business_id
    ORDER BY e.occurred_at DESC
    LIMIT p_limit;
END;
$$;

DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'businesses',
        'users',
        'business_memberships',
        'roles',
        'subscriptions',
        'business_settings',
        'integrations',
        'lead_pipeline_stages',
        'customers',
        'customer_labels',
        'customer_notes',
        'customer_timeline_events',
        'conversations',
        'file_uploads',
        'messages',
        'templates',
        'tasks',
        'reminders',
        'appointments',
        'products',
        'services',
        'quotations',
        'invoices',
        'payments',
        'broadcast_campaigns',
        'notification_deliveries',
        'support_tickets',
        'document_sequences',
        'customer_lead_scores',
        'lead_score_rules',
        'ai_assistant_sessions',
        'faq_entries'
    ]
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_updated_at ON whatsflow.%I;', t, t);
        EXECUTE format('CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON whatsflow.%I FOR EACH ROW EXECUTE FUNCTION whatsflow.touch_updated_at();', t, t);
    END LOOP;
END $$;

CREATE INDEX IF NOT EXISTS ix_business_memberships_business_status ON business_memberships (business_id, status);
CREATE INDEX IF NOT EXISTS ix_roles_business_scope ON roles (business_id, scope);
CREATE INDEX IF NOT EXISTS ix_customers_business_lead_status ON customers (business_id, lead_status);
CREATE INDEX IF NOT EXISTS ix_customers_business_contacted_at ON customers (business_id, last_contacted_at DESC);
CREATE INDEX IF NOT EXISTS ix_customer_notes_business_customer_created ON customer_notes (business_id, customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_conversations_business_provider ON conversations (business_id, provider);
CREATE INDEX IF NOT EXISTS ix_tasks_business_customer_due ON tasks (business_id, customer_id, due_at);
CREATE INDEX IF NOT EXISTS ix_reminders_business_customer_due ON reminders (business_id, customer_id, reminder_at);
CREATE INDEX IF NOT EXISTS ix_invoices_business_status_date ON invoices (business_id, status, issue_date DESC);
CREATE INDEX IF NOT EXISTS ix_quotations_business_status_date ON quotations (business_id, status, issue_date DESC);
CREATE INDEX IF NOT EXISTS ix_payments_business_invoice_paid_at ON payments (business_id, invoice_id, paid_at DESC);
CREATE INDEX IF NOT EXISTS ix_broadcast_campaigns_business_status ON broadcast_campaigns (business_id, status);
CREATE INDEX IF NOT EXISTS ix_support_tickets_business_status ON support_tickets (business_id, status);
CREATE INDEX IF NOT EXISTS ix_customer_lead_scores_business_score ON customer_lead_scores (business_id, current_score DESC);
CREATE INDEX IF NOT EXISTS ix_lead_score_events_business_customer_created ON lead_score_events (business_id, customer_id, created_at DESC);

-- Helpful views for reporting and API projection.
CREATE OR REPLACE VIEW whatsflow.v_customer_summary AS
SELECT
    c.id,
    c.business_id,
    c.display_name,
    c.company_name,
    c.phone_number,
    c.whatsapp_number,
    c.email,
    c.city,
    c.state,
    c.status,
    c.lead_status,
    c.last_contacted_at,
    c.next_follow_up_at,
    c.updated_at
FROM whatsflow.customers c;

CREATE OR REPLACE VIEW whatsflow.v_dashboard_metrics AS
SELECT
    b.id AS business_id,
    m.today_followups,
    m.upcoming_appointments,
    m.monthly_revenue,
    m.pending_payments,
    m.active_customers,
    m.new_leads,
    m.broadcast_status,
    m.lead_conversion_rate,
    m.customer_growth_rate
FROM whatsflow.businesses b
CROSS JOIN LATERAL whatsflow.get_dashboard_metrics(b.id) m;

COMMENT ON SCHEMA whatsflow IS 'WhatsFlow CRM multi-tenant PostgreSQL schema.';
COMMENT ON TABLE businesses IS 'Tenant/business profile and lifecycle.';
COMMENT ON TABLE users IS 'Global login identities.';
COMMENT ON TABLE business_memberships IS 'Business-specific access for a user.';
COMMENT ON TABLE customers IS 'Tenant-scoped customer and lead master record.';
COMMENT ON TABLE customer_timeline_events IS 'Immutable customer activity feed.';
COMMENT ON TABLE audit_logs IS 'Immutable security and operational audit trail.';
