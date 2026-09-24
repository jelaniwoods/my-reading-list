import HotwireNative
import Testing
import UIKit
import WebKit

@testable import FoundationApp

@MainActor
struct AppAppearanceTests {
    private let backgroundColor = UIColor(
        red: 0.12,
        green: 0.23,
        blue: 0.34,
        alpha: 1
    )
    private let tintColor = UIColor(
        red: 0.45,
        green: 0.56,
        blue: 0.67,
        alpha: 1
    )

    @Test
    func mapsGeneratedThemesOntoWindowInterfaceStyles() {
        #expect(ApplicationAppearance(theme: .automatic).interfaceStyle == .unspecified)
        #expect(ApplicationAppearance(theme: .light).interfaceStyle == .light)
        #expect(ApplicationAppearance(theme: .dark).interfaceStyle == .dark)
    }

    @Test
    func appliesGeneratedAppearanceToTheWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))

        AppAppearance.apply(
            ApplicationAppearance(theme: .dark),
            to: window,
            tintColor: tintColor,
            backgroundColor: backgroundColor
        )

        #expect(window.overrideUserInterfaceStyle == .dark)
        #expect(window.tintColor.isEqual(tintColor))
        #expect(window.backgroundColor?.isEqual(backgroundColor) == true)
    }

    @Test
    func leavesTheSystemTintInPlaceWithoutAGeneratedAccentColor() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.tintColor = tintColor

        if Bundle.main.object(
            forInfoDictionaryKey: "FoundationPlanSHA256"
        ) as? String == "core-fixture" {
            #expect(AppAppearance.tintColor == nil)
        }

        AppAppearance.apply(
            .neutral,
            to: window,
            tintColor: nil,
            backgroundColor: backgroundColor
        )

        #expect(window.overrideUserInterfaceStyle == .unspecified)
        #expect((window.tintColor as UIColor?)?.isEqual(tintColor) == true)
    }

    @Test
    func keepsTheRuntimeThemeAlignedWithThePrelaunchStyle() {
        let prelaunchStyle =
            Bundle.main.object(
                forInfoDictionaryKey: "UIUserInterfaceStyle"
            ) as? String

        switch GeneratedApplication.appearance.theme {
        case .automatic:
            #expect(prelaunchStyle == nil)
        case .light:
            #expect(prelaunchStyle == "Light")
        case .dark:
            #expect(prelaunchStyle == "Dark")
        }
    }

    @Test
    func givesEveryHotwireWebViewTheApplicationBackground() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = AppAppearance.makeWebView(
            configuration: configuration,
            backgroundColor: backgroundColor
        )

        #expect(webView.configuration.allowsInlineMediaPlayback)
        #expect(!webView.isOpaque)
        expect(webView.backgroundColor, toMatch: backgroundColor)
        expect(webView.scrollView.backgroundColor, toMatch: backgroundColor)
        expect(webView.underPageBackgroundColor, toMatch: backgroundColor)
    }

    @Test
    func givesEveryHotwireDestinationTheApplicationBackground() {
        let controller = AppWebViewController(
            url: URL(string: "https://app.example.test")!,
            backgroundColor: backgroundColor
        )

        controller.loadViewIfNeeded()

        #expect(controller.view.backgroundColor?.isEqual(backgroundColor) == true)
        #expect(controller.visitableView.backgroundColor?.isEqual(backgroundColor) == true)
    }

    @Test
    func sharesTheGeneratedBackgroundWithTheLaunchScreen() throws {
        let assetColor = try #require(AppAppearance.backgroundColor)
        let launchController = try #require(
            UIStoryboard(name: "LaunchScreen", bundle: .main)
                .instantiateInitialViewController()
        )

        launchController.loadViewIfNeeded()
        let launchColor = try #require(launchController.view.backgroundColor)

        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            #expect(
                launchColor.resolvedColor(with: traits)
                    .isEqual(assetColor.resolvedColor(with: traits))
            )
        }
    }

    private func expect(
        _ actual: UIColor?,
        toMatch expected: UIColor
    ) {
        let actualComponents = colorComponents(actual)
        let expectedComponents = colorComponents(expected)

        for (actual, expected) in zip(actualComponents, expectedComponents) {
            #expect(abs(actual - expected) < 0.005)
        }
    }

    private func colorComponents(_ color: UIColor?) -> [CGFloat] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #expect(
            color?.getRed(
                &red,
                green: &green,
                blue: &blue,
                alpha: &alpha
            ) == true
        )

        return [red, green, blue, alpha]
    }
}
