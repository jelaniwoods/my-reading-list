import Foundation
import HotwireNative
import Testing
import UIKit

@testable import FoundationApp

@MainActor
struct AppConfigurationTests {
    private let productionRootURL = URL(string: "https://app.example.test")!

    @Test
    func usesTheProductionRootWithoutAnOverride() {
        #expect(
            AppConfiguration.rootURL(
                productionRootURL: productionRootURL,
                environment: [:]
            ) == productionRootURL
        )
    }

    @Test
    func givesTheEnvironmentOverridePrecedenceOverTheLaunchArgument() {
        #expect(
            AppConfiguration.rootURL(
                productionRootURL: productionRootURL,
                environment: ["APP_ROOT_URL": "https://environment.example.test"],
                arguments: [
                    "FoundationApp",
                    "-APP_ROOT_URL",
                    "https://argument.example.test",
                ],
                allowsOverride: true
            ) == URL(string: "https://environment.example.test")
        )
    }

    @Test
    func acceptsHttpsAndLoopbackPreviewRoots() {
        #expect(
            AppConfiguration.previewRootURL(
                from: " https://preview.example.test/ "
            ) == URL(string: "https://preview.example.test")
        )
        #expect(
            AppConfiguration.previewRootURL(from: "http://localhost:3000") == URL(string: "http://localhost:3000")
        )
        #expect(
            AppConfiguration.previewRootURL(from: "http://[::1]:3000") == URL(string: "http://[::1]:3000")
        )
    }

    @Test
    func rejectsUnsafeOrNonRootPreviewURLs() {
        #expect(
            AppConfiguration.previewRootURL(
                from: "http://preview.example.test"
            ) == nil
        )
        #expect(
            AppConfiguration.previewRootURL(
                from: "https://user:password@preview.example.test"
            ) == nil
        )
        #expect(
            AppConfiguration.previewRootURL(
                from: "https://preview.example.test/app"
            ) == nil
        )
        #expect(
            AppConfiguration.previewRootURL(
                from: "https://preview.example.test?debug=true"
            ) == nil
        )
    }

    @Test
    func acceptsOnlyHttpsProductionRoots() {
        #expect(
            AppConfiguration.productionRootURL(
                from: "https://app.example.test/"
            ) == productionRootURL
        )
        #expect(
            AppConfiguration.productionRootURL(
                from: "http://localhost:3000"
            ) == nil
        )
    }

    @Test
    func ignoresOverridesWhenTheyAreDisabled() {
        #expect(
            AppConfiguration.rootURL(
                productionRootURL: productionRootURL,
                environment: ["APP_ROOT_URL": "http://localhost:3000"],
                allowsOverride: false
            ) == productionRootURL
        )
    }

    @Test
    func derivesTheRemotePathConfigurationURL() {
        #expect(
            AppConfiguration.remotePathConfigurationURL(
                rootURL: productionRootURL
            )
                == URL(
                    string: "https://app.example.test/configurations/ios_v1.json"
                )
        )
    }

    @Test
    func derivesAStableApplicationUserAgentPrefix() {
        #expect(
            AppConfiguration.userAgentPrefix(
                displayName: "Example App",
                version: "2.3"
            ) == "ExampleApp/2.3;"
        )
    }
}

@MainActor
struct ApplicationShellTests {
    @Test
    func mapsNavigationDefinitionsOntoHotwireEntries() {
        let rootURL = URL(string: "https://app.example.test")!
        let definitions = [
            AppNavigationDefinition(
                id: "movies",
                title: "Movies",
                systemImageName: "film",
                selectedSystemImageName: "film.fill",
                path: "/movies"
            ),
            AppNavigationDefinition(
                id: "people",
                title: "People",
                systemImageName: "person.2",
                selectedSystemImageName: "person.2.fill",
                path: "/"
            ),
        ]
        let entries = AppNavigation.make(
            definitions: definitions,
            rootURL: rootURL
        )

        #expect(entries.map(\.id) == ["movies", "people"])
        #expect(entries.map(\.title) == ["Movies", "People"])
        #expect(
            entries.map(\.url) == [
                rootURL.appendingPathComponent("movies"),
                rootURL,
            ]
        )
        #expect(entries.allSatisfy { $0.image != nil })
        #expect(entries.allSatisfy { $0.selectedImage != nil })
    }

    @Test
    func forwardsGeneratedNavigationThroughTheGenericMapper() {
        let rootURL = URL(string: "https://app.example.test")!
        let generatedEntries = AppNavigation.make(rootURL: rootURL)
        let explicitEntries = AppNavigation.make(
            definitions: GeneratedApplication.navigation,
            rootURL: rootURL
        )

        #expect(generatedEntries.map(\.id) == explicitEntries.map(\.id))
        #expect(generatedEntries.map(\.title) == explicitEntries.map(\.title))
        #expect(generatedEntries.map(\.url) == explicitEntries.map(\.url))
    }

    @Test
    func usesAPlainNavigationStackForOneEntry() {
        let rootURL = URL(string: "https://app.example.test")!
        let entries = [
            HotwireTab(
                id: "only",
                title: "Only",
                image: UIImage(systemName: "square"),
                url: rootURL
            )
        ]
        let container = AppNavigationContainer(entries: entries)

        #expect(container.rootViewController is UINavigationController)
        #expect(!(container.rootViewController is UITabBarController))
    }

    @Test
    func usesIndependentTabStacksForMultipleEntries() {
        let rootURL = URL(string: "http://127.0.0.1:1")!
        let entries = [
            HotwireTab(
                id: "one",
                title: "One",
                image: UIImage(systemName: "1.circle"),
                url: rootURL
            ),
            HotwireTab(
                id: "two",
                title: "Two",
                image: UIImage(systemName: "2.circle"),
                url: rootURL.appendingPathComponent("two")
            ),
        ]
        let container = AppNavigationContainer(entries: entries)
        let tabBarController = container.rootViewController as? HotwireTabBarController

        container.start()

        let firstNavigator = tabBarController?.navigator(for: entries[0])
        let secondNavigator = tabBarController?.navigator(for: entries[1])

        #expect(tabBarController != nil)
        #expect(firstNavigator != nil)
        #expect(secondNavigator != nil)
        #expect(firstNavigator !== secondNavigator)
        #expect(firstNavigator?.rootViewController !== secondNavigator?.rootViewController)
    }

    @Test(arguments: [2, 5, 6, 7])
    func preparesMoreDestinationsWhileKeepingOtherDirectTabsLazy(entryCount: Int) throws {
        let entries = (0..<entryCount).map { index in
            HotwireTab(
                id: "entry-\(index)",
                title: "Entry \(index)",
                image: nil,
                url: URL(string: "http://127.0.0.1:1/entry-\(index)")!
            )
        }
        let container = AppNavigationContainer(entries: entries)
        let tabs = try #require(container.rootViewController as? HotwireTabBarController)

        container.start()

        for (index, entry) in entries.enumerated() {
            let navigator = try #require(tabs.navigator(for: entry))
            let shouldStart = index == 0 || (entryCount > 5 && index >= 4)
            #expect(navigator.rootViewController.viewControllers.isEmpty == !shouldStart)
        }
    }

    @Test
    func ignoresLegacyMoreSelectionAndStillStartsOrdinaryTabs() throws {
        let entries = (0..<7).map { index in
            HotwireTab(
                id: "entry-\(index)",
                title: "Entry \(index)",
                image: nil,
                url: URL(string: "http://127.0.0.1:1/entry-\(index)")!
            )
        }
        let tabs = HotwireTabBarController(lazyLoadTabs: true)
        tabs.load(entries)
        // Drive the legacy callback explicitly even when UIKit uses its iOS 18+ delegate API.
        tabs.delegate = nil
        let selectionDelegate = LegacyMoreSelectionDelegate(hotwire: tabs)
        let secondNavigator = try #require(tabs.navigator(for: entries[1]))
        let thirdNavigator = try #require(tabs.navigator(for: entries[2]))
        let scene = try #require(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let window = UIWindow(windowScene: scene)
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        tabs.selectedIndex = 1
        #expect(secondNavigator.rootViewController.viewControllers.isEmpty)
        tabs.selectedViewController = tabs.moreNavigationController
        #expect(tabs.selectedViewController === tabs.moreNavigationController)
        #expect(tabs.selectedIndex == NSNotFound)
        selectionDelegate.tabBarController(tabs, didSelect: tabs.moreNavigationController)
        #expect(secondNavigator.rootViewController.viewControllers.isEmpty)

        tabs.selectedIndex = 1
        selectionDelegate.tabBarController(tabs, didSelect: secondNavigator.rootViewController)
        let destination = try #require(secondNavigator.rootViewController.viewControllers.first as? Visitable)
        #expect(destination.initialVisitableURL == entries[1].url)
        #expect(thirdNavigator.rootViewController.viewControllers.isEmpty)
    }

    @Test
    func bundlesAValidFallbackPathConfiguration() throws {
        let url = try #require(
            Bundle.main.url(forResource: "ios_v1", withExtension: "json")
        )
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let document = try #require(object as? [String: Any])
        let settings = try #require(document["settings"] as? [String: Any])
        let rules = try #require(document["rules"] as? [[String: Any]])

        #expect(settings["schema_version"] as? Int == 1)
        #expect(!rules.isEmpty)
    }

    @Test
    func bundlesFoundationPlanProvenance() throws {
        let digest = try #require(
            Bundle.main.object(
                forInfoDictionaryKey: "FoundationPlanSHA256"
            ) as? String
        )
        let digestRange = digest.range(
            of: #"^[0-9a-f]{64}$"#,
            options: .regularExpression
        )

        #expect(digest == "core-fixture" || digestRange != nil)
    }

    @Test
    func bundlesOnlyTheIPhoneDeviceFamily() {
        #expect(
            Bundle.main.object(forInfoDictionaryKey: "UIDeviceFamily")
                as? [Int] == [1]
        )
    }

    @Test
    func bundlesTheNarrowLocalNetworkingException() throws {
        let transportSecurity = try #require(
            Bundle.main.object(
                forInfoDictionaryKey: "NSAppTransportSecurity"
            ) as? [String: Any]
        )

        #expect(transportSecurity["NSAllowsLocalNetworking"] as? Bool == true)
        #expect(transportSecurity["NSAllowsArbitraryLoads"] == nil)
        #expect(transportSecurity["NSAllowsArbitraryLoadsInWebContent"] == nil)
    }

    @Test
    func bundlesHotwireNativeLicenseNotice() throws {
        let url = try #require(
            Bundle.main.url(
                forResource: "THIRD_PARTY_NOTICES",
                withExtension: "txt"
            )
        )
        let contents = try String(contentsOf: url, encoding: .utf8)

        #expect(contents.contains("Hotwire Native"))
        #expect(contents.contains("Copyright (c) 2024 Hotwire"))
        #expect(contents.contains("Permission is hereby granted"))
    }
}
