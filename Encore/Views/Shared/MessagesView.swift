//
//  MessagesView.swift
//  Encore
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var conversations: [Conversation] = []
    @State private var otherUsers: [UUID: AppUser] = [:]
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if conversations.isEmpty {
                MemphisEmptyView(
                    icon: "message.fill",
                    circleColor: Color.encoreBlue,
                    accentColor: Color.encoreAccent,
                    secondAccent: Color.encorePink,
                    title: Strings.noConversations(language.sp),
                    subtitle: Strings.noConversationsHint(language.sp)
                )
            } else {
                List {
                    ForEach(conversations) { conv in
                        let other = otherUsers[otherUserId(conv)]
                        NavigationLink {
                            ConversationView(conversation: conv, otherUser: other)
                        } label: {
                            ConversationRowView(
                                conversation: conv,
                                otherUser: other,
                                currentUserId: auth.currentUser?.id
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(Strings.messages(language.sp))
        .onAppear {
            loadConversations()
        }
        .refreshable {
            await loadConversationsAsync()
        }
    }

    private func otherUserId(_ conv: Conversation) -> UUID {
        guard let uid = auth.session?.userId else { return conv.hostId }
        return uid == conv.renterId ? conv.hostId : conv.renterId
    }

    private func loadConversations() {
        Task { await loadConversationsAsync() }
    }

    private func loadConversationsAsync() async {
        // Use session?.userId so this works even before loadUserAndRole finishes
        guard let uid = auth.session?.userId else {
            await MainActor.run {
                conversations = []
                otherUsers = [:]
                isLoading = false
            }
            return
        }
        await MainActor.run { isLoading = true }
        do {
            let orFilter = "(renter_id.eq.\(uid.uuidString),host_id.eq.\(uid.uuidString))"
            let list: [Conversation] = try await SupabaseClient.shared.fetch(
                table: "conversations",
                query: [
                    URLQueryItem(name: "select", value: "*,instruments(name,image_urls,image_emoji)"),
                    URLQueryItem(name: "or", value: orFilter),
                    URLQueryItem(name: "order", value: "updated_at.desc")
                ]
            )
            var others: [UUID: AppUser] = [:]
            let otherIds = list.map { otherUserId($0) }
            if !otherIds.isEmpty {
                let idList = otherIds.map { $0.uuidString }.joined(separator: ",")
                let inFilter = "in.(\(idList))"
                let users: [AppUser] = try await SupabaseClient.shared.fetch(
                    table: "users",
                    query: [URLQueryItem(name: "id", value: inFilter)]
                )
                for u in users { others[u.id] = u }
            }
            await MainActor.run {
                conversations = list
                otherUsers = others
                isLoading = false
            }
        } catch {
            print("[MessagesView] load failed: \(error)")
            await MainActor.run {
                conversations = []
                otherUsers = [:]
                isLoading = false
            }
        }
    }
}

// MARK: - Conversation row

struct ConversationRowView: View {
    @EnvironmentObject var language: LanguageManager
    let conversation: Conversation
    let otherUser: AppUser?
    let currentUserId: UUID?

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(url: otherUser?.avatarUrl, size: 50)
                if conversation.instrumentId != nil {
                    instrumentThumbnail
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(otherUser?.displayName ?? "—")
                    .font(.headline)
                    .foregroundStyle(Color.encoreText)
                if let preview = conversation.lastMessagePreview, !preview.isEmpty {
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let at = conversation.lastMessageAt {
                Text(formatDate(at))
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var instrumentThumbnail: some View {
        RemoteImage(
            url: conversation.instrumentImageUrl,
            emojiFallback: conversation.instrumentEmoji ?? "🎸",
            storageBucket: .instruments
        )
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
        .offset(x: 4, y: 4)
    }

    private func formatDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) ?? isoDateFallback(iso) else {
            return String(iso.prefix(10))
        }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.timeStyle = .short
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            return language.sp ? "Ayer" : "Yesterday"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func isoDateFallback(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: s)
    }
}

#Preview {
    NavigationStack {
        MessagesView()
            .environmentObject(AuthManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
