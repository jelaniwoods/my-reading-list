import HotwireNative
import UIKit
import WebKit

struct ApplicationAppearance {
    enum Theme {
        case automatic
        case light
        case dark
    }

    static let neutral = ApplicationAppearance(theme: .automatic)

    let theme: Theme

    var interfaceStyle: UIUserInterfaceStyle {
        switch theme {
        case .automatic:
            .unspecified
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum AppAppearance {
    static let accentColorAssetName = "AccentColor"
    static let backgroundColorAssetName = "FoundationBackground"

    static var tintColor: UIColor? {
        UIColor(named: accentColorAssetName)
    }

    static var backgroundColor: UIColor? {
        UIColor(named: backgroundColorAssetName)
    }

    static var resolvedBackgroundColor: UIColor {
        backgroundColor ?? .systemBackground
    }

    static func apply(
        _ appearance: ApplicationAppearance,
        to window: UIWindow,
        tintColor: UIColor? = tintColor,
        backgroundColor: UIColor = resolvedBackgroundColor
    ) {
        window.overrideUserInterfaceStyle = appearance.interfaceStyle
        window.backgroundColor = backgroundColor

        if let tintColor {
            window.tintColor = tintColor
        }
    }

    static func makeWebView(
        configuration: WKWebViewConfiguration,
        backgroundColor: UIColor = resolvedBackgroundColor
    ) -> WKWebView {
        let webView = AppWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.underPageBackgroundColor = backgroundColor

        #if DEBUG
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
        #endif

        return webView
    }
}

final class AppWebViewController: HotwireWebViewController {
    private let applicationBackgroundColor: UIColor
    private var titleObservation: NSKeyValueObservation?

    init(
        url: URL,
        backgroundColor: UIColor = AppAppearance.resolvedBackgroundColor
    ) {
        applicationBackgroundColor = backgroundColor
        super.init(url: url)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = applicationBackgroundColor
        visitableView.backgroundColor = applicationBackgroundColor

        // Keep WebKit's focus scrolling inside UIKit's visible area.
        visitableView.removeFromSuperview()
        view.addSubview(visitableView)
        NSLayoutConstraint.activate([
            visitableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visitableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visitableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            visitableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationItem.leftBarButtonItem == nil,
            presentingViewController != nil,
            navigationController?.viewControllers.first === self
        {
            let cancel = UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
            navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: cancel)
        }
    }

    override func visitableDidActivateWebView(_ webView: WKWebView) {
        super.visitableDidActivateWebView(webView)

        titleObservation = webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
            self?.navigationItem.title = webView.title
        }
    }

    override func visitableWillDeactivateWebView() {
        titleObservation?.invalidate()
        titleObservation = nil
        super.visitableWillDeactivateWebView()
    }
}
