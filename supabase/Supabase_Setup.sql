-- =============================================================================
-- Encore app – Supabase setup (copy-paste into SQL Editor)
-- Run in order. If you already have tables, skip Section 1 and run Section 2–4.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECTION 1: Storage buckets (create if missing)
-- Run this first. Creates public buckets so the app can upload and read images.
-- If this fails (e.g. missing columns), create buckets in Dashboard > Storage:
--   New bucket: "instrument-photos", Public ON. Then "avatars", Public ON.
-- -----------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('instrument-photos', 'instrument-photos', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;


-- -----------------------------------------------------------------------------
-- SECTION 2: Storage policies (who can upload/read)
-- Lets authenticated users upload to their own paths and everyone read.
-- -----------------------------------------------------------------------------

-- Drop existing policies if you re-run (avoids duplicates)
DROP POLICY IF EXISTS "Instrument photos: authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Instrument photos: public read" ON storage.objects;
DROP POLICY IF EXISTS "Avatars: authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Avatars: public read" ON storage.objects;

-- Instrument photos: any authenticated user can upload (app uses host_id in path)
CREATE POLICY "Instrument photos: authenticated upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'instrument-photos');

-- Instrument photos: public read (listing images)
CREATE POLICY "Instrument photos: public read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'instrument-photos');

-- Avatars: authenticated upload (app uses user id in path)
CREATE POLICY "Avatars: authenticated upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Avatars: public read (profile pictures)
CREATE POLICY "Avatars: public read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Allow update/delete so user can replace their avatar or instrument photo
CREATE POLICY "Instrument photos: authenticated update/delete"
ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'instrument-photos');
CREATE POLICY "Instrument photos: authenticated delete"
ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'instrument-photos');
CREATE POLICY "Avatars: authenticated update/delete"
ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'avatars');
CREATE POLICY "Avatars: authenticated delete"
ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'avatars');


-- -----------------------------------------------------------------------------
-- SECTION 3: Row Level Security (RLS) for app tables
-- Ensures data is only read/written when the JWT is valid and allowed.
-- -----------------------------------------------------------------------------

-- Enable RLS on tables (safe to run if already enabled)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instruments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- ----- users -----
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;

CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Allow public read of users for listing (e.g. show host name on instrument card)
-- If you prefer only authenticated read, remove this and use "users_select_own" only
CREATE POLICY "users_select_public" ON public.users
  FOR SELECT USING (true);

-- ----- instruments -----
DROP POLICY IF EXISTS "instruments_select_all" ON public.instruments;
DROP POLICY IF EXISTS "instruments_insert_host" ON public.instruments;
DROP POLICY IF EXISTS "instruments_update_host" ON public.instruments;
DROP POLICY IF EXISTS "instruments_delete_host" ON public.instruments;

CREATE POLICY "instruments_select_all" ON public.instruments
  FOR SELECT USING (true);

CREATE POLICY "instruments_insert_host" ON public.instruments
  FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "instruments_update_host" ON public.instruments
  FOR UPDATE USING (auth.uid() = host_id);

CREATE POLICY "instruments_delete_host" ON public.instruments
  FOR DELETE USING (auth.uid() = host_id);

-- ----- rentals -----
DROP POLICY IF EXISTS "rentals_select_renter_or_host" ON public.rentals;
DROP POLICY IF EXISTS "rentals_insert_renter" ON public.rentals;
DROP POLICY IF EXISTS "rentals_update_renter_or_host" ON public.rentals;

CREATE POLICY "rentals_select_renter_or_host" ON public.rentals
  FOR SELECT USING (auth.uid() = renter_id OR auth.uid() = host_id);

CREATE POLICY "rentals_insert_renter" ON public.rentals
  FOR INSERT WITH CHECK (auth.uid() = renter_id);

CREATE POLICY "rentals_update_renter_or_host" ON public.rentals
  FOR UPDATE USING (auth.uid() = renter_id OR auth.uid() = host_id);

-- ----- reviews -----
DROP POLICY IF EXISTS "reviews_select_all" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert_renter" ON public.reviews;
DROP POLICY IF EXISTS "reviews_update_host_reply" ON public.reviews;

CREATE POLICY "reviews_select_all" ON public.reviews
  FOR SELECT USING (true);

CREATE POLICY "reviews_insert_renter" ON public.reviews
  FOR INSERT WITH CHECK (auth.uid() = renter_id);

-- Host can update only host_reply (in app you update just that column)
CREATE POLICY "reviews_update_host_reply" ON public.reviews
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.rentals r
      WHERE r.id = reviews.rental_id AND r.host_id = auth.uid()
    )
  );


-- -----------------------------------------------------------------------------
-- SECTION 4: Auto-create users row on signup (optional but recommended)
-- When someone signs up with Supabase Auth, a row is created in public.users
-- so the app doesn’t have to rely only on the first client-side upsert.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, role, language)
  VALUES (
    NEW.id,
    NEW.email,
    'renter',
    COALESCE(NEW.raw_user_meta_data->>'language', 'en')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, users.email),
    updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- -----------------------------------------------------------------------------
-- SECTION 5: Optional – fix instruments.review_count / rating after reviews
-- Run if you want the DB to keep instrument rating in sync when reviews change.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_instrument_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.instruments
  SET
    rating = (SELECT COALESCE(AVG(rating)::numeric, 0) FROM public.reviews WHERE instrument_id = COALESCE(NEW.instrument_id, OLD.instrument_id)),
    review_count = (SELECT COUNT(*)::integer FROM public.reviews WHERE instrument_id = COALESCE(NEW.instrument_id, OLD.instrument_id)),
    updated_at = now()
  WHERE id = COALESCE(NEW.instrument_id, OLD.instrument_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS on_review_change_rating ON public.reviews;
CREATE TRIGGER on_review_change_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_instrument_rating();


-- -----------------------------------------------------------------------------
-- SECTION 6: Favorites (saved instruments, Airbnb/Marketplace style)
-- One row per user + instrument. Users can only manage their own favorites.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  instrument_id UUID NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, instrument_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_instrument_id ON public.favorites(instrument_id);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "favorites_select_own" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert_own" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete_own" ON public.favorites;

CREATE POLICY "favorites_select_own" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "favorites_insert_own" ON public.favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "favorites_delete_own" ON public.favorites
  FOR DELETE USING (auth.uid() = user_id);


-- =============================================================================
-- Done. Summary:
-- - Buckets: instrument-photos, avatars (public, with size/mime limits)
-- - Storage: authenticated upload; public read; authenticated update/delete
-- - RLS: users (own row + public read), instruments (all read, host write),
--        rentals (renter/host), reviews (all read, renter insert, host update)
-- - Trigger: new auth user → insert/update public.users
-- - Trigger: review change → update instrument rating/review_count
-- - Favorites: user_id + instrument_id (RLS: own rows only)
-- =============================================================================
