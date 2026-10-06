# Encore app – context for fixing profile/listings not showing

Use this file when asking Claude to help fix: **profile picture not showing, last name not showing, and host listings not showing** in the app, even though the data exists in Supabase.

---

## App overview

- **Encore**: iOS instrument rental app (SwiftUI, Supabase via URLSession).
- **Auth/profile**: `AuthManager` loads the current user from `public.users` (not `profiles`). Profile UI uses `auth.currentUser` (avatar, displayName = first + last name).
- **Listings**: Host instruments are loaded from `public.instruments` with `host_id=eq.<current-user-uuid>`.

---

## The problem

1. **Profile picture (avatar)** – Stored in Supabase (`users.avatar_url`) and visible in Dashboard/Table Editor, but not displayed in the app (profile shows default gray avatar).
2. **Last name** – Stored in `users.last_name`, but not shown in profile (displayName should be first + last).
3. **Host listings** – Instruments created by the host exist in `instruments` but "Your listings" shows empty (no listings).

---

## Supabase schema (relevant)

```sql
-- Table used for profile (the app uses this, not public.profiles)
public.users (
  id uuid PK, name text, last_name text, email text, role text,
  avatar_url text, city text, phone text, bio text, ...
)

-- Host instruments
public.instruments (
  id uuid PK, host_id uuid FK->users(id), name text, image_urls text[],
  created_at, updated_at, ...
)
```

- **Avatar**: full URL or path in `users.avatar_url`.
- **Instrument images**: array of URLs in `instruments.image_urls`.
- Storage buckets: `avatars`, `instrument-photos` (should be **public** in Storage settings).

---

## What’s already been done in the app

1. **URL normalization** (`Encore/Network/StorageService.swift`):
   - `StorageService.normalizedImageURL(_:bucket:)` – if value doesn’t start with `http`, builds public URL: `https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>`.
   - `ProfileAvatarView` uses it with bucket `avatars`.
   - `RemoteImage` uses it with bucket `instrument-photos` by default.

2. **Fetch with proper encoding** (`Encore/Network/SupabaseClient.swift`, `AuthManager`, `HostListingsView`):
   - User fetch: `client.fetch(table: "users", query: [URLQueryItem(name: "id", value: "eq.\(uid)"), URLQueryItem(name: "select", value: "id,name,last_name,...,avatar_url,...")])`.
   - Listings fetch: `client.fetch(table: "instruments", query: [URLQueryItem(name: "host_id", value: "eq.\(hostId)"), URLQueryItem(name: "order", value: "created_at.desc")])`.

3. **Profile refresh**: Renter and Host profile views call `auth.refreshUser()` in `.task` when the view appears; `refreshUser()` calls `loadUserAndRole()` which refetches from `users` with the select above.

4. **Models**: `AppUser` has `avatarUrl`, `lastName`, `displayName` (first + last). `Instrument` has `imageUrls: [String]`. CodingKeys map `avatar_url`, `last_name`, `image_urls`.

5. **RLS** (from `Supabase_Setup.sql`): `users` has `users_select_own` and `users_select_public`; `instruments` has `instruments_select_all` (USING true). JWT is sent in `Authorization` header; `SupabaseClient.accessToken` is set by `AuthManager` after sign-in and on restore.

---

## Key file paths

| Purpose | Path |
|--------|------|
| Auth + load user | `Encore/App/AuthManager.swift` |
| Supabase client + fetch | `Encore/Network/SupabaseClient.swift` |
| Storage + avatar/image views | `Encore/Network/StorageService.swift` |
| User model | `Encore/Models/Models.swift` (AppUser, Instrument) |
| Profile UI | `Encore/Views/Renter/RenterProfileView.swift`, `Encore/Views/Host/HostProfileView.swift`, `Encore/Views/Shared/EditProfileView.swift` |
| Host listings | `Encore/Views/Host/HostListingsView.swift`, `Encore/Views/Host/AddInstrumentView.swift` |
| SQL setup | `Supabase_Setup.sql`, `Supabase_HostMode_Ensure.sql` |

---

## What to check / try next

1. **API responses**
   - Add temporary logging in `AuthManager.loadUserAndRole()`: print decoded `user.avatarUrl`, `user.lastName`, and `users.count`.
   - In `HostListingsView.loadListingsAsync()`: print `list.count` and any decode error. Confirm whether the backend returns 0 rows or decoding fails.

2. **RLS and JWT**
   - Confirm RLS policies on `users` and `instruments` allow SELECT for the authenticated user (and that `instruments_select_all` or equivalent allows reading host’s instruments).
   - Confirm `SupabaseClient.shared.accessToken` is set when these fetches run (e.g. after sign-in and when restoring session).

3. **Storage**
   - In Supabase Dashboard → Storage: buckets `avatars` and `instrument-photos` set to **Public**.
   - Values in `users.avatar_url` and `instruments.image_urls`: either full URLs (`https://.../storage/v1/object/public/...`) or paths that the app can turn into that format via `normalizedImageURL`.

4. **Decoding**
   - Ensure `AppUser` decoding includes `last_name` and `avatar_url` (CodingKeys + optional handling). If the API returns `null` for some fields, make sure the model allows optional where needed so decode doesn’t throw and zero out the whole object.

5. **UI refresh**
   - Profile header uses `.id(displayName + avatarUrl)` so the view updates when user changes. After saving profile or refreshing, `auth.currentUser` should be updated by `loadUserAndRole()`; confirm that flow runs and that the UI is bound to `auth.currentUser`.

---

## One-line summary

**Problem**: Profile picture, last name, and host listings don’t show in the app even though the data exists in Supabase; fix by verifying fetch URLs/encoding, RLS + JWT, storage public URLs/paths, decoding, and that the UI refreshes from the refetched user and instruments.
