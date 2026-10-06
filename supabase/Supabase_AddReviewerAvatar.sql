-- =============================================================================
-- Encore – Add reviewer_avatar_url to reviews table if missing
-- Run in Supabase SQL Editor. Safe to run multiple times.
-- Needed for review profile pictures to display when joined from users.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reviews' AND column_name = 'reviewer_avatar_url') THEN
    ALTER TABLE public.reviews ADD COLUMN reviewer_avatar_url TEXT;
  END IF;
END $$;

-- =============================================================================
