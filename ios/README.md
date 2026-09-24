# Foundation iOS Core

Foundation iOS Core is the schema-independent Hotwire Native shell used by First Draft's Compiler. The Compiler
combines an exact Core revision with generated application identity, colors, navigation, path configuration, and
selected native capabilities.

After handoff, the result is an ordinary Xcode project whose owner may edit every file. The Rails application
remains the source of web screens and URLs.

[FOUNDATION.md](FOUNDATION.md) owns the immutable Core surface, provenance, replacement seams, and evidence
boundary. Product and Compiler decisions live in
[firstdraft/firstdraft](https://github.com/firstdraft/firstdraft).

## What Core provides

- a Hotwire Native session and navigator;
- native title and modal presentation handling;
- safe-area-correct single-navigation and tab-bar shells;
- automatic, light, and dark appearance support;
- a shared Debug loopback path for local Rails development;
- HTTPS-only compiled Release roots;
- generated navigation and application-definition seams; and
- unit and UI test targets for the generic shell and generated application definition.

The composed Rails layout remains a separate application-level smoke boundary described in
[FOUNDATION.md](FOUNDATION.md#evidence-boundary).

## Compiler replacement seams

The Compiler replaces these paths without rewriting the Xcode project:

- Generated/Application.xcconfig
- FoundationApp/Generated/ApplicationDefinition.swift
- FoundationApp/Generated/ios_v1.json
- FoundationApp/Assets.xcassets/AccentColor.colorset/Contents.json
- FoundationApp/Assets.xcassets/FoundationBackground.colorset/Contents.json
- FoundationAppTests/Generated/ApplicationDefinitionTests.swift
- FoundationAppUITests/Generated/ApplicationNavigationUITests.swift

The generated xcconfig records the captured Foundation Plan SHA-256. This standalone Core fixture uses the
documented core-fixture sentinel. Core-owned tests exercise the generic shell with explicit inputs; replaceable
tests exercise the emitted application's navigation and configuration.

GeneratedApplication.appearance selects automatic, light, or dark mode. Fixed modes also set
INFOPLIST_KEY_UIUserInterfaceStyle; automatic mode omits it. Generated color assets feed the native window, Hotwire
web views, and launch storyboard.

## Repository map

| Path | Responsibility |
|---|---|
| FoundationApp/ | Native runtime, generated seams, and assets |
| Generated/ | Standalone Core fixture inputs |
| FoundationAppTests/ | Configuration, navigation-shape, safe-area layout, title-tracking, and generated-definition unit proof |
| FoundationAppUITests/ | Simulator launch and generated tab-bar-shape proof |
| FoundationApp.xcodeproj/ | Shared schemes and build configuration |
| bin/ios | Doctor, lint, build, and test entrypoint |
| FOUNDATION.md | Ownership, provenance, and composition contract |

Agents and contributors should read [AGENTS.md](AGENTS.md) before changing the shell.

## Local verification

Development requires macOS and Xcode 26.6, the version selected by CI. `bin/ios doctor` reports the selected
toolchain.

~~~sh
bin/ios doctor
bin/ios lint
bin/ios build
bin/ios test
~~~

build produces an unsigned Release build for a generic iOS device. test runs unit and UI targets sequentially on
separate simulators so launches cannot race. Its defaults are iPhone 17 Pro for unit tests and iPhone 17 Pro Max for
UI tests. Set IOS_UNIT_TEST_DESTINATION and IOS_UI_TEST_DESTINATION to select other installed iPhone simulators.

## Work with a compiled Rails app

1. Run bin/dev from the generated Rails repository.
2. Open ios/FoundationApp.xcodeproj.
3. Select an installed iPhone Simulator.
4. Run the FoundationApp scheme.

The shared FoundationApp scheme's Run action sets APP_ROOT_URL=http://localhost:3000 for Debug, so ordinary local
development needs no scheme edit or launch argument. Debug accepts another HTTPS or HTTP-loopback root. Any other
value is ignored, logged in Debug, and falls back to the compiled origin. The scheme's Profile action uses Release
and does not inherit the Run action's launch environment. If local development opens the compiled origin, run
`bin/ios doctor`; it checks the shared scheme.

For a Debug preview pointed at a public Codespaces port, the web view sends
`X-Tunnel-Skip-AntiPhishing-Page: true` only to that configured HTTPS origin. The
[documented header](https://learn.microsoft.com/en-us/azure/developer/dev-tunnels/security#anti-phishing-protection)
skips the tunnel's HTML warning, which is not a Turbo page. The tunnel's access
controls still apply: Revyl needs a public preview port. Release requests remain
unchanged. This supports browser-hosted Simulator previews without embedding a
GitHub credential in the app.

## Versioning and downstream use

The Compiler copies a Core snapshot and replaces the seams above. Pin selection, verification, and promotion are
owned by First Draft's
[Foundation composition documentation](https://github.com/firstdraft/firstdraft/blob/main/docs/architecture/design/foundation.md).

Fix an urgent defect in an emitted application immediately. Carry reusable fixes back here for future Compilations;
there is no update channel that rewrites applications after handoff.

Released under the [MIT License](LICENSE).
