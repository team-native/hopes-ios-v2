import PDFKit
import UIKit
import UniformTypeIdentifiers

struct ValidatedChatDocument: Sendable {
    let fileName: String
    let url: URL
    let state: ChatAttachmentValidationState
    let pageCount: Int?
}

func validateChatDocument(at url: URL) -> ValidatedChatDocument {
    let didAccess = url.startAccessingSecurityScopedResource()
    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
    let state: ChatAttachmentValidationState
    let pageCount: Int?
    if UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) != true {
        state = .unsupportedFormat
        pageCount = nil
    } else if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
        do {
            try ChatAttachmentPolicy.validateFileSize(size)
            guard let document = PDFDocument(url: url), !document.isLocked, document.pageCount > 0 else {
                return ValidatedChatDocument(
                    fileName: url.lastPathComponent, url: url, state: .unreadablePDF, pageCount: nil
                )
            }
            do {
                try ChatAttachmentPolicy.validatePDFPages(document.pageCount)
                state = .supported
            } catch {
                state = .tooManyPDFPages
            }
            pageCount = document.pageCount
        } catch ChatAttachmentLimitError.fileTooLarge {
            state = .fileTooLarge
            pageCount = nil
        } catch {
            state = .unreadablePDF
            pageCount = nil
        }
    } else {
        state = .unreadablePDF
        pageCount = nil
    }
    return ValidatedChatDocument(fileName: url.lastPathComponent, url: url, state: state, pageCount: pageCount)
}

@MainActor
extension ChatAttachmentPickerViewController {
    nonisolated static func imageValidationState(_ image: UIImage?) -> ChatAttachmentValidationState {
        guard let image else { return .unsupportedFormat }
        let width = image.cgImage?.width ?? Int((image.size.width * image.scale).rounded())
        let height = image.cgImage?.height ?? Int((image.size.height * image.scale).rounded())
        do {
            try ChatAttachmentPolicy.validateImageDimensions(width: width, height: height)
            return .supported
        } catch {
            return .imageTooLarge
        }
    }
}
