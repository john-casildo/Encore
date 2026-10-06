# Plan: Instrument Photo in Messages

## Overview
Add a small instrument thumbnail next to the profile picture in the Messages list and in the chat header, so users can see which instrument the conversation is about.

---

## Current State
- **Conversation** model already has `instrumentId: UUID?` (optional – some chats may not be about a specific instrument)
- **ConversationRowView** shows: profile avatar (50pt) + name + message preview
- **ConversationView** (chat) shows: navigation title = other user's name only
- Conversations are fetched from `conversations` table; instruments are not joined

---

## Tasks

### 1. Backend: Fetch instrument data with conversations
- [ ] **Option A (join):** Add `select=*,instruments(image_urls,image_emoji,name)` to the conversations fetch so each conversation includes instrument details
- [ ] **Option B (separate fetch):** After loading conversations, fetch instruments for non-nil `instrumentId`s in one query (`id=in.(uuid1,uuid2,...)`)
- **Recommendation:** Option A (PostgREST embed) – fewer round trips

### 2. Conversation model: Add instrument display fields
- [ ] Add `instrumentName: String?`, `instrumentEmoji: String?`, `instrumentImageUrl: String?` to `Conversation` (either from join or from a separate Instrument fetch)
- [ ] Add custom `init(from decoder:)` if using join (similar to Rental)
- [ ] Or: create `ConversationWithInstrument` wrapper / extend fetch to populate these

### 3. Messages list (ConversationRowView)
- [ ] Layout: `[Profile Avatar] [Instrument thumbnail (if any)] [Name + preview] [Time]`
- [ ] Instrument thumbnail: small square (e.g. 36×36 or 40×40), rounded corners, to the right of the profile pic
- [ ] Use `RemoteImage` with `instrumentImageUrl` and `instrumentEmoji` fallback
- [ ] If `instrumentId == nil`, don't show the instrument thumbnail (conversation not tied to an instrument)

### 4. Chat header (ConversationView)
- [ ] Add instrument thumbnail in the navigation bar (e.g. as a trailing item or in the title area)
- [ ] Or: add a small bar below the nav title showing "About: [instrument name]" + thumbnail
- [ ] Fetch instrument if not already on `Conversation` (or ensure it's passed from MessagesView)

### 5. Where conversations are created
- [ ] Verify that when starting a chat from `InstrumentDetailView` (e.g. "Message host"), the `instrument_id` is set on the new conversation
- [ ] Check `findOrCreateConversation` / conversation creation flow

---

## UI Mockup (to refine with your example)
```
Messages list row:
[Avatar] [Instrument thumb]  Name
                             "Hi! I wanted to know..."
                                             12:30

Chat header:
< Back    Name    [Instrument thumb]
```

---

## Files to modify
1. `Encore/Models/Models.swift` – Conversation model (add instrument fields or decode from join)
2. `Encore/Views/Shared/MessagesView.swift` – fetch with join, ConversationRowView layout
3. `Encore/Views/Shared/ConversationView.swift` – chat header with instrument
4. Possibly `Encore/Views/Renter/InstrumentDetailView.swift` – ensure instrument_id is passed when creating conversation

---

## Notes
- User will send an example screenshot to refine the layout
- Instrument thumbnail should be subtle (small) so it doesn't overpower the profile pic
- Handle `instrumentId == nil` gracefully (no thumbnail, no extra space)
