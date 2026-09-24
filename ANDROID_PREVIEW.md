# Build and preview your Android app

Keep `bin/dev` running in one Codespace terminal and use the web preview for everyday Rails work.
For native Android checks, use Android Studio's local Emulator. Revyl's tested Android image needs a newer
WebView before it can provide a clean browser preview.

## Recommended: Android Studio and a local Emulator

1. Save the compiled app to your own **private GitHub repository**, then clone it onto your computer.
   Before a remote exists, use **Publish to GitHub → Publish to GitHub private repository** in Source Control.
   Afterward, commit and push normally. Open the clone's `android/` directory in Android Studio.
2. Install Android SDK platform **36** and build-tools **36.0.0**. Keep Android Studio's bundled Gradle JVM
   default; the tested Quail 4 release built this app with its bundled **Java 25**. Keep the project's pinned
   Android Gradle Plugin version for this preview.
   In **Device Manager**, create a phone using an **Android 16 / API 36** system image with Google APIs.
   The app requires **WebView 120 or newer**; use a compatible image if it reports an outdated WebView.
3. Leave Rails running in your Codespace and keep port 3000 **Private**. On your computer, sign into the
   GitHub CLI if needed, then forward Rails to your computer in a terminal that stays open:

   ```sh
   gh codespace ssh -- -N -L 3001:127.0.0.1:3000
   ```

   Select the Codespace running this app. If Rails runs on your computer instead, skip the tunnel and use
   `http://10.0.2.2:3000` in the next step. `10.0.2.2` is the Emulator's address for your computer.
4. In **Run → Edit Configurations**, select the `app` configuration, keep **Launch: Default Activity**, and
   enter this under **Launch Flags**:

   ```text
   --es APP_ROOT_URL http://10.0.2.2:3001
   ```

   Select the **debug** build variant and your Emulator, then click **Run**. Android Studio builds and installs
   the app. This launch setting points the Debug app at Rails; it does not change the compiled Release origin.
5. Check navigation and forms. Rails changes need a page refresh; native changes need a new local build.
   Pull updated native source into the local clone before rebuilding. When finished, stop the Emulator in
   Device Manager and press **Ctrl+C** in the forwarding terminal.

This path uses your computer for the Android build and preview; it consumes no Revyl device or remote-build time.
See [Android's device setup](https://developer.android.com/studio/run/managing-avds),
[Java configuration](https://developer.android.com/build/jdks),
[launch settings](https://developer.android.com/studio/run/rundebugconfig), and
[GitHub's SSH command](https://cli.github.com/manual/gh_codespace_ssh).

The command-line instructions in `android/README.md` and the GitHub build use **JDK 17**. That is separate
from Android Studio's build JVM; the generated Java/Kotlin bytecode still targets Java 17 in either case.
If changing **Gradle JVM criteria** reports `Toolchain download repositories have not been configured`,
restore Studio's bundled default. We encountered this error when selecting Java 17 in the Quail 4 trial.

## Revyl device prerequisite

Hotwire Native requires **Android System WebView 120 or newer**. Our September 12, 2026 Revyl test found
WebView 113 on its available Pixel 7 / Android 14 image. The app loaded Rails, but displayed an update
warning; **Update** opened Google Play sign-in. A clean Revyl preview is awaiting a compatible device image.

Check `revyl device targets --platform android` for available images. If the app reports an outdated
WebView, stop the device with `bin/android preview revyl stop` and continue in the web preview.
Use a compatible image when available; do not weaken the WebView requirement or sign into Google Play
just to complete this trial. A local emulator with a current WebView works; see
[`android/README.md`](android/README.md).

## Optional Revyl preview on a compatible device

1. Save the compiled app to your own **private GitHub repository**. If Source Control shows
   **Publish to GitHub**, choose that and then **Publish to GitHub private repository**. Once the
   repository has an `origin`, commit and push normally. The build needs your pushed source.
2. Run `bin/setup --skip-server`, then `bin/dev`. Leave that terminal running and open a second terminal.
3. In the **Ports** panel, find port **3000**, set **Port Visibility → Public**, and copy its HTTPS address.
   Revyl needs to reach Rails from outside your Codespace. Use disposable development data while the port is public.
4. Install the tested Revyl CLI and sign in:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/RevylAI/revyl-cli/v0.1.109/scripts/install.sh |
     REVYL_VERSION=v0.1.109 sh
   export PATH="$HOME/.revyl/bin:$PATH"
   revyl auth login
   ```

   Open the approval URL printed by `revyl auth login` in your browser and approve the matching code.
   This works even when the CLI runs in Codespaces. Use the same Revyl account in the browser and CLI.
   If you authenticated the CLI earlier or with an API key, the viewer may still ask you to sign in.
   The installer also replaces an older installation.
   Revyl can retire old CLI versions; follow an explicit compatibility error
   rather than retrying a rejected version.
5. From the second terminal, run:

   ```sh
   bin/android preview revyl doctor
   bin/android preview revyl --server https://YOUR-CODESPACE-3000.app.github.dev
   ```

   Use the copied address, with no `/movies` or other path. The command checks Rails and Revyl,
   finds or starts a GitHub build, verifies and uploads the debug APK, starts a device,
   and prints a **Viewer** link. Open that link in your browser.

The app uses this Rails address only for the Debug preview. The Release app keeps the HTTPS origin
compiled into `android/app/src/main/java/com/firstdraft/foundation/generated/GeneratedApplication.kt`. Debug requests to the configured Codespaces origin
skip its public-port warning, which cannot run as a Hotwire page; private ports still require authentication.

## Edit, refresh, and stop

- **Rails, HTML, CSS, and server data:** change the files and pull down in the Android view to refresh.
  The running app continues using the same native binary. A new preview also reuses a recent GitHub
  artifact when all native build inputs match an ancestor commit, even after Rails-only commits.
- **Kotlin, native assets, package pins, or native build configuration:** stop the device, commit and push,
  then rerun the preview command. It builds a new artifact when native inputs change.
- **Finish a native check:** run `bin/android preview revyl stop`. Closing the viewer tab does not stop the
  device. `bin/android preview revyl status` shows sessions for this checkout. Devices also have a five-minute
  idle timeout; do not use that as a substitute for stopping them. If the wrapper is unavailable, run
  `revyl device stop` directly from the same checkout.
- **Finish exposing Rails:** set port 3000 back to **Private**. Stop the Codespace when done working.

Downloaded artifacts remain in `tmp/android-preview/` for inspection. You can delete that folder when you no
longer need those copies; GitHub artifact retention and uploaded Revyl builds are separate.

Pushing native changes starts the build; Rails-only pushes and Dependabot branches do not. Artifacts last
seven days. If none is available, the helper tries to start a build. Codespaces can allow Git pushes while
rejecting workflow dispatch with HTTP 403. In that case, open your repository on GitHub, choose **Actions →
Android APK artifact → Run workflow**, select your branch, and rerun the preview command. This also
rebuilds an expired artifact without changing source or logging the Codespace into another GitHub account.
Uncommitted native changes cannot be included in a GitHub build, so the command asks you to commit them first.
Rails can remain uncommitted during a live preview.

The workflow installs JDK 17 and Android SDK 36 on Ubuntu and uses the pinned Gradle wrapper.
No Mac or Android Studio installation is required for this browser workflow. The artifact is a standalone
debug APK; Revyl does not accept an Android App Bundle (`.aab`) for this preview.

## Accounts and usage

You need access to this repository's GitHub Actions and to an Android device in your Revyl account.
GitHub Linux jobs consume your GitHub Actions allowance; Revyl devices consume Revyl usage. This path
uploads an already-built `.apk` and does **not** use Revyl remote build compute or connect a Revyl
GitHub App. Check your account's [current usage and pricing](https://revyl.com/pricing); do not assume a
recurring free allowance or enable paid overages just to follow this guide. After a stop, Revyl may still report
its concurrency limit while the old session finishes. Check your active devices and wait for the stopped
session to complete before starting again.

`config/android_preview.json` stores the app name and a non-secret Revyl app ID after first use. Credentials
stay in the GitHub and Revyl login stores. Each student normally uses their own repo and Revyl account.
A collaborator using another Revyl account may need to remove the saved `app_id` so their own app is selected.

For a build made elsewhere, use `--artifact PATH/Example.apk --manifest PATH/manifest.json`.
An explicit artifact must match the checkout's current commit and pass the manifest's digest and platform
checks. The regular command handles reuse automatically. Local build instructions remain in
[`android/README.md`](android/README.md). Revyl previews an Android Emulator build; this does not install an app on a phone.
