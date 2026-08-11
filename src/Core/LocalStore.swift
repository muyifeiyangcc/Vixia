import Foundation

extension Notification.Name {
    /// The single invalidation signal consumed by lists, details, profile and chat.
    static let vixiaRepositoryDidChange = Notification.Name("vixia.repository.didChange")
}

enum VixiaRepositoryChange: String {
    case session
    case profile
    case posts
    case meets
    case relationships
    case conversations
    case blacklist
    case reports
    case balance
    case unlocks
    case accountDeleted
    case all
}

enum VixiaRepositoryNotificationKey {
    static let change = "change"
    static let entityID = "entityID"
}

final class LocalStore {
    static let shared = LocalStore()

    private enum Key {
        static let eulaAccepted = "vixia.device.eulaAccepted"
        static let session = "vixia.account.session"
        static let explicitlySignedOut = "vixia.account.explicitlySignedOut"
        static let blocked = "vixia.account.blocked"
        static let reports = "vixia.account.reports"
        static let unlocked = "vixia.account.unlocked"
        static let balance = "vixia.account.balance"
        static let conversations = "vixia.account.conversations"
        static let dataSnapshot = "vixia.repository.snapshot.v1"
    }

    struct AccountState {
        var signedInUserID: UUID?
        var blockedUserIDs: Set<UUID>
        var reports: [ReportRecord]
        var unlockedPostIDs: Set<UUID>
        var diamondBalance: Int
        var conversations: [Conversation]
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSRecursiveLock()

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var hasAcceptedEULA: Bool { locked { defaults.bool(forKey: Key.eulaAccepted) } }
    func acceptEULA() { locked { defaults.set(true, forKey: Key.eulaAccepted) } }

    var signedInUserID: UUID? {
        get { locked { defaults.string(forKey: Key.session).flatMap(UUID.init(uuidString:)) } }
        set {
            locked {
                if let newValue {
                    defaults.set(newValue.uuidString, forKey: Key.session)
                    defaults.removeObject(forKey: Key.explicitlySignedOut)
                } else {
                    defaults.removeObject(forKey: Key.session)
                    defaults.set(true, forKey: Key.explicitlySignedOut)
                }
            }
            postChange(.session, entityID: newValue)
        }
    }

    var hasExplicitlySignedOut: Bool {
        locked { defaults.bool(forKey: Key.explicitlySignedOut) }
    }

    var blockedUserIDs: Set<UUID> {
        get { locked { decode(Set<UUID>.self, key: Key.blocked) ?? [] } }
        set {
            locked { encode(newValue, key: Key.blocked) }
            postChange(.blacklist)
        }
    }

    var reports: [ReportRecord] {
        get { locked { decode([ReportRecord].self, key: Key.reports) ?? [] } }
        set {
            locked { encode(newValue, key: Key.reports) }
            postChange(.reports)
        }
    }

    var unlockedPostIDs: Set<UUID> {
        get { locked { decode(Set<UUID>.self, key: Key.unlocked) ?? [] } }
        set {
            locked { encode(newValue, key: Key.unlocked) }
            postChange(.unlocks)
        }
    }

    var diamondBalance: Int {
        get { locked { defaults.object(forKey: Key.balance) == nil ? 0 : defaults.integer(forKey: Key.balance) } }
        set {
            locked { defaults.set(max(0, newValue), forKey: Key.balance) }
            postChange(.balance)
        }
    }

    var conversations: [Conversation] {
        get { locked { decode([Conversation].self, key: Key.conversations) ?? [] } }
        set {
            locked { encode(newValue, key: Key.conversations) }
            postChange(.conversations)
        }
    }

    var dataSnapshot: VixiaDataSnapshot? {
        get { locked { decode(VixiaDataSnapshot.self, key: Key.dataSnapshot) } }
        set {
            locked {
                if let newValue { encode(newValue, key: Key.dataSnapshot) }
                else { defaults.removeObject(forKey: Key.dataSnapshot) }
            }
        }
    }

    func block(_ userID: UUID) {
        var value = blockedUserIDs
        guard value.insert(userID).inserted else { return }
        locked { encode(value, key: Key.blocked) }
        postChange(.blacklist, entityID: userID)
        NotificationCenter.default.post(name: .socialUserDidBlock, object: nil, userInfo: [SocialNotificationKey.userID: userID.uuidString])
    }

    func unblock(_ userID: UUID) {
        var value = blockedUserIDs
        guard value.remove(userID) != nil else { return }
        locked { encode(value, key: Key.blocked) }
        postChange(.blacklist, entityID: userID)
    }

    /// Reporting is deliberately independent from blocking and never reads or
    /// mutates the blacklist. This invariant is intentionally enforced here.
    @discardableResult
    func report(targetUserID: UUID, sourceID: UUID?, reason: String) -> ReportRecord {
        let record = ReportRecord(
            id: UUID(),
            targetUserID: targetUserID,
            sourceID: sourceID,
            reason: reason,
            createdAt: Date()
        )
        var value = reports
        value.append(record)
        locked { encode(value, key: Key.reports) }
        postChange(.reports, entityID: record.id)
        return record
    }

    func signOut() { signedInUserID = nil }

    /// Compatibility entry point for existing settings UI. The repository owns
    /// the complete transaction so content, relations, credentials and messages
    /// cannot be left partially deleted.
    func deleteAccountData() {
        clearAccountState()
    }

    func accountState() -> AccountState {
        AccountState(
            signedInUserID: signedInUserID,
            blockedUserIDs: blockedUserIDs,
            reports: reports,
            unlockedPostIDs: unlockedPostIDs,
            diamondBalance: diamondBalance,
            conversations: conversations
        )
    }

    func restoreAccountState(_ state: AccountState, notify: Bool = true) {
        locked {
            if let userID = state.signedInUserID {
                defaults.set(userID.uuidString, forKey: Key.session)
                defaults.removeObject(forKey: Key.explicitlySignedOut)
            } else {
                defaults.removeObject(forKey: Key.session)
                defaults.set(true, forKey: Key.explicitlySignedOut)
            }
            encode(state.blockedUserIDs, key: Key.blocked)
            encode(state.reports, key: Key.reports)
            encode(state.unlockedPostIDs, key: Key.unlocked)
            defaults.set(max(0, state.diamondBalance), forKey: Key.balance)
            encode(state.conversations, key: Key.conversations)
        }
        if notify { postChange(.all) }
    }

    func clearAccountState(notify: Bool = true) {
        locked {
            [Key.session, Key.blocked, Key.reports, Key.unlocked, Key.balance, Key.conversations]
                .forEach(defaults.removeObject(forKey:))
            defaults.set(true, forKey: Key.explicitlySignedOut)
        }
        // Device-scoped EULA acceptance intentionally survives deletion.
        if notify { postChange(.accountDeleted) }
    }

    func postChange(_ change: VixiaRepositoryChange, entityID: UUID? = nil) {
        var userInfo: [AnyHashable: Any] = [VixiaRepositoryNotificationKey.change: change.rawValue]
        if let entityID { userInfo[VixiaRepositoryNotificationKey.entityID] = entityID }
        let post = {
            NotificationCenter.default.post(name: .vixiaRepositoryDidChange, object: nil, userInfo: userInfo)
        }
        if Thread.isMainThread { post() } else { DispatchQueue.main.async(execute: post) }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? decoder.decode(type, from: $0) }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
