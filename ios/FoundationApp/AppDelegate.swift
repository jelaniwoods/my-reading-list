import HotwireNative
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAppearance()
        configureHotwire()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    private func configureAppearance() {
        UINavigationBar.appearance().scrollEdgeAppearance = .init()
        UITabBar.appearance().scrollEdgeAppearance = .init()

        let backgroundColor = AppAppearance.resolvedBackgroundColor
        Hotwire.config.defaultViewController = { url in
            AppWebViewController(
                url: url,
                backgroundColor: backgroundColor
            )
        }
        Hotwire.config.makeCustomWebView = { configuration in
            AppAppearance.makeWebView(
                configuration: configuration,
                backgroundColor: backgroundColor
            )
        }
    }

    private func configureHotwire() {
        guard
            let bundledConfigurationURL = Bundle.main.url(
                forResource: "ios_v1",
                withExtension: "json"
            )
        else {
            preconditionFailure("Generated/ios_v1.json must be bundled with the app")
        }

        Hotwire.loadPathConfiguration(from: [
            .file(bundledConfigurationURL),
            .server(AppConfiguration.remotePathConfigurationURL),
        ])

        Hotwire.config.applicationUserAgentPrefix = AppConfiguration.userAgentPrefix
        Hotwire.config.backButtonDisplayMode = .minimal
        Hotwire.config.showDoneButtonOnModals = false
        Hotwire.config.animateReplaceActions = true

        #if DEBUG
            Hotwire.config.debugLoggingEnabled = true
        #endif
    }
}
