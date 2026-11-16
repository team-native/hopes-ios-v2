import Foundation

enum ChatAttachmentLimitError: LocalizedError, Equatable, Sendable {
    case unsupportedFormat
    case tooManyAttachments
    case fileTooLarge
    case totalTooLarge
    case tooManyPDFPages
    case imageTooLarge
    case unreadableFile

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: "PNG, JPEG 또는 PDF 파일만 첨부할 수 있어요."
        case .tooManyAttachments: "한 번에 최대 3개까지 첨부할 수 있어요."
        case .fileTooLarge: "파일 하나는 5MB 이하만 첨부할 수 있어요."
        case .totalTooLarge: "첨부 파일 전체 용량은 12MB까지예요. 파일을 줄이거나 일부를 빼 주세요."
        case .tooManyPDFPages: "PDF는 최대 50쪽까지 첨부할 수 있어요."
        case .imageTooLarge: "이미지 해상도는 2,500만 픽셀 이하만 첨부할 수 있어요."
        case .unreadableFile: "파일을 읽지 못했어요. 다시 선택해 주세요."
        }
    }
}

enum ChatAttachmentPolicy {
    // Mirrors the server's documented initial defaults; server validation remains authoritative.
    static let maximumCount = 3
    static let maximumFileBytes = 5_242_880
    static let maximumTotalBytes = 12_582_912
    static let maximumPDFPages = 50
    static let maximumImagePixels: Int64 = 25_000_000

    static func validateCount(_ count: Int) throws {
        guard count <= maximumCount else { throw ChatAttachmentLimitError.tooManyAttachments }
    }

    static func validateFileSize(_ bytes: Int) throws {
        guard bytes > 0 else { throw ChatAttachmentLimitError.unreadableFile }
        guard bytes <= maximumFileBytes else { throw ChatAttachmentLimitError.fileTooLarge }
    }

    static func validateTotalSize(_ bytes: Int) throws {
        guard bytes <= maximumTotalBytes else { throw ChatAttachmentLimitError.totalTooLarge }
    }

    static func validatePDFPages(_ count: Int) throws {
        guard (1...maximumPDFPages).contains(count) else { throw ChatAttachmentLimitError.tooManyPDFPages }
    }

    static func validateImageDimensions(width: Int, height: Int) throws {
        let maximumPixels = Int(maximumImagePixels)
        guard width > 0, height > 0, width <= maximumPixels / height else {
            throw ChatAttachmentLimitError.imageTooLarge
        }
    }

    static func validate(_ attachments: [ChatAttachmentItem]) throws {
        try validateCount(attachments.count)
        for attachment in attachments {
            switch attachment.validationState {
            case .supported:
                break
            case .unsupportedFormat:
                throw ChatAttachmentLimitError.unsupportedFormat
            case .unreadablePDF:
                throw ChatAttachmentLimitError.unreadableFile
            case .fileTooLarge:
                throw ChatAttachmentLimitError.fileTooLarge
            case .tooManyPDFPages:
                throw ChatAttachmentLimitError.tooManyPDFPages
            case .imageTooLarge:
                throw ChatAttachmentLimitError.imageTooLarge
            }
            guard attachment.image != nil || attachment.url != nil else {
                throw ChatAttachmentLimitError.unreadableFile
            }
            if attachment.image == nil {
                try validatePDFPages(attachment.pageCount ?? 0)
            }
        }
    }
}
