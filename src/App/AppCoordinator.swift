import UIKit
import Darwin

final class AppCoordinator {
    struct BPackageNavigationContext {
        let bPackageNavigationController: UINavigationController
        let bPackageAPackageViewController: UIViewController
    }

    private let window: UIWindow
    private let store: LocalStore
    private let accounts = LocalAccountStore.shared
    private let persistence = UserDefaultsEULAPersistence()
    private var authNavigation = UINavigationController()
    var bPackageOnEULAAccepted: (() -> Void)?

    var bPackageHasAcceptedEULA: Bool { persistence.hasAcceptedEULA }

    init(window: UIWindow, store: LocalStore = .shared) { self.window = window; self.store = store }

    func start() {
        if !store.hasExplicitlySignedOut,
           store.signedInUserID != nil,
           accounts.currentEmail != nil {
            showMain(isGuest: false)
        } else {
            showLogin()
        }
        window.makeKeyAndVisible()
        if case .presentEULA = AuthLaunchGate.decision(using: persistence) {
            DispatchQueue.main.async { self.window.rootViewController?.present(AuthModule.makeEULA(persistence: self.persistence, routeHandler: self.handle), animated: true) }
        }
    }

    func showLogin() {
        let entry = AuthModule.makeEntry(routeHandler: handle)
        authNavigation = UINavigationController(rootViewController: entry); authNavigation.setNavigationBarHidden(true, animated: false)
        window.rootViewController = authNavigation
    }

    func bPackageNavigationContext() -> BPackageNavigationContext? {
        if let bPackageNavigationController = window.rootViewController as? UINavigationController,
           let bPackageRoot = bPackageNavigationController.viewControllers.first {
            return BPackageNavigationContext(
                bPackageNavigationController: bPackageNavigationController,
                bPackageAPackageViewController: bPackageRoot
            )
        }

        guard let bPackageTabs = window.rootViewController as? UITabBarController else { return nil }
        bPackageTabs.loadViewIfNeeded()
        guard let bPackageNavigationController = bPackageTabs.selectedViewController as? UINavigationController,
              let bPackageRoot = bPackageNavigationController.viewControllers.first else { return nil }
        return BPackageNavigationContext(
            bPackageNavigationController: bPackageNavigationController,
            bPackageAPackageViewController: bPackageRoot
        )
    }

    private lazy var handle: AuthRouteHandler = { [weak self] intent, source in self?.route(intent, from: source) }
    private func route(_ intent: AuthRouteIntent, from source: UIViewController) {
        switch intent {
        case .eulaAccepted:
            source.dismiss(animated: true) { [weak self] in
                self?.bPackageOnEULAAccepted?()
            }
        case .terminateApplicationRequested: Darwin.exit(EXIT_SUCCESS)
        case .continueAsGuest: showMain(isGuest: true)
        case .openEmailSignIn:
            let openEmail = { [weak self] in
                guard let self else { return }
                if self.window.rootViewController !== self.authNavigation { self.showLogin() }
                let controller = AuthModule.makeEmailSignIn(routeHandler: self.handle)
                controller.credentialValidator = self.accounts.validationMessage
                self.authNavigation.pushViewController(controller, animated: true)
            }
            if source.presentingViewController != nil { source.dismiss(animated: true, completion: openEmail) } else { openEmail() }
        case .openRegistration:
            let controller = AuthModule.makeRegistration(routeHandler: handle); controller.accountValidator = accounts.registrationMessage; authNavigation.pushViewController(controller, animated: true)
        case .openPasswordRecovery:
            let controller = AuthModule.makePasswordRecovery(routeHandler: handle); controller.accountValidator = accounts.existsMessage; authNavigation.pushViewController(controller, animated: true)
        case .openAgreement(let agreement, let url):
            authNavigation.pushViewController(PolicyWebViewController(title: agreement.title, url: url), animated: true)
        case .signedIn:
            guard let email = accounts.currentEmail, let userID = accounts.userID(forEmail: email) else { showLogin(); return }
            if MockDataRepository.shared.user(userID) == nil {
                _ = MockDataRepository.shared.upsertProfile(userID: userID, name: email.components(separatedBy: "@").first ?? "Rider", role: .dolphin, birthday: nil, gender: nil, bio: "", avatarData: nil)
                store.diamondBalance = 0
            }
            store.signedInUserID = userID
            showMain(isGuest: false)
        case .registrationCreated(let draft): accounts.register(draft); authNavigation.pushViewController(AuthModule.makeIdentitySelection(draft: draft, routeHandler: handle), animated: true)
        case .identitySelected(let draft): authNavigation.pushViewController(AuthModule.makeProfileCompletion(draft: draft, routeHandler: handle), animated: true)
        case .profileCompleted(let draft, let profile):
            guard let userID = accounts.userID(forEmail: draft.email) else { showLogin(); return }
            let role = draft.identity.flatMap { RiderRole(rawValue: $0.rawValue) } ?? .dolphin
            _ = MockDataRepository.shared.upsertProfile(userID: userID, name: profile.name, role: role, birthday: profile.birthday, gender: profile.gender, bio: "", avatarData: profile.avatarData)
            store.diamondBalance = 0
            store.signedInUserID = userID
            showMain(isGuest: false)
        case .passwordReset(let email, let password): _ = accounts.reset(email: email, password: password); authNavigation.popToRootViewController(animated: true)
        }
    }

    private func showMain(isGuest: Bool) {
        let tabs = MainTabController(isGuest: isGuest)
        tabs.onGuestRestriction = { [weak self, weak tabs] in guard let self, let tabs else { return }; let modal = AuthModule.makeSignInRequired(routeHandler: self.handle); tabs.present(modal, animated: true) }
        window.rootViewController = tabs
    }

}
