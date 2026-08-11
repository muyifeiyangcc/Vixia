import Foundation

public enum AuthRideIdentity: String, CaseIterable, Codable {
    case dolphin = "Dolphin"
    case panther = "Panther"
    case flamingo = "Flamingo"
    case owl = "Owl"
    case wolf = "Wolf"
    case fox = "Fox"

    public var subtitle: String {
        switch self {
        case .dolphin: return "Coastal Cruise"
        case .panther: return "Performance Mods"
        case .flamingo: return "Fashion Ride"
        case .owl: return "Urban Night Ride"
        case .wolf: return "Ride Leader"
        case .fox: return "City Explorer"
        }
    }

    public var symbol: String {
        switch self {
        case .dolphin: return "🐬"
        case .panther: return "🐈‍⬛"
        case .flamingo: return "🦩"
        case .owl: return "🦉"
        case .wolf: return "🐺"
        case .fox: return "🦊"
        }
    }

    public var assetName: String {
        switch self {
        case .dolphin: return "an1"
        case .panther: return "an2"
        case .flamingo: return "an3"
        case .owl: return "an4"
        case .wolf: return "an5"
        case .fox: return "an6"
        }
    }

}

public struct AuthCredentials {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthRegistrationDraft {
    public let email: String
    public let password: String
    public var identity: AuthRideIdentity?

    public init(email: String, password: String, identity: AuthRideIdentity? = nil) {
        self.email = email
        self.password = password
        self.identity = identity
    }
}

public struct AuthProfileDraft {
    public let name: String
    public let birthday: Date
    public let gender: String
    public let avatarData: Data?

    public init(name: String, birthday: Date, gender: String, avatarData: Data?) {
        self.name = name
        self.birthday = birthday
        self.gender = gender
        self.avatarData = avatarData
    }
}

public enum AuthValidation {
    public static func isValidEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts[0].count > 0 && parts[1].contains(".")
    }

    public static func credentials(email: String, password: String) -> String? {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Please enter your email address." }
        guard isValidEmail(email) else { return "Please enter a valid email address." }
        guard !password.isEmpty else { return "Please enter your password." }
        return nil
    }

    public static func newPassword(_ password: String, confirmation: String) -> String? {
        guard password.count >= 6 else { return "Password must contain at least 6 characters." }
        guard password == confirmation else { return "The passwords do not match." }
        return nil
    }
}

public enum AuthProtectedDestination {
    case contentDetail
    case tab(Int)
}

public enum AuthGuestAccessDecision {
    case allow
    case requireSignIn
}

public enum AuthGuestAccessPolicy {
    public static func decision(for destination: AuthProtectedDestination) -> AuthGuestAccessDecision {
        switch destination {
        case .contentDetail:
            return .requireSignIn
        case .tab(let index):
            return index == 0 || index == 1 ? .allow : .requireSignIn
        }
    }
}
