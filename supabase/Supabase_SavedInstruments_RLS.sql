-- =============================================================================
-- Encore – saved_instruments RLS policies
-- Run this in the Supabase SQL Editor to enable favorites.
-- Safe to run multiple times (uses DROP IF EXISTS).
-- =============================================================================

-- Enable RLS on the table (safe if already enabled)
ALTER TABLE public.saved_instruments ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "saved_instruments_select_own" ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_instruments_insert_own" ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_instruments_delete_own" ON public.saved_instruments;

-- Users can only see their own saved instruments
CREATE POLICY "saved_instruments_select_own" ON public.saved_instruments
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only save instruments for themselves
CREATE POLICY "saved_instruments_insert_own" ON public.saved_instruments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only remove their own saved instruments
CREATE POLICY "saved_instruments_delete_own" ON public.saved_instruments
  FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- Done. Copy-paste this entire file into Supabase SQL Editor and run it.
-- =============================================================================
