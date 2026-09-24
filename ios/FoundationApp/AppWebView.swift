import WebKit

final class AppWebView: WKWebView {
    override func load(_ request: URLRequest) -> WKNavigation? {
        #if DEBUG
            let rootURL = AppConfiguration.rootURL
            if rootURL != AppConfiguration.productionRootURL {
                return super.load(CodespacesPreview.request(request, rootURL: rootURL))
            }
        #endif

        return super.load(request)
    }
}
