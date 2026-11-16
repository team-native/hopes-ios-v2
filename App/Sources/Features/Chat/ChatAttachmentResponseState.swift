import UIKit

@MainActor
final class ChatAttachmentResponseState {
    var pendingCard: UIView?
    var failureCard: UIView?
    var lastSentAttachments: [ChatAttachmentItem]?
    var messageClientRequestId: String?
    var thumbnails: [UIImageView] = []
    var uploadedAttachmentIDs: [String: Int64] = [:]
    var uploadProgressViews: [String: UIProgressView] = [:]
    var uploadStatusLabels: [String: UILabel] = [:]
    var uploadRetryButtons: [String: UIButton] = [:]
    var isResponse = false
}
