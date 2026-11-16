import XCTest
@testable import Hopes

final class AuthPasswordPolicyTests: XCTestCase {
    func testAllowsUpToServerMaximumLength() {
        let text = "abcd1234!efgh5"
        XCTAssertTrue(AuthPasswordPolicy.allowsChange(in: text, range: NSRange(location: 14, length: 0),
            replacement: "6"))
    }

    func testRejectsInputBeyondServerMaximumLength() {
        let text = "abcd1234!efgh56"
        XCTAssertFalse(AuthPasswordPolicy.allowsChange(in: text, range: NSRange(location: 15, length: 0),
            replacement: "7"))
    }

    func testRejectsPasteThatExceedsMaximumLength() {
        XCTAssertFalse(AuthPasswordPolicy.allowsChange(in: "", range: NSRange(location: 0, length: 0),
            replacement: "abcdefgh12345678"))
    }

    func testAllowsReplacingWholeSecureTextOnRefocus() {
        let text = "abcd1234!efgh56"
        XCTAssertTrue(AuthPasswordPolicy.allowsChange(in: text, range: NSRange(location: 0, length: 15),
            replacement: "a"))
    }
}
