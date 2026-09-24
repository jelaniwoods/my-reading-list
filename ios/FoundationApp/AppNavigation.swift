import Foundation
import HotwireNative
import UIKit

struct AppNavigationDefinition: Equatable {
    let id: String
    let title: String
    let systemImageName: String
    let selectedSystemImageName: String
    let path: String
}

enum AppNavigation {
    static func make(rootURL: URL) -> [HotwireTab] {
        make(
            definitions: GeneratedApplication.navigation,
            rootURL: rootURL
        )
    }

    static func make(
        definitions: [AppNavigationDefinition],
        rootURL: URL
    ) -> [HotwireTab] {
        definitions.map { definition in
            HotwireTab(
                id: definition.id,
                title: definition.title,
                image: UIImage(systemName: definition.systemImageName),
                selectedImage: UIImage(
                    systemName: definition.selectedSystemImageName
                ),
                url: url(for: definition.path, relativeTo: rootURL)
            )
        }
    }

    private static func url(for path: String, relativeTo rootURL: URL) -> URL {
        if path == "/" {
            return rootURL
        }

        precondition(
            path.hasPrefix("/"),
            "A generated navigation path must start with /"
        )
        return rootURL.appendingPathComponent(String(path.dropFirst()))
    }
}

final class AppNavigationContainer {
    let rootViewController: UIViewController

    private enum Mode {
        case navigator(Navigator)
        case tabs(HotwireTabBarController, [HotwireTab])

        var rootViewController: UIViewController {
            switch self {
            case .navigator(let navigator):
                navigator.rootViewController
            case .tabs(let tabBarController, _):
                tabBarController
            }
        }

        func start() {
            switch self {
            case .navigator(let navigator):
                navigator.start()
            case .tabs(let tabBarController, let entries):
                tabBarController.load(entries)

                // Hotwire 1.3's lazy selection callbacks do not start UIKit's More destinations.
                if entries.count > 5 {
                    for entry in entries.dropFirst(4) {
                        tabBarController.navigator(for: entry)?.start()
                    }
                }
            }
        }
    }

    private let mode: Mode
    private let legacyMoreSelectionDelegate: LegacyMoreSelectionDelegate?

    init(
        entries: [HotwireTab],
        navigatorDelegate: NavigatorDelegate? = nil
    ) {
        precondition(
            !entries.isEmpty,
            "The generated application must define a navigation entry"
        )

        let mode: Mode
        let legacyMoreSelectionDelegate: LegacyMoreSelectionDelegate?

        if entries.count == 1 {
            let entry = entries[0]
            let navigator = Navigator(
                configuration: .init(
                    name: entry.id,
                    startLocation: entry.url
                ),
                delegate: navigatorDelegate
            )

            mode = .navigator(navigator)
            legacyMoreSelectionDelegate = nil
        } else {
            let tabBarController = HotwireTabBarController(
                navigatorDelegate: navigatorDelegate,
                lazyLoadTabs: true
            )

            if #unavailable(iOS 18.0), entries.count > 5 {
                let selectionDelegate = LegacyMoreSelectionDelegate(hotwire: tabBarController)
                tabBarController.delegate = selectionDelegate
                legacyMoreSelectionDelegate = selectionDelegate
            } else {
                legacyMoreSelectionDelegate = nil
            }
            mode = .tabs(tabBarController, entries)
        }

        self.mode = mode
        self.legacyMoreSelectionDelegate = legacyMoreSelectionDelegate
        rootViewController = mode.rootViewController
    }

    func start() {
        mode.start()
    }
}

@MainActor
final class LegacyMoreSelectionDelegate: NSObject, UITabBarControllerDelegate {
    private let hotwire: HotwireTabBarController

    init(hotwire: HotwireTabBarController) {
        self.hotwire = hotwire
        super.init()
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        // UIKit's legacy More container has no Hotwire navigator; its selectedIndex is NSNotFound.
        guard viewController !== tabBarController.moreNavigationController else { return }
        hotwire.tabBarController(tabBarController, didSelect: viewController)
    }
}
