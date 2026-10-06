-- =============================================================================
-- Encore – user_reviews table (host ↔ renter reviews)
-- Run in Supabase SQL Editor AFTER the main setup.
-- Safe to run multiple times (IF NOT EXISTS / DROP IF EXISTS).
-- =============================================================================

-- 1. Table
CREATE TABLE IF NOT EXISTS public.user_reviews (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    rental_id           UUID        NOT NULL REFERENCES public.rentals(id)  ON DELETE CASCADE,
    reviewer_id         UUID        NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
    reviewee_id         UUID        NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
    reviewer_role       TEXT        NOT NULL,   -- 'renter' (renter reviews host) | 'host' (host reviews renter)
    rating              INT         NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment             TEXT,
    reviewer_name       TEXT,
    reviewer_avatar_url TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT user_reviews_one_per_direction UNIQUE (rental_id, reviewer_id, reviewer_role)
);

CREATE INDEX IF NOT EXISTS idx_user_reviews_reviewee  ON public.user_reviews (reviewee_id);
CREATE INDEX IF NOT EXISTS idx_user_reviews_reviewer  ON public.user_reviews (reviewer_id);
CREATE INDEX IF NOT EXISTS idx_user_reviews_rental    ON public.user_reviews (rental_id);

-- 2. Row Level Security
ALTER TABLE public.user_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ur_select_participant"  ON public.user_reviews;
DROP POLICY IF EXISTS "ur_insert_own"          ON public.user_reviews;
DROP POLICY IF EXISTS "ur_delete_own"          ON public.user_reviews;

-- Anyone involved in the rental (reviewer OR reviewee) can read the review
CREATE POLICY "ur_select_participant" ON public.user_reviews
    FOR SELECT USING (auth.uid() = reviewer_id OR auth.uid() = reviewee_id);

-- Only the reviewer can insert their own review
CREATE POLICY "ur_insert_own" ON public.user_reviews
    FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Reviewer can delete their own review
CREATE POLICY "ur_delete_own" ON public.user_reviews
    FOR DELETE USING (auth.uid() = reviewer_id);

-- 3. Trigger: recalculate users.rating and users.review_count after any user_review INSERT/DELETE
CREATE OR REPLACE FUNCTION public.refresh_user_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    target_id UUID;
BEGIN
    target_id := COALESCE(NEW.reviewee_id, OLD.reviewee_id);
    UPDATE public.users
    SET
        rating       = (SELECT COALESCE(AVG(rating), 0) FROM public.user_reviews WHERE reviewee_id = target_id),
        review_count = (SELECT COUNT(*)                  FROM public.user_reviews WHERE reviewee_id = target_id),
        updated_at   = now()
    WHERE id = target_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_user_review_change ON public.user_reviews;
CREATE TRIGGER on_user_review_change
    AFTER INSERT OR DELETE ON public.user_reviews
    FOR EACH ROW EXECUTE FUNCTION public.refresh_user_rating();

-- =============================================================================
-- Done. Summary:
--   user_reviews: reviewer_id reviews reviewee_id about a specific rental
--   reviewer_role = 'renter'  → renter reviewed the host
--   reviewer_role = 'host'    → host reviewed the renter
--   UNIQUE(rental_id, reviewer_id, reviewer_role) prevents duplicate reviews
--   Trigger auto-updates users.rating and users.review_count
-- =============================================================================
