-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION 008: SEPARATE BLOCKS/REPORTS TABLES + STALE PRESENCE CLEANUP
-- RideLink Additive Improvements
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- SEPARATE BLOCKS TABLE (for faster lookup)
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON blocks(blocked_id);

-- RLS for blocks
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own blocks" ON blocks
    FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can create blocks" ON blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can delete own blocks" ON blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- ═══════════════════════════════════════════════════════════════════════
-- SEPARATE REPORTS TABLE (with admin tracking)
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    category VARCHAR(30) CHECK (category IN ('harassment', 'fraud', 'safety', 'spam', 'other')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported ON reports(reported_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status) WHERE status = 'pending';

-- RLS for reports
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reports" ON reports
    FOR SELECT USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports" ON reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- ═══════════════════════════════════════════════════════════════════════
-- STALE PRESENCE CLEANUP FUNCTION
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cleanup_stale_presence()
RETURNS INTEGER AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    -- Mark users as offline if they haven't updated presence in 6+ hours
    UPDATE presence
    SET is_online = false,
        updated_at = NOW()
    WHERE is_online = true
    AND last_seen_at < NOW() - INTERVAL '6 hours';
    
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RETURN cleaned_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════
-- HELPER FUNCTION: Check if user is blocked
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION is_user_blocked(
    p_user_id UUID,
    p_other_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = p_user_id AND blocked_id = p_other_user_id)
           OR (blocker_id = p_other_user_id AND blocked_id = p_user_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════
-- PERFORMANCE INDEXES
-- ═══════════════════════════════════════════════════════════════════════

-- Index for faster presence queries
CREATE INDEX IF NOT EXISTS idx_presence_online_location ON presence(is_online, last_lat, last_lng)
    WHERE is_online = true AND last_lat IS NOT NULL;

-- Index for faster ride request lookups
CREATE INDEX IF NOT EXISTS idx_ride_requests_pending_expires ON ride_requests(expires_at)
    WHERE status = 'pending';

-- ═══════════════════════════════════════════════════════════════════════
-- SCHEDULED JOB (if pg_cron is enabled)
-- Run in Supabase Dashboard > SQL Editor to enable:
-- ═══════════════════════════════════════════════════════════════════════
-- SELECT cron.schedule(
--     'cleanup-stale-presence',
--     '0 * * * *',  -- Every hour at :00
--     $$SELECT cleanup_stale_presence()$$
-- );
