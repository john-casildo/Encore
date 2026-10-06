# Encore — Design System & Rationale

## Why Corporate Memphis?

Encore is a peer-to-peer instrument rental marketplace targeted at musicians in Costa Rica. The product sits in a space where trust, personality, and approachability matter more than corporate polish. We chose **Corporate Memphis** as the design language for three reasons:

1. **Differentiation.** Most rental and marketplace apps (Airbnb, Turo, Facebook Marketplace) use gradient-heavy, photo-first design with minimal personality. A flat, geometric, illustration-led aesthetic immediately signals that Encore is something different — a community product, not a corporate one.

2. **Warmth and playfulness.** Musicians are creative people. A design system that uses bold colors, thick outlines, and geometric illustration feels at home alongside instruments, creativity, and self-expression.

3. **Simplicity under constraints.** Memphis works beautifully without high-quality photography. When a listing has no photo, we show a hand-drawn SVG instrument illustration rather than a broken image or a gray box — the design system *expects* and *handles* the no-photo state gracefully.

---

## What is Corporate Memphis?

Corporate Memphis is a flat illustration style that became ubiquitous in tech branding around 2017–2021 (Slack, Mailchimp, Notion, Headspace, etc.). Its defining characteristics:

- **Flat, solid colors** — no gradients, no glass morphism, no drop shadows with blur
- **Bold black outlines** — thick strokes (1.5–2pt) on shapes and UI elements
- **Hard offset shadows** — a solid black shadow with no radius, offset diagonally — the "neo-brutalist" shadow
- **Geometric shapes** — circles, capsules, rounded rectangles used as decorative elements
- **Saturated palette** — bold, vibrant colors rather than muted pastels
- **Bold typography** — heavy weights (Black, ExtraBold) for headings

The "Corporate" prefix comes from the fact that this style was adopted so widely by tech companies that it became associated with a certain sanitized, approachable corporate aesthetic.

---

## Encore's Memphis implementation

### Color palette

| Token | Hex | Usage |
|-------|-----|-------|
| `encorePrimary` | `#7C3AED` | CTA buttons, active tabs, nav links, primary fills |
| `encorePrimaryDark` | `#4C1D95` | Hover/pressed states, dark accents |
| `encoreAccent` | `#FCD34D` | Yellow highlights — price badges, star ratings, photo picker icon, decorative dots |
| `encoreFrame` | `#F2E8FF` | Page background — soft lavender tint |
| `encoreLightPurple` | `#F3E8FF` | Card tinted backgrounds, emoji/icon containers |
| `encoreLightYellow` | `#FEF3C7` | Incoming chat bubbles, date row background |
| `encorePink` | `#EC4899` | Favorites heart, secondary accents |
| `encoreGreen` | `#34D399` | Available status, success, Excellent condition |
| `encoreBlue` | `#60A5FA` | Confirmed status, info |
| `encoreCoral` | `#F87171` | Cancelled status, destructive actions |
| `encoreTeal` | `#2DD4BF` | Tertiary accents |
| `encoreOrange` | `#FB923C` | Past/history, Fair condition, pending warnings |

### Typography rules

- **Screen headings / card titles**: `.weight(.black)` or `.weight(.bold)` — maximum visual weight
- **Section labels, field labels**: `.weight(.semibold)` — readable but authoritative
- **Body / descriptions**: `.weight(.regular)` — relaxed reading
- **Status badges, chips, prices**: `.weight(.bold)` or `.weight(.black)` — punchy

### The Memphis card modifier

Every interactive card in the app uses the same three-layer treatment:

```swift
// 1. Shape fill (flat color — no gradient)
// 2. Black stroke overlay
.overlay(RoundedRectangle(cornerRadius: r).stroke(.black, lineWidth: 1.5))
// 3. Hard offset shadow (no blur)
.shadow(color: .black, radius: 0, x: 3, y: 3)
```

This is encapsulated in the reusable `.memphisCard(cornerRadius:offset:lineWidth:)` modifier defined in `Extensions/Extensions.swift`.

The shadow offset varies by visual weight:
- **Heavy cards** (hero banners, confirmation screens): `x: 4, y: 4`
- **Standard content cards**: `x: 3, y: 3`
- **Small interactive elements** (chips, toggles): `x: 2, y: 2`

### Decorative geometry

Hero sections (Browse banner, Host Dashboard earnings card, Auth background, Booking Confirmed screen) use `GeometryReader` to scatter floating geometric shapes. These are never interactive — pure decoration that reinforces the Memphis feel without cluttering content:

```swift
GeometryReader { geo in
    Circle().fill(Color.encoreAccent).frame(width: 72).position(x: geo.size.width - 38, y: 30)
    Circle().fill(Color.encorePink).frame(width: 28).position(x: ..., y: ...)
    RoundedRectangle(...).fill(Color.encoreTeal).rotationEffect(.degrees(22)).position(...)
}
```

### Tab and chip selection states

Selected tabs and filter chips use the same pattern throughout the app:
- **Unselected**: white fill + transparent border (black stroke, clear shadow)
- **Selected**: `encorePrimary` fill + black stroke + hard black shadow

This creates a satisfying visual "pop" on selection and makes the active state immediately obvious.

---

## Screen-by-screen decisions

### AuthView
The login/signup screen floats a white Memphis card over a lavender `encoreFrame` background populated with scattered geometric shapes. This establishes the design language at the first impression. The Continue button gets a hard shadow only when it's enabled — the shadow appearing on valid input is a subtle affordance that the form is ready.

### BrowseView (main browse)
The hero banner replaces a gradient with flat `encorePrimary` purple and four floating shapes positioned with `GeometryReader`. Category chips use the standard selected/unselected chip treatment. Instrument cards get the full Memphis card treatment: `cornerRadius: 20, offset: 4, lineWidth: 2`.

### InstrumentCard / RemoteImage
When a listing has no photos, `RemoteImage` renders a `MemphisInstrumentIllustration` — a hand-drawn SwiftUI illustration built entirely from primitive shapes (`Circle`, `Capsule`, `RoundedRectangle`, `Ellipse`) with black outlines. Category-specific illustrations exist for strings (guitar), keys (piano), percussion (drums), and brass (trumpet). This keeps the no-photo state branded and intentional rather than broken.

### CheckoutView
The 4-step progress bar uses numbered circles (filled purple when reached, bordered when upcoming) instead of plain progress bars. The `PickupCard` options use a colored icon circle + checkmark badge instead of a checkbox. The `BookingConfirmedView` is a full-screen Memphis celebration: lavender background + floating shapes + a large purple circle with a checkmark and hard black shadow.

### HostDashboardView
The earnings card replicates the Browse hero banner treatment — flat purple + floating yellow/pink/teal shapes. The pending bookings card uses `encoreLightPurple` with a purple number circle. Recent activity rows put emojis in purple-tinted circles with black outlines.

### HostListingsView / HostBookingsView / MyRentalsView
Cards all use `.memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)`. Empty states use `MemphisEmptyView` — a colored circle (icon-specific color) with a drop shadow + SF symbol + floating accent dots + bold title + subtitle. Each tab has its own icon/color combination to reinforce which tab is empty.

### AddInstrumentView / EditInstrumentView
- Text fields: white background + black border + hard shadow (replaces gray `systemGray6` background)
- Category picker: horizontal pill chips with category emoji + label
- Condition picker: 3 color-coded pill chips (green = Excellent, blue = Good, orange = Fair)
- Description textarea: same Memphis field treatment
- Photo picker: yellow accent circle icon button instead of gray rectangle
- Delete button: red border + red hard shadow (signals irreversible action)
- Availability toggle (Edit): green-tinted background when on + green status dot

### ConversationView (messaging)
- Input bar: white background with bold 1.5pt black top divider (replaces `systemGroupedBackground`)
- Text field: white capsule with black stroke
- Send button: purple/gray circle with black border + hard shadow that animates on/off as the draft becomes sendable
- My messages: iMessage-style per-corner radius (cuts the bottom-right corner), black border + hard offset shadow, purple fill
- Their messages: soft yellow (`encoreLightYellow`) fill + black border + hard offset shadow

### RatingsView
- Instrument header card at top (emoji box + name + date) — branded context before rating
- Stars: yellow accent circles with black border + hard shadow when filled; spring animation on tap
- Comment textarea: white + memphisCard

### RenterProfileView
Converted from SwiftUI `List` (system styling, hard to override) to a custom `ScrollView` with Memphis section cards. The profile header shows the avatar with a yellow accent dot badge. Nav links are grouped in a single card; each row has a colored icon circle. Sign out gets a red-bordered button with red hard shadow (matches the destructive delete button pattern).

### EditProfileView
Converted from SwiftUI `Form` to a `ScrollView` with custom section cards. Each input field is a `fieldRow` — a colored icon circle + text field wrapped in a Memphis card. Section headers use uppercase small caps in `encoreTextSecondary`. Avatar gets a yellow camera badge with black border.

---

## What we avoided

- **Gradients**: Removed from all buttons and cards. Gradients feel premium/corporate; flat color feels friendly/indie.
- **Soft shadows** (`radius > 0`): Every shadow in the app uses `radius: 0`. Blurred shadows look modern/skeuomorphic; hard shadows look Memphis/neo-brutalist.
- **Rounded system components unstyled**: Every `Toggle`, `Picker` used in context gets styled — wrapping in a Memphis card or replacing with pill chips so system chrome doesn't break the design language.
- **Gray placeholder states**: Instead of gray boxes for missing images or empty lists, every empty state is a custom `MemphisEmptyView` with a themed icon, colors, and text.

---

## Files reference

| File | Purpose |
|------|---------|
| `Extensions/Extensions.swift` | Color tokens, `MemphisCardModifier`, `RoundedCorner` shape, `StyledTextField` |
| `Views/Shared/MemphisIllustrations.swift` | All hand-drawn instrument illustrations + `MemphisEmptyView` + `MemphisIconScene` |
| `Network/StorageService.swift` | `RemoteImage` — falls back to `MemphisInstrumentIllustration` when no photo |
