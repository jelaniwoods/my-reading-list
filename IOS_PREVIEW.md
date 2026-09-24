# Preview your iPhone app with Revyl

Keep `bin/dev` running in one Codespace terminal and use the web preview for everyday Rails work.
Use Revyl when you want to check the iPhone shell, native navigation, or a Swift change. You can do this
from a browser; GitHub builds the Simulator app on a Mac runner.

## First preview

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
   bin/ios preview revyl doctor
   bin/ios preview revyl --server https://YOUR-CODESPACE-3000.app.github.dev
   ```

   Use the copied address, with no `/movies` or other path. The command checks Rails and Revyl,
   finds or starts a GitHub build, verifies and uploads the Simulator artifact, starts a device,
   and prints a **Viewer** link. Open that link in your browser.

The app uses this Rails address only for the Debug preview. The Release app keeps the HTTPS origin
compiled into `ios/Generated/Application.xcconfig`. Debug requests to the configured Codespaces origin
skip its public-port warning, which cannot run as a Hotwire page; private ports still require authentication.

## Edit, refresh, and stop

- **Rails, HTML, CSS, and server data:** change the files and pull down in the iPhone view to refresh.
  The running app continues using the same native binary. A new preview also reuses a recent GitHub
  artifact when all native build inputs match an ancestor commit, even after Rails-only commits.
- **Swift, native assets, package pins, or native build configuration:** stop the device, commit and push,
  then rerun the preview command. It builds a new artifact when native inputs change.
- **Finish a native check:** run `bin/ios preview revyl stop`. Closing the viewer tab does not stop the
  device. `bin/ios preview revyl status` shows sessions for this checkout. Devices also have a five-minute
  idle timeout; do not use that as a substitute for stopping them. If the wrapper is unavailable, run
  `revyl device stop` directly from the same checkout.
- **Finish exposing Rails:** set port 3000 back to **Private**. Stop the Codespace when done working.

Downloaded artifacts remain in `tmp/ios-preview/` for inspection. You can delete that folder when you no
longer need those copies; GitHub artifact retention and uploaded Revyl builds are separate.

Pushing native changes starts the build; Rails-only pushes and Dependabot branches do not. Artifacts last
seven days. If none is available, the helper tries to start a build. Codespaces can allow Git pushes while
rejecting workflow dispatch with HTTP 403. In that case, open your repository on GitHub, choose **Actions →
iOS Simulator artifact → Run workflow**, select your branch, and rerun the preview command. This also
rebuilds an expired artifact without changing source or logging the Codespace into another GitHub account.
Uncommitted native changes cannot be included in a GitHub build, so the command asks you to commit them first.
Rails can remain uncommitted during a live preview.

The workflow pins Xcode 26.6 for a repeatable build. If GitHub later removes that version from its Mac
runner image, update `DEVELOPER_DIR` in `.github/workflows/ios-simulator-artifact.yml` to an available
Xcode version and rebuild. The manifest records the Xcode version that actually built the artifact.

## Accounts and usage

You need access to this repository's GitHub Actions and to an iOS device in your Revyl account.
GitHub macOS jobs consume your GitHub Actions allowance; Revyl devices consume Revyl usage. This path
uploads an already-built `.app.zip` and does **not** use Revyl remote build compute or connect a Revyl
GitHub App. Check your account's [current usage and pricing](https://revyl.com/pricing); do not assume a
recurring free allowance or enable paid overages just to follow this guide. After a stop, Revyl may still report
its concurrency limit while the old session finishes. Check your active devices and wait for the stopped
session to complete before starting again.

`config/ios_preview.json` stores the app name and a non-secret Revyl app ID after first use. Credentials
stay in the GitHub and Revyl login stores. Each student normally uses their own repo and Revyl account.
A collaborator using another Revyl account may need to remove the saved `app_id` so their own app is selected.

For a build made elsewhere, use `--artifact PATH/Example.app.zip --manifest PATH/manifest.json`.
An explicit artifact must match the checkout's current commit and pass the manifest's digest and platform
checks. The regular command handles reuse automatically. Local Mac instructions remain in
[`ios/README.md`](ios/README.md). Revyl previews a Simulator build; this does not install an app on a phone.
