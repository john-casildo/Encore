-- =============================================================================
-- Encore – Add latitude/longitude to users (for location detection)
-- Run this in Supabase SQL Editor if "Use my location" doesn't save coordinates.
-- =============================================================================

-- Add latitude and longitude to public.users if missing
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'latitude') THEN
    ALTER TABLE public.users ADD COLUMN latitude DOUBLE PRECISION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'longitude') THEN
    ALTER TABLE public.users ADD COLUMN longitude DOUBLE PRECISION;
  END IF;
END $$;

-- Done. After running this, detect location in Edit Profile and Save – coordinates will persist.
-- =============================================================================
