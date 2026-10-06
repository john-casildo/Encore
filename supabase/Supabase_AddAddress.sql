-- Add residential address column to the users table.
-- Run this in the Supabase SQL editor.

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address text;

-- Also re-confirm the instruments SELECT policy so the home page shows instruments.
DROP POLICY IF EXISTS "instruments_select_public" ON public.instruments;
CREATE POLICY "instruments_select_public" ON public.instruments
    FOR SELECT USING (true);
