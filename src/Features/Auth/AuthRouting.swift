import Foundation
import UIKit

public enum AuthAgreementKind {
    case privacyPolicy
    case termsOfService

    public var url: URL {
        switch self {
        case .privacyPolicy:
            return URL(string: "https://sites.google.com/view/vixia/privacy")!
        case .termsOfService:
            return URL(string: "https://sites.google.com/view/vixia/users")!
        }
    }

    public var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        }
    }
}

public enum AuthRouteIntent {
    case eulaAccepted
    case terminateApplicationRequested
    case continueAsGuest
    case openEmailSignIn
    case openRegistration
    case openPasswordRecovery
    case openAgreement(AuthAgreementKind, URL)
    case signedIn(AuthCredentials)
    case registrationCreated(AuthRegistrationDraft)
    case identitySelected(AuthRegistrationDraft)
    case profileCompleted(AuthRegistrationDraft, AuthProfileDraft)
    case passwordReset(email: String, newPassword: String)
}

public typealias AuthRouteHandler = (AuthRouteIntent, UIViewController) -> Void

public protocol AuthEULAPersisting {
    var hasAcceptedEULA: Bool { get }
    func persistEULAAcceptance(completion: @escaping (Result<Void, Error>) -> Void)
}

public enum AuthLaunchDecision {
    case presentEULA
    case continueToAuthentication
}

public enum AuthLaunchGate {
    public static func decision(using persistence: AuthEULAPersisting) -> AuthLaunchDecision {
        persistence.hasAcceptedEULA ? .continueToAuthentication : .presentEULA
    }
}

public final class UserDefaultsEULAPersistence: AuthEULAPersisting {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "vixia.device.eulaAccepted") {
        self.defaults = defaults
        self.key = key
    }

    public var hasAcceptedEULA: Bool { defaults.bool(forKey: key) }

    public func persistEULAAcceptance(completion: @escaping (Result<Void, Error>) -> Void) {
        defaults.set(true, forKey: key)
        completion(defaults.bool(forKey: key) ? .success(()) : .failure(PersistenceError.writeFailed))
    }

    private enum PersistenceError: Error { case writeFailed }
}
