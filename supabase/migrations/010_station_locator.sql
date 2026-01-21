-- ═══════════════════════════════════════════════════════════════════════
-- STATION LOCATOR - Battery Swap & EV Charging Stations
-- Migration: 010_station_locator.sql
-- ═══════════════════════════════════════════════════════════════════════

-- PostGIS is already enabled in the base schema

-- ═══════════════════════════════════════════════════════════════════════
-- BATTERY SWAP STATIONS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS battery_swap_stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100), -- e.g., "Ampersand", "Kigali Battery Swap"
    address TEXT NOT NULL,
    city VARCHAR(100),
    country VARCHAR(3), -- ISO 3166-1 alpha-3
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    
    -- Operational details
    operating_hours JSONB, -- {monday: "06:00-22:00", ...}
    is_24_hours BOOLEAN DEFAULT false,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    website TEXT,
    
    -- Battery details
    supported_battery_types TEXT[], -- Array of battery model names
    swap_time_minutes INTEGER, -- Average swap time
    price_per_swap DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'RWF',
    
    -- Real-time data
    batteries_available INTEGER,
    total_capacity INTEGER,
    last_availability_update TIMESTAMP WITH TIME ZONE,
    is_operational BOOLEAN DEFAULT true,
    
    -- Amenities
    amenities TEXT[], -- ["waiting_area", "wifi", "restroom", "shop"]
    payment_methods TEXT[], -- ["cash", "momo", "card"]
    
    -- Metadata
    verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    source VARCHAR(50) DEFAULT 'user_submitted', -- google_places, user_submitted, admin
    google_place_id VARCHAR(255) UNIQUE,
    
    -- Ratings
    average_rating DECIMAL(3, 2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    
    -- User tracking
    added_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Spatial index for battery swap stations
CREATE INDEX IF NOT EXISTS idx_battery_swap_stations_location 
    ON battery_swap_stations USING GIST(location);

-- Index for nearby queries
CREATE INDEX IF NOT EXISTS idx_battery_swap_stations_country_operational 
    ON battery_swap_stations(country, is_operational);

-- ═══════════════════════════════════════════════════════════════════════
-- EV CHARGING STATIONS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ev_charging_stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    network VARCHAR(100), -- e.g., "ChargePoint", "Tesla Supercharger"
    address TEXT NOT NULL,
    city VARCHAR(100),
    country VARCHAR(3),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    
    -- Operational details
    operating_hours JSONB,
    is_24_hours BOOLEAN DEFAULT false,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    website TEXT,
    
    -- Charging details
    total_ports INTEGER,
    available_ports INTEGER,
    connector_types JSONB, -- [{type: "CCS", count: 4, power_kw: 150}, ...]
    max_power_kw DECIMAL(6, 2),
    charging_levels TEXT[], -- ["level_2", "dc_fast"]
    
    -- Pricing
    pricing_info JSONB, -- {per_kwh: 0.30, per_minute: 0.10, currency: "RWF"}
    is_free BOOLEAN DEFAULT false,
    
    -- Real-time data
    last_availability_update TIMESTAMP WITH TIME ZONE,
    is_operational BOOLEAN DEFAULT true,
    
    -- Amenities and access
    amenities TEXT[],
    payment_methods TEXT[],
    access_type VARCHAR(50), -- public, private, semi_private
    requires_membership BOOLEAN DEFAULT false,
    parking_type VARCHAR(50), -- outdoor, indoor, covered, garage
    
    -- Location context
    location_description TEXT,
    poi_name TEXT, -- Point of interest (e.g., "Kigali City Tower Parking")
    
    -- Metadata
    verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    source VARCHAR(50) DEFAULT 'user_submitted',
    google_place_id VARCHAR(255) UNIQUE,
    
    -- Ratings
    average_rating DECIMAL(3, 2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    
    -- User tracking
    added_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Spatial index for EV charging stations
CREATE INDEX IF NOT EXISTS idx_ev_charging_stations_location 
    ON ev_charging_stations USING GIST(location);

CREATE INDEX IF NOT EXISTS idx_ev_charging_stations_country_operational 
    ON ev_charging_stations(country, is_operational);

-- ═══════════════════════════════════════════════════════════════════════
-- USER FAVORITES
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS station_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    station_type VARCHAR(20) CHECK (station_type IN ('battery_swap', 'ev_charging')),
    station_id UUID NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, station_type, station_id)
);

CREATE INDEX IF NOT EXISTS idx_station_favorites_user ON station_favorites(user_id);

-- ═══════════════════════════════════════════════════════════════════════
-- STATION REVIEWS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS station_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    station_type VARCHAR(20) CHECK (station_type IN ('battery_swap', 'ev_charging')),
    station_id UUID NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    helpful_count INTEGER DEFAULT 0,
    
    -- Review details
    service_quality INTEGER CHECK (service_quality >= 1 AND service_quality <= 5),
    wait_time_minutes INTEGER,
    price_rating INTEGER CHECK (price_rating >= 1 AND price_rating <= 5),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_station_reviews_station 
    ON station_reviews(station_type, station_id);

-- ═══════════════════════════════════════════════════════════════════════
-- AVAILABILITY REPORTS (User check-ins)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS station_availability_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    station_type VARCHAR(20) CHECK (station_type IN ('battery_swap', 'ev_charging')),
    station_id UUID NOT NULL,
    
    -- For battery swap
    batteries_available INTEGER,
    
    -- For EV charging
    ports_available INTEGER,
    ports_in_use INTEGER,
    estimated_wait_minutes INTEGER,
    
    -- Common
    is_operational BOOLEAN,
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_availability_reports_recent 
    ON station_availability_reports(station_type, station_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Function to find nearby battery swap stations
CREATE OR REPLACE FUNCTION nearby_battery_swap_stations(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    brand VARCHAR,
    address TEXT,
    distance_km DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    batteries_available INTEGER,
    total_capacity INTEGER,
    is_operational BOOLEAN,
    average_rating DECIMAL,
    operating_hours JSONB,
    amenities TEXT[],
    payment_methods TEXT[],
    price_per_swap DECIMAL,
    currency VARCHAR,
    swap_time_minutes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.brand,
        s.address,
        ST_Distance(
            ST_MakePoint(user_lng, user_lat)::geography,
            s.location
        ) / 1000 AS distance_km,
        s.latitude,
        s.longitude,
        s.batteries_available,
        s.total_capacity,
        s.is_operational,
        s.average_rating,
        s.operating_hours,
        s.amenities,
        s.payment_methods,
        s.price_per_swap,
        s.currency,
        s.swap_time_minutes
    FROM battery_swap_stations s
    WHERE 
        s.is_operational = true
        AND ST_DWithin(
            ST_MakePoint(user_lng, user_lat)::geography,
            s.location,
            radius_km * 1000
        )
    ORDER BY distance_km
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to find nearby EV charging stations
CREATE OR REPLACE FUNCTION nearby_ev_charging_stations(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10,
    connector_filter TEXT DEFAULT NULL,
    min_power_kw DOUBLE PRECISION DEFAULT NULL,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    network VARCHAR,
    address TEXT,
    distance_km DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    available_ports INTEGER,
    total_ports INTEGER,
    connector_types JSONB,
    max_power_kw DECIMAL,
    is_operational BOOLEAN,
    average_rating DECIMAL,
    operating_hours JSONB,
    amenities TEXT[],
    pricing_info JSONB,
    is_free BOOLEAN,
    access_type VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.network,
        s.address,
        ST_Distance(
            ST_MakePoint(user_lng, user_lat)::geography,
            s.location
        ) / 1000 AS distance_km,
        s.latitude,
        s.longitude,
        s.available_ports,
        s.total_ports,
        s.connector_types,
        s.max_power_kw,
        s.is_operational,
        s.average_rating,
        s.operating_hours,
        s.amenities,
        s.pricing_info,
        s.is_free,
        s.access_type
    FROM ev_charging_stations s
    WHERE 
        s.is_operational = true
        AND ST_DWithin(
            ST_MakePoint(user_lng, user_lat)::geography,
            s.location,
            radius_km * 1000
        )
        AND (connector_filter IS NULL OR s.connector_types::text ILIKE '%' || connector_filter || '%')
        AND (min_power_kw IS NULL OR s.max_power_kw >= min_power_kw)
    ORDER BY distance_km
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════
-- TRIGGERS FOR RATING UPDATES
-- ═══════════════════════════════════════════════════════════════════════

-- Trigger to update average rating for battery swap stations
CREATE OR REPLACE FUNCTION update_battery_swap_station_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE battery_swap_stations
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0)
            FROM station_reviews
            WHERE station_type = 'battery_swap'
            AND station_id = NEW.station_id
        ),
        total_ratings = (
            SELECT COUNT(*)
            FROM station_reviews
            WHERE station_type = 'battery_swap'
            AND station_id = NEW.station_id
        ),
        updated_at = NOW()
    WHERE id = NEW.station_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_battery_swap_rating ON station_reviews;
CREATE TRIGGER trigger_update_battery_swap_rating
    AFTER INSERT OR UPDATE ON station_reviews
    FOR EACH ROW
    WHEN (NEW.station_type = 'battery_swap')
    EXECUTE FUNCTION update_battery_swap_station_rating();

-- Trigger to update average rating for EV charging stations
CREATE OR REPLACE FUNCTION update_ev_charging_station_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ev_charging_stations
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0)
            FROM station_reviews
            WHERE station_type = 'ev_charging'
            AND station_id = NEW.station_id
        ),
        total_ratings = (
            SELECT COUNT(*)
            FROM station_reviews
            WHERE station_type = 'ev_charging'
            AND station_id = NEW.station_id
        ),
        updated_at = NOW()
    WHERE id = NEW.station_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_ev_charging_rating ON station_reviews;
CREATE TRIGGER trigger_update_ev_charging_rating
    AFTER INSERT OR UPDATE ON station_reviews
    FOR EACH ROW
    WHEN (NEW.station_type = 'ev_charging')
    EXECUTE FUNCTION update_ev_charging_station_rating();

-- Updated_at triggers
CREATE TRIGGER update_battery_swap_stations_updated_at
    BEFORE UPDATE ON battery_swap_stations
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_ev_charging_stations_updated_at
    BEFORE UPDATE ON ev_charging_stations
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_station_reviews_updated_at
    BEFORE UPDATE ON station_reviews
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE battery_swap_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ev_charging_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE station_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE station_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE station_availability_reports ENABLE ROW LEVEL SECURITY;

-- Stations are publicly readable
CREATE POLICY "Battery swap stations are publicly readable"
    ON battery_swap_stations FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can add battery swap stations"
    ON battery_swap_stations FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "EV charging stations are publicly readable"
    ON ev_charging_stations FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can add EV charging stations"
    ON ev_charging_stations FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Users can manage their own favorites
CREATE POLICY "Users can view own favorites"
    ON station_favorites FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own favorites"
    ON station_favorites FOR ALL
    USING (auth.uid() = user_id);

-- Users can create reviews
CREATE POLICY "Users can create reviews"
    ON station_reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view all reviews"
    ON station_reviews FOR SELECT
    USING (true);

CREATE POLICY "Users can update own reviews"
    ON station_reviews FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
    ON station_reviews FOR DELETE
    USING (auth.uid() = user_id);

-- Users can submit availability reports
CREATE POLICY "Users can submit availability reports"
    ON station_availability_reports FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view availability reports"
    ON station_availability_reports FOR SELECT
    USING (true);

-- ═══════════════════════════════════════════════════════════════════════
-- REALTIME CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE station_availability_reports;
ALTER TABLE station_availability_reports REPLICA IDENTITY FULL;
