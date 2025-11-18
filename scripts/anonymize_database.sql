-- ============================================================================
-- Database Anonymization Script - Odoo Sh Compatible
-- ============================================================================
--
-- Purpose:
--   This script anonymizes sensitive data in your Odoo database, making it
--   safe to use production data in development environments.
--
--   Based on Odoo.sh documentation:
--   https://www.odoo.sh/documentation/user/advanced/security
--
-- What Gets Anonymized:
--   1. Partner/Customer names and contact information
--   2. User accounts (except admin for testing)
--   3. Email addresses and communication history
--   4. Security tokens, API keys, and authentication credentials
--   5. Mail server credentials
--   6. Bank account information
--   7. Message bodies and sensitive documents
--   8. User sessions and login history
--
-- What Is NOT Anonymized:
--   - Document metadata (kept for audit trail)
--   - Transaction records (important for accounting)
--   - Configuration data (needed for functionality)
--   - Module-specific data (only anonymized if module is installed)
--
-- Usage:
--   psql -U odoo -d your_database_name -f scripts/anonymize_database.sql
--
-- Safety:
--   - This script uses IF statements to handle missing tables
--   - Uncomment specific sections to apply only what you need
--   - Test on a copy of your database first!
--
-- ============================================================================

-- ============================================================================
-- SECTION 1: PARTNERS & CONTACTS
-- ============================================================================
-- Anonymize customer and partner contact information while preserving structure

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'res_partner') THEN
    -- Anonymize company partners
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
    WHERE type = 'invoice' OR type = 'delivery';

    -- Anonymize individual contacts
    UPDATE res_partner
    SET
        name = 'Contact ' || id,
        email = 'contact' || id || '@example.local',
        phone = '0000000000',
        mobile = NULL,
        function = NULL
    WHERE type = 'contact';
  END IF;
END $$;

-- ============================================================================
-- SECTION 2: USER ACCOUNTS & AUTHENTICATION
-- ============================================================================
-- Anonymize user information (keeping admin for testing)

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'res_users') THEN
    -- Reset all non-admin user logins and emails
    UPDATE res_users
    SET
        login = 'user' || id || '@local.test',
        email = 'user' || id || '@example.local',
        signature = '',
        phone = '0000000000',
        mobile_phone = NULL
    WHERE id > 1;  -- Preserve admin (id=1) for testing

    -- Clear 2FA and security settings
    UPDATE res_users
    SET
        totp_secret = NULL
    WHERE id > 1;
  END IF;
END $$;

-- ============================================================================
-- SECTION 3: SECURITY & API TOKENS
-- ============================================================================
-- Remove all API keys, tokens, and sensitive credentials

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ir_config_parameter') THEN
    -- Delete all security-related parameters
    DELETE FROM ir_config_parameter
    WHERE key LIKE '%token%'
       OR key LIKE '%key%'
       OR key LIKE '%secret%'
       OR key LIKE '%credential%'
       OR key LIKE '%password%'
       OR key LIKE '%api%';
  END IF;
END $$;

-- ============================================================================
-- SECTION 4: USER SESSIONS & LOGIN HISTORY
-- ============================================================================
-- Clear all active sessions and login logs

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ir_session') THEN
    DELETE FROM ir_session;
  END IF;

  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'res_users_log') THEN
    DELETE FROM res_users_log;
  END IF;
END $$;

-- ============================================================================
-- SECTION 5: MAIL SERVER CREDENTIALS
-- ============================================================================
-- Disable and anonymize mail server settings

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ir_mail_server') THEN
    UPDATE ir_mail_server
    SET
        active = FALSE,
        smtp_host = 'localhost',
        smtp_port = 587,
        smtp_user = NULL,
        smtp_pass = NULL,
        smtp_encryption = 'starttls',
        sequence = 999
    WHERE active = TRUE;
  END IF;
END $$;

-- ============================================================================
-- SECTION 6: EMAIL HISTORY & MESSAGES
-- ============================================================================
-- Anonymize historical emails and messages

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'mail_mail') THEN
    UPDATE mail_mail
    SET
        email_from = 'noreply@example.local',
        email_to = 'test@example.local',
        reply_to = NULL,
        message_id = NULL
    WHERE create_date < CURRENT_DATE - INTERVAL '1 day';
  END IF;

  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'mail_message') THEN
    UPDATE mail_message
    SET
        body = '<p>Message anonymized</p>',
        email_from = 'user@example.local',
        subject = 'Message ' || id
    WHERE create_date < CURRENT_DATE - INTERVAL '30 days'
      AND message_type = 'comment';
  END IF;
END $$;

-- ============================================================================
-- SECTION 7: BANK & PAYMENT INFORMATION (IF ACCOUNTING MODULE INSTALLED)
-- ============================================================================
-- Clear all bank account and payment details

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'res_partner_bank') THEN
    UPDATE res_partner_bank
    SET
        acc_number = '****',
        acc_holder_name = 'Account',
        sanitized_acc_number = '****';
  END IF;

  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'account_payment') THEN
    UPDATE account_payment
    SET
        communication = 'Payment ' || id,
        name = 'Payment ' || id;
  END IF;
END $$;

-- ============================================================================
-- SECTION 8: DOCUMENT ATTACHMENTS
-- ============================================================================
-- Anonymize attachment descriptions

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ir_attachment') THEN
    UPDATE ir_attachment
    SET
        description = NULL
    WHERE create_date < CURRENT_DATE - INTERVAL '7 days';
  END IF;
END $$;

-- ============================================================================
-- SECTION 9: HELPDESK TICKETS (IF HELPDESK MODULE INSTALLED)
-- ============================================================================
-- Anonymize support tickets and descriptions

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'helpdesk_ticket') THEN
    UPDATE helpdesk_ticket
    SET
        name = 'Ticket-' || id,
        description = 'Anonymized ticket',
        internal_note = NULL
    WHERE create_date < CURRENT_DATE - INTERVAL '30 days';
  END IF;
END $$;

-- ============================================================================
-- SECTION 10: CALENDAR & MEETINGS (IF CALENDAR MODULE INSTALLED)
-- ============================================================================
-- Clear meeting notes and sensitive calendar data

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'calendar_event') THEN
    UPDATE calendar_event
    SET
        description = NULL,
        location = NULL,
        summary = 'Meeting ' || id
    WHERE create_date < CURRENT_DATE - INTERVAL '30 days';
  END IF;
END $$;

-- ============================================================================
-- SECTION 11: WEBSITE FORMS (IF WEBSITE MODULE INSTALLED)
-- ============================================================================
-- Clear website visitor tracking

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'website_visitor') THEN
    TRUNCATE TABLE website_visitor CASCADE;
  END IF;

  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'website_form_visit') THEN
    TRUNCATE TABLE website_form_visit CASCADE;
  END IF;
END $$;

-- ============================================================================
-- SECTION 12: DATABASE OPTIMIZATION
-- ============================================================================
-- Clean up and optimize database after anonymization

VACUUM ANALYZE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Uncomment to verify anonymization results:
--
-- SELECT 'Partners anonymized' AS check_type, COUNT(*) as count
-- FROM res_partner WHERE email LIKE '%@example.local%';
--
-- SELECT 'Users anonymized' AS check_type, COUNT(*) as count
-- FROM res_users WHERE id > 1 AND login LIKE 'user%@local.test';
--
-- SELECT 'API tokens deleted' AS check_type, COUNT(*) as count
-- FROM ir_config_parameter WHERE key LIKE '%token%';

-- ============================================================================
-- END OF ANONYMIZATION SCRIPT
-- ============================================================================
