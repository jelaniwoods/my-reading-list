# Reading List

A public demonstration reading list with disposable data and no accounts. Anyone can list, view, add, edit, and
delete books; each book has a required title and author, an optional note, and a Finished checkbox. The web app
opens on the book list, and the iPhone (`ios/`) and Android (`android/`) clients open on the same public list.
Development setup loads three sample books.

This app started with First Draft. The generated baseline does not yet set a database default for Finished;
see `.firstdraft/design/implementation-notes.md` and `.firstdraft/gaps.json`.

## Setup and run

Use the Ruby and Node versions in [`.ruby-version`](.ruby-version) and [`.node-version`](.node-version),
and PostgreSQL 18 (the schema uses `uuidv7()`). The [Dev Container](.devcontainer/devcontainer.json) supplies these
and a browser for system specs. Open the repository in that container, or install the toolchain locally, then run:

```sh
bin/setup --skip-server
bin/dev
```

Setup installs Ruby and JavaScript dependencies and prepares the database. Without `--skip-server`, it also
starts `bin/dev`. The development process runs Rails and the JavaScript/CSS watchers; open
[localhost:3000](http://localhost:3000), or the forwarded application port in a Codespace.

For native clients, start Rails with `bin/dev`, then follow the applicable guide:

- iPhone: [`IOS_PREVIEW.md`](IOS_PREVIEW.md) covers the client in `ios/`, Simulator builds, and Revyl preview.
- Android: [`ANDROID_PREVIEW.md`](ANDROID_PREVIEW.md) covers the client in `android/`, APK builds, and local Emulator preview.

Keep the web fallback usable. Each guide owns its current build prerequisites, preview limitations, and the
bounded procedure for exposing a development port during a remote preview and making it private afterward.

### Local configuration

No `.env` file is required for ordinary setup. For overrides, copy [`.env.example`](.env.example) to a gitignored
`.env` or `.env.development.local`. Dotenv loads local overrides before shared files; existing process environment
values win, and tests ignore `.env.local`. Never commit secrets.

`bin/lint-env` checks env-file key names without printing values. Missing optional files are fine; unknown keys
make a direct invocation fail, while setup warns and continues. Explicit paths must exist. This checks names,
not credentials or service connectivity; features validate their configuration when used.

### Development samples

Setup loads the disposable records in [`db/seeds/development.rb`](db/seeds/development.rb) when it initializes
the development database. To load them into an already prepared development database, run:

```sh
RAILS_ENV=development bin/rails db:seed
```

Keep these samples in the development seed file; ordinary production seeding does not load them.
Ordinary samples match their generated attribute values. If you edit those values, rerunning seeds can recreate
the original sample instead of updating your edited record.

### Development container and Codespaces

PostgreSQL data persists across container recreation in the named volume mounted at `/var/lib/postgresql`.
Keep that PostgreSQL 18 volume root; the older `/var/lib/postgresql/data` mount is incompatible. Compose waits for
Selenium's health check before starting Rails. Run system specs serially: the two browser sessions share a fixed
Capybara server port.

Keep a Codespaces development port private: development includes detailed errors and web-console and omits CSP.
Use the selected native preview guide's temporary public-port procedure only for that preview, then restore privacy.
Rails admits the exact forwarded host built from the Codespace name, `PORT`, and the forwarding domain; it does not
admit sibling Codespaces. Set `PORT` when changing the application port; `rails server -p` alone does not change
that host rule. Codespaces development disables the additional CSRF Origin-header check while retaining
form-authenticity-token verification. Other development environments and production retain Rails' default Origin
validation. Action Cable's localhost-only development origins are separate: add the exact Codespaces origin if
you need to preview broadcasts there. These settings do not establish production domain policy.

The container's SSH service accepts public-key authentication for `vscode`; root/password logins and non-loopback
remote forwards are disabled. Port 2222 is not forwarded by this configuration.

Before resetting an existing volume, back up data that matters. For disposable data only, find this checkout's
exact project with `docker compose ls --all`, then run from the repository root:

```sh
docker compose --project-name PROJECT_NAME --file .devcontainer/compose.yaml down --volumes
```

Replace `PROJECT_NAME` with that exact name. This removes its containers and declared volumes; the next start
initializes a fresh database. Do not prune unrelated Docker volumes.

## Checks

After setup, build assets before running specs in a fresh checkout:

```sh
npm run build
npm run build:css
bundle exec rspec
```

Run `bundle exec rspec spec/system` for browser specs, or pass a specific spec path for a focused check. Local
system specs need Chrome; the Dev Container uses its healthy Selenium service. System visits and clicks include
accessibility checks. Browser/native-user-agent checks do not establish actual device behavior.

```sh
bundle exec standardrb
bundle exec erb_lint --lint-all
npm run check
bin/ci
```

`bin/ci` builds assets and runs the application tests, lint, audits, and reproducibility checks. Before changes
that affect container delivery, also run `bin/devcontainer-smoke` and `bin/production-smoke`. Both require Docker.
The development smoke requires a clean, committed tree because it archives `HEAD`; it checks first setup and a
restart with the retained PostgreSQL volume. The production smoke builds the image and exercises PostgreSQL and
the Solid adapters. These local checks do not prove a hosted deployment or a fresh Codespace attachment.

Use minimal FactoryBot factories in `spec/factories`, with scenario values and relationships visible in the spec.
Use `build` when persistence is unnecessary; keep request payloads and authentication setup explicit. WebMock
blocks external HTTP in specs. Bullet catches exercised association N+1 paths; use `n_plus_one_control` query-growth
specs for important collections and explicit-query loops. Set up fixtures before measurement. For a direct model
example, use `Bullet.profile` around the behavior; request/system collection is automatic. Unused-preload and
counter-cache advice remains advisory in development.

## Continue development

Every file is ordinary application source. Extend or replace it directly with Rails and established libraries.
Read [UI.md](UI.md) for component and interaction conventions and its [Assets guide](UI.md#assets) for the build
pipeline and adding a previously unused picker. Read [AGENTS.md](AGENTS.md) for agent guidance and
[DEPLOY.md](DEPLOY.md) for deployment, email, domain policy, and the policy drafts to complete before launch.
Retain the [MIT notice](LICENSE) for the starter code and the required third-party notices under [licenses](licenses).

Rails model/scaffold generators use RSpec and FactoryBot. Complete their pending request examples and meaningful
factory relationships when adding behavior; generated empty attributes are not an application scenario.

Application table generators default to UUID primary/reference keys and PostgreSQL 18's `uuidv7()` primary-key
default. An explicit `--primary-key-type=bigint` keeps Rails' bigint output, including references; choose each
reference type to match its target when mixing key types. Existing tables retain their types/defaults. Framework
migrations have their own templates: Active Storage, Action Text, and Action Mailbox may use the generator key type
but retain `gen_random_uuid()` for UUID defaults. Check unrun framework migrations when changing this setting.
The existing Solid tables use bigint keys.

If retained, `.firstdraft/gaps.json` records reviewed support gaps and `.firstdraft/design/implementation-notes.md`
may contain product decisions and open questions. Read them before feature work. The `.firstdraft/` directory is
removable context; setup, runtime, preview, and tests do not require it. Inspect the actual application before
claiming a feature is complete or choosing a second implementation.
