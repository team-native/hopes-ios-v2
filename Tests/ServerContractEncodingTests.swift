import XCTest
@testable import Hopes

final class ServerContractEncodingTests: XCTestCase {
    private func json(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testPreferencesSendAllMajorsWithFirstAsSpecialtyId() throws {
        let ids = CatalogAPI.specialtyIDs(for: ["iOS", "AI", "iOS", "없는전공"])
        XCTAssertEqual(ids.count, 2)
        let body = try json(ChatPreferencesPayload(departmentId: 1, specialtyIds: ids))
        XCTAssertEqual(body["specialtyIds"] as? [Int64], ids)
        XCTAssertEqual(body["specialtyId"] as? Int64, ids.first)
    }

    func testClearingMajorsSendsEmptyListAndNullSpecialty() throws {
        let body = try json(ChatPreferencesPayload(departmentId: 1, specialtyIds: []))
        XCTAssertEqual((body["specialtyIds"] as? [Any])?.count, 0)
        XCTAssertTrue(body["specialtyId"] is NSNull)
    }

    func testSpecialtyIdsAreCappedAtServerLimit() {
        let many = Array(repeating: ["iOS", "Android", "Frontend", "Backend", "AI", "IoT", "DevOps", "Design", "기타"],
            count: 3).flatMap { $0 }
        XCTAssertLessThanOrEqual(CatalogAPI.specialtyIDs(for: many).count, 20)
    }

    func testRecommendationQueryCarriesEveryMajor() {
        let items = CatalogAPI.specialtyQueryItems(for: ["iOS", "Backend"])
        let ids = CatalogAPI.specialtyIDs(for: ["iOS", "Backend"])
        XCTAssertEqual(items.first { $0.name == "specialtyId" }?.value, ids.first.map(String.init))
        XCTAssertEqual(items.first { $0.name == "specialtyIds" }?.value, ids.map(String.init).joined(separator: ","))
        XCTAssertTrue(CatalogAPI.specialtyQueryItems(for: []).isEmpty)
    }

    func testChatMessageCarriesSpecialtyIds() throws {
        let payload = SendMessagePayload(content: "q", attachmentIds: [], departmentId: 1, specialtyId: 101,
            clientRequestId: "r", specialtyIds: [101, 105])
        let body = try json(payload)
        XCTAssertEqual(body["specialtyIds"] as? [Int64], [101, 105])
        XCTAssertEqual(body["specialtyId"] as? Int64, 101)
    }

    func testInquirySendsReplyEmailSeparately() {
        XCTAssertEqual(AccountAPI.inquiryBody(email: " me@gsm.hs.kr ", message: "도와주세요"),
            ["content": "도와주세요", "replyEmail": "me@gsm.hs.kr"])
        XCTAssertEqual(AccountAPI.inquiryBody(email: "", message: "도와주세요"), ["content": "도와주세요"])
    }
}
