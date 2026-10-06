-- =============================================================================
-- Encore – Fake Seed Data
-- Run in Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- Password for ALL demo accounts: Encore123!
-- Safe to re-run: uses ON CONFLICT DO NOTHING
--
-- Requires: All migrations (Setup, Messaging, PaymentMethods, UserReviews,
-- AddCountryIso, Profile_Photo_LastName, InstrumentComments, etc.).
-- =============================================================================

-- Requires pgcrypto (already enabled in every Supabase project by default)
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- =============================================================================
-- STEP 1 – AUTH USERS (3 hosts + 3 renters)
-- =============================================================================

INSERT INTO auth.users (
    id, instance_id, aud, role,
    email, encrypted_password,
    email_confirmed_at, confirmation_sent_at,
    created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, recovery_token, confirmation_token,
    email_change, email_change_token_new, email_change_token_current
) VALUES
-- Hosts
(
    'aa000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'carlos.mora@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
),
(
    'aa000002-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'sofia.vargas@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
),
(
    'aa000003-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'andres.jimenez@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
),
-- Renters
(
    'bb000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'maria.castro@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
),
(
    'bb000002-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'diego.ramirez@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
),
(
    'bb000003-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'lucia.rodriguez@demo.com', crypt('Encore123!', gen_salt('bf')),
    now(), now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    false, '', '', '', '', ''
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 2 – PUBLIC USERS (profiles)
-- =============================================================================

INSERT INTO public.users (id, name, last_name, email, role, city, country_iso, phone, bio, is_verified, latitude, longitude, created_at, updated_at) VALUES
-- Hosts
(
    'aa000001-0000-0000-0000-000000000001',
    'Carlos', 'Mora', 'carlos.mora@demo.com', 'host',
    'San José', 'CR', '+506 8800-1111',
    'Músico profesional con 10 años de experiencia. Cuido mis instrumentos como si fueran oro.',
    true, 9.9281, -84.0907, now(), now()
),
(
    'aa000002-0000-0000-0000-000000000002',
    'Sofía', 'Vargas', 'sofia.vargas@demo.com', 'host',
    'Heredia', 'CR', '+506 8800-2222',
    'Profesora de música en la UCR. Tengo una colección variada lista para rentar.',
    true, 9.9981, -84.1197, now(), now()
),
(
    'aa000003-0000-0000-0000-000000000003',
    'Andrés', 'Jiménez', 'andres.jimenez@demo.com', 'host',
    'Alajuela', 'CR', '+506 8800-3333',
    'Baterista de sesión. Equipo en perfectas condiciones, serio y puntual.',
    false, 10.0162, -84.2149, now(), now()
),
-- Renters
(
    'bb000001-0000-0000-0000-000000000001',
    'María', 'Castro', 'maria.castro@demo.com', 'renter',
    'Cartago', 'CR', '+506 8801-0001',
    'Estudiante de música, apasionada por la guitarra y el piano.',
    false, 9.8641, -83.9199, now(), now()
),
(
    'bb000002-0000-0000-0000-000000000002',
    'Diego', 'Ramírez', 'diego.ramirez@demo.com', 'renter',
    'San José', 'CR', '+506 8801-0002',
    'Músico amateur, me gusta probar instrumentos antes de comprar.',
    false, 9.9281, -84.0907, now(), now()
),
(
    'bb000003-0000-0000-0000-000000000003',
    'Lucía', 'Rodríguez', 'lucia.rodriguez@demo.com', 'renter',
    'Heredia', 'CR', '+506 8801-0003',
    'Estudiante de canto que necesita acompañamiento musical de vez en cuando.',
    false, 9.9981, -84.1197, now(), now()
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 3 – INSTRUMENTS (12 listings across all categories)
-- =============================================================================

INSERT INTO public.instruments (
    id, host_id, name, category, description,
    price_per_day, deposit_amount, image_emoji, image_urls,
    location,
    is_available, condition, requires_id,
    rating, review_count,
    created_at, updated_at
) VALUES

-- Carlos's listings (host 1)
(
    'cc000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    'Guitarra Acústica Yamaha F310',
    'string',
    'Guitarra acústica en excelente estado. Ideal para principiantes y músicos intermedios. Incluye funda acolchada.',
    8000, 20000, '🎸', '{}'::text[],
    'San José Centro, Costa Rica',
    true, 'excellent', false, 4.8, 6,
    now() - interval '90 days', now()
),
(
    'cc000002-0000-0000-0000-000000000002',
    'aa000001-0000-0000-0000-000000000001',
    'Ukulele Soprano Kala',
    'string',
    'Ukulele soprano en perfecto estado, afinación estable. Perfecto para viajes o principiantes.',
    4500, 10000, '🪕', '{}'::text[],
    'San José Centro, Costa Rica',
    true, 'excellent', false, 4.9, 3,
    now() - interval '60 days', now()
),
(
    'cc000003-0000-0000-0000-000000000003',
    'aa000001-0000-0000-0000-000000000001',
    'Trompeta Yamaha YTR-2330',
    'brass',
    'Trompeta de latón plateado, llaves de acción suave. Incluye boquilla y estuche.',
    12000, 35000, '🎺', '{}'::text[],
    'San José Centro, Costa Rica',
    true, 'good', true, 4.5, 2,
    now() - interval '45 days', now()
),

-- Sofía's listings (host 2)
(
    'cc000004-0000-0000-0000-000000000004',
    'aa000002-0000-0000-0000-000000000002',
    'Piano Digital Casio CDP-S150',
    'keys',
    'Piano digital de 88 teclas con sensibilidad al tacto. Incluye pedal de sustain y adaptador. Sonido profesional.',
    15000, 50000, '🎹', '{}'::text[],
    'Heredia Centro, Costa Rica',
    true, 'excellent', true, 5.0, 8,
    now() - interval '120 days', now()
),
(
    'cc000005-0000-0000-0000-000000000005',
    'aa000002-0000-0000-0000-000000000002',
    'Violín 4/4 Mendini',
    'string',
    'Violín de tamaño completo con arco, colofonia y estuche. Buen instrumento para estudiantes avanzados.',
    10000, 30000, '🎻', '{}'::text[],
    'Heredia Centro, Costa Rica',
    true, 'good', false, 4.6, 4,
    now() - interval '80 days', now()
),
(
    'cc000006-0000-0000-0000-000000000006',
    'aa000002-0000-0000-0000-000000000002',
    'Guitarra Eléctrica Squier Stratocaster',
    'string',
    'Stratocaster negra con amplificador de práctica Fender Frontman 10G incluido. Lista para tocar.',
    14000, 40000, '🎸', '{}'::text[],
    'Heredia Centro, Costa Rica',
    true, 'good', true, 4.7, 5,
    now() - interval '55 days', now()
),

-- Andrés's listings (host 3)
(
    'cc000007-0000-0000-0000-000000000007',
    'aa000003-0000-0000-0000-000000000003',
    'Batería Pearl Export 5 Piezas',
    'percussion',
    'Set completo de batería acústica: bombo, caja, 2 toms, floor tom y hi-hat. Sin platillos. Ideal para ensayos.',
    25000, 80000, '🥁', '{}'::text[],
    'Alajuela Centro, Costa Rica',
    true, 'good', true, 4.4, 7,
    now() - interval '100 days', now()
),
(
    'cc000008-0000-0000-0000-000000000008',
    'aa000003-0000-0000-0000-000000000003',
    'Cajón Peruano LP Americana',
    'percussion',
    'Cajón de madera con cuerdas internas ajustables, gran sonido. Portátil y fácil de transportar.',
    6000, 15000, '📦', '{}'::text[],
    'Alajuela Centro, Costa Rica',
    true, 'excellent', false, 4.9, 9,
    now() - interval '70 days', now()
),
(
    'cc000009-0000-0000-0000-000000000009',
    'aa000003-0000-0000-0000-000000000003',
    'Saxofón Alto Yamaha YAS-280',
    'brass',
    'Saxo alto lacado dorado, teclas bien ajustadas. Incluye boquilla, ligadura, caña y estuche original.',
    18000, 60000, '🎷', '{}'::text[],
    'Alajuela Centro, Costa Rica',
    true, 'excellent', true, 4.8, 4,
    now() - interval '40 days', now()
),
(
    'cc000010-0000-0000-0000-000000000010',
    'aa000001-0000-0000-0000-000000000001',
    'Bajo Eléctrico Squier Affinity',
    'string',
    'Bajo eléctrico de 4 cuerdas con amplificador de 15W. Buen instrumento para iniciarse en el bajo.',
    11000, 30000, '🎸', '{}'::text[],
    'San José Norte, Costa Rica',
    true, 'good', false, 4.3, 3,
    now() - interval '35 days', now()
),
(
    'cc000011-0000-0000-0000-000000000011',
    'aa000002-0000-0000-0000-000000000002',
    'Flauta Traversa Yamaha YFL-222',
    'brass',
    'Flauta traversa plateada con estuche. Excelente para estudiantes de conservatorio o bachillerato.',
    9000, 25000, '🪗', '{}'::text[],
    'Heredia Norte, Costa Rica',
    true, 'excellent', false, 4.7, 2,
    now() - interval '25 days', now()
),
(
    'cc000012-0000-0000-0000-000000000012',
    'aa000003-0000-0000-0000-000000000003',
    'Teclado MIDI Arturia MiniLab',
    'keys',
    'Controlador MIDI de 25 teclas con pads y knobs. Compatible con cualquier DAW. Incluye cable USB.',
    7000, 18000, '🎹', '{}'::text[],
    'Alajuela Sur, Costa Rica',
    true, 'excellent', false, 4.6, 1,
    now() - interval '15 days', now()
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 4 – RENTALS (mix of statuses)
-- =============================================================================

INSERT INTO public.rentals (
    id, instrument_id, renter_id, host_id,
    start_date, end_date, total_price, deposit_amount, deposit_returned,
    status, instrument_name, instrument_emoji, pickup_method, has_been_reviewed,
    created_at, updated_at
) VALUES
-- Completed rentals (will get reviews)
(
    'dd000001-0000-0000-0000-000000000001',
    'cc000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    '2026-02-01', '2026-02-05', 32000, 20000, true,
    'completed', 'Guitarra Acústica Yamaha F310', '🎸', 'meet_up', true,
    now() - interval '35 days', now() - interval '28 days'
),
(
    'dd000002-0000-0000-0000-000000000002',
    'cc000004-0000-0000-0000-000000000004',
    'bb000001-0000-0000-0000-000000000001',
    'aa000002-0000-0000-0000-000000000002',
    '2026-02-10', '2026-02-17', 105000, 50000, true,
    'completed', 'Piano Digital Casio CDP-S150', '🎹', 'host_address', true,
    now() - interval '28 days', now() - interval '18 days'
),
(
    'dd000003-0000-0000-0000-000000000003',
    'cc000007-0000-0000-0000-000000000007',
    'bb000002-0000-0000-0000-000000000002',
    'aa000003-0000-0000-0000-000000000003',
    '2026-01-20', '2026-01-27', 175000, 80000, true,
    'completed', 'Batería Pearl Export 5 Piezas', '🥁', 'host_address', true,
    now() - interval '48 days', now() - interval '35 days'
),
(
    'dd000004-0000-0000-0000-000000000004',
    'cc000008-0000-0000-0000-000000000008',
    'bb000003-0000-0000-0000-000000000003',
    'aa000003-0000-0000-0000-000000000003',
    '2026-02-14', '2026-02-16', 12000, 15000, true,
    'completed', 'Cajón Peruano LP Americana', '📦', 'meet_up', true,
    now() - interval '20 days', now() - interval '15 days'
),
(
    'dd000005-0000-0000-0000-000000000005',
    'cc000005-0000-0000-0000-000000000005',
    'bb000002-0000-0000-0000-000000000002',
    'aa000002-0000-0000-0000-000000000002',
    '2026-02-20', '2026-02-24', 40000, 30000, true,
    'completed', 'Violín 4/4 Mendini', '🎻', 'meet_up', false,
    now() - interval '14 days', now() - interval '7 days'
),
-- Completed rentals (can still leave review: has_been_reviewed = false)
(
    'dd000012-0000-0000-0000-000000000012',
    'cc000009-0000-0000-0000-000000000009',
    'bb000001-0000-0000-0000-000000000001',
    'aa000003-0000-0000-0000-000000000003',
    '2026-01-15', '2026-01-22', 126000, 60000, true,
    'completed', 'Saxofón Alto Yamaha YAS-280', '🎷', 'meet_up', false,
    now() - interval '55 days', now() - interval '48 days'
),
(
    'dd000013-0000-0000-0000-000000000013',
    'cc000002-0000-0000-0000-000000000002',
    'bb000003-0000-0000-0000-000000000003',
    'aa000001-0000-0000-0000-000000000001',
    '2026-02-05', '2026-02-08', 13500, 10000, true,
    'completed', 'Ukulele Soprano Kala', '🪕', 'meet_up', false,
    now() - interval '32 days', now() - interval '28 days'
),
(
    'dd000014-0000-0000-0000-000000000014',
    'cc000001-0000-0000-0000-000000000001',
    'bb000002-0000-0000-0000-000000000002',
    'aa000001-0000-0000-0000-000000000001',
    '2026-01-08', '2026-01-12', 32000, 20000, true,
    'completed', 'Guitarra Acústica Yamaha F310', '🎸', 'host_address', false,
    now() - interval '62 days', now() - interval '55 days'
),
(
    'dd000015-0000-0000-0000-000000000015',
    'cc000003-0000-0000-0000-000000000003',
    'bb000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    '2026-02-18', '2026-02-21', 36000, 35000, true,
    'completed', 'Trompeta Yamaha YTR-2330', '🎺', 'meet_up', false,
    now() - interval '20 days', now() - interval '16 days'
),
-- Active rentals
(
    'dd000006-0000-0000-0000-000000000006',
    'cc000006-0000-0000-0000-000000000006',
    'bb000001-0000-0000-0000-000000000001',
    'aa000002-0000-0000-0000-000000000002',
    '2026-03-03', '2026-03-10', 98000, 40000, false,
    'active', 'Guitarra Eléctrica Squier Stratocaster', '🎸', 'host_address', false,
    now() - interval '2 days', now() - interval '2 days'
),
(
    'dd000007-0000-0000-0000-000000000007',
    'cc000009-0000-0000-0000-000000000009',
    'bb000003-0000-0000-0000-000000000003',
    'aa000003-0000-0000-0000-000000000003',
    '2026-03-01', '2026-03-08', 126000, 60000, false,
    'active', 'Saxofón Alto Yamaha YAS-280', '🎷', 'meet_up', false,
    now() - interval '4 days', now() - interval '4 days'
),
-- Confirmed (upcoming)
(
    'dd000008-0000-0000-0000-000000000008',
    'cc000002-0000-0000-0000-000000000002',
    'bb000002-0000-0000-0000-000000000002',
    'aa000001-0000-0000-0000-000000000001',
    '2026-03-10', '2026-03-13', 13500, 10000, false,
    'confirmed', 'Ukulele Soprano Kala', '🪕', 'meet_up', false,
    now() - interval '1 day', now() - interval '1 day'
),
(
    'dd000009-0000-0000-0000-000000000009',
    'cc000012-0000-0000-0000-000000000012',
    'bb000001-0000-0000-0000-000000000001',
    'aa000003-0000-0000-0000-000000000003',
    '2026-03-12', '2026-03-15', 21000, 18000, false,
    'confirmed', 'Teclado MIDI Arturia MiniLab', '🎹', 'meet_up', false,
    now(), now()
),
-- Pending (waiting for host approval)
(
    'dd000010-0000-0000-0000-000000000010',
    'cc000003-0000-0000-0000-000000000003',
    'bb000003-0000-0000-0000-000000000003',
    'aa000001-0000-0000-0000-000000000001',
    '2026-03-15', '2026-03-18', 36000, 35000, false,
    'pending', 'Trompeta Yamaha YTR-2330', '🎺', 'host_address', false,
    now(), now()
),
(
    'dd000011-0000-0000-0000-000000000011',
    'cc000010-0000-0000-0000-000000000010',
    'bb000002-0000-0000-0000-000000000002',
    'aa000001-0000-0000-0000-000000000001',
    '2026-03-20', '2026-03-23', 33000, 30000, false,
    'pending', 'Bajo Eléctrico Squier Affinity', '🎸', 'meet_up', false,
    now(), now()
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 5 – INSTRUMENT REVIEWS (for completed rentals)
-- =============================================================================

INSERT INTO public.reviews (
    id, rental_id, instrument_id, renter_id,
    rating, comment, reviewer_name, host_reply,
    created_at
) VALUES
(
    'ee000001-0000-0000-0000-000000000001',
    'dd000001-0000-0000-0000-000000000001',
    'cc000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    5, 'Guitarra en perfecto estado, la cuerda llegó bien afinada y el sonido es hermoso. Carlos fue muy amable y puntual.',
    'María Castro', 'Gracias María, fue un placer rentarte la guitarra. ¡Vuelve cuando quieras!',
    now() - interval '27 days'
),
(
    'ee000002-0000-0000-0000-000000000002',
    'dd000002-0000-0000-0000-000000000002',
    'cc000004-0000-0000-0000-000000000004',
    'bb000001-0000-0000-0000-000000000001',
    5, 'El piano digital es increíble, el tacto es muy parecido a un piano acústico. Sofía me explicó todo perfectamente.',
    'María Castro', '¡Qué bueno que disfrutaste el piano! Fue genial tenerte como arrendataria.',
    now() - interval '17 days'
),
(
    'ee000003-0000-0000-0000-000000000003',
    'dd000003-0000-0000-0000-000000000003',
    'cc000007-0000-0000-0000-000000000007',
    'bb000002-0000-0000-0000-000000000002',
    4, 'La batería suena muy bien, pero el parche del bombo estaba un poco desgastado. El proceso fue rápido y sencillo.',
    'Diego Ramírez', 'Gracias por el feedback Diego. Ya cambié el parche del bombo.',
    now() - interval '34 days'
),
(
    'ee000004-0000-0000-0000-000000000004',
    'dd000004-0000-0000-0000-000000000004',
    'cc000008-0000-0000-0000-000000000008',
    'bb000003-0000-0000-0000-000000000003',
    5, 'El cajón suena de maravilla, los graves son profundos y los agudos muy definidos. Lo recomiendo 100%.',
    'Lucía Rodríguez', '¡Gracias Lucía! El cajón es mi favorito, me alegra que lo hayas disfrutado.',
    now() - interval '14 days'
),
(
    'ee000005-0000-0000-0000-000000000005',
    'dd000001-0000-0000-0000-000000000001',
    'cc000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    5, 'Segunda vez rentando esta guitarra. Siempre en perfectas condiciones. Carlos es el mejor host.',
    'María Castro', null,
    now() - interval '10 days'
),
(
    'ee000006-0000-0000-0000-000000000006',
    'dd000003-0000-0000-0000-000000000003',
    'cc000007-0000-0000-0000-000000000007',
    'bb000002-0000-0000-0000-000000000002',
    4, 'Buena batería para ensayos. Le faltan algunos platillos pero el precio es muy justo.',
    'Diego Ramírez', null,
    now() - interval '20 days'
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 6 – INSTRUMENT COMMENTS (Q&A on listings)
-- Skipped: requires Supabase_InstrumentComments.sql. Run that migration first to enable.
-- =============================================================================


-- =============================================================================
-- STEP 7 – USER REVIEWS (host ↔ renter, for completed rentals)
-- =============================================================================

INSERT INTO public.user_reviews (
    id, rental_id, reviewer_id, reviewee_id, reviewer_role, rating, comment, reviewer_name, created_at
) VALUES
-- María (renter) reviewed Carlos (host) for dd000001
(
    '0f000001-0000-0000-0000-000000000001',
    'dd000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    'renter', 5, 'Carlos fue muy profesional y la guitarra estaba impecable.',
    'María Castro', now() - interval '27 days'
),
-- Carlos (host) reviewed María (renter) for dd000001
(
    '0f000002-0000-0000-0000-000000000002',
    'dd000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    'host', 5, 'María cuidó muy bien el instrumento. Excelente arrendataria.',
    'Carlos Mora', now() - interval '27 days'
),
-- María (renter) reviewed Sofía (host) for dd000002
(
    '0f000003-0000-0000-0000-000000000003',
    'dd000002-0000-0000-0000-000000000002',
    'bb000001-0000-0000-0000-000000000001',
    'aa000002-0000-0000-0000-000000000002',
    'renter', 5, 'Sofía muy amable, el piano estaba perfecto.',
    'María Castro', now() - interval '17 days'
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- STEP 8 – Refresh instrument ratings from reviews
-- =============================================================================

UPDATE public.instruments i
SET
    rating       = sub.avg_rating,
    review_count = sub.cnt,
    updated_at   = now()
FROM (
    SELECT
        instrument_id,
        ROUND(AVG(rating)::numeric, 2) AS avg_rating,
        COUNT(*) AS cnt
    FROM public.reviews
    GROUP BY instrument_id
) sub
WHERE i.id = sub.instrument_id;


-- =============================================================================
-- Done!
-- 
-- Demo accounts (password: Encore123!)
-- ─────────────────────────────────────────
-- HOSTS
--   carlos.mora@demo.com     → San José,  3 listings
--   sofia.vargas@demo.com    → Heredia,   4 listings
--   andres.jimenez@demo.com  → Alajuela,  4 listings
--
-- RENTERS
--   maria.castro@demo.com    → Cartago
--   diego.ramirez@demo.com   → San José
--   lucia.rodriguez@demo.com → Heredia
--
-- 12 instruments, 15 rentals, 6 instrument reviews, 3 user reviews inserted.
--
-- Rentals that can still leave a review (has_been_reviewed = false):
--   diego.ramirez@demo.com  → Violín 4/4 Mendini (Sofía)
--   maria.castro@demo.com  → Saxofón (Andrés), Trompeta (Carlos)
--   lucia.rodriguez@demo.com → Ukulele (Carlos)
--   diego.ramirez@demo.com  → Guitarra Acústica (Carlos)
--
-- Testing reviews: Sign in as diego.ramirez@demo.com → My Rentals → Violín 4/4 Mendini
-- (dd000005 has has_been_reviewed=false) → Rate + Review Host. As sofia.vargas@demo.com
-- → Reservations → Past → same rental → Review Renter.
-- =============================================================================
