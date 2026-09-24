import HotwireNative
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var navigationContainer: AppNavigationContainer?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let entries = AppNavigation.make(rootURL: AppConfiguration.rootURL)
        let navigationContainer = AppNavigationContainer(
            entries: entries,
            navigatorDelegate: self
        )

        let window = UIWindow(windowScene: windowScene)
        AppAppearance.apply(GeneratedApplication.appearance, to: window)
        window.rootViewController = navigationContainer.rootViewController
        window.makeKeyAndVisible()
        self.window = window
        self.navigationContainer = navigationContainer

        navigationContainer.start()
    }
}

extension SceneDelegate: NavigatorDelegate {}
