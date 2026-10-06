# Encore — Comprehensive Testing Plan

This document provides an analysis of key components, data flows, edge cases, and a proposed testing strategy. **No test code has been generated yet** — approve this plan to proceed with implementation.

---

## 1. Analysis

### 1.1 Current State

- **No existing tests** — The project has no `tests` folder and no XCTest target in the Xcode project.
- **SwiftUI + Supabase** — iOS 16+, URLSession-based REST, no Supabase SDK.
- **Singletons** — `AuthManager.shared`, `SupabaseClient.shared`, `FavoritesStore.shared`, `StorageService.shared` are used throughout.

### 1.2 Key Components & Data Flows

| Component | Key Functions | Data Flow |
|-----------|---------------|-----------|
| **Models** | `AppUser.displayName`, `Codable` init/encode | JSON ↔ Swift structs |
| **SupabaseClient** | `fetch`, `insert`, `update`, `delete` | URL building, headers, decode, assertOK |
| **AuthManager** | `init`, `loadUserAndRole`, `refreshTokens`, `validateSessionIfNeeded`, `signIn`, `signUp` | UserDefaults → session → API |
| **FavoritesStore** | `load`, `toggle`, `isFavorite`, `clear` | API → Set<UUID>, optimistic updates |
| **StorageService** | `upload`, `uploadMultiple`, `delete`, `normalizedImageURL` | Data → Supabase Storage |
| **CheckoutView** | `cardBrand`, `formatCardNumber`, `formatExpiry`, `loadRentedDates`, `handlePaymentStep` | Card validation, date range logic |
| **CountryDialCode** | `forIso`, `fromLocale` | ISO lookup, locale fallback |
| **LocationChipView** | `locationText` (computed) | city + country → display string |
| **Extensions** | `Color.init(hex:)`, `RoundedCorner.path` | Hex parsing, shape geometry |

### 1.3 Potential Edge Cases

| Area | Edge Cases |
|------|------------|
| **AppUser.displayName** | `name`/`lastName` nil, empty, whitespace-only; `email` nil; all empty → "—" |
| **Models Codable** | Missing keys, null values, wrong types (e.g. `instruments` JSON embed) |
| **RentalStatus / PickupMethod** | Unknown raw values from API |
| **Conversation** | `instruments` nested object vs. missing |
| **Card validation** | Empty, short digits, invalid expiry (past/format), CVV length |
| **Card brand** | `4` (Visa), `5`/`2` (Mastercard), `34`/`37` (Amex), unknown |
| **formatCardNumber** | Empty, 16+ digits, non-numeric |
| **formatExpiry** | 2 digits, 4 digits, invalid |
| **CountryDialCode.forIso** | `nil`, empty string, unknown ISO, case mismatch |
| **LocationChipView** | `city` nil, `country` nil, both empty, whitespace-only city |
| **Color(hex:)** | 3, 6, 8, 0 chars; invalid hex; non-hex chars |
| **FavoritesStore** | No session, API failure, toggle race (optimistic revert) |
| **Rented dates** | `startDate`/`endDate` parse failure, invalid range |
| **URL building** | Empty query, special chars in UUIDs |

---

## 2. Testing Strategy

### 2.1 Unit Tests (XCTest)

**Target:** `EncoreTests` (new unit test target)

| Test File | Scope | Tests |
|-----------|-------|-------|
| **AppUserTests** | `displayName` | Happy path (first+last), name only, email fallback, all empty → "—", whitespace |
| **ModelsTests** | Codable decoding | `AppUser`, `Instrument`, `Rental`, `Conversation` from JSON; missing keys, nulls |
| **CheckoutHelpersTests** | Pure logic | `cardBrand`, `formatCardNumber`, `formatExpiry` (extracted or tested via internal access) |
| **CountryDialCodeTests** | `forIso`, `fromLocale` | ISO lookup, nil, empty, unknown, case |
| **LocationChipViewTests** | `locationText` logic | city+country, city only, country only, empty, nil |
| **ColorHexTests** | `Color.init(hex:)` | 3/6/8/0 chars, invalid hex |
| **RoundedCornerTests** | `RoundedCorner.path` | Path output for given rect |

**Note:** `cardBrand`, `formatCardNumber`, `formatExpiry` are private in `CheckoutView`. Options:
- Extract to a shared `CheckoutHelpers` struct/enum in a separate file, or
- Test via `@testable import Encore` if they remain internal (they’re in a View).

### 2.2 Integration Tests

**Target:** `EncoreTests` (same target, separate section)

| Test | Scope | Approach |
|------|-------|----------|
| **SupabaseClient** | fetch/insert/update/delete | Mock `URLSession` via `URLProtocol` or inject mock; verify URL, headers, body |
| **AuthManager** | Session restore, sign-in | Mock `URLSession`; verify UserDefaults, `currentUser`, `session` |
| **FavoritesStore** | `toggle`, `load` | Mock `SupabaseClient` (requires protocol abstraction) or mock `URLSession` |

**Refactor for testability:** Introduce protocols (e.g. `SupabaseClientProtocol`, `URLSessionProtocol`) for `SupabaseClient` and `AuthManager` so they can be injected. This is a larger refactor; a lighter option is to use `URLProtocol` to stub network responses.

### 2.3 UI / SwiftUI Tests

| Approach | Tool | Scope |
|----------|------|-------|
| **Preview snapshots** | SwiftUI Previews | `#Preview` blocks already exist; run in Xcode |
| **View existence** | XCTest + ViewInspector (optional) | Assert views render for given state |
| **E2E** | XCUITest | Sign in → browse → checkout flow (if desired) |

**Recommendation:** Start with unit tests. Add ViewInspector if you need deeper SwiftUI tests. XCUITest for critical flows only after unit coverage is stable.

---

## 3. Proposed Structure

```
Encore/
├── Encore/                    # App target (existing)
└── EncoreTests/               # NEW unit test target
    ├── Models/
    │   ├── AppUserTests.swift
    │   └── ModelsCodableTests.swift
    ├── Helpers/
    │   ├── CheckoutHelpersTests.swift
    │   ├── CountryDialCodeTests.swift
    │   └── LocationChipTests.swift
    ├── Extensions/
    │   ├── ColorHexTests.swift
    │   └── RoundedCornerTests.swift
    └── Mocks/
        └── MockURLSession.swift   # For URLProtocol-based stubbing
```

---

## 4. Implementation Steps (After Approval)

1. **Create `EncoreTests` target** in Xcode (File → New → Target → Unit Testing Bundle).
2. **Extract testable helpers** (optional): Move `cardBrand`, `formatCardNumber`, `formatExpiry` (and related logic) to a `CheckoutHelpers` module if we want direct unit tests.
3. **Add test files** following the structure above.
4. **Run tests** via `⌘U` or `xcodebuild test`.

---

## 5. Framework Summary

| Layer | Framework | Notes |
|-------|-----------|-------|
| Unit | **XCTest** | Built into Xcode, no extra deps |
| Mocking | **URLProtocol** | Stub `URLSession` without protocols |
| UI | **SwiftUI Previews** | Already in use |
| E2E | **XCUITest** | Optional, for critical flows |

---

## 6. Implementation Complete ✓

- [x] Unit test scope (Models, Helpers, Extensions)
- [x] Integration approach (URLProtocol via MockURLProtocol)
- [x] Extracted `CheckoutHelpers` for direct testing
- [ ] XCUITest E2E (deferred)

**Run tests:** Open in Xcode, select EncoreTests scheme, press `⌘U`.
