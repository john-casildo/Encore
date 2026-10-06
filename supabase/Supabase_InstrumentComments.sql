-- =============================================================================
-- Encore – instrument_comments table
-- Run in Supabase SQL Editor AFTER the main setup.
-- Safe to run multiple times (IF NOT EXISTS / DROP IF EXISTS).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.instrument_comments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    instrument_id   UUID        NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES public.users(id)       ON DELETE CASCADE,
    body            TEXT        NOT NULL,
    user_name       TEXT,            -- denormalized at insert time
    user_avatar_url TEXT,            -- denormalized at insert time
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_instrument_comments_instrument ON public.instrument_comments (instrument_id, created_at DESC);

ALTER TABLE public.instrument_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comments_select_public"  ON public.instrument_comments;
DROP POLICY IF EXISTS "comments_insert_own"     ON public.instrument_comments;
DROP POLICY IF EXISTS "comments_delete_own"     ON public.instrument_comments;

-- Anyone (including anonymous) can read comments
CREATE POLICY "comments_select_public" ON public.instrument_comments
    FOR SELECT USING (true);

-- Only authenticated users can post, and only as themselves
CREATE POLICY "comments_insert_own" ON public.instrument_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only the author can delete their own comment
CREATE POLICY "comments_delete_own" ON public.instrument_comments
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- Done. Run this before testing the comments feature.
-- =============================================================================
