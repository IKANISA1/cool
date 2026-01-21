-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION: Add vehicle_category and phone_number to profiles
-- Migration ID: 003_profile_enhancements
-- Created: 2026-01-17
-- ═══════════════════════════════════════════════════════════════════════

-- Add vehicle_category column to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS vehicle_category VARCHAR(20) 
    CHECK (vehicle_category IS NULL OR vehicle_category IN ('moto', 'cab', 'liffan', 'truck', 'rent', 'other'));

-- Add phone_number column to profiles table (may duplicate users.phone but useful for display)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);

-- Create index on vehicle_category for filtering drivers by vehicle type
CREATE INDEX IF NOT EXISTS idx_profiles_vehicle_category 
    ON profiles(vehicle_category) 
    WHERE vehicle_category IS NOT NULL;

-- Create index on role for filtering by user type
CREATE INDEX IF NOT EXISTS idx_profiles_role 
    ON profiles(role);

-- Update the profiles table comment
COMMENT ON TABLE profiles IS 'Extended user information including role, vehicle category, and languages';

-- Update column comments for clarity
COMMENT ON COLUMN profiles.role IS 'User role: driver, passenger, or both';
COMMENT ON COLUMN profiles.vehicle_category IS 'Vehicle type for drivers: moto, cab, liffan, truck, rent, other';
COMMENT ON COLUMN profiles.country IS 'ISO 3166-1 alpha-3 country code (e.g., RWA for Rwanda)';
COMMENT ON COLUMN profiles.languages IS 'Array of languages the user speaks';
