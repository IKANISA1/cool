-- ═══════════════════════════════════════════════════════════
-- REMOVE OTP AUTHENTICATION SCHEMA
-- Cleanup: WhatsApp OTP authentication has been removed
-- App now uses Supabase anonymous authentication only
-- ═══════════════════════════════════════════════════════════

-- Drop OTP-related tables (no longer used)
DROP TABLE IF EXISTS otp_verifications CASCADE;
DROP TABLE IF EXISTS otp_attempts CASCADE;

-- Drop OTP cleanup function
DROP FUNCTION IF EXISTS cleanup_expired_otps();

-- Note: The audit_events table is kept as it's still useful
-- for logging authentication and other security events.

-- Note: The users table is kept as it stores application
-- user data regardless of authentication method.
