# iOS Foundation Core contract

This repository is the product-independent iOS half of a compiled First Draft
application. It is a source template, not a framework dependency: the Compiler
copies a tagged Core snapshot, replaces the generated seams below, and hands
the resulting ordinary Xcode project to its owner.

## Core and generated ownership

The Xcode project and target are always named `FoundationApp`. Keeping this
internal identity stable avoids rewriting project references for every
application. Product identity is carried by build settings and generated
source.

| Core-owned and stable | Compiler-generated replacement |
| --- | --- |
| `FoundationApp.xcodeproj` structure, targets, shared scheme, iOS floor, iPhone device family, and exact Hotwire Native package requirement | `Generated/Application.xcconfig` app display name, app and derived test bundle identifiers, Rails origin, version, canonical Foundation Plan SHA-256, and optional fixed interface style |
| `AppDelegate.swift`, `SceneDelegate.swift`, `AppConfiguration.swift`, `AppAppearance.swift`, and `AppNavigation.swift` | `FoundationApp/Generated/ApplicationDefinition.swift` appearance theme, navigation identifiers, labels, symbols, and root paths |
| Shared Debug launch action with an enabled accepted `APP_ROOT_URL`, Debug-only override handling, a Release Profile action isolated from the Run environment, and remote path-configuration URL convention | `FoundationApp/Generated/ios_v1.json` route rules |
| Unconditional, narrow local-network ATS declaration; arbitrary loads remain disabled | Rails origin and application traffic remain HTTPS in Release |
| Minimal navigation chrome defaults: transparent scroll edges, minimal back labels, modal Cancel buttons, live page titles, and animated replace actions | Later product-specific styling may replace these defaults |
| Launch storyboard and asset-catalog structure | `AccentColor` and `FoundationBackground` color-set contents |
| Unit/UI target structure, Core-owned tests, and `bin/ios` commands | `FoundationAppTests/Generated/ApplicationDefinitionTests.swift` and `FoundationAppUITests/Generated/ApplicationNavigationUITests.swift` application-specific assertions |
| `THIRD_PARTY_NOTICES.txt` and this repository's license | Additional notices required by generated capabilities |

`FOUNDATION_PLAN_SHA256` becomes the `FoundationPlanSHA256` application
metadata value. The Compiler writes the lowercase SHA-256 of the canonical
serialized captured Foundation Plan. Core's standalone fixture uses the
explicit `core-fixture` sentinel because it has no Foundation Plan input.

The generated source and test files are replaced together. Core-owned tests use
explicit navigation definitions and remain valid for every generated
navigation shape. The generated unit and UI tests prove the navigation and
configuration emitted for one application. The filesystem-synchronized test
groups keep these stable paths in their targets without project-file rewrites.
Generated UI tests set a loopback `APP_ROOT_URL` so verification never depends
on or contacts the compiled Rails origin. All generated Swift must pass Core's
strict `bin/ios lint` formatting gate.

The shared scheme's Debug launch action enables
`APP_ROOT_URL=http://localhost:3000`, so starting Rails with `bin/dev` and
running the app in a Simulator requires no generated-project edit. Debug may
replace that value with another HTTPS or HTTP-loopback root. Release builds do
not honor the process environment or launch argument and always use the
compiled HTTPS `RAILS_ORIGIN`. The Release Profile action also does not inherit
the Debug Run action's launch arguments or environment.

Each active Hotwire destination tracks the shared web view's current document
title. This keeps reused modal sessions aligned with the newly rendered page
after an earlier modal has been dismissed.

The first destination in a modal stack has UIKit's localized Cancel control.
It dismisses the sheet; the web form's Create or Update action saves. An existing
custom left item is preserved. A pushed modal destination keeps ordinary Back
navigation. Core disables Hotwire's Done
item because its iOS 26 checkmark looks like a save action while only dismissing
the sheet. This does not add draft tracking or a discard-confirmation bridge.

## Appearance replacement contract

`GeneratedApplication.appearance` supplies exactly one theme: `.automatic`,
`.light`, or `.dark`. Core applies that value to the application window. For a
fixed theme, `Generated/Application.xcconfig` must also contain exactly one of:

```text
INFOPLIST_KEY_UIUserInterfaceStyle = Light
INFOPLIST_KEY_UIUserInterfaceStyle = Dark
```

Automatic mode omits the setting. Keeping the build-time and runtime values in
agreement lets iOS resolve the launch storyboard in the fixed style before the
scene delegate exists, then preserves that style for native chrome and web
media queries after launch.

The Compiler replaces the contents of the `AccentColor` and
`FoundationBackground` color sets. Each set may carry universal and dark
variants. The launch storyboard resolves `FoundationBackground` by name. Core
also applies that color to the window, every default Hotwire destination, and
every web view made through Hotwire Native's customization hook, including a
web view recreated after process termination. The web view is nonopaque and
uses the same color for its view, scroll view, and under-page background so an
unrendered page cannot expose Hotwire Native's white default.

The standalone Core fixture represents omitted Appearance. Its theme is
automatic, its generated xcconfig omits `UIUserInterfaceStyle`, its unassigned
accent preserves UIKit's system tint, and its background color set supplies
neutral light and dark values. Runtime background lookup additionally falls
back to `systemBackground` if a hand-edited application removes the named
asset.

Capabilities such as accounts, push notifications, universal links, native
bridge components, Apple signing, and distribution are composed separately.
They are not latent or dormant in Core.

One generated navigation entry uses a plain Hotwire `Navigator` and does not
show a tab bar. Two or more entries use `HotwireTabBarController`, giving each
entry an independent navigation stack.

The first entry loads at launch; other directly visible tabs load on first
selection. With more than five entries, UIKit shows four direct tabs and a More
list. Hotwire Native 1.3.0's lazy
selection callbacks leave those overflow navigators unstarted, so Core starts
the overflow entries through the public `navigator(for:)` API after loading
the tabs. The first selected tab also starts normally; the remaining three
direct tabs stay lazy. This adds one initial request per overflow destination.
It avoids replacing UIKit's More controller or forking Hotwire. Revisit this
workaround when an upstream update passes the generated More-row and Back
interaction tests with fully lazy loading.

Below iOS 18, a retained tab-selection delegate also ignores UIKit's More
container before forwarding ordinary selections to Hotwire. UIKit reports
`NSNotFound` for that container's selected index; Hotwire 1.3.0's legacy
callback assumes a real navigator. The regression invokes that public legacy
callback on the current Simulator. The older-OS branch that installs and
retains the adapter has not been executed on an earlier iOS runtime.
Retire the adapter when the pinned upstream callback handles More itself.

## Safe-area ownership

UIKit and the pinned Hotwire Native shell own physical-screen, navigation-bar,
tab-bar, and home-indicator insets. Core anchors Hotwire's public visitable
view below the controller's top safe-area edge. Its remaining edges retain
Hotwire's full-controller bounds, and the web view's scroll view keeps
automatic content-inset adjustment. This clips WebKit's focus scrolling below
the navigation bar while preserving automatic bottom and side adjustment. At
the top and bottom scroll limits, document edges meet the native chrome in
both the single-navigator and native-tab configurations.

Hotwire 1.3.0 installs its visitable view against all four controller edges
inside a private method. Core reanchors that public view using UIKit
constraints; it does not inspect private constraints or fork the dependency.
Revisit this adaptation if Hotwire supplies an equivalent public layout hook.
The web view uses UIKit's `keyboardDismissMode = .onDrag`, so scrolling the
visible form dismisses the keyboard and exposes its save action in landscape.
Actual keyboard and form behavior requires the composed Rails interaction
smoke; the sentinel tests alone do not prove it.

The composed Rails foundation must retain its ordinary viewport behavior.
Opting into both `viewport-fit=cover` and generic
`env(safe-area-inset-*)` padding transfers safe-area ownership to the document;
combining that with the remaining automatic native insets can create
duplicate spacing, including below the last control. Ordinary viewport behavior also leaves
browser layout unchanged. An owner may later choose a deliberately edge-to-edge
design, but that replacement must take over both native and web inset behavior
together.

Core's tests load a Core-owned sentinel document into the real navigation
containers. They anchor the expected edges to the native navigation and tab
bars, proving that missing native adjustment or an extra native/web inset would
move the document away from those edges. This constrains the native shell only;
a composed smoke test must separately verify the Rails layout contract.

Core currently targets iPhone only. iPad is not yet qualified: an exploratory
iPadOS 26 run showed that the selected controller's safe area can extend beneath
the floating tab bar while `UITabBarController.contentLayoutGuide` identifies a
smaller unobscured area. Before enabling the iPad device family, adapt the shell
to that iOS 26 API, preserve the earlier-OS path, and qualify both navigation
shapes on iPad. This is a boundary of this Core release, not a limitation claim
about Hotwire Native.

After handoff, this distinction is provenance rather than protection. The
application owner may change any file, and First Draft does not regenerate
into an owner-modified repository.

## Provenance and licenses

The initial shell was extracted from
[`firstdraft/photogram-golden`](https://github.com/firstdraft/photogram-golden)
at commit `65bd0517584d0f9ae93fad59018636f1246a203d`. Photogram supplied proven
source material; its product routes, identity, accounts, push, deep links,
signing, distribution, and deployment details were deliberately excluded.

Hotwire Native is consumed as an unmodified Swift package dependency at
version `1.3.0`, revision
`65e5e21ad7c2f80182cac670d1d7b2cb40c0da47`. It is distributed under the MIT
License by Hotwire; its full notice is bundled in
`FoundationApp/THIRD_PARTY_NOTICES.txt`. This repository's original and
extracted code is distributed under the repository's MIT License.

## Evidence boundary

The local and hosted gates can prove that the committed package lock resolves,
the product-independent Swift code compiles, the app and test targets require
no signing identity, configuration contracts pass, and the generic navigation
shell launches in a simulator. On the latest iPhone Simulator OS configured by
`bin/ios`, Core unit tests also place the first and last controls of a Core-owned
sentinel document exactly at native-chrome boundaries in both navigation
shapes. Those checks catch missing or extra native inset handling and duplicate
padding in the sentinel. The gates verify that the narrow local-network ATS
declaration is bundled; an integrated local Rails smoke test remains
application-level evidence. The serialized WebKit test moves one shared web
view from destination A through deactivation to destination B, then proves B
tracks the new document title while A keeps its earlier title.

`bin/ios doctor` structurally verifies that the shared Debug launch enables an
HTTPS or HTTP-loopback root accepted by Core and that the Release Profile
action does not inherit that environment. Unit tests invoke the configuration
seam with overrides disabled and prove it returns the compiled production root.
No Release-configured app process was executed for that proof, so it is not a
positive runtime observation of Release ignoring `APP_ROOT_URL`.

Xcode 26.6's canonical scheme serialization omits the redundant
`parallelizable="NO"` attribute from the UI testable. `bin/ios test` owns the
actual serialization boundary: it invokes the unit and UI targets sequentially
and passes `-parallel-testing-enabled NO` to both.

They do not prove iPad, earlier iOS versions, application-specific Rails pages,
generated route choices, accounts, bridge components, universal links, push
delivery, physical-device behavior, TestFlight, App Store delivery, or any
future Compiler replacement. The fixture's generated tests prove only its
default Home/no-tab configuration. Each composed capability and compiled
application must replace those tests with evidence for the behavior it adds.
