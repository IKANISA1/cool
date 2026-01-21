-- ═══════════════════════════════════════════════════════════
-- OTP AUTHENTICATION SCHEMA
-- Phase 2: WhatsApp OTP Authentication
-- ═══════════════════════════════════════════════════════════

-- OTP verifications table
-- Stores hashed OTPs with expiry for secure verification
CREATE TABLE IF NOT EXISTS otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    otp_hash TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    device_id TEXT,
    attempts INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for quick lookups by phone and verification status
CREATE INDEX IF NOT EXISTS idx_otp_phone_verified 
    ON otp_verifications(phone, verified);

-- Index for expiry cleanup
CREATE INDEX IF NOT EXISTS idx_otp_expires_at 
    ON otp_verifications(expires_at);

-- ═══════════════════════════════════════════════════════════
-- RATE LIMITING
-- ═══════════════════════════════════════════════════════════

-- OTP attempts for rate limiting (5 per hour per phone)
CREATE TABLE IF NOT EXISTS otp_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for rate limiting queries
CREATE INDEX IF NOT EXISTS idx_otp_attempts_phone_created 
    ON otp_attempts(phone, created_at);

-- ═══════════════════════════════════════════════════════════
-- AUDIT TRAIL
-- ═══════════════════════════════════════════════════════════

-- Audit events for security logging
CREATE TABLE IF NOT EXISTS audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    event_type TEXT NOT NULL,
    event_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for querying events by user
CREATE INDEX IF NOT EXISTS idx_audit_user_id 
    ON audit_events(user_id);

-- Index for querying events by type
CREATE INDEX IF NOT EXISTS idx_audit_event_type 
    ON audit_events(event_type, created_at);

-- ═══════════════════════════════════════════════════════════
-- USERS TABLE (if not exists)
-- ═══════════════════════════════════════════════════════════

-- Application users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE REFERENCES auth.users(id),
    phone VARCHAR(20) UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    profile_completed BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for phone lookup
CREATE INDEX IF NOT EXISTS idx_users_phone 
    ON users(phone);

-- ═══════════════════════════════════════════════════════════
-- CLEANUP FUNCTION
-- ═══════════════════════════════════════════════════════════

-- Function to clean up expired OTP records
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
    -- Delete expired OTP verifications (older than 1 hour)
    DELETE FROM otp_verifications
    WHERE expires_at < NOW() - INTERVAL '1 hour';
    
    -- Delete old rate limiting records (older than 1 hour)
    DELETE FROM otp_attempts
    WHERE created_at < NOW() - INTERVAL '1 hour';
    
    -- Log cleanup
    RAISE NOTICE 'OTP cleanup completed at %', NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- UPDATED_AT TRIGGER
-- ═══════════════════════════════════════════════════════════

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for otp_verifications
DROP TRIGGER IF EXISTS update_otp_verifications_updated_at ON otp_verifications;
CREATE TRIGGER update_otp_verifications_updated_at
    BEFORE UPDATE ON otp_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can read own data" ON users
    FOR SELECT
    USING (auth.uid() = auth_id);

-- Users can update their own profile
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE
    USING (auth.uid() = auth_id)
    WITH CHECK (auth.uid() = auth_id);

-- Service role can manage all users
CREATE POLICY "Service role full access" ON users
    FOR ALL
    USING (auth.role() = 'service_role');

-- Enable RLS on audit_events (read-only for users)
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

-- Users can read their own audit events
CREATE POLICY "Users can read own audit events" ON audit_events
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can insert audit events
CREATE POLICY "Service role can manage audit events" ON audit_events
    FOR ALL
    USING (auth.role() = 'service_role');

-- ═══════════════════════════════════════════════════════════
-- SCHEDULED CLEANUP (requires pg_cron extension)
-- ═══════════════════════════════════════════════════════════

-- Note: Uncomment below after enabling pg_cron in Supabase Dashboard
-- SELECT cron.schedule(
--     'cleanup-expired-otps',
--     '*/15 * * * *',
--     $$SELECT cleanup_expired_otps()$$
-- );
