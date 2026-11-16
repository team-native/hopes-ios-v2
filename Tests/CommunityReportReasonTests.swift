import XCTest
@testable import Hopes

@MainActor
final class CommunityReportReasonTests: XCTestCase {
    func testReasonsMapToServerReasonCodes() {
        XCTAssertEqual(CommunityReportFlowViewController.reasonCode(for: "욕설·비방"), "ABUSE")
        XCTAssertEqual(CommunityReportFlowViewController.reasonCode(for: "도배·광고"), "SPAM")
        XCTAssertEqual(CommunityReportFlowViewController.reasonCode(for: "개인정보 노출"), "PRIVACY")
        XCTAssertEqual(CommunityReportFlowViewController.reasonCode(for: "기타"), "OTHER")
    }

    func testReportedCommentIsTrackedForDuplicateGuard() {
        let store = CommunityPostStore.shared
        store.reportedCommentIDs.remove(987_654)
        store.markCommentReported(id: 987_654, reasonCode: "SPAM")
        XCTAssertTrue(store.reportedCommentIDs.contains(987_654))
        store.reportedCommentIDs.remove(987_654)
    }
}
