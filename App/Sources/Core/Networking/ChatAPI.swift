import Foundation

struct ChatSummaryDTO: Decodable {
    let id: Int64
    let title: String
    let updatedAt: String
}

struct ChatListDTO: Decodable {
    let chatList: [ChatSummaryDTO]
    let hasNext: Bool
}

struct ChatMessageDTO: Decodable {
    let id: Int64
    let role: String
    let content: String
    let createdAt: String

    var isUser: Bool { role.uppercased() == "USER" }
}

struct ChatDetailDTO: Decodable {
    let id: Int64
    let title: String
    let messages: [ChatMessageDTO]
}

struct SendMessagePayload: Encodable {
    let content: String
    let attachmentIds: [Int64]
    let departmentId: Int64?
    let specialtyId: Int64?
    let clientRequestId: String
}

enum ChatAPI {
    private static var client: APIClient { .shared }

    static func list(searchKeyword: String? = nil, page: Int = 0) async throws -> ChatListDTO {
        var path = "/api/main?page=\(page)&size=50"
        if let searchKeyword, !searchKeyword.isEmpty,
           let encoded = searchKeyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "&searchKeyword=\(encoded)"
        }
        return try await client.send("GET", path, authenticated: true)
    }

    static func create(title: String?) async throws -> ChatDetailDTO {
        let body = ["title": title.map { String($0.prefix(100)) }]
        return try await client.send("POST", "/api/chats", body: body, authenticated: true)
    }

    static func detail(id: Int64) async throws -> ChatDetailDTO {
        try await client.send("GET", "/api/chats/\(id)?messagePage=0&messageSize=100", authenticated: true)
    }

    static func send(chatID: Int64, payload: SendMessagePayload) async throws -> ChatDetailDTO {
        try await client.send("POST", "/api/chats/\(chatID)/messages", body: payload, authenticated: true)
    }

    static func delete(id: Int64) async throws {
        try await client.send("DELETE", "/api/chats/\(id)", authenticated: true)
    }

    static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

struct AttachmentDTO: Decodable {
    let id: Int64
    let status: String
}

enum AttachmentAPI {
    static func upload(
        data: Data,
        fileName: String,
        mimeType: String,
        clientRequestId: String,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void = { _, _ in }
    ) async throws -> AttachmentDTO {
        try await APIClient.shared.upload(
            "/api/attachments",
            fileData: data,
            fileName: fileName,
            mimeType: mimeType,
            clientRequestId: clientRequestId,
            onProgress: onProgress
        )
    }

    static func delete(id: Int64) async throws {
        try await APIClient.shared.send("DELETE", "/api/attachments/\(id)", authenticated: true)
    }
}
