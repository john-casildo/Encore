//
//  ConversationView.swift
//  Encore
//

import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    private let conversation: Conversation?
    private let otherUser: AppUser?
    private let pendingHostId: UUID?
    private let pendingHostUser: AppUser?
    private let instrument: Instrument?
    private let onConversationCreated: ((Conversation) -> Void)?

    private var isPending: Bool { conversation == nil }

    init(conversation: Conversation, otherUser: AppUser?) {
        self.conversation = conversation
        self.otherUser = otherUser
        self.pendingHostId = nil
        self.pendingHostUser = nil
        self.instrument = nil
        self.onConversationCreated = nil
    }

    init(pendingHostId: UUID, pendingHostUser: AppUser?, instrument: Instrument, onConversationCreated: @escaping (Conversation) -> Void) {
        self.conversation = nil
        self.otherUser = pendingHostUser
        self.pendingHostId = pendingHostId
        self.pendingHostUser = pendingHostUser
        self.instrument = instrument
        self.onConversationCreated = onConversationCreated
    }

    @State private var messages: [Message] = []
    @State private var messageDraft = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var loadedHostUser: AppUser?

    private var displayUser: AppUser? {
        otherUser ?? pendingHostUser ?? loadedHostUser
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            chatHeader
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(messages) { msg in
                                    MessageBubbleView(
                                        message: msg,
                                        isFromMe: msg.senderId == auth.session?.userId
                                    )
                                    .id(msg.id)
                                }
                            }
                            .padding()
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            messageInputBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if isPending {
                await MainActor.run { isLoading = false }
                if let hostId = pendingHostId {
                    do {
                        let list: [AppUser] = try await SupabaseClient.shared.fetch(
                            table: "users",
                            query: [
                                URLQueryItem(name: "select", value: "id,name,last_name,avatar_url"),
                                URLQueryItem(name: "id", value: "eq.\(hostId.uuidString)")
                            ]
                        )
                        await MainActor.run { loadedHostUser = list.first }
                    } catch {
                        print("[ConversationView] load host for pending failed: \(error)")
                    }
                }
            } else {
                await loadMessages()
                while !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { break }
                    guard !Task.isCancelled else { break }
                    await pollMessages()
                }
            }
        }
    }

    // MARK: - Chat header

    private var chatHeader: some View {
        let hasInstrument = (conversation?.instrumentId != nil) || (instrument != nil)
        let instrumentName = conversation?.instrumentName ?? instrument?.name
        let instrumentEmoji = conversation?.instrumentEmoji ?? instrument?.imageEmoji
        let instrumentImageUrl = conversation?.instrumentImageUrl ?? instrument?.imageUrls.first
        return VStack(spacing: 8) {
            ProfileAvatarView(url: displayUser?.avatarUrl, size: 80)
            Text(displayUser?.displayName ?? "—")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.encoreText)
            if hasInstrument {
                HStack(spacing: 6) {
                    RemoteImage(
                        url: instrumentImageUrl,
                        emojiFallback: instrumentEmoji ?? "🎸",
                        storageBucket: .instruments
                    )
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(instrumentName ?? (language.sp ? "Instrumento" : "Instrument"))
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal)
    }

    // MARK: - Input bar

    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.black)
                .frame(height: 1.5)
            HStack(spacing: 10) {
                TextField(Strings.typeMessage(language.sp), text: $messageDraft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                Button {
                    sendMessage()
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? Color.encorePrimary : Color(.systemGray4))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                            .shadow(color: canSend ? .black : .clear, radius: 0, x: 2, y: 2)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(!canSend || isSending)
                .animation(.easeInOut(duration: 0.15), value: canSend)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    private var canSend: Bool {
        !messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Data

    /// Full load — shows spinner.
    private func loadMessages() async {
        await MainActor.run { isLoading = true }
        let fetched = await fetchMessages()
        await MainActor.run {
            messages = fetched
            isLoading = false
        }
    }

    /// Silent poll — no spinner; only updates if something changed.
    private func pollMessages() async {
        let fetched = await fetchMessages()
        await MainActor.run {
            if fetched.count != messages.count || fetched.last?.id != messages.last?.id {
                messages = fetched
            }
        }
    }

    private func fetchMessages() async -> [Message] {
        guard let conv = conversation else { return [] }
        do {
            let list: [Message] = try await SupabaseClient.shared.fetch(
                table: "messages",
                query: [
                    URLQueryItem(name: "conversation_id", value: "eq.\(conv.id.uuidString)"),
                    URLQueryItem(name: "order", value: "created_at.asc")
                ]
            )
            return list
        } catch {
            print("[ConversationView] fetchMessages failed: \(error)")
            return messages  // keep existing on error
        }
    }

    private func sendMessage() {
        let text = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let senderId = auth.session?.userId else { return }
        isSending = true
        messageDraft = ""

        Task {
            do {
                var convId: UUID
                if let conv = conversation {
                    convId = conv.id
                } else {
                    // Pending: create conversation first, then message
                    guard let hostId = pendingHostId, let inst = instrument else {
                        await MainActor.run { messageDraft = text; isSending = false }
                        return
                    }
                    _ = try await SupabaseClient.shared.insert(table: "conversations", body: [
                        "renter_id": senderId.uuidString,
                        "host_id": hostId.uuidString,
                        "instrument_id": inst.id.uuidString
                    ] as [String: Any])
                    let created: [Conversation] = try await SupabaseClient.shared.fetch(
                        table: "conversations",
                        query: [
                            URLQueryItem(name: "select", value: "*,instruments(name,image_urls,image_emoji)"),
                            URLQueryItem(name: "renter_id", value: "eq.\(senderId.uuidString)"),
                            URLQueryItem(name: "host_id", value: "eq.\(hostId.uuidString)")
                        ]
                    )
                    guard let newConv = created.first else {
                        throw NSError(domain: "ConversationView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch created conversation"])
                    }
                    convId = newConv.id
                    await MainActor.run {
                        onConversationCreated?(newConv)
                    }
                }
                let body: [String: Any] = [
                    "conversation_id": convId.uuidString,
                    "sender_id": senderId.uuidString,
                    "body": text
                ]
                _ = try await SupabaseClient.shared.insert(table: "messages", body: body)
                if conversation != nil {
                    let fetched = await fetchMessages()
                    await MainActor.run {
                        messages = fetched
                        isSending = false
                    }
                } else {
                    // Pending: we already called onConversationCreated; parent will swap to existing view
                    await MainActor.run { isSending = false }
                }
            } catch {
                print("[ConversationView] send failed: \(error)")
                await MainActor.run {
                    messageDraft = text
                    isSending = false
                }
            }
        }
    }
}

// MARK: - Message bubble

struct MessageBubbleView: View {
    let message: Message
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromMe { Spacer(minLength: 60) }
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(isFromMe ? .white : Color.encoreText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.encorePrimary : Color.encoreLightYellow)
                    .cornerRadius(18, corners: isFromMe
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight])
                    .overlay(
                        RoundedCorner(radius: 18, corners: isFromMe
                            ? [.topLeft, .topRight, .bottomLeft]
                            : [.topLeft, .topRight, .bottomRight])
                            .stroke(Color.primary, lineWidth: 1.5)
                    )
                    .memphisShadow(x: 2, y: 2)
                if let ts = message.createdAt {
                    Text(shortTime(ts))
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                        .padding(.horizontal, 4)
                }
            }
            if !isFromMe { Spacer(minLength: 60) }
        }
    }

    private func shortTime(_ iso: String) -> String {
        let parsers: [DateFormatter] = {
            let f1 = DateFormatter()
            f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            f1.locale = Locale(identifier: "en_US_POSIX")
            let f2 = DateFormatter()
            f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            f2.locale = Locale(identifier: "en_US_POSIX")
            return [f1, f2]
        }()
        let date = parsers.compactMap { $0.date(from: iso) }.first
            ?? ISO8601DateFormatter().date(from: iso)
        guard let d = date else { return String(iso.prefix(10)) }
        let cal = Calendar.current
        if cal.isDateInToday(d) {
            let f = DateFormatter(); f.timeStyle = .short
            return f.string(from: d)
        }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: d)
    }
}

#Preview {
    NavigationStack {
        ConversationView(
            conversation: Conversation(
                id: UUID(), renterId: UUID(), hostId: UUID(),
                instrumentId: nil, instrumentName: nil, instrumentEmoji: nil, instrumentImageUrl: nil,
                lastMessagePreview: "Hi", lastMessageAt: nil, createdAt: nil, updatedAt: nil
            ),
            otherUser: nil
        )
        .environmentObject(AuthManager.shared)
        .environmentObject(LanguageManager.shared)
    }
}
