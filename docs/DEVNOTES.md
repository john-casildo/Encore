# Encore — Dev Notes

## SQL Scripts to Run in Supabase (in order)

1. **`Supabase_AllFixes.sql`** — Run this first. Covers all RLS policies, makes `messages.rental_id` nullable, creates `instrument_comments` table.
2. **`Supabase_AddAddress.sql`** — Adds `address` column to `users`, re-confirms public instruments policy.
3. **Run manually if `city` column is missing:**
   ```sql
   ALTER TABLE public.users ADD COLUMN IF NOT EXISTS city text;
   ```

---

## Important Things to Note

- **Email changes require confirmation** — When a user updates their email in Edit Profile, Supabase sends a confirmation link to the new address. The change won't apply until they click the link. Expected behavior.

- **Location permission** — `NSLocationWhenInUseUsageDescription` must be in `Info.plist` for the "Use my location" button to work. Already added but double-check if location crashes.

- **New Swift files added outside Xcode** — If you ever get "Cannot find X in scope", it means a file wasn't added to the Xcode target. Files that were manually wired in `project.pbxproj`:
  - `HelpView.swift`
  - `PrivacySettingsView.swift`
  - `LegalView.swift`
  - `UserReviewFormView.swift`
  - `UserReviewsListView.swift`
  - `LocationManager.swift`
  - `CountryCodePickerView.swift`
  
  Fix: drag the file into Xcode's project navigator and make sure the target checkbox is checked.

- **Clean build after big changes** — `Cmd + Shift + K` (Clean Build Folder) in Xcode before building clears stale compiler cache that causes phantom errors.

---

## What's Working

- Auth (sign in, sign up, forgot password)
- Role switching (Renter ↔ Host)
- Browse instruments with category filters, sort, and nearby radius
- Favorites / Saved tab
- Host listings (create, edit, delete with images)
- Multi-step checkout flow (dates → pickup → payment → confirm)
- Messaging with 5-second polling
- Instrument comments (public)
- Reviews: instrument reviews + user-to-user reviews (host ↔ renter)
- Host Insights dashboard (revenue, bookings, top instruments)
- Edit Profile (name, last name, bio, city, country, address, phone with country code, avatar, email)
- Signup with full info (name, last name, country, city, address, phone)
- Help, Privacy Settings, Legal pages
- Bilingual support (English / Spanish)

---

## Suggestions for Next Sessions

| Feature | Notes |
|---|---|
| Push notifications | Rental status changes + new messages via Supabase Edge Functions + APNs |
| Real Stripe payments | Checkout saves cards but no actual charge — needs Edge Function |
| Host approval flow | pending → approved / rejected before rental is confirmed |
| Instrument image gallery | Multiple photos per listing (store as JSON array of URLs) |
| Search bar in Browse | Keyword search by instrument name / description |
| Verified badge UI | `is_verified` column exists in DB but isn't shown anywhere |
| Onboarding screens | 2–3 screens explaining Renter vs Host on first launch |

---

*Last updated: March 3, 2026*
