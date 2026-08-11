import Foundation

enum LocalLoadState<Value> {
    case loading
    case empty
    case malformed(String)
    case loaded(Value)
}

extension LocalLoadState {
    var value: Value? {
        guard case let .loaded(value) = self else { return nil }
        return value
    }
}

enum RiderRole: String, Codable, CaseIterable {
    case dolphin = "Dolphin", panther = "Panther", flamingo = "Flamingo", owl = "Owl", wolf = "Wolf", fox = "Fox"
}

struct Rider: Codable, Hashable {
    let id: UUID
    var name: String
    var role: RiderRole
    var location: String
    var bio: String
    var followers: Int
    var following: Int
    var birthday: Date? = nil
    var gender: String? = nil
    var avatarData: Data? = nil
    var avatarAssetName: String? = nil
}

struct WavePost: Codable, Hashable {
    let id: UUID
    let authorID: UUID
    var title: String
    var route: String
    var distance: String
    var body: String
    var specs: [String: String]
    var unlockPrice: Int
    var likes: Int
    var comments: [WaveComment]
    var isLiked: Bool
    var boostedAt: Date? = nil
    var media: [LocalMediaReference] = []
    var routeNodes: [RouteNode] = []
}

struct LocalMediaReference: Codable, Hashable {
    enum Kind: String, Codable { case image, video }
    let id: UUID
    let kind: Kind
    /// PHPicker local identifier, an app-sandbox relative file URL, or another
    /// stable identifier understood by the replaceable local media provider.
    let localIdentifier: String
}

struct RouteNode: Codable, Hashable {
    let id: UUID
    var title: String
    var detail: String
}

struct RepositoryPostDraft: Hashable {
    var authorID: UUID
    var title: String
    var route: String
    var distance: String
    var body: String
    var specs: [String: String]
    var unlockPrice: Int
    var media: [LocalMediaReference]
    var routeNodes: [RouteNode]
}

struct WaveComment: Codable, Hashable {
    let id: UUID
    let authorID: UUID
    let text: String
    let date: Date
}

struct LocalMeet: Codable, Hashable {
    let id: UUID
    let hostID: UUID
    var title: String
    var location: String
    var distance: String
    var date: Date
    var attendees: Int
    var capacity: Int
    var joined: Bool
    var attendeeIDs: [UUID] = []
    var coverAssetName: String? = nil
}

struct Conversation: Codable, Hashable {
    let id: UUID
    let peerID: UUID
    var messages: [ChatMessage]
    var unread: Bool
    var ownerID: UUID? = nil
}

struct ChatMessage: Codable, Hashable {
    enum Kind: String, Codable { case text, image, voice }
    let id: UUID
    let senderID: UUID
    let kind: Kind
    let payload: String
    let date: Date
}

struct ReportRecord: Codable, Hashable {
    let id: UUID
    let targetUserID: UUID
    let sourceID: UUID?
    let reason: String
    let createdAt: Date
}

struct FollowRelationship: Codable, Hashable {
    let followerID: UUID
    let followedID: UUID
    let createdAt: Date
}

struct PostLike: Codable, Hashable {
    let userID: UUID
    let postID: UUID
}

/// Codable aggregate used by the replaceable local repository boundary.
/// A future bundled JSON data source can provide this exact shape without
/// requiring feature controllers to change.
struct VixiaDataSnapshot: Codable, Hashable {
    var schemaVersion: Int
    var riders: [Rider]
    var posts: [WavePost]
    var meets: [LocalMeet]
    var conversations: [Conversation]
    var relationships: Set<FollowRelationship>
    var postLikes: Set<PostLike>

    var isEmpty: Bool {
        riders.isEmpty && posts.isEmpty && meets.isEmpty && conversations.isEmpty
    }
}

enum RepositoryMutationError: LocalizedError, Equatable {
    case malformedLocalData(String)
    case userNotFound
    case postNotFound
    case meetNotFound
    case conversationNotFound
    case invalidOperation(String)
    case insufficientDiamonds(required: Int, available: Int)
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case let .malformedLocalData(message): return message
        case .userNotFound: return "The user no longer exists."
        case .postNotFound: return "The post no longer exists."
        case .meetNotFound: return "The meet no longer exists."
        case .conversationNotFound: return "The conversation no longer exists."
        case let .invalidOperation(message): return message
        case let .insufficientDiamonds(required, available):
            return "This action needs \(required) diamonds; \(available) are available."
        case let .persistenceFailed(message): return message
        }
    }
}

struct DiamondProduct: Hashable {
    let productID: String
    let diamonds: Int
    let fallbackPrice: String
}
