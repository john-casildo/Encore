-- =============================================================================
-- Encore – Add country to users (so Location country selection persists)
-- Run this in Supabase SQL Editor if the selected country reverts after save.
-- =============================================================================

-- Add country_iso (e.g. "CR", "NI") to public.users if missing
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'country_iso') THEN
    ALTER TABLE public.users ADD COLUMN country_iso TEXT;
  END IF;
END $$;

-- Done. After running this, select Costa Rica (or any country), tap Save – it will stay.
-- =============================================================================
