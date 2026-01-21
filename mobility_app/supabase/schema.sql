-- ═══════════════════════════════════════════════════════════════════════
-- MOBILITY APP - SUPABASE DATABASE SCHEMA
-- Sub-Saharan Africa Mobility Platform
-- ═══════════════════════════════════════════════════════════════════════

-- Enable PostGIS for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ═══════════════════════════════════════════════════════════════════════
-- USERS TABLE - Core user accounts (phone-based auth)
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════
-- PROFILES TABLE - Extended user information
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100),
    role VARCHAR(20) CHECK (role IN ('driver', 'passenger', 'both')),
    country VARCHAR(3), -- ISO 3166-1 alpha-3
    languages TEXT[], -- Array of language codes
    avatar_url TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════
-- VEHICLES TABLE - Driver vehicle information
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(20) CHECK (category IN ('moto', 'cab', 'liffan', 'truck', 'rent', 'other')),
    capacity INTEGER,
    plate VARCHAR(20),
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    color VARCHAR(30),
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════
-- PRESENCE TABLE - Real-time online status with location
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE presence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT false,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_lat DOUBLE PRECISION,
    last_lng DOUBLE PRECISION,
    accuracy_m DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add spatial index for location queries
CREATE INDEX idx_presence_location ON presence USING GIST(
    ST_MakePoint(last_lng, last_lat)::geography
);

CREATE INDEX idx_presence_online ON presence(is_online) WHERE is_online = true;

-- ═══════════════════════════════════════════════════════════════════════
-- RIDE REQUESTS TABLE - 60-second expiring ride requests
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE ride_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user UUID REFERENCES users(id) ON DELETE CASCADE,
    payload JSONB, -- Flexible trip details
    status VARCHAR(20) CHECK (status IN ('pending', 'accepted', 'denied', 'expired', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '1 minute',
    responded_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_ride_requests_from ON ride_requests(from_user);
CREATE INDEX idx_ride_requests_to ON ride_requests(to_user);
CREATE INDEX idx_ride_requests_status ON ride_requests(status);
CREATE INDEX idx_ride_requests_expires ON ride_requests(expires_at) WHERE status = 'pending';

-- ═══════════════════════════════════════════════════════════════════════
-- SCHEDULED TRIPS TABLE - Future trip offers/requests
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE scheduled_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    trip_type VARCHAR(10) CHECK (trip_type IN ('offer', 'request')),
    when_datetime TIMESTAMP WITH TIME ZONE,
    from_text TEXT,
    to_text TEXT,
    from_geo GEOGRAPHY(POINT, 4326),
    to_geo GEOGRAPHY(POINT, 4326),
    seats_qty INTEGER,
    vehicle_pref VARCHAR(20),
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_scheduled_trips_user ON scheduled_trips(user_id);
CREATE INDEX idx_scheduled_trips_when ON scheduled_trips(when_datetime);
CREATE INDEX idx_scheduled_trips_from_geo ON scheduled_trips USING GIST(from_geo);
CREATE INDEX idx_scheduled_trips_to_geo ON scheduled_trips USING GIST(to_geo);

-- ═══════════════════════════════════════════════════════════════════════
-- BLOCKS & REPORTS TABLE - Safety features
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE blocks_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES users(id),
    reported_id UUID REFERENCES users(id),
    action_type VARCHAR(10) CHECK (action_type IN ('block', 'report')),
    reason TEXT,
    resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_blocks_reporter ON blocks_reports(reporter_id);
CREATE INDEX idx_blocks_reported ON blocks_reports(reported_id);

-- ═══════════════════════════════════════════════════════════════════════
-- AUDIT EVENTS TABLE - Activity logging
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    event_type VARCHAR(50),
    event_data JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_events(user_id);
CREATE INDEX idx_audit_type ON audit_events(event_type);
CREATE INDEX idx_audit_created ON audit_events(created_at);

-- ═══════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════

-- Users: can read/update own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Profiles: publicly readable for discovery, users update own
CREATE POLICY "Profiles are publicly readable" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Vehicles: publicly readable, users manage own
CREATE POLICY "Vehicles are publicly readable" ON vehicles
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own vehicles" ON vehicles
    FOR ALL USING (auth.uid() = user_id);

-- Presence: publicly readable for discovery, users update own
CREATE POLICY "Presence is publicly readable" ON presence
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own presence" ON presence
    FOR ALL USING (auth.uid() = user_id);

-- Ride requests: users can see requests they're part of
CREATE POLICY "Users view relevant requests" ON ride_requests
    FOR SELECT USING (auth.uid() IN (from_user, to_user));

CREATE POLICY "Users can create requests" ON ride_requests
    FOR INSERT WITH CHECK (auth.uid() = from_user);

CREATE POLICY "Recipients can update requests" ON ride_requests
    FOR UPDATE USING (auth.uid() = to_user);

CREATE POLICY "Senders can cancel requests" ON ride_requests
    FOR UPDATE USING (auth.uid() = from_user AND status = 'pending');

-- Scheduled trips: publicly readable, users manage own
CREATE POLICY "Trips are publicly readable" ON scheduled_trips
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own trips" ON scheduled_trips
    FOR ALL USING (auth.uid() = user_id);

-- Blocks/reports: users can manage their own reports
CREATE POLICY "Users can view own reports" ON blocks_reports
    FOR SELECT USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports" ON blocks_reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Audit events: users can view own events
CREATE POLICY "Users can view own audit events" ON audit_events
    FOR SELECT USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════
-- REALTIME CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE presence;
ALTER PUBLICATION supabase_realtime ADD TABLE ride_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE scheduled_trips;

ALTER TABLE presence REPLICA IDENTITY FULL;
ALTER TABLE ride_requests REPLICA IDENTITY FULL;

-- ═══════════════════════════════════════════════════════════════════════
-- DATABASE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Function to find nearby users
CREATE OR REPLACE FUNCTION nearby_users(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10,
    user_role VARCHAR DEFAULT NULL,
    exclude_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    user_id UUID,
    distance_km DOUBLE PRECISION,
    profile JSONB,
    vehicle JSONB,
    is_online BOOLEAN,
    last_seen_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        ST_Distance(
            ST_MakePoint(user_lng, user_lat)::geography,
            ST_MakePoint(p.last_lng, p.last_lat)::geography
        ) / 1000 AS distance_km,
        row_to_json(pr.*)::JSONB AS profile,
        row_to_json(v.*)::JSONB AS vehicle,
        p.is_online,
        p.last_seen_at
    FROM presence p
    JOIN profiles pr ON pr.id = p.user_id
    LEFT JOIN vehicles v ON v.user_id = p.user_id AND v.is_active = true
    WHERE 
        p.is_online = true
        AND p.last_lat IS NOT NULL
        AND p.last_lng IS NOT NULL
        AND ST_DWithin(
            ST_MakePoint(user_lng, user_lat)::geography,
            ST_MakePoint(p.last_lng, p.last_lat)::geography,
            radius_km * 1000
        )
        AND (user_role IS NULL OR pr.role IN (user_role, 'both'))
        AND (exclude_user_id IS NULL OR p.user_id != exclude_user_id)
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-expire pending requests
CREATE OR REPLACE FUNCTION expire_old_requests()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE ride_requests
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, phone)
    VALUES (new.id, new.phone);
    
    INSERT INTO public.profiles (id)
    VALUES (new.id);
    
    INSERT INTO public.presence (user_id, is_online)
    VALUES (new.id, false);
    
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- ═══════════════════════════════════════════════════════════════════════
-- SCHEDULED JOB (if pg_cron is available)
-- ═══════════════════════════════════════════════════════════════════════

-- Uncomment if pg_cron extension is enabled:
-- SELECT cron.schedule(
--     'expire-requests',
--     '* * * * *', -- Every minute
--     $$SELECT expire_old_requests()$$
-- );

-- ═══════════════════════════════════════════════════════════════════════
-- UPDATED_AT TRIGGER
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_presence_updated_at
    BEFORE UPDATE ON presence
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_scheduled_trips_updated_at
    BEFORE UPDATE ON scheduled_trips
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
