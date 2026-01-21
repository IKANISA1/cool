# Data Model

## Supabase Tables

### `public.profiles`
- `id` (uuid, PK, references auth.users)
- `phone` (text, unique)
- `role` (enum: 'driver', 'rider')
- `full_name` (text)
- `avatar_url` (text)
- `vehicle_info` (jsonb, nullable)
- `verified` (boolean)

### `public.presence`
- `id` (uuid, PK, references profiles.id)
- `location` (geography point)
- `last_seen` (timestamptz)
- `is_online` (boolean)

### `public.trips`
- `id` (uuid, PK)
- `rider_id` (uuid, FK)
- `driver_id` (uuid, FK, nullable)
- `origin` (text)
- `destination` (text)
- `scheduled_time` (timestamptz)
- `status` (enum: 'pending', 'accepted', 'completed', 'cancelled')
