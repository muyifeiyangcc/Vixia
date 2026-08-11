import Foundation

protocol VixiaRepository: AnyObject {
    var currentUser: Rider { get }
    func user(_ id: UUID) -> Rider?
    func users() -> [Rider]
    func posts(role: RiderRole?) -> [WavePost]
    func posts(authorID: UUID) -> [WavePost]
    func post(_ id: UUID) -> WavePost?
    func meets() -> [LocalMeet]
    func meets(for userID: UUID) -> [LocalMeet]
    func conversations() -> [Conversation]
    func followers(of userID: UUID) -> [Rider]
    func following(of userID: UUID) -> [Rider]
    func isFollowing(_ followerID: UUID, _ followedID: UUID) -> Bool
    func isMutualFollow(_ firstID: UUID, _ secondID: UUID) -> Bool

    @discardableResult func upsertProfile(userID: UUID, name: String, role: RiderRole, birthday: Date?, gender: String?, bio: String, avatarData: Data?) -> Rider
    @discardableResult func createPost(_ draft: RepositoryPostDraft) -> WavePost
    @discardableResult func toggleLike(postID: UUID, userID: UUID) throws -> WavePost
    @discardableResult func addComment(postID: UUID, authorID: UUID, text: String) throws -> WavePost
    @discardableResult func toggleFollow(followerID: UUID, followedID: UUID) throws -> Bool
    @discardableResult func toggleMeetJoin(meetID: UUID, userID: UUID) throws -> LocalMeet
    @discardableResult func conversation(with peerID: UUID, ownerID: UUID) throws -> Conversation
    func appendMessage(_ message: ChatMessage, to conversationID: UUID) throws
    func markConversationRead(_ conversationID: UUID)
    func deletePost(_ id: UUID)
    func deleteUser(_ id: UUID)
}

/// Persistent local repository. The seed factory is the only place that owns
/// placeholder content, so a future CSV importer can replace it without changing UI code.
final class MockDataRepository: VixiaRepository {
    static let shared = MockDataRepository()

    private static let currentSchemaVersion = 2

    private enum SeedID {
        static let weber = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        static let elena = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        static let benetti = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
        static let laurent = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
        static let henrik = UUID(uuidString: "00000000-0000-0000-0000-000000000105")!
        static let clara = UUID(uuidString: "00000000-0000-0000-0000-000000000106")!

        static let postWeber = UUID(uuidString: "10000000-0000-0000-0000-000000000101")!
        static let postElena = UUID(uuidString: "10000000-0000-0000-0000-000000000102")!
        static let postBenetti = UUID(uuidString: "10000000-0000-0000-0000-000000000103")!
        static let postLaurent = UUID(uuidString: "10000000-0000-0000-0000-000000000104")!
        static let postHenrik = UUID(uuidString: "10000000-0000-0000-0000-000000000105")!
        static let postClara = UUID(uuidString: "10000000-0000-0000-0000-000000000106")!

        static let meetCoastal = UUID(uuidString: "20000000-0000-0000-0000-000000000101")!
        static let meetBerlin = UUID(uuidString: "20000000-0000-0000-0000-000000000102")!

        static let legacyUserIDs: Set<UUID> = [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        ]
    }

    private let store: LocalStore
    private var snapshot: VixiaDataSnapshot

    var currentUser: Rider {
        let id = store.signedInUserID ?? SeedID.weber
        return user(id) ?? snapshot.riders.first ?? Self.fallbackRider
    }

    init(store: LocalStore = .shared) {
        self.store = store
        if let saved = store.dataSnapshot, saved.schemaVersion >= Self.currentSchemaVersion {
            snapshot = saved
        } else if let saved = store.dataSnapshot {
            snapshot = Self.migrateReplacingLegacySeed(saved)
            store.dataSnapshot = snapshot
        } else {
            snapshot = Self.seedSnapshot(existingConversations: store.conversations)
            store.dataSnapshot = snapshot
        }
        seedBundledTestProfileIfNeeded()
    }

    func user(_ id: UUID) -> Rider? {
        guard !store.blockedUserIDs.contains(id) || id == store.signedInUserID else { return nil }
        return snapshot.riders.first(where: { $0.id == id }).map(renderedRider)
    }

    func users() -> [Rider] {
        snapshot.riders.filter { !store.blockedUserIDs.contains($0.id) }.map(renderedRider)
    }

    func posts(role: RiderRole? = nil) -> [WavePost] {
        snapshot.posts
            .filter { post in
                !store.blockedUserIDs.contains(post.authorID)
                    && (role == nil || snapshot.riders.first(where: { $0.id == post.authorID })?.role == role)
            }
            .map(renderedPost)
    }

    func posts(authorID: UUID) -> [WavePost] {
        posts(role: nil).filter { $0.authorID == authorID }
    }

    func post(_ id: UUID) -> WavePost? {
        posts(role: nil).first { $0.id == id }
    }

    func meets() -> [LocalMeet] {
        snapshot.meets.filter { !store.blockedUserIDs.contains($0.hostID) }.map(renderedMeet)
    }

    func meets(for userID: UUID) -> [LocalMeet] {
        meets().filter { $0.hostID == userID || $0.attendeeIDs.contains(userID) }
    }

    func conversations() -> [Conversation] {
        let ownerID = store.signedInUserID ?? currentUser.id
        return snapshot.conversations.filter {
            !store.blockedUserIDs.contains($0.peerID) && ($0.ownerID == nil || $0.ownerID == ownerID)
        }
    }

    func followers(of userID: UUID) -> [Rider] {
        let ids = Set(snapshot.relationships.filter { $0.followedID == userID }.map(\.followerID))
        return users().filter { ids.contains($0.id) }
    }

    func following(of userID: UUID) -> [Rider] {
        let ids = Set(snapshot.relationships.filter { $0.followerID == userID }.map(\.followedID))
        return users().filter { ids.contains($0.id) }
    }

    func isFollowing(_ followerID: UUID, _ followedID: UUID) -> Bool {
        snapshot.relationships.contains { $0.followerID == followerID && $0.followedID == followedID }
    }

    func isMutualFollow(_ firstID: UUID, _ secondID: UUID) -> Bool {
        isFollowing(firstID, secondID) && isFollowing(secondID, firstID)
    }

    @discardableResult
    func upsertProfile(userID: UUID, name: String, role: RiderRole, birthday: Date?, gender: String?, bio: String = "", avatarData: Data?) -> Rider {
        if let index = snapshot.riders.firstIndex(where: { $0.id == userID }) {
            snapshot.riders[index].name = name
            snapshot.riders[index].role = role
            snapshot.riders[index].birthday = birthday
            snapshot.riders[index].gender = gender
            snapshot.riders[index].bio = bio
            if let avatarData { snapshot.riders[index].avatarData = avatarData }
        } else {
            snapshot.riders.append(Rider(id: userID, name: name, role: role, location: "", bio: bio, followers: 0, following: 0, birthday: birthday, gender: gender, avatarData: avatarData))
        }
        persist(.profile, entityID: userID)
        return snapshot.riders.first { $0.id == userID }!
    }

    @discardableResult
    func createPost(_ draft: RepositoryPostDraft) -> WavePost {
        let post = WavePost(id: UUID(), authorID: draft.authorID, title: draft.title, route: draft.route, distance: draft.distance, body: draft.body, specs: draft.specs, unlockPrice: draft.unlockPrice, likes: 0, comments: [], isLiked: false, media: draft.media, routeNodes: draft.routeNodes)
        snapshot.posts.insert(post, at: 0)
        persist(.posts, entityID: post.id)
        return post
    }

    @discardableResult
    func toggleLike(postID: UUID, userID: UUID) throws -> WavePost {
        guard let index = snapshot.posts.firstIndex(where: { $0.id == postID }) else { throw RepositoryMutationError.postNotFound }
        let like = PostLike(userID: userID, postID: postID)
        if snapshot.postLikes.remove(like) != nil {
            snapshot.posts[index].likes = max(0, snapshot.posts[index].likes - 1)
        } else {
            snapshot.postLikes.insert(like)
            snapshot.posts[index].likes += 1
        }
        snapshot.posts[index].isLiked = snapshot.postLikes.contains(like)
        persist(.posts, entityID: postID)
        return renderedPost(snapshot.posts[index])
    }

    @discardableResult
    func addComment(postID: UUID, authorID: UUID, text: String) throws -> WavePost {
        guard let index = snapshot.posts.firstIndex(where: { $0.id == postID }) else { throw RepositoryMutationError.postNotFound }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw RepositoryMutationError.invalidOperation("Comment cannot be empty.") }
        snapshot.posts[index].comments.append(WaveComment(id: UUID(), authorID: authorID, text: value, date: Date()))
        persist(.posts, entityID: postID)
        return renderedPost(snapshot.posts[index])
    }

    @discardableResult
    func toggleFollow(followerID: UUID, followedID: UUID) throws -> Bool {
        guard followerID != followedID else { throw RepositoryMutationError.invalidOperation("You cannot follow yourself.") }
        guard let followerIndex = snapshot.riders.firstIndex(where: { $0.id == followerID }),
              let followedIndex = snapshot.riders.firstIndex(where: { $0.id == followedID }) else { throw RepositoryMutationError.userNotFound }
        if let relationship = snapshot.relationships.first(where: { $0.followerID == followerID && $0.followedID == followedID }) {
            snapshot.relationships.remove(relationship)
            snapshot.riders[followerIndex].following = max(0, snapshot.riders[followerIndex].following - 1)
            snapshot.riders[followedIndex].followers = max(0, snapshot.riders[followedIndex].followers - 1)
            persist(.relationships, entityID: followedID)
            return false
        }
        snapshot.relationships.insert(FollowRelationship(followerID: followerID, followedID: followedID, createdAt: Date()))
        snapshot.riders[followerIndex].following += 1
        snapshot.riders[followedIndex].followers += 1
        persist(.relationships, entityID: followedID)
        return true
    }

    @discardableResult
    func toggleMeetJoin(meetID: UUID, userID: UUID) throws -> LocalMeet {
        guard let index = snapshot.meets.firstIndex(where: { $0.id == meetID }) else { throw RepositoryMutationError.meetNotFound }
        if let attendeeIndex = snapshot.meets[index].attendeeIDs.firstIndex(of: userID) {
            snapshot.meets[index].attendeeIDs.remove(at: attendeeIndex)
            snapshot.meets[index].joined = false
        } else {
            guard snapshot.meets[index].attendeeIDs.count < snapshot.meets[index].capacity else { throw RepositoryMutationError.invalidOperation("This ride is full.") }
            snapshot.meets[index].attendeeIDs.append(userID)
            snapshot.meets[index].joined = true
        }
        snapshot.meets[index].attendees = snapshot.meets[index].attendeeIDs.count
        persist(.meets, entityID: meetID)
        return snapshot.meets[index]
    }

    @discardableResult
    func conversation(with peerID: UUID, ownerID: UUID) throws -> Conversation {
        guard snapshot.riders.contains(where: { $0.id == peerID }) else { throw RepositoryMutationError.userNotFound }
        if let existing = snapshot.conversations.first(where: { $0.peerID == peerID && ($0.ownerID == nil || $0.ownerID == ownerID) }) { return existing }
        let value = Conversation(id: UUID(), peerID: peerID, messages: [], unread: false, ownerID: ownerID)
        snapshot.conversations.append(value)
        persist(.conversations, entityID: value.id)
        return value
    }

    func appendMessage(_ message: ChatMessage, to conversationID: UUID) throws {
        guard let index = snapshot.conversations.firstIndex(where: { $0.id == conversationID }) else { throw RepositoryMutationError.conversationNotFound }
        guard !snapshot.conversations[index].messages.contains(where: { $0.id == message.id }) else { return }
        snapshot.conversations[index].messages.append(message)
        snapshot.conversations[index].messages.sort { $0.date < $1.date }
        snapshot.conversations[index].unread = message.senderID != currentUser.id
        persist(.conversations, entityID: conversationID)
    }

    func markConversationRead(_ conversationID: UUID) {
        guard let index = snapshot.conversations.firstIndex(where: { $0.id == conversationID }), snapshot.conversations[index].unread else { return }
        snapshot.conversations[index].unread = false
        persist(.conversations, entityID: conversationID)
    }

    func deletePost(_ id: UUID) {
        snapshot.posts.removeAll { $0.id == id }
        snapshot.postLikes = snapshot.postLikes.filter { $0.postID != id }
        persist(.posts, entityID: id)
    }

    func deleteUser(_ id: UUID) {
        snapshot.riders.removeAll { $0.id == id }
        let postIDs = Set(snapshot.posts.filter { $0.authorID == id }.map(\.id))
        snapshot.posts.removeAll { $0.authorID == id }
        snapshot.posts = snapshot.posts.map { post in
            var copy = post
            copy.comments.removeAll { $0.authorID == id }
            return copy
        }
        snapshot.postLikes = snapshot.postLikes.filter { $0.userID != id && !postIDs.contains($0.postID) }
        snapshot.relationships = snapshot.relationships.filter { $0.followerID != id && $0.followedID != id }
        snapshot.meets.removeAll { $0.hostID == id }
        for index in snapshot.meets.indices {
            if snapshot.meets[index].attendeeIDs.contains(id) {
                snapshot.meets[index].attendeeIDs.removeAll { $0 == id }
                snapshot.meets[index].attendees = max(0, snapshot.meets[index].attendees - 1)
            }
        }
        snapshot.conversations.removeAll { $0.ownerID == id || $0.peerID == id }
        persist(.accountDeleted, entityID: id)
    }

    func blockedUsers() -> [Rider] {
        snapshot.riders.filter { store.blockedUserIDs.contains($0.id) }
    }

    func rider(_ id: UUID) -> Rider? { user(id) }

    private func seedBundledTestProfileIfNeeded() {
        guard LocalAccountStore.shared.userID(forEmail: BundledTestAccount.email) == BundledTestAccount.userID else { return }
        if !snapshot.riders.contains(where: { $0.id == BundledTestAccount.userID }) {
            snapshot.riders.append(Rider(
                id: BundledTestAccount.userID,
                name: "Test Rider",
                role: .dolphin,
                location: "",
                bio: "",
                followers: 1,
                following: 0
            ))
        }
        if !snapshot.relationships.contains(where: { $0.followedID == BundledTestAccount.userID }) {
            snapshot.relationships.insert(FollowRelationship(
                followerID: SeedID.weber,
                followedID: BundledTestAccount.userID,
                createdAt: Self.date(2026, 8, 1, 12, 0)
            ))
        }
        snapshot.schemaVersion = Self.currentSchemaVersion
        store.dataSnapshot = snapshot
    }

    private func renderedPost(_ stored: WavePost) -> WavePost {
        var post = stored
        let currentID = store.signedInUserID ?? currentUser.id
        post.isLiked = snapshot.postLikes.contains(PostLike(userID: currentID, postID: post.id))
        post.comments.removeAll { store.blockedUserIDs.contains($0.authorID) }
        return post
    }

    private func renderedRider(_ stored: Rider) -> Rider {
        var rider = stored
        rider.followers = snapshot.relationships.filter { $0.followedID == rider.id }.count
        rider.following = snapshot.relationships.filter { $0.followerID == rider.id }.count
        return rider
    }

    private func renderedMeet(_ stored: LocalMeet) -> LocalMeet {
        var meet = stored
        let currentID = store.signedInUserID ?? currentUser.id
        meet.joined = meet.attendeeIDs.contains(currentID)
        meet.attendees = meet.attendeeIDs.count
        return meet
    }

    private func persist(_ change: VixiaRepositoryChange, entityID: UUID? = nil) {
        snapshot.schemaVersion = Self.currentSchemaVersion
        store.dataSnapshot = snapshot
        store.postChange(change, entityID: entityID)
    }

    private static let fallbackRider = Rider(id: SeedID.weber, name: "Rider", role: .dolphin, location: "", bio: "", followers: 0, following: 0)

    private static func seedSnapshot(existingConversations: [Conversation]) -> VixiaDataSnapshot {
        let riders = [
            Rider(id: SeedID.weber, name: "Weber", role: .panther, location: "", bio: "DIY mechanic & weekend rider.", followers: 0, following: 0, avatarAssetName: "m1"),
            Rider(id: SeedID.elena, name: "Elena", role: .dolphin, location: "", bio: "Sunset lover", followers: 0, following: 0, avatarAssetName: "w1"),
            Rider(id: SeedID.benetti, name: "Benetti", role: .wolf, location: "", bio: "Organizer of Milan & LA weekend rides. Let's cruise together!", followers: 0, following: 0, avatarAssetName: "m2"),
            Rider(id: SeedID.laurent, name: "Laurent", role: .flamingo, location: "", bio: "Daily commuter in Europe, weekend explorer in California.", followers: 0, following: 0, avatarAssetName: "w2"),
            Rider(id: SeedID.henrik, name: "Henrik", role: .owl, location: "", bio: "Clean builds & smooth routes. Always up for a chill ride.", followers: 0, following: 0, avatarAssetName: "m3"),
            Rider(id: SeedID.clara, name: "Clara", role: .fox, location: "", bio: "Weekend rider, coffee shop collector.", followers: 0, following: 0, avatarAssetName: "w3")
        ]
        let posts = [
            makePost(id: SeedID.postWeber, authorID: SeedID.weber, title: "Classic GTS 300 Super", route: "Black Forest Mountain Pass", distance: "58 mi", body: "Finally adjusted the exhaust and shocks on my Vespa GTS 300! Ready for the coastal twisties this weekend.", specs: ["EXHAUST": "Sport Slip-On Line", "SUSPENSION": "Racing Gas Shocks", "SEAT": "Custom Leather Diamond Stitch", "WHEELS": "12\" Lightweight Forged Alloy Rims", "ECU": "Stage 1 Fuel & Timing Performance Module"], media: .image, mediaIdentifier: "m01", commentAuthorID: SeedID.elena, comment: "Top tier vibes!"),
            makePost(id: SeedID.postElena, authorID: SeedID.elena, title: "Italian Retro 150 Touring", route: "Malibu Coast Line", distance: "42 mi", body: "Found the quietest lookout spot on the Malibu Coast Line. Golden hour hit just right today!", specs: ["EXHAUST": "Dual-Tip Carbon Performance Exhaust", "SUSPENSION": "Sport Lowering Suspension Kit", "SEAT": "Genuine Italian Tan Leather Saddle", "WHEELS": "12\" Polished Chrome Classic Wheels", "LIGHTING": "Vintage Chrome Bezel LED Headlight"], media: .image, mediaIdentifier: "w01", commentAuthorID: SeedID.benetti, comment: "Enjoy the ride!"),
            makePost(id: SeedID.postBenetti, authorID: SeedID.benetti, title: "Sprint 150 Sport Edition", route: "Santa Monica Pier & Coastal Loop", distance: "32 mi", body: "Sunday Sunset Cruise is officially live! Meeting up at Santa Monica Pier this weekend. Who’s joining?", specs: ["EXHAUST": "Full-System Race Exhaust", "SUSPENSION": "Twin Gas Shock Absorbers", "SEAT": "Low-Profile Sport Gel Seat", "WHEELS": "12\" Ultra-Lightweight Racing Rims", "ECU": "Race Mapping ECU Control Unit", "LIGHTING": "Daymaker Projector LED Front Light"], media: .image, mediaIdentifier: "m02"),
            makePost(id: SeedID.postLaurent, authorID: SeedID.laurent, title: "Lambretta V125 Special", route: "Paris Left Bank Heritage Tour", distance: "18 mi", body: "Handlebar wraps are finally complete. Took three hours of continuous effort, but totally worth it.", specs: ["EXHAUST": "Urban Dark Stainless Steel Exhaust", "SUSPENSION": "Hydraulic Touring Suspension", "SEAT": "Hand-Stitched Vintage Suede Leather Seat", "WHEELS": "Classic Chrome Spoke-Style Alloys", "ECU": "Standard Factory ECU", "LIGHTING": "Retrofit Amber Lens LED Lighting"], media: .image, mediaIdentifier: "w02", commentAuthorID: SeedID.henrik, comment: "Worth every minute!"),
            makePost(id: SeedID.postHenrik, authorID: SeedID.henrik, title: "GTS 300 Tech Custom", route: "Nordic Hillside Twisties", distance: "75 mi", body: "Enjoy summer sunsets.", specs: ["EXHAUST": "Titanium Full System with Carbon Cap", "SUSPENSION": "Fully Adjustable Performance Rear Shocks", "SEAT": "Ergo-Comfort Touring Seat (Satin Black)", "WHEELS": "13\" Matte Black Custom Alloys", "ECU": "Rapid Plug-and-Play ECU Optimizer", "LIGHTING": "Dual Auxiliary Strobe LED Trail Lights"], media: .video, mediaIdentifier: "2afb3ca309971fd830ecb97fd37d6086.mp4", commentAuthorID: SeedID.clara, comment: "Awesome spot!"),
            makePost(id: SeedID.postClara, authorID: SeedID.clara, title: "Peugeot Django 150", route: "Vienna Woods & City Cafe Run", distance: "25 mi", body: "Quick stop for an iced latte before joining the afternoon cruise with the local squad.", specs: ["EXHAUST": "High-Flow Urban Performance Pipe", "SUSPENSION": "Gas-Charged Sport Front Shocks", "SEAT": "Touring Seat with Integrated Passenger Backrest", "WHEELS": "12\" Satin Black Multi-Spoke Rims", "ECU": "Factory Tuned ECU", "LIGHTING": "Clear Lens HD Daytime Running Lights"], media: .image, mediaIdentifier: "w04")
        ]
        let meets = [
            LocalMeet(id: SeedID.meetCoastal, hostID: SeedID.benetti, title: "Sunday Sunset Coastal Cruise", location: "Santa Monica Pier, Los Angeles, CA", distance: "Malibu Coast Line · 28 mi", date: date(2026, 8, 16, 17, 0), attendees: 1, capacity: 12, joined: false, attendeeIDs: [SeedID.weber], coverAssetName: "l1"),
            LocalMeet(id: SeedID.meetBerlin, hostID: SeedID.clara, title: "Midnight Neon & Espresso Tour", location: "Alexanderplatz, 10178 Berlin, Germany", distance: "Berlin City Center & Spree Loop · 18 mi", date: date(2026, 8, 21, 21, 30), attendees: 1, capacity: 12, joined: false, attendeeIDs: [SeedID.laurent], coverAssetName: "l2")
        ]
        return VixiaDataSnapshot(schemaVersion: currentSchemaVersion, riders: riders, posts: posts, meets: meets, conversations: [], relationships: [], postLikes: [])
    }

    private static func makePost(id: UUID, authorID: UUID, title: String, route: String, distance: String, body: String, specs: [String: String], media: LocalMediaReference.Kind, mediaIdentifier: String, commentAuthorID: UUID? = nil, comment: String? = nil) -> WavePost {
        let comments: [WaveComment]
        if let commentAuthorID, let comment {
            comments = [WaveComment(id: UUID(), authorID: commentAuthorID, text: comment, date: date(2026, 8, 2, 12, 0))]
        } else {
            comments = []
        }
        return WavePost(id: id, authorID: authorID, title: title, route: route, distance: distance, body: body, specs: specs, unlockPrice: 300, likes: 0, comments: comments, isLiked: false, media: [LocalMediaReference(id: UUID(), kind: media, localIdentifier: mediaIdentifier)], routeNodes: [])
    }

    private static func migrateReplacingLegacySeed(_ saved: VixiaDataSnapshot) -> VixiaDataSnapshot {
        var migrated = seedSnapshot(existingConversations: [])
        let preservedRiders = saved.riders.filter { !SeedID.legacyUserIDs.contains($0.id) }
        let preservedUserIDs = Set(preservedRiders.map(\.id))
        let preservedPosts = saved.posts.filter { preservedUserIDs.contains($0.authorID) }
        let preservedPostIDs = Set(preservedPosts.map(\.id))
        migrated.riders.append(contentsOf: preservedRiders)
        migrated.posts.insert(contentsOf: preservedPosts, at: 0)
        migrated.meets.append(contentsOf: saved.meets.filter { preservedUserIDs.contains($0.hostID) })
        migrated.conversations = saved.conversations.filter { conversation in
            preservedUserIDs.contains(conversation.peerID) && conversation.ownerID.map(preservedUserIDs.contains) == true
        }
        migrated.relationships.formUnion(saved.relationships.filter { preservedUserIDs.contains($0.followerID) && preservedUserIDs.contains($0.followedID) })
        migrated.postLikes.formUnion(saved.postLikes.filter { preservedUserIDs.contains($0.userID) && preservedPostIDs.contains($0.postID) })
        migrated.schemaVersion = currentSchemaVersion
        return migrated
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
