# Encore — Instrument Rental App: Build Plan

This document defines architecture, file structure, data models, and screen flow. **No code will be written until you approve this plan.**

---

## 1. Tech Stack (Locked)

| Layer | Choice |
|-------|--------|
| Language | Swift only (no RN, Flutter, Objective-C) |
| UI | SwiftUI, iOS 16+ |
| Backend | Supabase REST API via `URLSession` (no Supabase Swift SDK) |
| Storage | Supabase Storage (images) |
| Auth | Supabase Auth (email/password) |
| Dependencies | **Zero** — no SPM, no CocoaPods |

---

## 2. Design System — Corporate Memphis

- **Colors (from Figma):**
  - **Primary / accent:** Bright yellow (`#FFD93D` or similar) for CTAs, selected tabs, highlights
  - **Frame / secondary accent:** Lime green for outer framing/branding (splash, welcome)
  - **Surfaces:** White for content cards and main content areas
  - **Text:** Dark gray / black for primary text; gray for secondary
- **Typography:** Clean sans-serif (SF Pro by default; no custom fonts to avoid dependencies)
- **UI:** Rounded corners on cards, buttons, and inputs; simple line icons; ample whitespace
- **Illustrations:** Optional simple, geometric “Corporate Memphis” style where needed (e.g. welcome)
- **iOS:** Follow HIG (navigation patterns, safe areas, dynamic type where practical, native controls)

---

## 3. App Structure Overview

### 3.1 User Roles

- **Renter** — Browse instruments, book, manage rentals, message hosts, rate completed rentals.
- **Host** — List instruments, manage availability, approve/decline bookings, view earnings, reply to reviews.
- **Role switching:** User can switch between Renter and Host within the app (stored in `profiles.role`; UI shows different tab roots).

### 3.2 High-Level Architecture

- **Single SwiftUI app** with role-based root:
  - Not authenticated → `AuthView` (or onboarding if needed).
  - Authenticated → either **Renter** root (tab bar) or **Host** root (tab bar); switch via Profile/Menu.
- **Auth:** `AuthManager` (ObservableObject) holds session, current user, and role; used for `Authorization` header and routing.
- **API:** All Supabase access via `SupabaseClient` (URLSession). No SDK.
- **Storage:** `StorageService` for upload/delete; `RemoteImage` + emoji fallback in one place (e.g. in or next to `StorageService` as specified).
- **Localization:** `LanguageManager` (ObservableObject) with `.english` / `.spanish`; all UI strings via centralized strings (e.g. `Strings` or similar) keyed by language.

---

## 4. File Structure (Full File List)

```
Encore/
├── App/
│   ├── EncoreApp.swift              # @main, environment objects, root navigation
│   ├── AuthManager.swift            # Session, user, role; login/logout/signUp
│   └── LanguageManager.swift       # .english / .spanish, persisted
├── Network/
│   ├── SupabaseClient.swift        # REST: fetch, insert (Encodable + [String:Any]), update, delete
│   └── StorageService.swift        # upload, uploadMultiple (sequential), delete; RemoteImage
├── Models/
│   └── Models.swift                # AppUser, Instrument, Rental, Review, NewInstrument, enums
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift          # Sign in / sign up, role selection (Renter/Owner)
│   ├── Renter/
│   │   ├── BrowseView.swift
│   │   ├── InstrumentDetailView.swift
│   │   ├── CheckoutView.swift
│   │   ├── MyRentalsView.swift
│   │   └── RenterProfileView.swift
│   ├── Host/
│   │   ├── HostDashboardView.swift
│   │   ├── HostListingsView.swift
│   │   ├── AddInstrumentView.swift
│   │   ├── HostBookingsView.swift
│   │   └── HostProfileView.swift
│   └── Shared/
│   ├── RatingsView.swift          # Star + comment, submit review
│   ├── ReviewsListView.swift      # Summary bars + review cards, host reply
│   ├── Components/                 # Optional: reusable chips, cards, nav bar
│   └── (any shared UI)
├── Resources/
│   └── Localizable.strings        # Or inline enum; EN + ES
└── Extensions/
    └── Extensions.swift           # Color(hex:), StyledTextField, etc.
```

- **No** separate `Components` folder required if you prefer to keep shared UI next to `Shared` views; the list above is minimal and can be flattened.
- **RemoteImage:** Defined once (e.g. in `StorageService.swift` as specified in the prompt).

---

## 5. Data Models (Swift ↔ Supabase)

### 5.1 Supabase Table Definitions (Reference)

```sql
-- Mirrors auth.users; synced on signup or first login
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'renter',  -- 'renter' | 'host'
  city TEXT,
  avatar_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  language TEXT DEFAULT 'en',          -- 'en' | 'es'
  phone TEXT,
  bio TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: users can read/update own profile; public read for listing display
-- (Exact RLS policies to be defined in Supabase dashboard.)

CREATE TABLE instruments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,             -- e.g. 'string', 'percussion', 'keys', 'brass', 'other'
  description TEXT,
  price_per_day DECIMAL(12,2) NOT NULL,
  deposit_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  image_emoji TEXT,                  -- fallback if no images
  image_urls TEXT[] DEFAULT '{}',    -- Supabase Storage URLs
  location TEXT,                     -- human-readable address/area
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_available BOOLEAN DEFAULT TRUE,
  rating DECIMAL(3,2) DEFAULT NULL, -- 1.00–5.00, null if no reviews
  review_count INTEGER DEFAULT 0,
  condition TEXT,                    -- e.g. 'excellent', 'good', 'fair'
  requires_id BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rentals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instrument_id UUID NOT NULL REFERENCES instruments(id) ON DELETE CASCADE,
  renter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  deposit_amount DECIMAL(12,2) NOT NULL,
  deposit_returned BOOLEAN DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending | confirmed | active | completed | cancelled
  instrument_name TEXT,
  instrument_emoji TEXT,
  pickup_method TEXT NOT NULL,       -- 'meet_up' | 'host_address' | 'shipping'
  has_been_reviewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id UUID NOT NULL REFERENCES rentals(id) ON DELETE CASCADE,
  instrument_id UUID NOT NULL REFERENCES instruments(id) ON DELETE CASCADE,
  renter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  reviewer_name TEXT,
  reviewer_avatar_url TEXT,
  host_reply TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_instruments_host_id ON instruments(host_id);
CREATE INDEX idx_instruments_category ON instruments(category);
CREATE INDEX idx_instruments_is_available ON instruments(is_available);
CREATE INDEX idx_rentals_renter_id ON rentals(renter_id);
CREATE INDEX idx_rentals_host_id ON rentals(host_id);
CREATE INDEX idx_rentals_status ON rentals(status);
CREATE INDEX idx_reviews_instrument_id ON reviews(instrument_id);
```

### 5.2 Storage Buckets

- `instrument-photos` (public) — instrument images.
- `avatars` (public) — profile avatars.

### 5.3 Swift Models (Models.swift)

- **AppUser** — maps to `profiles`: id, name, email, role, city, avatarUrl, latitude, longitude, language, phone, bio, isVerified. Conform to `Codable` with snake_case coding keys where needed.
- **Instrument** — id, hostId, name, category, description, pricePerDay, depositAmount, imageEmoji, imageUrls, location, latitude, longitude, isAvailable, rating, reviewCount, condition, requiresId. Optional: `host` (nested or fetched separately).
- **Rental** — id, instrumentId, renterId, hostId, startDate, endDate, totalPrice, depositAmount, depositReturned, status, instrumentName, instrumentEmoji, pickupMethod, hasBeenReviewed, createdAt. Status enum: `pending`, `confirmed`, `active`, `completed`, `cancelled`.
- **Review** — id, rentalId, instrumentId, renterId, rating, comment, reviewerName, reviewerAvatarUrl, hostReply, createdAt.
- **NewInstrument** — for create/update: name, category, description, pricePerDay, depositAmount, imageEmoji, imageUrls, location, latitude, longitude, condition, requiresId (and optionally isAvailable). Used by `AddInstrumentView`.
- **Sample/Preview data:** `Instrument.samples`, `Rental.samples`, `Review.samples` in `#if DEBUG` or clearly marked for previews only; never used in production list logic.

---

## 6. Network Layer Rules

### 6.1 SupabaseClient

- Base URL: `https://<project-ref>.supabase.co/rest/v1/`.
- Headers on every request: `apikey`, `Authorization: Bearer <token>`, `Content-Type: application/json` for body, `Accept: application/json` for GET.
- If token is nil: log a clear warning and still send the request (so unauthenticated endpoints work if any).
- **Insert:** Two overloads — one for `Encodable`, one for `[String: Any]`.
- **Errors:** Log status code and response body for every non-2xx; never swallow failures silently.
- Methods: `fetch<T>(table:query:)`, `insert<T>(table:body:)` (Encodable), `insert(table:body:)` ([String:Any]), `update(table:id:body:)`, `delete(table:id:)` (or filter). Exact signatures can be refined in implementation.

### 6.2 StorageService

- Bucket enum: `.instruments = "instrument-photos"`, `.avatars = "avatars"`.
- `upload(bucket:path:data:contentType:)` → returns public URL or throws.
- `uploadMultiple(bucket:pathsAndData:)` — **sequential** only (chain completions); no concurrent uploads.
- Header `x-upsert: true` (not `"public-read"`).
- On non-2xx: log full response body.
- **RemoteImage:** Single place (e.g. in `StorageService.swift`): loads URL with placeholder/emoji fallback; used app-wide for instruments and avatars.

---

## 7. Screen Flow (Text-Based)

```
[App Launch]
    │
    ├─ No session ──────────────────────────────────► AuthView
    │       │
    │       ├─ Sign in / Sign up (email + password)
    │       ├─ Role: Renter | Owner (Host)
    │       └─ On success: fetch/upsert profile, set role ─► Role-specific root
    │
    └─ Has session ─────────────────────────────────► Role-specific root
            │
            ├─ Renter root (TabView)
            │   ├─ Home (BrowseView)
            │   │     └─ Tap instrument ─► InstrumentDetailView
            │   │             ├─ Reserve ─► CheckoutView ─► Confirm ─► create rental (pending) ─► My Rentals or Home
            │   │             └─ Reviews ─► ReviewsListView
            │   ├─ Transactions (optional; or merged into My Rentals)
            │   ├─ My Rentals (MyRentalsView: Active | History)
            │   │     └─ Completed rental ─► Rate ─► RatingsView ─► submit review, update instrument rating, set has_been_reviewed
            │   ├─ Messages (placeholder or simple list; can be stub)
            │   └─ Profile (RenterProfileView) ─► Settings, language, Switch to Host, Sign out
            │
            └─ Host root (TabView) [dark theme]
                ├─ Today/Dashboard (HostDashboardView) — earnings, chart, pending, activity
                ├─ Calendar (optional; or part of Bookings)
                ├─ Listings (HostListingsView) ─► + Add ─► AddInstrumentView ─► create instrument
                ├─ Messages (shared concept)
                └─ Menu (HostProfileView) ─► Earnings, Insights, Create listing, Account, Switch to Renter, Sign out
                    └─ HostBookingsView (e.g. from Menu or separate tab) — Pending / Active / Past; Approve | Decline for pending
```

- **ReviewsListView** is reachable from InstrumentDetailView (and optionally from My Rentals for “See all reviews”).
- **RatingsView** is reached after a completed rental (e.g. “Rate” on a completed card in MyRentalsView); on submit: insert review, then recalc instrument rating/review_count, set rental `has_been_reviewed = true`.

---

## 8. Screen-by-Screen Summary

| Screen | Purpose | Key Behaviors |
|--------|--------|----------------|
| **AuthView** | Sign in / sign up, role selection | Email + password; role Renter/Owner; create session and profile |
| **BrowseView** | Grid of instruments, search, categories, location | Fetch instruments (filter by category, search, sort by distance if lat/long); ProgressView + empty state |
| **InstrumentDetailView** | Single instrument: image, price, description, deposit, reviews, map | Sticky “Reserve” CTA; link to ReviewsListView; Reserve → CheckoutView |
| **CheckoutView** | Dates, pickup method, price breakdown, confirm | Date picker; pickup: Meet Up / Host’s Address / Shipping; show total; confirm → insert rental (pending) |
| **MyRentalsView** | Tabs: Active, History | Rental cards with status; “Rate” for completed; empty state |
| **RenterProfileView** | Avatar, stats, settings, language, sign out | Language toggle EN/ES; sign out |
| **HostDashboardView** | Dark theme; earnings, 6-month chart, pending, activity | Fetch rentals/earnings for host; simple bar chart (SwiftUI shapes) |
| **HostListingsView** | List of host instruments, availability toggle, + add | Fetch by host_id; toggle is_available; + → AddInstrumentView |
| **AddInstrumentView** | Form: name, category, price, deposit, location, condition, description, ID required, photos (≤5) | Upload photos sequentially; insert instrument |
| **HostBookingsView** | Tabs: Pending, Active, Past | Pending: Approve (→ confirmed) / Decline (→ cancelled); list by status |
| **HostProfileView** | Dark theme; earnings, menu, Switch to Renter | Menu rows; switch role to renter |
| **RatingsView** | 1–5 stars + comment | Submit review; then recalc instrument rating and set has_been_reviewed |
| **ReviewsListView** | Summary bars + review cards, host reply | Read-only for renter; host can add reply (update review) if we support it |

---

## 9. Key Behaviors (Logic)

- **Booking flow:** Renter submits from CheckoutView → rental created with `status: pending`. Host approves → `confirmed`; when dates overlap “today” or host marks active → `active`; after end date or host marks done → `completed`. Decline → `cancelled`.
- **Reviews:** After submit in RatingsView: insert `reviews` row; fetch all reviews for that instrument; recompute average and count; update `instruments.rating` and `instruments.review_count`; set `rentals.has_been_reviewed = true` for that rental.
- **Date format:** All date math and API use `yyyy-MM-dd` (DateFormatter explicitly set).
- **Optimistic UI:** For status toggles (e.g. approve booking, availability), update UI immediately then persist; on failure, revert and show error.
- **Empty / loading:** Every list view: loading → ProgressView; empty → empty state message; data → list. No hardcoded sample data in production.

---

## 10. Bilingual Support

- **LanguageManager:** ObservableObject with `language: .english | .spanish`, persisted (UserDefaults or App Storage).
- **Helper:** e.g. `var sp: Bool { languageManager.language == .spanish }` (or a `Strings` API that takes language).
- **Strings:** Every user-facing string has EN and ES; language toggle in RenterProfileView and HostProfileView.

---

## 11. Optional Additions / Notes

- **Messages:** Implement as a lightweight list + detail (list conversations, then chat-style view); store can be a simple `messages` table (sender_id, rental_id or thread_id, body, created_at) and fetch in Shared MessagesView. If you prefer to stub it for v1, we can show a “Coming soon” or empty list.
- **Notifications:** Bell icon can be a stub (no push in v1) or deep-link later.
- **Maps:** InstrumentDetailView “Rental Location” can use Map with coordinate (SwiftUI Map); no need for MapKit keys if using default map.
- **Host “Insights”:** Can be a placeholder screen or a simple list of bookings/earnings by period; full analytics can come later.
- **RLS:** Supabase RLS should restrict: profiles (read own + public read for display); instruments (host CRUD own, public read); rentals (renter/host see own); reviews (read all, create by renter, update host_reply by host). We’ll implement client with correct auth; you’ll configure RLS in Supabase.

---

## 12. Implementation Order (After Approval)

1. **Foundation:** `Models.swift`, `SupabaseClient.swift`, `StorageService.swift` (with RemoteImage), `AuthManager.swift`, `LanguageManager.swift`, `Extensions.swift`.
2. **Auth:** `AuthView` and wiring in `EncoreApp.swift` (session → AuthView vs main app).
3. **Renter:** BrowseView → InstrumentDetailView → CheckoutView → MyRentalsView → RenterProfileView; then RatingsView and ReviewsListView.
4. **Host:** HostDashboardView → HostListingsView → AddInstrumentView → HostBookingsView → HostProfileView.
5. **Polish:** Empty states, error toasts, language strings, and any shared components.

Checkpoints: after each major screen or group (e.g. after Auth, after Renter flows, after Host flows), we can “check in” so you can run and test before moving on.

---

## 13. What I Need From You

- **Approval** of this plan (or edits you want).
- **Supabase:** Project URL and anon key (and optionally service role for admin tasks); we’ll use env or a config that’s gitignored for keys.
- **Confirm:** Whether Messages should be a real feature in v1 (with a simple table and UI) or a stub.
- **Confirm:** Whether Host can reply to reviews in v1 (if yes, we add “Reply” in ReviewsListView for host and an `update` on `reviews.host_reply`).

Once you confirm, implementation starts with step 1 (Models, Network, AuthManager, LanguageManager, Extensions) and then Auth screens.
