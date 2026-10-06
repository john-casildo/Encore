-- ============================================================
-- Encore – All pending fixes (run this in Supabase SQL Editor)
-- ============================================================

-- ─── 1. USERS TABLE – RLS policies ────────────────────────
-- Enable RLS (safe to run even if already enabled)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated user to read any user row
-- (needed to display host name / avatar on instrument detail)
DROP POLICY IF EXISTS "users_select_public"   ON public.users;
CREATE POLICY "users_select_public" ON public.users
    FOR SELECT USING (true);

-- Allow a user to update ONLY their own row
DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE
    USING      (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow a user to insert their own row (needed on first sign-up)
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = id);


-- ─── 2. MESSAGES TABLE – make rental_id nullable ──────────
-- The column was created NOT NULL but messages can exist without a rental
ALTER TABLE public.messages
    ALTER COLUMN rental_id DROP NOT NULL;

-- Also drop the FK constraint so we can send null (re-add as optional)
ALTER TABLE public.messages
    DROP CONSTRAINT IF EXISTS messages_rental_id_fkey;

ALTER TABLE public.messages
    ADD CONSTRAINT messages_rental_id_fkey
    FOREIGN KEY (rental_id) REFERENCES public.rentals(id)
    ON DELETE SET NULL;

-- RLS for messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_select_participant" ON public.messages;
CREATE POLICY "messages_select_participant" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
              AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "messages_insert_participant" ON public.messages;
CREATE POLICY "messages_insert_participant" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
              AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "messages_update_participant" ON public.messages;
CREATE POLICY "messages_update_participant" ON public.messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
              AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
        )
    );


-- ─── 3. CONVERSATIONS TABLE – RLS ─────────────────────────
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conversations_select_participant" ON public.conversations;
CREATE POLICY "conversations_select_participant" ON public.conversations
    FOR SELECT USING (
        renter_id = auth.uid() OR host_id = auth.uid()
    );

DROP POLICY IF EXISTS "conversations_insert_renter" ON public.conversations;
CREATE POLICY "conversations_insert_renter" ON public.conversations
    FOR INSERT WITH CHECK (renter_id = auth.uid());


-- ─── 4. INSTRUMENT COMMENTS TABLE ─────────────────────────
CREATE TABLE IF NOT EXISTS public.instrument_comments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    instrument_id   UUID        NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES public.users(id)       ON DELETE CASCADE,
    body            TEXT        NOT NULL,
    user_name       TEXT,
    user_avatar_url TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.instrument_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comments_select_public"    ON public.instrument_comments;
DROP POLICY IF EXISTS "comments_insert_authed"    ON public.instrument_comments;
DROP POLICY IF EXISTS "comments_delete_own"       ON public.instrument_comments;

CREATE POLICY "comments_select_public" ON public.instrument_comments
    FOR SELECT USING (true);

CREATE POLICY "comments_insert_authed" ON public.instrument_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "comments_delete_own" ON public.instrument_comments
    FOR DELETE USING (auth.uid() = user_id);


-- ─── 5. SAVED INSTRUMENTS – RLS ───────────────────────────
ALTER TABLE public.saved_instruments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_select_own"  ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_insert_own"  ON public.saved_instruments;
DROP POLICY IF EXISTS "saved_delete_own"  ON public.saved_instruments;

CREATE POLICY "saved_select_own" ON public.saved_instruments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "saved_insert_own" ON public.saved_instruments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "saved_delete_own" ON public.saved_instruments
    FOR DELETE USING (auth.uid() = user_id);


-- ─── 6. INSTRUMENTS – RLS ─────────────────────────────────
ALTER TABLE public.instruments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "instruments_select_public" ON public.instruments;
DROP POLICY IF EXISTS "instruments_insert_host"   ON public.instruments;
DROP POLICY IF EXISTS "instruments_update_host"   ON public.instruments;
DROP POLICY IF EXISTS "instruments_delete_host"   ON public.instruments;

CREATE POLICY "instruments_select_public" ON public.instruments
    FOR SELECT USING (true);

CREATE POLICY "instruments_insert_host" ON public.instruments
    FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "instruments_update_host" ON public.instruments
    FOR UPDATE
    USING      (auth.uid() = host_id)
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "instruments_delete_host" ON public.instruments
    FOR DELETE USING (auth.uid() = host_id);


-- ─── 7. RENTALS – RLS ─────────────────────────────────────
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rentals_select_participant" ON public.rentals;
DROP POLICY IF EXISTS "rentals_insert_renter"      ON public.rentals;
DROP POLICY IF EXISTS "rentals_update_host"        ON public.rentals;

CREATE POLICY "rentals_select_participant" ON public.rentals
    FOR SELECT USING (
        renter_id = auth.uid() OR host_id = auth.uid()
    );

CREATE POLICY "rentals_insert_renter" ON public.rentals
    FOR INSERT WITH CHECK (renter_id = auth.uid());

CREATE POLICY "rentals_update_host" ON public.rentals
    FOR UPDATE
    USING      (host_id = auth.uid() OR renter_id = auth.uid())
    WITH CHECK (host_id = auth.uid() OR renter_id = auth.uid());


-- ─── 8. REVIEWS – RLS ─────────────────────────────────────
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reviews_select_public"  ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert_renter"  ON public.reviews;

CREATE POLICY "reviews_select_public" ON public.reviews
    FOR SELECT USING (true);

CREATE POLICY "reviews_insert_renter" ON public.reviews
    FOR INSERT WITH CHECK (auth.uid() = renter_id);


-- ─── 9. USER REVIEWS – RLS ────────────────────────────────
ALTER TABLE public.user_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_reviews_select_public"   ON public.user_reviews;
DROP POLICY IF EXISTS "user_reviews_insert_reviewer" ON public.user_reviews;

CREATE POLICY "user_reviews_select_public" ON public.user_reviews
    FOR SELECT USING (true);

CREATE POLICY "user_reviews_insert_reviewer" ON public.user_reviews
    FOR INSERT WITH CHECK (auth.uid() = reviewer_id);


-- ─── 10. PAYMENT METHODS – RLS ────────────────────────────
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pm_select_own" ON public.payment_methods;
DROP POLICY IF EXISTS "pm_insert_own" ON public.payment_methods;
DROP POLICY IF EXISTS "pm_update_own" ON public.payment_methods;
DROP POLICY IF EXISTS "pm_delete_own" ON public.payment_methods;

CREATE POLICY "pm_select_own" ON public.payment_methods
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "pm_insert_own" ON public.payment_methods
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "pm_update_own" ON public.payment_methods
    FOR UPDATE
    USING      (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "pm_delete_own" ON public.payment_methods
    FOR DELETE USING (auth.uid() = user_id);


-- ─── 11. USER SETTINGS – RLS ──────────────────────────────
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "settings_select_own" ON public.user_settings;
DROP POLICY IF EXISTS "settings_upsert_own" ON public.user_settings;

CREATE POLICY "settings_select_own" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "settings_upsert_own" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK  (auth.uid() = user_id);
