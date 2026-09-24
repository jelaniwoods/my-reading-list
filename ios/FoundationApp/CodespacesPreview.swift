import Foundation

enum CodespacesPreview {
    static func request(_ request: URLRequest, rootURL: URL) -> URLRequest {
        guard
            rootURL.scheme == "https",
            let host = rootURL.host?.lowercased(),
            host.range(of: #"^[a-z0-9-]+-[0-9]+\.app\.github\.dev$"#, options: .regularExpression) != nil,
            let url = request.url,
            url.scheme == "https",
            url.host?.lowercased() == host,
            (url.port ?? 443) == (rootURL.port ?? 443),
            url.user == nil,
            url.password == nil
        else {
            return request
        }

        var previewRequest = request
        // Codespaces' HTML warning is not a Turbo page. This skips that warning,
        // while the tunnel's public/private access control still applies.
        previewRequest.setValue("true", forHTTPHeaderField: "X-Tunnel-Skip-AntiPhishing-Page")
        return previewRequest
    }
}
