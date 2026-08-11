import Foundation

struct LocalAccountRecord: Codable, Hashable {
    let userID: UUID
    let email: String
    var password: String
}

enum BundledTestAccount {
    static let userID = UUID(uuidString: "90000000-0000-0000-0000-000000000001")!
    static let email = "123@gmail.com"
    static let password = "12345678"
}

final class LocalAccountStore {
    static let shared = LocalAccountStore()

    struct Snapshot {
        let records: [LocalAccountRecord]
        let currentEmail: String?
    }

    private enum Key {
        static let accounts = "vixia.local.accounts.v2"
        static let legacyAccounts = "vixia.local.accounts"
        static let currentEmail = "vixia.local.currentAccountEmail"
        static let bundledTestAccountSeeded = "vixia.local.bundledTestAccountSeeded.v1"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSRecursiveLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        seedBundledTestAccountIfNeeded()
    }

    private var records: [LocalAccountRecord] {
        get {
            locked {
                if let data = defaults.data(forKey: Key.accounts),
                   let decoded = try? decoder.decode([LocalAccountRecord].self, from: data) {
                    return decoded
                }
                return migratedLegacyRecords()
            }
        }
        set {
            locked {
                guard let data = try? encoder.encode(newValue) else { return }
                defaults.set(data, forKey: Key.accounts)
            }
        }
    }

    private(set) var currentEmail: String? {
        get { locked { defaults.string(forKey: Key.currentEmail) } }
        set { locked { defaults.set(newValue, forKey: Key.currentEmail) } }
    }

    func validationMessage(for credentials: AuthCredentials) -> String? {
        let email = normalize(credentials.email)
        guard let account = records.first(where: { $0.email == email }), account.password == credentials.password else {
            return "The email or password is incorrect."
        }
        currentEmail = email
        return nil
    }

    func registrationMessage(for draft: AuthRegistrationDraft) -> String? {
        records.contains(where: { $0.email == normalize(draft.email) })
            ? "This account already exists. Sign in or reset its password."
            : nil
    }

    @discardableResult
    func register(_ draft: AuthRegistrationDraft) -> UUID {
        let email = normalize(draft.email)
        if let existing = records.first(where: { $0.email == email }) {
            currentEmail = email
            return existing.userID
        }
        var value = records
        let userID = UUID()
        value.append(LocalAccountRecord(userID: userID, email: email, password: draft.password))
        records = value
        currentEmail = email
        return userID
    }

    func reset(email: String, password: String) -> String? {
        let normalized = normalize(email)
        var value = records
        guard let index = value.firstIndex(where: { $0.email == normalized }) else {
            return "No account matches this email."
        }
        value[index].password = password
        records = value
        return nil
    }

    func existsMessage(email: String) -> String? {
        records.contains(where: { $0.email == normalize(email) })
            ? nil
            : "No account matches this email."
    }

    func userID(forEmail email: String) -> UUID? {
        records.first(where: { $0.email == normalize(email) })?.userID
    }

    func email(forUserID userID: UUID) -> String? {
        records.first(where: { $0.userID == userID })?.email
    }

    func snapshot() -> Snapshot { Snapshot(records: records, currentEmail: currentEmail) }

    func restore(_ snapshot: Snapshot) {
        records = snapshot.records
        currentEmail = snapshot.currentEmail
    }

    @discardableResult
    func deleteAccount(userID: UUID) -> Bool {
        var value = records
        guard let index = value.firstIndex(where: { $0.userID == userID }) else { return false }
        let removedEmail = value[index].email
        value.remove(at: index)
        records = value
        if currentEmail == removedEmail { currentEmail = nil }
        return true
    }

    func clearCurrentSelection() { currentEmail = nil }

    private func seedBundledTestAccountIfNeeded() {
        guard !defaults.bool(forKey: Key.bundledTestAccountSeeded) else { return }
        var value = records
        if !value.contains(where: { $0.email == BundledTestAccount.email }) {
            value.append(LocalAccountRecord(
                userID: BundledTestAccount.userID,
                email: BundledTestAccount.email,
                password: BundledTestAccount.password
            ))
            records = value
        }
        // This marker deliberately survives account deletion. Therefore the
        // bundled account is never silently recreated after the user deletes it.
        defaults.set(true, forKey: Key.bundledTestAccountSeeded)
    }

    private func migratedLegacyRecords() -> [LocalAccountRecord] {
        let fallbackID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let legacy = (defaults.dictionary(forKey: Key.legacyAccounts) as? [String: String])
            ?? ["rider@vixia.local": "vixia123"]
        let migrated = legacy.sorted(by: { $0.key < $1.key }).map { email, password in
            LocalAccountRecord(
                userID: normalize(email) == "rider@vixia.local" ? fallbackID : UUID(),
                email: normalize(email),
                password: password
            )
        }
        if let data = try? encoder.encode(migrated) { defaults.set(data, forKey: Key.accounts) }
        return migrated
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
