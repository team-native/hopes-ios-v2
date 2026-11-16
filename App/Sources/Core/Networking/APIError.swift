import Foundation

enum APIError: Error, Equatable {
    case server(status: Int, code: String, message: String, fieldErrors: [String: String])
    case unauthorized(message: String)
    case network
    case decoding

    var status: Int? {
        switch self {
        case let .server(status, _, _, _): status
        case .unauthorized: 401
        case .network, .decoding: nil
        }
    }

    var message: String {
        switch self {
        case let .server(_, _, message, _): message
        case let .unauthorized(message): message
        case .network: "인터넷 연결이 끊겼어요. 연결되면 다시 시도해 주세요."
        case .decoding: "서버 응답을 처리하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

struct APIErrorBody: Decodable {
    let code: String?
    let message: String?
    let errors: [String: String]?
}
