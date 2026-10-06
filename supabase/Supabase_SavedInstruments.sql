-- =============================================================================
-- Encore – saved_instruments table (favorites)
-- Run this in the Supabase SQL Editor if favorites aren't working.
-- Creates the table and RLS policies. Safe to run multiple times.
-- =============================================================================

-- Create the table (same structure as favorites)
CREATE TABLE IF NOT EXISTS public.saved_instruments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  instrument_id UUID NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, instrument_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_instruments_user_id ON public.saved_instruments(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_instruments_instrument_id ON public.saved_instruments(instrument_id);

ALTER TABLE public.saved_instruments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_instruments_select_own" ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_select_own" ON public.saved_instruments;
CREATE POLICY "saved_instruments_select_own" ON public.saved_instruments
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_instruments_insert_own" ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_insert_own" ON public.saved_instruments;
CREATE POLICY "saved_instruments_insert_own" ON public.saved_instruments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_instruments_delete_own" ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_delete_own" ON public.saved_instruments;
CREATE POLICY "saved_instruments_delete_own" ON public.saved_instruments
  FOR DELETE USING (auth.uid() = user_id);
