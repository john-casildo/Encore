//
//  Models.swift
//  Encore
//

import Foundation

// MARK: - Enums

enum UserRole: String, Codable, CaseIterable {
    case renter
    case host
}

enum RentalStatus: String, Codable, CaseIterable {
    case pending
    case confirmed
    case active
    case completed
    case cancelled
}

enum PickupMethod: String, Codable, CaseIterable {
    case meet_up
    case host_address
    case shipping
}

// MARK: - AppUser (users table)

struct AppUser: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String?
    var lastName: String?
    var email: String?
    var role: UserRole
    var city: String?
    var countryIso: String?
    var avatarUrl: String?
    var latitude: Double?
    var longitude: Double?
    var language: String?
    var phone: String?
    var bio: String?
    var address: String?
    var isVerified: Bool?
    var rating: Double?
    var reviewCount: Int?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, role, city, language, phone, bio
        case lastName = "last_name"
        case countryIso = "country_iso"
        case avatarUrl = "avatar_url"
        case latitude, longitude
        case address
        case isVerified = "is_verified"
        case rating
        case reviewCount = "review_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        role = try c.decodeIfPresent(UserRole.self, forKey: .role) ?? .renter
        city = try c.decodeIfPresent(String.self, forKey: .city)
        countryIso = try c.decodeIfPresent(String.self, forKey: .countryIso)
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
        rating = try c.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    /// Full display name: "First Last" or name/email fallback.
    var displayName: String {
        let first = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let full = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        if !full.isEmpty { return full }
        return email ?? "—"
    }
}

// MARK: - Instrument

struct Instrument: Codable, Identifiable, Hashable {
    var id: UUID
    var hostId: UUID
    var name: String
    var category: String
    var description: String?
    var pricePerDay: Decimal
    var depositAmount: Decimal
    var imageEmoji: String?
    var imageUrls: [String]
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var isAvailable: Bool
    var rating: Decimal?
    var reviewCount: Int?
    var condition: String?
    var requiresId: Bool
    var maxRentalDays: Int
    var blockedDates: [String]
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, location, condition
        case hostId = "host_id"
        case pricePerDay = "price_per_day"
        case depositAmount = "deposit_amount"
        case imageEmoji = "image_emoji"
        case imageUrls = "image_urls"
        case latitude, longitude
        case isAvailable = "is_available"
        case rating
        case reviewCount = "review_count"
        case requiresId = "requires_id"
        case maxRentalDays = "max_rental_days"
        case blockedDates = "blocked_dates"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        hostId = try c.decode(UUID.self, forKey: .hostId)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description)
        pricePerDay = try c.decodeIfPresent(Decimal.self, forKey: .pricePerDay) ?? 0
        depositAmount = try c.decodeIfPresent(Decimal.self, forKey: .depositAmount) ?? 0
        imageEmoji = try c.decodeIfPresent(String.self, forKey: .imageEmoji)
        imageUrls = try c.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        location = try c.decodeIfPresent(String.self, forKey: .location)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        isAvailable = try c.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
        rating = try c.decodeIfPresent(Decimal.self, forKey: .rating)
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount)
        condition = try c.decodeIfPresent(String.self, forKey: .condition)
        requiresId = try c.decodeIfPresent(Bool.self, forKey: .requiresId) ?? false
        maxRentalDays = try c.decodeIfPresent(Int.self, forKey: .maxRentalDays) ?? 7
        blockedDates = (try? c.decodeIfPresent([String].self, forKey: .blockedDates)) ?? []
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    /// Memberwise initializer (needed when custom init(from:) is defined).
    init(id: UUID, hostId: UUID, name: String, category: String, description: String?, pricePerDay: Decimal, depositAmount: Decimal, imageEmoji: String?, imageUrls: [String], location: String?, latitude: Double?, longitude: Double?, isAvailable: Bool, rating: Decimal?, reviewCount: Int?, condition: String?, requiresId: Bool, maxRentalDays: Int = 7, blockedDates: [String] = [], createdAt: String?, updatedAt: String?) {
        self.id = id
        self.hostId = hostId
        self.name = name
        self.category = category
        self.description = description
        self.pricePerDay = pricePerDay
        self.depositAmount = depositAmount
        self.imageEmoji = imageEmoji
        self.imageUrls = imageUrls
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.isAvailable = isAvailable
        self.rating = rating
        self.reviewCount = reviewCount
        self.condition = condition
        self.requiresId = requiresId
        self.maxRentalDays = maxRentalDays
        self.blockedDates = blockedDates
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: Instrument, rhs: Instrument) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    #if DEBUG
    static let samples: [Instrument] = [
        Instrument(
            id: UUID(),
            hostId: UUID(),
            name: "Acoustic Guitar",
            category: "string",
            description: "Great condition, perfect for beginners.",
            pricePerDay: 10_000,
            depositAmount: 20_000,
            imageEmoji: "🎸",
            imageUrls: [],
            location: "Alajuela, Costa Rica",
            latitude: 10.0,
            longitude: -84.2,
            isAvailable: true,
            rating: 4.85,
            reviewCount: 12,
            condition: "excellent",
            requiresId: true,
            createdAt: nil,
            updatedAt: nil
        )
    ]
    #endif
}

// MARK: - Rental

private struct RentalInstrumentEmbed: Decodable {
    let imageUrls: [String]?
    enum CodingKeys: String, CodingKey { case imageUrls = "image_urls" }
}

struct Rental: Codable, Identifiable {
    var id: UUID
    var instrumentId: UUID
    var renterId: UUID
    var hostId: UUID
    var startDate: String
    var endDate: String
    var totalPrice: Decimal
    var depositAmount: Decimal
    var depositReturned: Bool
    var status: RentalStatus
    var instrumentName: String?
    var instrumentEmoji: String?
    /// First image URL from joined instruments table (for My Rentals thumbnails)
    var instrumentImageUrl: String?
    var pickupMethod: PickupMethod
    var hasBeenReviewed: Bool
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case instrumentId = "instrument_id"
        case renterId = "renter_id"
        case hostId = "host_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalPrice = "total_price"
        case depositAmount = "deposit_amount"
        case depositReturned = "deposit_returned"
        case instrumentName = "instrument_name"
        case instrumentEmoji = "instrument_emoji"
        case instrumentImageUrl = "instrument_image_url"
        case instruments
        case pickupMethod = "pickup_method"
        case hasBeenReviewed = "has_been_reviewed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        instrumentId = try c.decode(UUID.self, forKey: .instrumentId)
        renterId = try c.decode(UUID.self, forKey: .renterId)
        hostId = try c.decode(UUID.self, forKey: .hostId)
        startDate = try c.decode(String.self, forKey: .startDate)
        endDate = try c.decode(String.self, forKey: .endDate)
        totalPrice = try c.decode(Decimal.self, forKey: .totalPrice)
        depositAmount = try c.decode(Decimal.self, forKey: .depositAmount)
        depositReturned = try c.decode(Bool.self, forKey: .depositReturned)
        status = try c.decode(RentalStatus.self, forKey: .status)
        instrumentName = try c.decodeIfPresent(String.self, forKey: .instrumentName)
        instrumentEmoji = try c.decodeIfPresent(String.self, forKey: .instrumentEmoji)
        instrumentImageUrl = try c.decodeIfPresent(String.self, forKey: .instrumentImageUrl)
        pickupMethod = try c.decode(PickupMethod.self, forKey: .pickupMethod)
        hasBeenReviewed = try c.decode(Bool.self, forKey: .hasBeenReviewed)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        // Extract first image from nested instruments embed (PostgREST join)
        if let nested = try? c.decodeIfPresent(RentalInstrumentEmbed.self, forKey: .instruments),
           let first = nested.imageUrls?.first, instrumentImageUrl == nil {
            instrumentImageUrl = first
        }
    }

    /// Memberwise initializer (needed when custom init(from:) is defined).
    init(id: UUID, instrumentId: UUID, renterId: UUID, hostId: UUID, startDate: String, endDate: String, totalPrice: Decimal, depositAmount: Decimal, depositReturned: Bool, status: RentalStatus, instrumentName: String?, instrumentEmoji: String?, instrumentImageUrl: String?, pickupMethod: PickupMethod, hasBeenReviewed: Bool, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.instrumentId = instrumentId
        self.renterId = renterId
        self.hostId = hostId
        self.startDate = startDate
        self.endDate = endDate
        self.totalPrice = totalPrice
        self.depositAmount = depositAmount
        self.depositReturned = depositReturned
        self.status = status
        self.instrumentName = instrumentName
        self.instrumentEmoji = instrumentEmoji
        self.instrumentImageUrl = instrumentImageUrl
        self.pickupMethod = pickupMethod
        self.hasBeenReviewed = hasBeenReviewed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(instrumentId, forKey: .instrumentId)
        try c.encode(renterId, forKey: .renterId)
        try c.encode(hostId, forKey: .hostId)
        try c.encode(startDate, forKey: .startDate)
        try c.encode(endDate, forKey: .endDate)
        try c.encode(totalPrice, forKey: .totalPrice)
        try c.encode(depositAmount, forKey: .depositAmount)
        try c.encode(depositReturned, forKey: .depositReturned)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(instrumentName, forKey: .instrumentName)
        try c.encodeIfPresent(instrumentEmoji, forKey: .instrumentEmoji)
        try c.encode(pickupMethod, forKey: .pickupMethod)
        try c.encode(hasBeenReviewed, forKey: .hasBeenReviewed)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    #if DEBUG
    static let samples: [Rental] = [
        Rental(
            id: UUID(),
            instrumentId: UUID(),
            renterId: UUID(),
            hostId: UUID(),
            startDate: "2026-02-09",
            endDate: "2026-02-10",
            totalPrice: 50_000,
            depositAmount: 20_000,
            depositReturned: false,
            status: .confirmed,
            instrumentName: "Acoustic Guitar",
            instrumentEmoji: "🎸",
            instrumentImageUrl: nil,
            pickupMethod: .meet_up,
            hasBeenReviewed: false,
            createdAt: nil,
            updatedAt: nil
        )
    ]
    #endif
}

// MARK: - Review

private struct ReviewRenterEmbed: Decodable {
    let avatarUrl: String?
    enum CodingKeys: String, CodingKey { case avatarUrl = "avatar_url" }
}

struct Review: Codable, Identifiable {
    var id: UUID
    var rentalId: UUID
    var instrumentId: UUID
    var renterId: UUID
    var rating: Int
    var comment: String?
    var reviewerName: String?
    var reviewerAvatarUrl: String?
    var hostReply: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, rating, comment
        case rentalId = "rental_id"
        case instrumentId = "instrument_id"
        case renterId = "renter_id"
        case reviewerName = "reviewer_name"
        case reviewerAvatarUrl = "reviewer_avatar_url"
        case hostReply = "host_reply"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case users
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        rentalId = try c.decode(UUID.self, forKey: .rentalId)
        instrumentId = try c.decode(UUID.self, forKey: .instrumentId)
        renterId = try c.decode(UUID.self, forKey: .renterId)
        rating = try c.decode(Int.self, forKey: .rating)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        reviewerName = try c.decodeIfPresent(String.self, forKey: .reviewerName)
        hostReply = try c.decodeIfPresent(String.self, forKey: .hostReply)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        reviewerAvatarUrl = try c.decodeIfPresent(String.self, forKey: .reviewerAvatarUrl)
            ?? (try? c.decodeIfPresent(ReviewRenterEmbed.self, forKey: .users))?.avatarUrl
    }

    init(id: UUID, rentalId: UUID, instrumentId: UUID, renterId: UUID, rating: Int, comment: String?, reviewerName: String?, reviewerAvatarUrl: String?, hostReply: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.rentalId = rentalId
        self.instrumentId = instrumentId
        self.renterId = renterId
        self.rating = rating
        self.comment = comment
        self.reviewerName = reviewerName
        self.reviewerAvatarUrl = reviewerAvatarUrl
        self.hostReply = hostReply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(rentalId, forKey: .rentalId)
        try c.encode(instrumentId, forKey: .instrumentId)
        try c.encode(renterId, forKey: .renterId)
        try c.encode(rating, forKey: .rating)
        try c.encodeIfPresent(comment, forKey: .comment)
        try c.encodeIfPresent(reviewerName, forKey: .reviewerName)
        try c.encodeIfPresent(reviewerAvatarUrl, forKey: .reviewerAvatarUrl)
        try c.encodeIfPresent(hostReply, forKey: .hostReply)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    #if DEBUG
    static let samples: [Review] = [
        Review(
            id: UUID(),
            rentalId: UUID(),
            instrumentId: UUID(),
            renterId: UUID(),
            rating: 5,
            comment: "Perfect guitar, smooth process!",
            reviewerName: "Maria",
            reviewerAvatarUrl: nil,
            hostReply: "Thanks for renting!",
            createdAt: nil,
            updatedAt: nil
        )
    ]
    #endif
}

// MARK: - Conversation (messaging)

private struct ConversationInstrumentEmbed: Decodable {
    let name: String?
    let imageUrls: [String]?
    let imageEmoji: String?
    enum CodingKeys: String, CodingKey {
        case name
        case imageUrls = "image_urls"
        case imageEmoji = "image_emoji"
    }
}

struct Conversation: Codable, Identifiable {
    var id: UUID
    var renterId: UUID
    var hostId: UUID
    var instrumentId: UUID?
    var instrumentName: String?
    var instrumentEmoji: String?
    var instrumentImageUrl: String?
    var lastMessagePreview: String?
    var lastMessageAt: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case renterId = "renter_id"
        case hostId = "host_id"
        case instrumentId = "instrument_id"
        case instruments
        case lastMessagePreview = "last_message_preview"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        renterId = try c.decode(UUID.self, forKey: .renterId)
        hostId = try c.decode(UUID.self, forKey: .hostId)
        instrumentId = try c.decodeIfPresent(UUID.self, forKey: .instrumentId)
        lastMessagePreview = try c.decodeIfPresent(String.self, forKey: .lastMessagePreview)
        lastMessageAt = try c.decodeIfPresent(String.self, forKey: .lastMessageAt)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        if let nested = try? c.decodeIfPresent(ConversationInstrumentEmbed.self, forKey: .instruments) {
            instrumentName = nested.name
            instrumentEmoji = nested.imageEmoji
            instrumentImageUrl = nested.imageUrls?.first
        } else {
            instrumentName = nil
            instrumentEmoji = nil
            instrumentImageUrl = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(renterId, forKey: .renterId)
        try c.encode(hostId, forKey: .hostId)
        try c.encodeIfPresent(instrumentId, forKey: .instrumentId)
        try c.encodeIfPresent(lastMessagePreview, forKey: .lastMessagePreview)
        try c.encodeIfPresent(lastMessageAt, forKey: .lastMessageAt)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    init(id: UUID, renterId: UUID, hostId: UUID, instrumentId: UUID?, instrumentName: String?, instrumentEmoji: String?, instrumentImageUrl: String?, lastMessagePreview: String?, lastMessageAt: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.renterId = renterId
        self.hostId = hostId
        self.instrumentId = instrumentId
        self.instrumentName = instrumentName
        self.instrumentEmoji = instrumentEmoji
        self.instrumentImageUrl = instrumentImageUrl
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Message (messaging)

struct Message: Codable, Identifiable {
    var id: UUID
    var conversationId: UUID
    var senderId: UUID
    var body: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, body
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case createdAt = "created_at"
    }
}

// MARK: - UserReview (user_reviews table – host↔renter reviews)

private struct UserReviewReviewerEmbed: Decodable {
    let avatarUrl: String?
    enum CodingKeys: String, CodingKey { case avatarUrl = "avatar_url" }
}

struct UserReview: Codable, Identifiable {
    var id: UUID
    var rentalId: UUID
    var reviewerId: UUID
    var revieweeId: UUID
    var reviewerRole: String   // "renter" | "host"
    var rating: Int
    var comment: String?
    var reviewerName: String?
    var reviewerAvatarUrl: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, rating, comment
        case rentalId = "rental_id"
        case reviewerId = "reviewer_id"
        case revieweeId = "reviewee_id"
        case reviewerRole = "reviewer_role"
        case reviewerName = "reviewer_name"
        case reviewerAvatarUrl = "reviewer_avatar_url"
        case createdAt = "created_at"
        case users
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        rentalId = try c.decode(UUID.self, forKey: .rentalId)
        reviewerId = try c.decode(UUID.self, forKey: .reviewerId)
        revieweeId = try c.decode(UUID.self, forKey: .revieweeId)
        reviewerRole = try c.decode(String.self, forKey: .reviewerRole)
        rating = try c.decode(Int.self, forKey: .rating)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        reviewerName = try c.decodeIfPresent(String.self, forKey: .reviewerName)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        reviewerAvatarUrl = try c.decodeIfPresent(String.self, forKey: .reviewerAvatarUrl)
            ?? (try? c.decodeIfPresent(UserReviewReviewerEmbed.self, forKey: .users))?.avatarUrl
    }

    init(id: UUID, rentalId: UUID, reviewerId: UUID, revieweeId: UUID, reviewerRole: String, rating: Int, comment: String?, reviewerName: String?, reviewerAvatarUrl: String?, createdAt: String?) {
        self.id = id
        self.rentalId = rentalId
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.reviewerRole = reviewerRole
        self.rating = rating
        self.comment = comment
        self.reviewerName = reviewerName
        self.reviewerAvatarUrl = reviewerAvatarUrl
        self.createdAt = createdAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(rentalId, forKey: .rentalId)
        try c.encode(reviewerId, forKey: .reviewerId)
        try c.encode(revieweeId, forKey: .revieweeId)
        try c.encode(reviewerRole, forKey: .reviewerRole)
        try c.encode(rating, forKey: .rating)
        try c.encodeIfPresent(comment, forKey: .comment)
        try c.encodeIfPresent(reviewerName, forKey: .reviewerName)
        try c.encodeIfPresent(reviewerAvatarUrl, forKey: .reviewerAvatarUrl)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// MARK: - Favorite (favorites table – saved instruments)

struct Favorite: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var instrumentId: UUID
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case instrumentId = "instrument_id"
        case createdAt = "created_at"
    }
}

// MARK: - UserSettings (user_settings table)

struct UserSettings: Codable {
    var userId: UUID
    var notifBookings: Bool
    var notifMessages: Bool
    var notifReminders: Bool
    var notifPromotions: Bool
    var showPhone: Bool
    var showLocation: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notifBookings = "notif_bookings"
        case notifMessages = "notif_messages"
        case notifReminders = "notif_reminders"
        case notifPromotions = "notif_promotions"
        case showPhone = "show_phone"
        case showLocation = "show_location"
    }

    static func defaults(for userId: UUID) -> UserSettings {
        UserSettings(
            userId: userId,
            notifBookings: true,
            notifMessages: true,
            notifReminders: true,
            notifPromotions: false,
            showPhone: false,
            showLocation: true
        )
    }
}

// MARK: - NewInstrument (create/update payload)
// Matches public.instruments columns. Omit latitude/longitude unless you add those columns to the table.

struct NewInstrument: Codable {
    var name: String
    var category: String
    var description: String?
    var pricePerDay: Decimal
    var depositAmount: Decimal
    var imageEmoji: String?
    var imageUrls: [String]
    var location: String?
    var condition: String?
    var requiresId: Bool
    var isAvailable: Bool?

    enum CodingKeys: String, CodingKey {
        case name, category, description, location, condition
        case pricePerDay = "price_per_day"
        case depositAmount = "deposit_amount"
        case imageEmoji = "image_emoji"
        case imageUrls = "image_urls"
        case requiresId = "requires_id"
        case isAvailable = "is_available"
    }
}
