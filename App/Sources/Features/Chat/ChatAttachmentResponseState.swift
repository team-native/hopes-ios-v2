import UIKit

@MainActor
final class ChatAttachmentResponseState {
    var pendingCard: UIView?
    var failureCard: UIView?
    var lastSentAttachments: [ChatAttachmentItem]?
    var messageClientRequestId: String?
    var thumbnails: [UIImageView] = []
    var isResponse = false
}
