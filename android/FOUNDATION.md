# Android Core composition

Core owns the schema-independent Hotwire Native runtime. First Draft mounts an
exact Git archive under `android/`, retains its revision and archive digest in
`FOUNDATION_PROVENANCE.json`, and replaces only these application seams:

- `Generated/application.properties`
- `app/src/main/java/com/firstdraft/foundation/generated/GeneratedApplication.kt`
- `app/src/test/java/com/firstdraft/foundation/generated/GeneratedApplicationTest.kt`
- `app/src/main/res/layout/activity_main.xml`
- `app/src/main/res/values/strings.xml`
- `app/src/main/res/values/colors.xml`
- `app/src/main/res/values-night/colors.xml`
- `app/src/main/assets/json/android_v1.json`

The application ID is independent of the stable Kotlin namespace. The generated
definition owns an HTTPS Rails origin with no credentials, path, query, or
fragment, plus the theme, ordered entries, matching NavigatorHost IDs, and a
placeholder-identity disclosure for applications without an authored domain.
`application.properties` supplies the APK manifest's Plan digest and its
BuildConfig copy. Generated Kotlin carries the same digest; a generated unit
test requires them to agree. Neither value may remain `core-fixture` after
composition. The Compiler preserves every entry; Core is structured for one
entry without tabs, up to five direct tabs, or four tabs and a native More list.
Each tab uses Hotwire's own Navigator and back stack. Overflow destinations push
from More, allowing Android Back to return to the list.

Core registers Hotwire Web and bottom-sheet fragments and the native More
fragment. The Compiler must supply the application-specific bundled rules:
direct tab roots use `presentation: replace_root`; public new/edit routes keep
`uri: hotwire://fragment/web` with `context: modal` and disable pull-to-refresh.
This is the pinned Hotwire demo's full-screen form pattern. More uses the
reserved path `/__firstdraft_android_more__` with
`uri: hotwire://fragment/firstdraft-more` and `presentation: replace_root`.
Overflow destinations retain ordinary push presentation so Back can return to
More. The stock one-entry fixture supplies only its root rule. Registered
fragments alone do not select these destinations. No remote configuration
endpoint is required.
Hotwire owns links, form visits, file selection, cookies, and browser behavior.
Native authentication integration, authenticated session restoration, push, signing, and store
delivery are not implemented by this shell.

Native views own system and keyboard insets. Material DayNight themes and the
generated colors apply to the native shell and WebView background; Rails owns
HTML styling. Material's OnSurface toolbar style tints navigation icons for the
current light or dark theme. The adaptive launcher icon is a stock Core asset.

Tab labels stay visible, wrap as needed, and follow the system font size.
The Core theme supplies these defaults even when the Compiler replaces the
activity layout. The Compiler resolves authored Entity icon tokens and uses the
grid fallback when absent; Core consumes each entry's icon resource as supplied.
The optional bottom-sheet destination opens expanded and skips the collapsed
stop. A downward swipe dismisses it and discards its unsaved form. Generated
forms use full-screen modals: a sheet's nested scrolling did not reliably expose
controls after a validation response increased the page height.
Phone rotation resizes the existing activity and its views.
Process death and other activity recreation are
separate events; this does not promise unsaved-draft restoration after either.
Failed page loads show a readable message and a Try again button in both regular
screens and modal destinations, retaining Hotwire's error description. The button calls
Hotwire's public `refresh` method to reload the page from scratch; an unsaved form
is not retained. It does not queue or automatically retry writes. Runtime strings live separately
from the Compiler-owned application-name resource.

Hotwire 1.3.1 [sets toolbar navigation icons](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/navigation-fragments/src/main/java/dev/hotwire/navigation/fragments/HotwireFragmentDelegate.kt)
without accessible names. After its
`onViewCreated` hook installs the icon and pop action, Core supplies the
Back or Close description through localizable Android string resources; only
English is supplied. The description matches Hotwire's icon. Close dismisses
the current modal screen, which can return to an earlier full-screen modal.
Back is deliberate: the toolbar and system Back both call `Navigator.pop()`.
Root screens, including More under the Compiler's rules, retain no Back control.
Retire this label-only hook when the pinned Hotwire implementation supplies
those descriptions itself.

Debug preview accepts `APP_ROOT_URL` as an Intent string extra. A narrow WebView
hook adds `X-Tunnel-Skip-AntiPhishing-Page: true` only to the exact configured
HTTPS Codespaces preview origin. This does not authenticate a private forwarded
port. Release builds use the generated origin and never add this preview header.
Revisit the hook if Codespaces removes its warning or Hotwire provides a request
header configuration API. Unit tests cover its origin and build-mode boundary;
an actual device launch is required to claim that a particular preview works.

`bin/android test` exercises the navigation arithmetic, origin/header boundaries,
and generated identity on the JVM. `lint` checks source and resources; `build`
assembles the debug APK. CI also compiles the instrumentation APK with
`assembleDebugAndroidTest`; it does not run an emulator. `device-test` runs the
instrumentation tests locally on an attached emulator or device. Compiler composition and generated runtime
evidence belong to the First Draft service repository; neither a build nor the
JVM suite establishes device navigation, forms, or appearance.
The synthetic per-type inset tests require API 30 or later; they do not qualify
the older window-resizing path on API 28/29.
Navigation accessibility instrumentation uses bundled test-only path rules and
checks real fragment controls, nested modal dismissal, and a More root with an
overflow-style return without a Rails server. The stock fixture has one Navigator;
these tests do not qualify tab switching or every root in a composed multi-tab
application. They do not establish TalkBack focus order or spoken announcements.

## Upstream comparison

Hotwire Native 1.3.1 supplies the
[tab controller](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/navigation-fragments/src/main/java/dev/hotwire/navigation/tabs/HotwireBottomNavigationController.kt)
and fragment routing used here. Core adds only the generated entry adapter and
the More list; it does not replace Navigator, navigation history, or form visits.

The [public Hotwire configuration](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/core/src/main/kotlin/dev/hotwire/core/config/HotwireConfig.kt)
offers `makeCustomWebView` but no initial-request header option.
[Session loading](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/core/src/main/kotlin/dev/hotwire/core/turbo/session/Session.kt)
calls the WebView's public `loadUrl` method. `PreviewWebView` therefore uses
[Android's loadUrl with headers](https://developer.android.com/reference/android/webkit/WebView#loadUrl(java.lang.String,java.util.Map%3Cjava.lang.String,java.lang.String%3E))
for the first preview request. A second HTTP client or navigation library would
duplicate Hotwire's session behavior without improving this narrow request hook.
The motivation is the
[observed Codespaces warning in the iPhone trial](https://github.com/firstdraft/firstdraft/blob/12310636e6049fadcb8ee69dc99d15f7e1f7f982/docs/solutions/2026-09-10-generated-iphone-revyl-preview.md).
That observation motivates the Android experiment; Android device proof remains
separate. The retirement trigger is recorded with the hook above.

Hotwire's [applyDefaultImeWindowInsets](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/navigation-fragments/src/main/java/dev/hotwire/navigation/util/NavigationExtensions.kt)
handles keyboard padding only. Core uses
[Android's window-insets API](https://developer.android.com/develop/ui/views/layout/edge-to-edge)
to reserve keyboard space, system navigation space when a single destination has
no Material tab bar, and cutout space at the sides. The activity consumes the
insets it handles. A full-screen modal reserves any remaining bottom inset
because Hotwire hides its tab bar. Hotwire's toolbar owns the top inset.

The activity handles `orientation|screenSize`, matching the
[pinned Hotwire demo manifest](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/demo/src/main/AndroidManifest.xml).
The optional bottom-sheet fragment uses Material's public `BottomSheetDialog.behavior` API.
Generated forms follow the [demo path configuration](https://github.com/hotwired/hotwire-native-android/blob/a49cb9bf87e095d52c2f9529f951c78f20b2dc23/demo/src/main/assets/json/path-configuration.json)
for full-screen modals. No separate draft store or replacement navigation is needed.
