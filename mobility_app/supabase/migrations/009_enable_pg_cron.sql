-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION: Enable pg_cron for automatic request expiration
-- Run this in Supabase SQL Editor or Dashboard
-- ═══════════════════════════════════════════════════════════════════════

-- Enable pg_cron extension (requires Dashboard activation first)
-- Note: pg_cron must be enabled in Supabase Dashboard > Database > Extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant cron schema usage to postgres
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

-- ═══════════════════════════════════════════════════════════════════════
-- CRON JOB: Expire pending ride requests after 60 seconds
-- Runs every minute to check for expired requests
-- ═══════════════════════════════════════════════════════════════════════

-- Clean up any existing job with same name
SELECT cron.unschedule('expire-ride-requests')
WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'expire-ride-requests'
);

-- Schedule the job to run every minute
SELECT cron.schedule(
    'expire-ride-requests',           -- Job name
    '* * * * *',                      -- Every minute
    $$
    UPDATE ride_requests
    SET status = 'expired',
        responded_at = NOW()
    WHERE status = 'pending'
    AND expires_at < NOW();
    $$
);

-- ═══════════════════════════════════════════════════════════════════════
-- CRON JOB: Clean up old audit events (older than 90 days)
-- Runs daily at 3 AM UTC
-- ═══════════════════════════════════════════════════════════════════════

-- Clean up any existing job with same name  
SELECT cron.unschedule('cleanup-audit-events')
WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'cleanup-audit-events'
);

-- Schedule daily cleanup
SELECT cron.schedule(
    'cleanup-audit-events',
    '0 3 * * *',                      -- 3 AM UTC daily
    $$
    DELETE FROM audit_events
    WHERE created_at < NOW() - INTERVAL '90 days';
    $$
);

-- ═══════════════════════════════════════════════════════════════════════
-- CRON JOB: Set stale presence to offline (no heartbeat for 5 minutes)
-- Runs every 5 minutes
-- ═══════════════════════════════════════════════════════════════════════

-- Clean up any existing job with same name
SELECT cron.unschedule('stale-presence-cleanup')
WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'stale-presence-cleanup'
);

-- Schedule presence cleanup
SELECT cron.schedule(
    'stale-presence-cleanup',
    '*/5 * * * *',                    -- Every 5 minutes
    $$
    UPDATE presence
    SET is_online = false
    WHERE is_online = true
    AND updated_at < NOW() - INTERVAL '5 minutes';
    $$
);

-- ═══════════════════════════════════════════════════════════════════════
-- VERIFY SCHEDULED JOBS
-- ═══════════════════════════════════════════════════════════════════════
-- Run this to check jobs are scheduled:
-- SELECT * FROM cron.job;
--
-- To view job run history:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
