import UIKit

/// Public construction surface for the Auth feature. The app coordinator owns all
/// navigation and account persistence by handling `AuthRouteIntent` values.
public enum AuthModule {
    public static func makeEntry(routeHandler: @escaping AuthRouteHandler) -> UIViewController {
        AuthEntryViewController(routeHandler: routeHandler)
    }

    public static func makeEULA(
        persistence: AuthEULAPersisting,
        routeHandler: @escaping AuthRouteHandler
    ) -> UIViewController {
        EULAViewController(persistence: persistence, routeHandler: routeHandler)
    }

    public static func makeEmailSignIn(routeHandler: @escaping AuthRouteHandler) -> EmailSignInViewController {
        EmailSignInViewController(routeHandler: routeHandler)
    }

    public static func makeRegistration(routeHandler: @escaping AuthRouteHandler) -> RegistrationViewController {
        RegistrationViewController(routeHandler: routeHandler)
    }

    public static func makePasswordRecovery(routeHandler: @escaping AuthRouteHandler) -> PasswordRecoveryViewController {
        PasswordRecoveryViewController(routeHandler: routeHandler)
    }

    public static func makeIdentitySelection(
        draft: AuthRegistrationDraft,
        routeHandler: @escaping AuthRouteHandler
    ) -> RideIdentityViewController {
        RideIdentityViewController(draft: draft, routeHandler: routeHandler)
    }

    public static func makeProfileCompletion(
        draft: AuthRegistrationDraft,
        routeHandler: @escaping AuthRouteHandler
    ) -> ProfileCompletionViewController {
        ProfileCompletionViewController(draft: draft, routeHandler: routeHandler)
    }

    public static func makeSignInRequired(routeHandler: @escaping AuthRouteHandler) -> UIViewController {
        SignInRequiredViewController(routeHandler: routeHandler)
    }
}
