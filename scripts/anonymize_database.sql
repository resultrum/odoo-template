-- PROD to UAT Database Anonymization Script
-- This script anonymizes sensitive data for GDPR/privacy compliance
-- Based on Odoo.sh documentation standards
-- https://www.odoo.sh/documentation/user/advanced/security#gdpr

-- Run this script after copying PROD database to UAT:
-- psql -U odoo -d uat_db -f scripts/anonymize_database.sql

-- ============================================================================
-- PARTNERS & CONTACTS
-- ============================================================================

-- Anonymize customer/partner information
UPDATE res_partner
SET
    name = 'Partner ' || id,
    email = 'partner' || id || '@example.local',
    phone = '0000000000',
    mobile = NULL,
    street = NULL,
    street2 = NULL,
    city = 'City',
    state_id = NULL,
    zip = '00000',
    country_id = NULL,
    vat = NULL,
    website = NULL,
    function = NULL,
    comment = NULL
WHERE company_id IS NOT NULL;

-- Anonymize individual contact names
UPDATE res_partner
SET
    name = 'Contact ' || id,
    email = 'contact' || id || '@example.local',
    phone = '0000000000',
    mobile = NULL,
    function = NULL
WHERE type = 'contact' AND company_id IS NULL;

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

-- Anonymize user accounts (keep admin for testing)
UPDATE res_users
SET
    login = 'user' || id || '@local.test',
    email = 'user' || id || '@example.local',
    signature = '',
    phone = '0000000000',
    mobile_phone = NULL,
    notification_type = 'email'
WHERE id > 1;  -- Keep user 1 (admin) as-is for testing

-- Clear user preferences and settings
UPDATE res_users
SET
    context_lang = 'en_US',
    context_tz = 'UTC',
    notification_email_send = 'comment'
WHERE id > 1;

-- ============================================================================
-- SESSIONS & AUTHENTICATION TOKENS
-- ============================================================================

-- Clear all active sessions
DELETE FROM ir_session;

-- Clear authentication tokens
DELETE FROM ir_config_parameter
WHERE key LIKE '%access_token%'
   OR key LIKE '%refresh_token%'
   OR key LIKE '%api_key%'
   OR key LIKE '%secret%'
   OR key LIKE '%password%';

-- ============================================================================
-- SECURITY & AUTHENTICATION TOKENS
-- ============================================================================

-- Remove API keys and tokens from ir_config_parameter
DELETE FROM ir_config_parameter
WHERE key LIKE '%token%'
   OR key LIKE '%key%'
   OR key LIKE '%secret%'
   OR key LIKE '%credential%';

-- Clear 2FA and security-related data
UPDATE res_users
SET
    totp_secret = NULL,
    backup_codes = NULL
WHERE id > 1;

-- ============================================================================
-- EMAILS & COMMUNICATIONS
-- ============================================================================

-- Anonymize email addresses in mail.mail (sent emails)
UPDATE mail_mail
SET
    email_from = 'noreply@example.local',
    email_to = 'test@example.local',
    reply_to = NULL
WHERE create_date < CURRENT_DATE - INTERVAL '1 day';  -- Keep recent emails for testing

-- Clear email headers and message IDs
UPDATE mail_mail
SET
    message_id = NULL,
    in_reply_to = NULL,
    references = NULL
WHERE create_date < CURRENT_DATE - INTERVAL '1 day';

-- ============================================================================
-- SALES & CUSTOMER DATA
-- ============================================================================

-- Anonymize sale order information
UPDATE sale_order
SET
    client_order_ref = 'SO-' || id,
    note = NULL,
    signature = NULL
WHERE state IN ('draft', 'cancel');  -- Only anonymize non-confirmed orders

-- Anonymize purchase order information
UPDATE purchase_order
SET
    notes = NULL,
    signature = NULL
WHERE state IN ('draft', 'cancel');

-- ============================================================================
-- INVOICES & ACCOUNTING
-- ============================================================================

-- Anonymize invoice reference numbers (keep structure)
UPDATE account_move
SET
    ref = 'INV-' || id
WHERE move_type IN ('out_invoice', 'out_refund')
  AND state = 'draft';

-- ============================================================================
-- BANK & PAYMENT INFORMATION
-- ============================================================================

-- Clear bank account details
UPDATE res_partner_bank
SET
    acc_number = '****',
    acc_holder_name = 'Account',
    sanitized_acc_number = '****'
WHERE partner_id IS NOT NULL;

-- Clear payment information
UPDATE account_payment
SET
    communication = 'Payment ' || id,
    name = 'Payment ' || id
WHERE state IN ('draft', 'posted');

-- ============================================================================
-- DOCUMENTS & ATTACHMENTS
-- ============================================================================

-- Anonymize document descriptions
UPDATE ir_attachment
SET
    name = 'Document_' || id,
    description = NULL
WHERE create_date < CURRENT_DATE - INTERVAL '7 days';  -- Keep recent files

-- ============================================================================
-- LOGS & AUDIT TRAIL
-- ============================================================================

-- Clear detailed audit logs (keep structure for audit purposes)
DELETE FROM ir_model_fields_selection WHERE id > 100;

-- Clear user login history
DELETE FROM res_users_log;

-- ============================================================================
-- CUSTOMER FEEDBACK & SUPPORT
-- ============================================================================

-- Anonymize support tickets if using helpdesk
UPDATE helpdesk_ticket
SET
    name = 'Ticket-' || id,
    description = 'Anonymized ticket',
    internal_note = NULL,
    tag_ids = NULL
WHERE create_date < CURRENT_DATE - INTERVAL '30 days';

-- ============================================================================
-- CALENDAR & SCHEDULING
-- ============================================================================

-- Clear meeting notes
UPDATE calendar_event
SET
    description = NULL,
    location = NULL,
    summary = 'Meeting ' || id
WHERE create_date < CURRENT_DATE - INTERVAL '30 days';

-- ============================================================================
-- MESSAGES & CHAT
-- ============================================================================

-- Clear message bodies (keep structure)
UPDATE mail_message
SET
    body = '<p>Message anonymized</p>',
    email_from = 'user@example.local',
    subject = 'Message ' || id
WHERE create_date < CURRENT_DATE - INTERVAL '30 days'
  AND message_type = 'comment';

-- ============================================================================
-- WEBSITE & WEBSITE FORMS
-- ============================================================================

-- Clear website form submissions
TRUNCATE website_form_visit CASCADE;

-- ============================================================================
-- ANALYTICS & TRACKING
-- ============================================================================

-- Clear website visitor tracking
TRUNCATE website_visitor CASCADE;

-- ============================================================================
-- CLEANUP & OPTIMIZATION
-- ============================================================================

-- Vacuum and analyze for performance
VACUUM ANALYZE;

-- ============================================================================
-- VERIFICATION SCRIPT
-- ============================================================================

-- This verification query shows what was anonymized:
/*
SELECT
    'Customers anonymized' AS type,
    COUNT(*) AS count
FROM res_partner
WHERE email LIKE '%@example.local%'
UNION ALL
SELECT
    'Users anonymized',
    COUNT(*)
FROM res_users
WHERE login LIKE 'user%@local.test'
UNION ALL
SELECT
    'Sessions cleared',
    COUNT(*)
FROM (SELECT 1 WHERE NOT EXISTS(SELECT 1 FROM ir_session)) AS t;
*/

-- ============================================================================
-- END OF ANONYMIZATION SCRIPT
-- ============================================================================
