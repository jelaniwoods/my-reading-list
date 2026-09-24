import Foundation
import Testing

@testable import FoundationApp

struct CodespacesPreviewTests {
    private let root = URL(string: "https://sample-space-3000.app.github.dev")!
    private let header = "X-Tunnel-Skip-AntiPhishing-Page"

    @Test
    func acceptsOnlyRequestsToTheConfiguredCodespacesOrigin() {
        let request = URLRequest(url: root.appendingPathComponent("movies"))
        let result = CodespacesPreview.request(request, rootURL: root)
        #expect(result.value(forHTTPHeaderField: header) == "true")
        #expect(result.url == request.url)

        for value in [
            "https://another-space-3000.app.github.dev/movies",
            "https://sample-space-3000.app.github.dev.example.com/movies",
            "https://sample-space-3000.app.github.dev:8443/movies",
            "http://sample-space-3000.app.github.dev/movies",
            "https://user:password@sample-space-3000.app.github.dev/movies",
        ] {
            let other = URLRequest(url: URL(string: value)!)
            #expect(CodespacesPreview.request(other, rootURL: root) == other)
        }
    }

    @Test
    func leavesOtherPreviewProvidersUnchanged() {
        let url = URL(string: "https://preview.example.com")!
        let request = URLRequest(url: url)
        #expect(CodespacesPreview.request(request, rootURL: url) == request)
    }
}
