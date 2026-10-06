//
//  ModelsCodableTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class ModelsCodableTests: XCTestCase {

    // MARK: - AppUser

    func testAppUser_decode_minimal() throws {
        let json = """
        {"id": "\(UUID().uuidString)", "role": "renter"}
        """
        let user = try JSONDecoder.supabase.decode(AppUser.self, from: json.data(using: .utf8)!)
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.role, .renter)
        XCTAssertNil(user.name)
        XCTAssertNil(user.email)
    }

    func testAppUser_decode_missingRole_defaultsToRenter() throws {
        let json = """
        {"id": "\(UUID().uuidString)"}
        """
        let user = try JSONDecoder.supabase.decode(AppUser.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(user.role, .renter)
    }

    // MARK: - Instrument

    func testInstrument_decode_minimal() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "host_id": "\(UUID().uuidString)",
            "name": "Guitar",
            "category": "string"
        }
        """
        let inst = try JSONDecoder.supabase.decode(Instrument.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(inst.name, "Guitar")
        XCTAssertEqual(inst.category, "string")
        XCTAssertEqual(inst.pricePerDay, 0)
        XCTAssertEqual(inst.maxRentalDays, 7)
        XCTAssertEqual(inst.blockedDates, [])
    }

    // MARK: - Rental

    func testRental_decode_withNestedInstruments() throws {
        let instrumentId = UUID()
        let hostId = UUID()
        let renterId = UUID()
        let rentalId = UUID()
        let json = """
        {
            "id": "\(rentalId.uuidString)",
            "instrument_id": "\(instrumentId.uuidString)",
            "renter_id": "\(renterId.uuidString)",
            "host_id": "\(hostId.uuidString)",
            "start_date": "2026-02-09",
            "end_date": "2026-02-10",
            "total_price": 50000,
            "deposit_amount": 20000,
            "deposit_returned": false,
            "status": "confirmed",
            "pickup_method": "meet_up",
            "has_been_reviewed": false,
            "instruments": {"image_urls": ["https://example.com/img.jpg"]}
        }
        """
        let rental = try JSONDecoder.supabase.decode(Rental.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(rental.instrumentImageUrl, "https://example.com/img.jpg")
    }

    // MARK: - Conversation

    func testConversation_decode_withNestedInstruments() throws {
        let id = UUID()
        let renterId = UUID()
        let hostId = UUID()
        let json = """
        {
            "id": "\(id.uuidString)",
            "renter_id": "\(renterId.uuidString)",
            "host_id": "\(hostId.uuidString)",
            "instruments": {
                "name": "Acoustic Guitar",
                "image_urls": ["https://example.com/guitar.jpg"],
                "image_emoji": "🎸"
            }
        }
        """
        let conv = try JSONDecoder.supabase.decode(Conversation.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(conv.instrumentName, "Acoustic Guitar")
        XCTAssertEqual(conv.instrumentEmoji, "🎸")
        XCTAssertEqual(conv.instrumentImageUrl, "https://example.com/guitar.jpg")
    }

    func testConversation_decode_withoutInstruments() throws {
        let id = UUID()
        let renterId = UUID()
        let hostId = UUID()
        let json = """
        {
            "id": "\(id.uuidString)",
            "renter_id": "\(renterId.uuidString)",
            "host_id": "\(hostId.uuidString)"
        }
        """
        let conv = try JSONDecoder.supabase.decode(Conversation.self, from: json.data(using: .utf8)!)
        XCTAssertNil(conv.instrumentName)
        XCTAssertNil(conv.instrumentEmoji)
        XCTAssertNil(conv.instrumentImageUrl)
    }
}
