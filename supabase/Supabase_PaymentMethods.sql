-- =============================================================================
-- Encore – payment_methods table + RLS
-- Run this in the Supabase SQL Editor.
-- Safe to run multiple times (uses IF NOT EXISTS / DROP IF EXISTS).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.payment_methods (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    stripe_pm_id   TEXT NOT NULL DEFAULT '',      -- placeholder; replace with real Stripe PM id when integrating Stripe
    brand          TEXT,                           -- 'visa', 'mastercard', 'amex', etc.
    last4          TEXT,
    expiry_month   INT,
    expiry_year    INT,
    is_default     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure only one default per user
CREATE UNIQUE INDEX IF NOT EXISTS payment_methods_one_default
    ON public.payment_methods (user_id)
    WHERE is_default = TRUE;

-- Enable RLS
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "pm_select_own"  ON public.payment_methods;
DROP POLICY IF EXISTS "pm_insert_own"  ON public.payment_methods;
DROP POLICY IF EXISTS "pm_update_own"  ON public.payment_methods;
DROP POLICY IF EXISTS "pm_delete_own"  ON public.payment_methods;

CREATE POLICY "pm_select_own"  ON public.payment_methods
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "pm_insert_own"  ON public.payment_methods
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "pm_update_own"  ON public.payment_methods
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "pm_delete_own"  ON public.payment_methods
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- Done. Copy-paste into Supabase SQL Editor and click Run.
-- =============================================================================
