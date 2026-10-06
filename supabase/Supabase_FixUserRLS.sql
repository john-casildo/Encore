-- Fix: ensure authenticated users can UPDATE their own row in public.users
-- Run this in the Supabase SQL editor if profile changes are not persisting.

-- 1. Enable RLS (no-op if already enabled)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 2. Drop old update policy if it exists, then recreate cleanly
DROP POLICY IF EXISTS "users_update_own" ON public.users;

CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE
    USING      (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 3. Make sure the SELECT policy also exists (needed for return=representation after PATCH)
DROP POLICY IF EXISTS "users_select_own" ON public.users;

CREATE POLICY "users_select_own" ON public.users
    FOR SELECT
    USING (true);   -- anyone authenticated can read users (needed for host/renter profile display)
