-- ═══════════════════════════════════════════════════════════════════════
-- TRIP MATCHING FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Function to find matching trips based on origin, destination and time
CREATE OR REPLACE FUNCTION find_matching_trips(
    start_lat DOUBLE PRECISION,
    start_lng DOUBLE PRECISION,
    end_lat DOUBLE PRECISION,
    end_lng DOUBLE PRECISION,
    window_start TIMESTAMP WITH TIME ZONE,
    window_end TIMESTAMP WITH TIME ZONE,
    radius_meters DOUBLE PRECISION DEFAULT 1000,
    match_type VARCHAR DEFAULT NULL -- 'offer' or 'request' or NULL for both
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    trip_type VARCHAR,
    when_datetime TIMESTAMP WITH TIME ZONE,
    from_text TEXT,
    to_text TEXT,
    seats_qty INTEGER,
    vehicle_pref VARCHAR,
    notes TEXT,
    distance_from_origin_m DOUBLE PRECISION,
    distance_from_dest_m DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        st.id,
        st.user_id,
        st.trip_type,
        st.when_datetime,
        st.from_text,
        st.to_text,
        st.seats_qty,
        st.vehicle_pref,
        st.notes,
        ST_Distance(
            st.from_geo,
            ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326)::geography
        ) AS distance_from_origin_m,
        ST_Distance(
            st.to_geo,
            ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326)::geography
        ) AS distance_from_dest_m
    FROM scheduled_trips st
    WHERE 
        st.is_active = true
        AND (match_type IS NULL OR st.trip_type = match_type)
        AND st.when_datetime BETWEEN window_start AND window_end
        -- Match origin within radius
        AND ST_DWithin(
            st.from_geo,
            ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326)::geography,
            radius_meters
        )
        -- Match destination within radius
        AND ST_DWithin(
            st.to_geo,
            ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326)::geography,
            radius_meters
        )
    ORDER BY 
        -- Order by closeness to desired time, then closeness to locations
        ABS(EXTRACT(EPOCH FROM (st.when_datetime - window_start))),
        (
            ST_Distance(st.from_geo, ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326)::geography) +
            ST_Distance(st.to_geo, ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326)::geography)
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
