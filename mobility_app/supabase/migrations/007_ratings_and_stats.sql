-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION: 007_ratings_and_stats.sql
-- Phase 2B Additive Improvements
-- Adds: ratings table, profile/vehicle enhancements, user_stats view,
--       auto-rating trigger, cleanup functions, pg_cron jobs
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- 1. RATINGS TABLE
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  trip_id UUID, -- Can link to completed trips
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id, trip_id)
);

-- Indexes for ratings
CREATE INDEX IF NOT EXISTS idx_ratings_to_user ON ratings(to_user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_from_user ON ratings(from_user_id);

-- Enable RLS on ratings
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ratings
CREATE POLICY "Users can view all ratings"
  ON ratings FOR SELECT
  USING (TRUE);

CREATE POLICY "Users can create ratings"
  ON ratings FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);

-- ═══════════════════════════════════════════════════════════════════════
-- 2. PROFILE ENHANCEMENTS
-- ═══════════════════════════════════════════════════════════════════════

-- Add total_rides column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_rides INTEGER DEFAULT 0;

-- ═══════════════════════════════════════════════════════════════════════
-- 3. VEHICLE ENHANCEMENTS
-- ═══════════════════════════════════════════════════════════════════════

-- Add is_primary column to vehicles
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS is_primary BOOLEAN DEFAULT FALSE;

-- ═══════════════════════════════════════════════════════════════════════
-- 4. AUTO-UPDATE USER RATING TRIGGER
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_user_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET rating = (
    SELECT ROUND(AVG(rating)::numeric, 2)
    FROM ratings
    WHERE to_user_id = NEW.to_user_id
  )
  WHERE id = NEW.to_user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists, then create
DROP TRIGGER IF EXISTS on_new_rating ON ratings;
CREATE TRIGGER on_new_rating
  AFTER INSERT ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_rating();

-- ═══════════════════════════════════════════════════════════════════════
-- 5. USER STATS VIEW
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW user_stats AS
SELECT 
  p.id,
  pr.name,
  pr.role,
  pr.rating,
  pr.total_rides,
  pr.verified,
  COUNT(DISTINCT r.id) as total_ratings,
  p.is_online,
  p.last_seen_at
FROM presence p
JOIN profiles pr ON pr.id = p.user_id
LEFT JOIN ratings r ON pr.id = r.to_user_id
GROUP BY p.id, pr.id, pr.name, pr.role, pr.rating, pr.total_rides, pr.verified, p.is_online, p.last_seen_at;

-- Grant access to views
GRANT SELECT ON user_stats TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════
-- 6. CLEANUP EXPIRED REQUESTS FUNCTION
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_expired_requests()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM ride_requests
  WHERE status = 'expired'
    AND expires_at < NOW() - INTERVAL '24 hours';
    
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════
-- 7. INCREMENT TOTAL RIDES ON ACCEPTED REQUEST
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION increment_total_rides()
RETURNS TRIGGER AS $$
BEGIN
  -- When a ride request is accepted, increment total_rides for both users
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    UPDATE profiles SET total_rides = total_rides + 1 WHERE id = NEW.from_user;
    UPDATE profiles SET total_rides = total_rides + 1 WHERE id = NEW.to_user;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ride_accepted ON ride_requests;
CREATE TRIGGER on_ride_accepted
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION increment_total_rides();

-- ═══════════════════════════════════════════════════════════════════════
-- 8. REALTIME FOR RATINGS (optional)
-- ═══════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE ratings;

-- ═══════════════════════════════════════════════════════════════════════
-- NOTES:
-- pg_cron jobs should be enabled via Supabase Dashboard or separately:
--
-- To enable auto-expiry every minute:
-- SELECT cron.schedule('expire-requests', '* * * * *', 'SELECT expire_old_requests();');
--
-- To enable cleanup daily at 2 AM:
-- SELECT cron.schedule('cleanup-requests', '0 2 * * *', 'SELECT cleanup_expired_requests();');
-- ═══════════════════════════════════════════════════════════════════════
