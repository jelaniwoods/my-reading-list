import Foundation

enum AppConfiguration {
    static let allowsPreviewRootOverride: Bool = {
        #if DEBUG
            true
        #else
            false
        #endif
    }()

    static let productionRootURL: URL = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "RailsOrigin") as? String,
            let url = productionRootURL(from: value)
        else {
            preconditionFailure("RailsOrigin must be an HTTPS host root")
        }

        return url
    }()

    static var rootURL: URL {
        rootURL(
            productionRootURL: productionRootURL,
            environment: ProcessInfo.processInfo.environment,
            arguments: ProcessInfo.processInfo.arguments
        )
    }

    static func rootURL(
        productionRootURL: URL,
        environment: [String: String],
        arguments: [String] = [],
        allowsOverride: Bool = allowsPreviewRootOverride
    ) -> URL {
        guard allowsOverride else {
            return productionRootURL
        }

        let rawValue = environment["APP_ROOT_URL"] ?? launchArgumentValue(named: "APP_ROOT_URL", in: arguments)

        guard let rawValue else {
            return productionRootURL
        }

        guard let url = previewRootURL(from: rawValue) else {
            #if DEBUG
                print("Ignoring APP_ROOT_URL; expected an HTTPS host root or HTTP loopback root.")
            #endif
            return productionRootURL
        }

        return url
    }

    static var remotePathConfigurationURL: URL {
        remotePathConfigurationURL(rootURL: rootURL)
    }

    static func remotePathConfigurationURL(rootURL: URL) -> URL {
        rootURL
            .appendingPathComponent("configurations")
            .appendingPathComponent("ios_v1.json")
    }

    static var userAgentPrefix: String {
        guard
            let displayName = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleDisplayName"
            ) as? String,
            let version = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
        else {
            preconditionFailure("The app display name and version must be configured")
        }

        return userAgentPrefix(displayName: displayName, version: version)
    }

    static func userAgentPrefix(displayName: String, version: String) -> String {
        "\(displayName.replacingOccurrences(of: " ", with: ""))/\(version);"
    }

    static func productionRootURL(from rawValue: String) -> URL? {
        rootURL(from: rawValue, allowsLoopbackHTTP: false)
    }

    static func previewRootURL(from rawValue: String) -> URL? {
        rootURL(from: rawValue, allowsLoopbackHTTP: true)
    }

    private static func rootURL(
        from rawValue: String,
        allowsLoopbackHTTP: Bool
    ) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, var components = URLComponents(string: value) else {
            return nil
        }

        guard
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil,
            let scheme = components.scheme?.lowercased(),
            let host = components.host?.lowercased(),
            components.path.isEmpty || components.path == "/"
        else {
            return nil
        }

        let normalizedHost =
            if host.hasPrefix("[") && host.hasSuffix("]") {
                String(host.dropFirst().dropLast())
            } else {
                host
            }

        switch scheme {
        case "https":
            break
        case "http" where allowsLoopbackHTTP && ["localhost", "127.0.0.1", "::1"].contains(normalizedHost):
            break
        default:
            return nil
        }

        components.path = ""
        return components.url
    }

    private static func launchArgumentValue(
        named name: String,
        in arguments: [String]
    ) -> String? {
        guard let index = arguments.firstIndex(of: "-\(name)") else {
            return nil
        }

        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        return arguments[valueIndex]
    }
}
