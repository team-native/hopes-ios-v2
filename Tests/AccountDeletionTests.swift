import XCTest
@testable import Hopes

@MainActor
final class AccountDeletionTests: XCTestCase {
    private func makeController() -> AccountDeletionViewController {
        let controller = AccountDeletionViewController()
        controller.hasSession = { true }
        controller.loadViewIfNeeded()
        return controller
    }

    func testEmptyPasswordShowsInlineErrorWithoutCallingServer() {
        let controller = makeController()
        var called = false
        controller.accountDeleter = { _ in called = true }
        controller.confirmDeletion()
        XCTAssertFalse(controller.errorRow.isHidden)
        XCTAssertEqual(controller.errorLabel.text, AccountDeletionViewController.emptyPasswordMessage)
        XCTAssertFalse(called)
    }

    func testWrongPasswordShowsInlineErrorInsteadOfSessionExpiry() async {
        let controller = makeController()
        var deleted = false
        controller.onDeleted = { deleted = true }
        controller.accountDeleter = { _ in throw APIError.unauthorized(message: "비밀번호가 일치하지 않습니다") }
        controller.deleteAccount(password: "wrong-pass1")
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(deleted)
        XCTAssertFalse(controller.isDeleting)
        XCTAssertEqual(controller.errorLabel.text, AccountDeletionViewController.wrongPasswordMessage)
        XCTAssertTrue(controller.deleteButton.isEnabled)
    }

    func testSuccessfulDeletionSendsPasswordAndFinishes() async {
        let controller = makeController()
        var sentPassword: String?
        var deleted = false
        controller.onDeleted = { deleted = true }
        controller.accountDeleter = { sentPassword = $0 }
        controller.deleteAccount(password: "correct-pass1")
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(sentPassword, "correct-pass1")
        XCTAssertTrue(deleted)
    }

    func testDeletionWithoutSessionDoesNotCallServer() {
        let controller = makeController()
        controller.hasSession = { false }
        var called = false
        controller.accountDeleter = { _ in called = true }
        controller.deleteAccount(password: "pass1234")
        XCTAssertFalse(called)
    }

    func testClearLocalDataRemovesStoredProfile() {
        let store = UserProfileStore.shared
        store.update(name: "임서하", department: "인공지능과", email: "someone@example.invalid", introduction: "소개")
        store.clearLocalData()
        XCTAssertNil(store.savedEmail)
        XCTAssertEqual(store.introduction, "")
    }
}
