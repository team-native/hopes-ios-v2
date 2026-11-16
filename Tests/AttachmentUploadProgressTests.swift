import XCTest
@testable import Hopes

@MainActor
final class AttachmentUploadProgressTests: XCTestCase {
    func testUploadProgressAndRetryStateArePerFile() throws {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        let image = ChatAttachmentItem(fileName: "photo.jpg", image: UIImage())
        let pdf = ChatAttachmentItem(
            fileName: "notes.pdf", image: nil, url: URL(fileURLWithPath: "/tmp/notes.pdf")
        )
        controller.addSentAttachments([image, pdf])

        let imageKey = image.id.uuidString
        let pdfKey = pdf.id.uuidString
        let imageStatus = try XCTUnwrap(controller.attachmentResponseState.uploadStatusLabels[imageKey])
        let pdfStatus = try XCTUnwrap(controller.attachmentResponseState.uploadStatusLabels[pdfKey])
        let imageProgress = try XCTUnwrap(controller.attachmentResponseState.uploadProgressViews[imageKey])

        controller.updateAttachmentUploadProgress(clientRequestId: imageKey, sent: 30, expected: 100)
        controller.updateAttachmentUploadCompleted(clientRequestId: pdfKey)
        XCTAssertEqual(imageStatus.text, "업로드 중 · 30%")
        XCTAssertEqual(imageProgress.progress, 0.3, accuracy: 0.01)
        XCTAssertEqual(pdfStatus.text, "업로드 완료")

        controller.updateAttachmentUploadFailed(clientRequestId: imageKey)
        let retry = try XCTUnwrap(controller.attachmentResponseState.uploadRetryButtons[imageKey])
        XCTAssertEqual(imageStatus.text, "업로드 실패 · 다시 시도")
        XCTAssertFalse(retry.isHidden)
        controller.networkMonitor.cancel()
    }
}
