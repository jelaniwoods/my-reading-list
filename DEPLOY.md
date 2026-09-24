# Deploying to Render

The repo ships `render.yaml`: one Docker web service in Render's `ohio` region (AWS us-east-2),
with an external Neon Postgres database created in the same AWS region. Cache, Queue, and Cable share that
database.

Foundation deliberately omits the Blueprint `plan` field. Render currently creates a new service on paid
`starter` when that field is absent, and retains the current instance type for an existing service. That is the
safe default for an application whose data or delivery obligations may become durable. After handoff, the
application owner may add or change an explicit plan. Use `plan: free` only for an explicitly disposable demo; low
traffic alone is not enough to opt an application into sleeping and best-effort background work.

Ohio is the default because the initial apps and maintainers are centered around Chicago. If an application's
users are elsewhere, choose a nearer supported region before first deploy and change Render and Neon together.

## Before inviting real users

Complete the bracketed details in `/privacy` and `/terms`: the operator's legal name, contact information, effective
date, hosting and other providers, and retention periods. Verify that the policies describe the application's actual
data collection, purposes, transfers, retention, and rights processes. Fill unknowns from real operating decisions;
do not invent practices or assume a jurisdiction. Add applicable law or a forum only when the owner has chosen it.
Keep the visible draft notice while details or statements remain unfinished.

Retain the policy text's source, license, and adaptation attribution when revising it. That attribution concerns the
covered policy text; it does not change the licenses of application code, branding, or third-party assets.

## First deploy

1. Push the repository to GitHub and let its CI checks pass.
2. In Neon, create a project using **PostgreSQL 18 or newer** in **AWS us-east-2 (Ohio)**; generated tables use
   `uuidv7()`. Copy the direct connection string with
   connection pooling off (no `-pooler` in the hostname). `db:prepare` uses migration advisory locks and the
   application installs session-level query timeouts, both of which require a direct/session connection.
3. In Render, choose **New → Blueprint**, select the repository, and paste the Neon string as `DATABASE_URL`.
   It is the only prompted value; Render generates `SECRET_KEY_BASE`, and observability remains dormant until
   its optional keys are added later. Confirm that the proposed instance type is **Starter** unless this is an
   explicitly disposable demo.
4. Wait for the required GitHub checks and deploy. `https://<your-app>.onrender.com/ready` should return 200.

Render regions are immutable after service creation. Recreate, rather than reconfigure, a service created in
the wrong region. Keep the database and service colocated: even a tiny app pays cross-region latency on every
Solid Cache, Queue, Cable, and domain query.

Removing `plan: free` does not upgrade an existing service: Render preserves its current instance type when the
field is omitted. Upgrade an existing durable application in the Render dashboard or declare the desired paid
plan before relying on always-on behavior.

## The single-instance 512 MB runtime profile

The Blueprint settings are a coupled profile for one 512 MB Render instance. Both Free and Starter currently
have 512 MB RAM, so an explicitly disposable demo can reuse the same Puma, Queue, and database-pool settings:

- `WEB_CONCURRENCY=0` keeps Puma in single mode. Render otherwise supplies `1`, which starts a cluster master
  plus worker and wastes memory.
- `RAILS_MAX_THREADS=3` bounds request concurrency.
- `SOLID_QUEUE_IN_PUMA=true` runs Solid Queue in async/thread mode in the Puma process. Fork mode is a better
  isolation boundary when memory allows, but exceeds the free instance's budget.
- `DB_POOL=8` leaves connection headroom for three request threads plus Queue execution, polling, and heartbeat
  work.
- jemalloc is preloaded and configured in the Docker image to return dirty pages promptly and limit arenas.
- `db:prepare` runs in the web entrypoint so the same artifact also works on an explicitly selected free plan,
  where Render's coordinated pre-deploy command is unavailable.

These are not universal high-scale defaults. On a paid/multi-instance deployment, move jobs to a separate
worker, run migrations once in a coordinated release phase, and size workers, threads, and database pools from
measurements.

The memory profile came from deployed student apps, not an estimate: the incident sequence is recorded in
`appdev-projects/rails-8-template` [PR #22](https://github.com/appdev-projects/rails-8-template/pull/22)
(Puma cluster OOM), [PR #23](https://github.com/appdev-projects/rails-8-template/pull/23) (Solid Queue fork versus
async), and [PR #27](https://github.com/appdev-projects/rails-8-template/pull/27) (region colocation). Render's
[environment-variable documentation](https://render.com/docs/environment-variables) explains its injected Puma
concurrency, and its [Blueprint specification](https://render.com/docs/blueprint-spec) defines the omitted-plan
default, region, and checks-passed deployment behavior. Render's
[instance-type reference](https://render.com/docs/compute-plans) records the current memory and CPU budgets.

If you later add per-IP endpoint limits, verify client identity in the deployed proxy topology.
Rails' [`rate_limit`](https://api.rubyonrails.org/v8.1.3/classes/ActionController/RateLimiting/ClassMethods.html)
defaults to `request.remote_ip`. [Render forwards public requests through Cloudflare and load
balancers](https://render.com/articles/how-render-handles-ddos-attacks#reading-the-true-client-ip), so choose an
appropriate `by:` key using the provider's verified header and trust contract.

## Secrets and encrypted credentials

`render.yaml` generates a persistent `SECRET_KEY_BASE`. It signs cookies, sessions, and CSRF tokens and does
not decrypt Rails credentials, so no master key is needed for the baseline.

The Foundation deliberately ships no `config/credentials.yml.enc` or shared master key. If the application
later adopts encrypted credentials, run `bin/rails credentials:edit` to create a fresh pair for that application,
commit only the encrypted file, and add the generated `config/master.key` value to Render as
`RAILS_MASTER_KEY`. Never commit the key. You may then opt into `config.require_master_key = true`.

## Environment keys

`.env.example` documents application settings and optional local overrides. Production does not load dotenv files:
supply deployment values through Render. Its Blueprint prompts for `DATABASE_URL`, generates `SECRET_KEY_BASE`,
and configures the runtime values marked below. An absent or partial local `.env` does not indicate missing
production configuration; Rails and the relevant integrations validate the values they actually use.

| Key | Required? | What it does |
|---|---|---|
| `DATABASE_URL` | you provide | Direct Neon connection; application and all three Solid adapters share it |
| `SECRET_KEY_BASE` | generated by Render | Cookie/session/CSRF signing |
| `WEB_CONCURRENCY` | Blueprint (`0`) | Puma single mode for the 512 MB profile |
| `RAILS_MAX_THREADS` | Blueprint (`3`) | Puma request threads |
| `DB_POOL` | Blueprint (`8`) | Shared Active Record connection ceiling |
| `SOLID_QUEUE_IN_PUMA` | Blueprint (`true`) | Enables in-process Solid Queue async mode; only the literal `true` enables it |
| `JOB_CONCURRENCY` | optional (`1`) | Queue worker process count for a fork-mode supervisor; the Blueprint uses async mode |
| `RACK_TIMEOUT_SERVICE_TIMEOUT` | Blueprint (`15`) | Hard request deadline in seconds |
| `SOLID_CACHE_MAX_SIZE_MB` | optional (`64`) | Disposable cache budget inside the shared database |
| `SOLID_QUEUE_POLL_INTERVAL` | optional (`5`) | Seconds between Queue worker polls; also the worst-case job pickup latency |
| `SOLID_QUEUE_DISPATCH_INTERVAL` | optional (`5`) | Seconds between Queue dispatcher polls for due scheduled jobs |
| `SOLID_CABLE_POLL_INTERVAL` | optional (`1`) | Seconds between Cable listener polls; also the worst-case broadcast delivery delay |
| `ROLLBAR_ACCESS_TOKEN` | optional | Activates production error reporting; absent is silent and dormant |
| `ROLLBAR_ENV` | optional (Rails environment) | Overrides the Rollbar environment label |
| `SKYLIGHT_AUTHENTICATION` | optional | Activates production APM; absent is silent and dormant |
| `RAILS_LOG_LEVEL` | Blueprint (`info`) | Production log level |

Foundation remains production-domain-agnostic: it does not configure production Host Authorization or a canonical
host. A generic baseline does not know which public domains an application should serve. Before mapping a public
domain, configure the application's coordinated Render subdomain setting, host allowlist, and any canonical redirect.
The exact GitHub Codespaces host admitted in development is a separate preview rule.

## Health, sleeping, and background work

- `/up` is process liveness and intentionally does not touch the database. Docker uses it to decide whether the
  container booted.
- `/ready` performs a real database round-trip. Render and availability monitors use it to decide whether the
  application can serve traffic.
- Neither route proves that a time-sensitive job has completed. Add a Queue heartbeat/dead-job alert before
  making delivery promises for push, scheduled email, or recurring work.

When an explicitly disposable demo uses Free, Render sleeps the service after an idle period, and its in-process
Queue sleeps with it. An external monitor that calls `/ready` frequently can keep the service
awake, but it also keeps the app querying Neon and defeats database scale-to-zero. Do not describe scheduled work
on that profile as reliable. Durable apps keep the paid default and add Queue heartbeat/dead-job monitoring before
making delivery promises.

### Queue and Cable polling is metered bandwidth

Solid Queue 1.x has no LISTEN/NOTIFY, so every poll is a real query, and the database is off-platform. Since
2025-08-01 Render meters service-initiated egress — explicitly including calls to an external database — against
the workspace bandwidth allowance, so an idle application still bills for its own polling. Rails' stock 0.1s
worker interval costs roughly 30MB per instance-hour, which exhausts a 5GB Hobby allowance in about a week of
continuous uptime.

Production therefore polls every 5s, cutting idle queries ~95% (~11.2/s to ~0.6/s). Development and test keep the
responsive stock intervals, where the database is local and the traffic is free. The trade is pickup latency:
worst case ~5s for an immediate job and ~10s for a scheduled one. Tune with `SOLID_QUEUE_POLL_INTERVAL` and
`SOLID_QUEUE_DISPATCH_INTERVAL` when an application needs faster pickup and can afford the egress; lower them
only against a same-region database, where Render bills no bandwidth at all.

Solid Cable polls the same way, for the same metered query, and is set to 1s for the same reason. It is the
cheaper of the two: its listener is built lazily on first subscribe and then polls only while someone is
connected, where the Queue polls for as long as the service is awake. Core itself never subscribes, so the
setting is inert here — it is set conservatively because a generated app that adds a single `turbo_stream_from`
would otherwise inherit 10 queries a second without anyone choosing it. Tune with `SOLID_CABLE_POLL_INTERVAL`;
genuinely interactive channels such as typing indicators or live cursors will want it lower, and should weigh
that against the egress.

Note that a default that is merely inert in Core is not therefore harmless: generated apps carry their own copy
of these files, so a value shipped here is a value every descendant inherits and must be fixed one repo at a
time. Prefer defaults that are safe under the deployment topology this document describes, not under the
behavior of Core's own empty demo.

The container filesystem is ephemeral. If the application accepts durable uploads, configure external object
storage; never place durable user files on the production `:local` service.

Neon's free storage is shared by application rows and Solid Cache/Queue/Cable. The baseline caps disposable
cache data at 64MB; monitor finished jobs, cable retention, and storage before approaching the provider limit.

## Email

The baseline sends no mail. If the application needs email, configure Action Mailer and its provider, set a real
application host, add delivery monitoring, and complete an SPF/DKIM/DMARC launch checklist.

Further provider behavior: [Render health checks](https://render.com/docs/health-checks),
[Render free instances](https://render.com/docs/free), and
[Neon scale to zero](https://neon.com/docs/introduction/scale-to-zero).
