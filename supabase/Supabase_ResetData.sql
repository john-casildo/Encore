-- ============================================================
-- Encore – Reset all data, preserve users
-- Run in Supabase SQL Editor (safe to re-run)
-- Deletes in dependency order to avoid FK violations.
-- ============================================================

-- 1. Messages (depends on conversations + users)
DELETE FROM public.messages;

-- 2. Conversations (depends on users + instruments)
DELETE FROM public.conversations;

-- 3. Instrument comments (depends on instruments + users)
DELETE FROM public.instrument_comments;

-- 4. Saved instruments (depends on instruments + users)
DELETE FROM public.saved_instruments;

-- 5. User reviews (depends on rentals + users)
DELETE FROM public.user_reviews;

-- 6. Instrument reviews (depends on rentals + users)
DELETE FROM public.reviews;

-- 7. Rentals (depends on instruments + users)
DELETE FROM public.rentals;

-- 8. Instruments (depends on users)
DELETE FROM public.instruments;

-- 9. Payment methods (depends on users)
DELETE FROM public.payment_methods;

-- 10. User settings (depends on users)
DELETE FROM public.user_settings;

-- 11. Reset computed columns on users that are derived from deleted data
UPDATE public.users
SET
    rating       = 0,
    review_count = 0,
    updated_at   = now();
