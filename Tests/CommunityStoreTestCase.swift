import XCTest
@testable import Hopes

@MainActor
class CommunityStoreTestCase: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        CommunityPostStore.shared.resetForNewSession()
    }

    override func tearDown() async throws {
        CommunityPostStore.shared.resetForNewSession()
        try await super.tearDown()
    }
}
