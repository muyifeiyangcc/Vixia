import UIKit

public typealias SocialDataLoader<Value> = (@escaping (Result<Value, Error>) -> Void) -> Void
public typealias SocialMutationCompletion<Value> = (Result<Value, Error>) -> Void

public extension Notification.Name {
    /// Posted after a block has been persisted. `userInfo[SocialNotificationKey.userID]`
    /// contains the blocked social user identifier.
    static let socialUserDidBlock = Notification.Name("vixia.social.userDidBlock")
    /// Posted after follow state/profile data/messages have changed and screens should reload.
    static let socialDataDidChange = Notification.Name("vixia.social.dataDidChange")
}

public enum SocialNotificationKey {
    public static let userID = "userID"
}

public enum SocialLocalError: LocalizedError {
    case invalidImage
    case cannotStoreAttachment
    case recordingTooShort
    case recordingFailed
    case playbackFailed

    public var errorDescription: String? {
        switch self {
        case .invalidImage: return "The selected image could not be read."
        case .cannotStoreAttachment: return "The attachment could not be saved locally."
        case .recordingTooShort: return "Recording is too short."
        case .recordingFailed: return "Voice recording failed."
        case .playbackFailed: return "This voice message cannot be played."
        }
    }
}

public enum SocialLoadState<Value> {
    case loading
    case empty(message: String)
    case failure(message: String)
    case loaded(Value)
}

public struct SocialUser: Hashable {
    public let id: String
    public var name: String
    public var role: String
    public var location: String
    public var bio: String
    public var avatar: UIImage?
    public var avatarName: String?
    public var meetsCount: Int
    public var followersCount: Int
    public var followingCount: Int
    public var isFollowing: Bool
    public var isMutualFollow: Bool

    public init(id: String, name: String, role: String, location: String = "", bio: String = "", avatar: UIImage? = nil, avatarName: String? = nil, meetsCount: Int = 0, followersCount: Int = 0, followingCount: Int = 0, isFollowing: Bool = false, isMutualFollow: Bool = false) {
        self.id = id
        self.name = name
        self.role = role
        self.location = location
        self.bio = bio
        self.avatar = avatar
        self.avatarName = avatarName
        self.meetsCount = meetsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isFollowing = isFollowing
        self.isMutualFollow = isMutualFollow
    }
}

public struct SocialPostPreview: Hashable {
    public let id: String
    public var authorName: String
    public var authorRole: String
    public var title: String
    public var subtitle: String
    public var cover: UIImage?
    public var coverName: String?

    public init(id: String, authorName: String, authorRole: String, title: String, subtitle: String, cover: UIImage? = nil, coverName: String? = nil) {
        self.id = id
        self.authorName = authorName
        self.authorRole = authorRole
        self.title = title
        self.subtitle = subtitle
        self.cover = cover
        self.coverName = coverName
    }
}

public struct SocialConversation: Hashable {
    public let id: String
    public let participant: SocialUser
    public var lastMessage: String
    public var timeText: String
    public var unreadCount: Int
    public var lastActivityAt: Date

    public init(id: String, participant: SocialUser, lastMessage: String, timeText: String, unreadCount: Int = 0, lastActivityAt: Date = .distantPast) {
        self.id = id
        self.participant = participant
        self.lastMessage = lastMessage
        self.timeText = timeText
        self.unreadCount = unreadCount
        self.lastActivityAt = lastActivityAt
    }
}

public struct SocialImageAttachment {
    public let image: UIImage
    public let data: Data
    public let localURL: URL

    public init(image: UIImage, data: Data, localURL: URL) {
        self.image = image
        self.data = data
        self.localURL = localURL
    }
}

public enum SocialMessageContent {
    case text(String)
    case image(SocialImageAttachment)
    case voice(duration: TimeInterval, localURL: URL)
}

/// Storage-friendly message payload passed to the repository boundary.
public enum SocialMessagePayload {
    case text(String)
    case image(data: Data, localURL: URL)
    case voice(localURL: URL, duration: TimeInterval)
}

public struct SocialMessage {
    public let id: String
    public let senderID: String
    public let isFromCurrentUser: Bool
    public let sentAt: Date
    public let content: SocialMessageContent
    public let avatar: UIImage?

    public init(id: String, senderID: String, isFromCurrentUser: Bool, sentAt: Date, content: SocialMessageContent, avatar: UIImage? = nil) {
        self.id = id
        self.senderID = senderID
        self.isFromCurrentUser = isFromCurrentUser
        self.sentAt = sentAt
        self.content = content
        self.avatar = avatar
    }

    public var payload: SocialMessagePayload {
        switch content {
        case .text(let text): return .text(text)
        case .image(let attachment): return .image(data: attachment.data, localURL: attachment.localURL)
        case .voice(let duration, let localURL): return .voice(localURL: localURL, duration: duration)
        }
    }
}

public enum SocialProfileSegment: Int {
    case waveDrops
    case localMeets
}

public enum SocialUsersListKind {
    case following
    case followers

    var title: String { self == .following ? "Following" : "Followers" }
}

public enum SocialActionSource {
    case profile
    case post(postID: String)
    case conversation(conversationID: String)
}

public enum SocialActionResult {
    case reported(user: SocialUser, source: SocialActionSource, reason: String)
    case blocked(user: SocialUser, source: SocialActionSource)
}
