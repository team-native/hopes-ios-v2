import XCTest
@testable import Hopes

@MainActor
final class ChatMajorSelectionTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        defaults = UserDefaults(suiteName: "ChatMajorSelectionTests")
        defaults.removePersistentDomain(forName: "ChatMajorSelectionTests")
    }

    func testSavingMultipleMajorsKeepsFirstAsServerPrimary() {
        ChatMajorSelection.save(["iOS", "Backend"], defaults: defaults)
        XCTAssertEqual(ChatMajorSelection.load(defaults: defaults), ["iOS", "Backend"])
        XCTAssertEqual(defaults.string(forKey: ChatMajorSelection.primaryKey), "iOS")
    }

    func testLegacySingleMajorIsMigrated() {
        defaults.set("Android", forKey: ChatMajorSelection.primaryKey)
        XCTAssertEqual(ChatMajorSelection.load(defaults: defaults), ["Android"])
    }

    func testDisplayNameCollapsesLongSelections() {
        XCTAssertNil(ChatMajorSelection.displayName([]))
        XCTAssertEqual(ChatMajorSelection.displayName(["iOS", "AI"]), "iOS, AI")
        XCTAssertEqual(ChatMajorSelection.displayName(["iOS", "AI", "IoT"]), "iOS 외 2")
    }

    func testDefaultStudyQuestionFollowsSelectedMajor() {
        XCTAssertEqual(ChatMajorSelection.studyQuestion(for: "iOS"), "iOS는 뭐부터 공부하면 좋아?")
        XCTAssertEqual(ChatMajorSelection.studyQuestion(for: "Design"), "Design은 뭐부터 공부하면 좋아?")
        XCTAssertEqual(ChatMajorSelection.studyQuestion(for: nil), "전공 공부는 뭐부터 하면 좋아?")
        let sets = ChatHomeViewController.defaultQuestionSets(major: "iOS")
        XCTAssertTrue(sets[0].contains { $0.1 == "iOS는 뭐부터 공부하면 좋아?" })
        XCTAssertFalse(sets.flatMap { $0 }.contains { $0.1.contains("Frontend") })
    }

    func testPickerTogglesMultipleMajors() {
        let picker = MajorPickerViewController(selectedMajors: ["iOS"])
        picker.toggle("Backend")
        XCTAssertEqual(picker.selectedMajors, ["iOS", "Backend"])
        picker.toggle("iOS")
        XCTAssertEqual(picker.selectedMajors, ["Backend"])
    }
}
