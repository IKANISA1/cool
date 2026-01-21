---
description: 
---

/supabase-setup

Set up complete Supabase backend infrastructure:

1. SUPABASE CLI SETUP
   - Verify: supabase --version
   - Login: supabase login
   - Link project: supabase link --project-ref [PROJECT_REF]

2. DATABASE SCHEMA
   Create migration file: supabase/migrations/001_initial_schema.sql
   
   Tables to create:
   a) profiles (user data)
   b) vehicles (driver vehicles)
   c) user_presence (real-time location)
   d) ride_requests (60s requests)
   e) scheduled_trips (pre-scheduled rides)
   f) ratings (user reviews)
   g) blocks (blocked users)
   h) reports (safety reports)
   
   For each table:
   - Add appropriate indexes
   - Create timestamps (created_at, updated_at)
   - Add foreign key constraints
   - Enable RLS

3. ROW LEVEL SECURITY POLICIES
   For each table, create policies:
   - SELECT: Who can view data
   - INSERT: Who can create data
   - UPDATE: Who can modify data
   - DELETE: Who can remove data
   
   Key rules:
   - Users can always view their own data
   - Online users visible to all
   - Blocked users filtered out
   - Privacy-first approach

4. DATABASE FUNCTIONS
   Create functions:
   
   a) get_nearby_users(lat, lng, radius_km, role)
      - Use PostGIS ST_DWithin
      - Filter by distance and role
      - Exclude blocked users
      - Order by proximity
   
   b) update_user_presence(user_id, is_online, lat, lng)
      - Upsert presence record
      - Update last_seen timestamp
      - Store geography point
   
   c) expire_old_requests()
      - Mark pending requests as expired
      - Runs via pg_cron every minute
   
   d) update_user_rating()
      - Trigger function
      - Recalculates average rating
      - Updates profile table

5. EDGE FUNCTIONS
   Create Supabase Edge Functions:
   
   a) parse-trip-request
      - Accepts text/voice input
      - Calls Gemini API
      - Returns structured trip data
      - Handles geocoding
   
   b) send-whatsapp-notification
      - Sends request notifications
      - Uses Meta Business API
      - Template-based messages
   
   c) match-scheduled-trips
      - Finds matching trips
      - Suggests connections
      - Runs periodically

6. REAL-TIME SETUP
   - Enable realtime for:
     * ride_requests (instant notifications)
     * user_presence (live status)
     * scheduled_trips (updates)
   - Configure broadcast channels
   - Set up presence tracking

7. STORAGE (if needed)
   - Create 'avatars' bucket
   - Set public read permissions
   - Configure RLS policies
   - Set upload limits

8. AUTHENTICATION
   - Enable phone authentication
   - Configure WhatsApp OTP provider
   - Set redirect URLs
   - Configure rate limits

9. ENVIRONMENT SECRETS
   - Set: supabase secrets set GEMINI_API_KEY=xxx
   - Set: supabase secrets set WHATSAPP_TOKEN=xxx

Testing:
- Run: supabase db push
- Test functions locally: supabase functions serve
- Verify RLS: supabase db test
- Test real-time: Create test subscriptions
- Load test nearby queries with PostGIS

Artifacts:
- Database schema diagram
- RLS policy documentation
- Function API documentation
- Real-time event flow diagram