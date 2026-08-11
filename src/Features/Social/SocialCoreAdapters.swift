import UIKit

// Keeps Core persistence models out of view controllers. When local static data replaces
// MockDataRepository, only this mapping/factory boundary needs to change.
extension SocialUser {
    init(rider: Rider, isFollowing: Bool = false, isMutualFollow: Bool = false) {
        self.init(
            id: rider.id.uuidString,
            name: rider.name,
            role: rider.role.rawValue,
            location: rider.location,
            bio: rider.bio,
            avatar: rider.displayAvatarImage,
            avatarName: rider.avatarAssetName,
            meetsCount: 0,
            followersCount: rider.followers,
            followingCount: rider.following,
            isFollowing: isFollowing,
            isMutualFollow: isMutualFollow
        )
    }
}

extension SocialPostPreview {
    init(post: WavePost, author: Rider) {
        self.init(id: post.id.uuidString, authorName: author.name, authorRole: "\(author.role.rawValue) · \(author.location)", title: post.title, subtitle: post.route)
    }
}

extension SocialMessage {
    init(message: ChatMessage, currentUserID: UUID, avatar: UIImage? = nil) {
        let content: SocialMessageContent
        switch message.kind {
        case .text: content = .text(message.payload)
        case .image:
            let url = URL(fileURLWithPath: message.payload)
            let data = (try? Data(contentsOf: url)) ?? Data()
            let image = UIImage(data: data) ?? UIImage(named: message.payload) ?? UIImage(systemName: "photo") ?? UIImage()
            content = .image(SocialImageAttachment(image: image, data: data, localURL: url))
        case .voice:
            let components = message.payload.split(separator: "|", maxSplits: 1).map(String.init)
            let url = URL(fileURLWithPath: components.first ?? message.payload)
            let duration = components.count > 1 ? (TimeInterval(components[1]) ?? 0) : 0
            content = .voice(duration: duration, localURL: url)
        }
        self.init(id: message.id.uuidString, senderID: message.senderID.uuidString, isFromCurrentUser: message.senderID == currentUserID, sentAt: message.date, content: content, avatar: avatar)
    }
}

enum SocialCoreAdapters {
    static func chatMessage(_ message: SocialMessage) throws -> ChatMessage {
        guard let id = UUID(uuidString: message.id),
              let senderID = UUID(uuidString: message.senderID) else {
            throw RepositoryMutationError.invalidOperation("The message identifier is invalid.")
        }
        let kind: ChatMessage.Kind
        let payload: String
        switch message.content {
        case .text(let text):
            kind = .text
            payload = text
        case .image(let attachment):
            kind = .image
            payload = attachment.localURL.path
        case .voice(let duration, let localURL):
            kind = .voice
            payload = "\(localURL.path)|\(duration)"
        }
        return ChatMessage(id: id, senderID: senderID, kind: kind, payload: payload, date: message.sentAt)
    }

    static func conversations(repository: VixiaRepository, currentUserID: UUID) -> [SocialConversation] {
        let usersByID = Dictionary(uniqueKeysWithValues: repository.users().map { ($0.id, $0) })
        let timeFormatter = DateFormatter(); timeFormatter.doesRelativeDateFormatting = true; timeFormatter.timeStyle = .short; timeFormatter.dateStyle = .none
        return repository.conversations().compactMap { conversation in
            guard let rider = usersByID[conversation.peerID] else { return nil }
            let last = conversation.messages.max(by: { $0.date < $1.date })
            return SocialConversation(
                id: conversation.id.uuidString,
                participant: SocialUser(rider: rider),
                lastMessage: last.map(summary) ?? "",
                timeText: last.map { timeFormatter.string(from: $0.date) } ?? "",
                unreadCount: conversation.unread ? 1 : 0,
                lastActivityAt: last?.date ?? .distantPast
            )
        }
    }

    static func messages(conversation: Conversation, currentUserID: UUID, currentUserAvatar: UIImage? = nil) -> [SocialMessage] {
        conversation.messages.map { message in
            SocialMessage(message: message, currentUserID: currentUserID, avatar: message.senderID == currentUserID ? currentUserAvatar : nil)
        }
    }

    private static func summary(_ message: ChatMessage) -> String {
        switch message.kind { case .text: return message.payload; case .image: return "Photo"; case .voice: return "Voice message" }
    }
}
