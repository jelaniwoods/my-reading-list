# Application UI

The application uses Rails ERB, Tailwind, and Basecoat Vega for ordinary screens. Selected interactive controls
use checked-in shadcn `base-vega` React components mounted through Turbo Mount. Rails still owns routes,
authorization, forms, CSRF, validation, responses, and pagination. Every file is ordinary application source.

## Assets

Start with [README setup and run](README.md#setup-and-run) for dependencies and `bin/dev`. The development process
runs Rails plus JavaScript and CSS watchers. These are the application sources and generated outputs:

| Location | Purpose |
| --- | --- |
| [application.js](app/javascript/application.js) | Turbo, Stimulus, and islands; theme code for auto/toggle |
| [register.ts](app/javascript/islands/register.ts) | Ordinary imports and registrations for the islands this app uses |
| [islands](app/javascript/islands) | App controls and their existing Rails/Turbo boundary and controllers |
| [components/ui](app/javascript/components/ui) | Reusable, checked-in shadcn primitives |
| [application.tailwind.css](app/assets/stylesheets/application.tailwind.css) | Tailwind entry, Basecoat, and shared styles |
| [theme.css](app/assets/stylesheets/theme.css) | Semantic color and theme tokens used by ERB and React |
| `app/assets/images`, `app/assets/fonts` | Application images and fonts; create the fonts directory when needed |
| `app/assets/builds`, `public/assets` | Generated bundles and fingerprinted production assets; do not edit them |

[script/build-js.mjs](script/build-js.mjs) uses esbuild to bundle imported JavaScript/TypeScript into one eager
application entry. Tailwind scans the application sources and builds CSS separately. Propshaft serves these assets
and fingerprints production output; use Rails asset helpers such as `image_tag` and CSS `url(...)` asset references.
Files in `public/` instead have direct, unfingerprinted URLs.

The retained component kit and npm dependencies are available for later development. A file in `islands` or
`components/ui` does not enter the JavaScript bundle merely because it exists. Check `register.ts`: date pickers,
Reference pickers, and deletion confirmation are registered when generated controls use them. Navigation and
toasts remain registered. Adding the first use of an omitted widget requires its import and registration below.
Keep the selected widgets on the existing eager Turbo Mount path.

### Icons and Add to Home Screen

`public/icon.svg` and `public/icon.png` are the shared favicon and Apple touch-icon sources. They have direct URLs;
keep those paths aligned with the shared layout when replacing artwork.

When `app/views/pwa/manifest.json.erb` is present, the app supports ordinary online browser installation or Add to
Home Screen. Rails serves it through `rails/pwa#manifest`. Keep its 192px `public/icon-192.png` and 512px
`public/icon.png` declarations aligned with the files' actual dimensions. A `maskable` icon needs an opaque
background and important artwork within the centered 40%-radius safe zone. The app name comes from `app_name` in
the locale. The start URL `/` uses the app's Home route and its normal sign-in/access rules. Manifest colors are
fixed installation metadata; web page themes may change independently.

Test on HTTPS, or localhost for development. Browser promotion, Add to Home Screen, standalone launch/navigation,
and sign-in after relaunch are distinct checks. Use the actual browsers and phones you intend to support. This
application has no offline cache, service worker, Web Push, or custom install prompt. A browser may still save a
site when installation metadata is absent. Plan authors can omit that metadata with `application.pwa: false`.

### Add the first date picker

This example starts with an app whose registry has no `DatePicker`. It adds a new Appointment model; use a different
model name if Appointment already exists. After the README setup, generate the ordinary Rails resource:

```sh
bin/rails generate scaffold Appointment title:string starts_on:date
bin/rails db:migrate
```

Add `validates :title, presence: true` inside `app/models/appointment.rb`. In
`app/javascript/islands/register.ts`, add this import beside the other island imports:

```ts
import DatePicker from "./DatePicker"
```

Inside `registerIslands`, after `turboMount` and `nonce` are defined and before `return turboMount`, add:

```ts
registerComponent(turboMount, "DatePicker", withIslandBoundary(DatePicker, nonce) as ComponentType, IslandController)
```

The existing imports already provide the boundary, controller, and `ComponentType`. Keep them: the boundary carries
the CSP nonce and restores the Rails fallback after a rendering failure. No new dependency or mount controller is
needed. Add `config/locales/appointments.en.yml`:

```yaml
en:
  activerecord:
    models:
      appointment: Appointment
    attributes:
      appointment:
        title: Title
        starts_on: Starts on
  appointments:
    new:
      title: New appointment
    edit:
      title: Editing appointment
    index:
      title: Appointments
    form:
      errors: Check your appointment
      submit: Save appointment
```

Translate the scaffold generator's headings and record labels so they pass the application's ERB checks:

| File under `app/views/appointments` | Replace | With |
| --- | --- | --- |
| `new.html.erb` | `New appointment` inside `<h1>` | `<%= t(".title") %>` |
| `edit.html.erb` | `Editing appointment` inside `<h1>` | `<%= t(".title") %>` |
| `index.html.erb` | `Appointments` inside `<h1>` | `<%= t(".title") %>` |
| `_appointment.html.erb` | `Title:` | `<%= appointment.class.human_attribute_name(:title) %>:` |
| `_appointment.html.erb` | `Starts on:` | `<%= appointment.class.human_attribute_name(:starts_on) %>:` |

Use `t(".title")` for the new, edit, and index page's `content_for :title` value too.
The generated Show page has no heading. Add `<h1 class="text-2xl font-semibold"><%= @appointment.title %></h1>`
before its record partial and `<% content_for :title, @appointment.title %>` at the top. Remove its notice paragraph;
the shared layout already renders feedback. This gives the saved record an accessible heading without duplicate
success messages.

Replace `app/views/appointments/_form.html.erb` with:

```erb
<%# locals: (appointment:) %>
<%= form_with model: appointment, html: {novalidate: true}, class: "space-y-6" do |form| %>
  <%= render "shared/ui/form_errors", errors: appointment.errors,
    field_ids: {title: form.field_id(:title), starts_on: form.field_id(:starts_on)},
    title: t(".errors"), id: form.field_id(:errors) %>
  <div class="field">
    <%= form.label :title, class: "label" %>
    <%= form.text_field :title, required: true, class: "input",
      aria: {invalid: appointment.errors[:title].any?, describedby: form.field_id(:title_errors)} %>
    <%= render "shared/ui/field_errors", errors: appointment.errors.full_messages_for(:title),
      id: form.field_id(:title_errors) %>
  </div>
  <%= render "shared/ui/date_field", form: form, attribute: :starts_on,
    label: appointment.class.human_attribute_name(:starts_on), value: appointment.starts_on,
    errors: appointment.errors.full_messages_for(:starts_on) %>
  <%= form.button t(".submit"), class: "btn" %>
<% end %>
```

The scaffold controller already permits `:starts_on`. The shared partial supplies translated calendar props and a
native date input, preserving the Rails `appointment[starts_on]` ISO date value. It disables that fallback only
after React commits. Keep the generated controller's `422` response and its submitted record on validation errors.

Run `npm run check:fix` to format the registration, then the checks below. With `bin/dev` running, open
`/appointments/new`, enter a date, and leave Title blank. Save should retain the date and show the title error.
Enter Title and save again; confirm the date on the saved record and its Edit form. Use Tab to reach the calendar,
Enter to open it, arrow keys to choose a day, and Escape to dismiss it and restore focus. Follow an ordinary Turbo
link away and use Back/Forward to check restored values, a single control, and no leftover overlay. Disable
JavaScript and repeat the save using the native input. Add focused request/system examples for these behaviors.

Complete the generated request spec's three attribute placeholders in `spec/requests/appointments_spec.rb`:

```ruby
let(:valid_attributes) { {title: "Planning", starts_on: "2026-10-15"} }
let(:invalid_attributes) { {title: "", starts_on: "2026-10-15"} }
let(:new_attributes) { {starts_on: "2026-10-16"} }
```

Replace its `skip("Add assertions for updated state")` with
`expect(appointment.starts_on).to eq(Date.new(2026, 10, 16))`. Replace the pending model example in
`spec/models/appointment_spec.rb` with:

```ruby
it "requires a title" do
  appointment = described_class.new(title: "")
  expect(appointment).not_to be_valid
  expect(appointment.errors[:title]).to include("can't be blank")
end
```

Add `spec/system/appointments_spec.rb`. These examples use the app's actual form and registry:

```ruby
require "rails_helper"

RSpec.describe "Appointments", type: :system do
  it "keeps the date after validation and saves the calendar selection" do
    visit new_appointment_path
    expect(page).to have_selector("button[aria-label='Open Starts on calendar']")
    fill_in "Starts on", with: Date.new(2026, 10, 15)
    click_button "Save appointment"
    expect(page).to have_link("Title can't be blank")
    expect(page).to have_field("Starts on", with: "2026-10-15")
    find("button[aria-label='Open Starts on calendar']").click
    find("[role=gridcell][data-day='2026-10-16'] button").click
    expect(page).to have_no_selector("[role=dialog]")
    fill_in "Title", with: "Planning"
    click_button "Save appointment"
    expect(page).to have_text("2026-10-16")
    click_link "Edit this appointment"
    expect(page).to have_field("Starts on", with: "2026-10-16")
  end

  it "saves the native date field when application JavaScript cannot load" do
    visit new_appointment_path
    browser = page.driver.browser
    browser.execute_cdp("Network.enable")
    browser.execute_cdp("Network.setBlockedURLs", urls: ["*application*.js*"])
    browser.navigate.to(page.current_url)
    expect(page).to have_no_selector("button[aria-label='Open Starts on calendar']")
    fill_in "Title", with: "Native input"
    fill_in "Starts on", with: Date.new(2026, 10, 20)
    browser.find_element(:css, "button[type=submit]").click
    expect(page).to have_text("Native input")
    expect(page).to have_text("2026-10-20")
  ensure
    browser&.execute_cdp("Network.setBlockedURLs", urls: [])
  end
end
```

The fallback example uses Selenium's click because the ordinary system helper waits for Turbo before a click;
that wait cannot finish when this example deliberately blocks the application script.

A first Reference picker follows the same registration shape with `ReferencePicker` and `IslandController`.
Use `shared/ui/reference_field` with a form builder, translated label/errors, and authorized option pairs as shown
under [Shared primitives](#shared-primitives). Its fallback is a Rails select. Keep option authorization in Rails.

A first `shared/ui/destroy` needs `ConfirmSubmit` imported and registered with the same boundary and
`IslandController`. Until it enhances, the ordinary Rails fallback submits deletion immediately, without a
confirmation dialog. Check both confirmation and fallback behavior when adding the first Delete control.

### Build and verify

For individual builds and checks, run:

```sh
npm run build
npm run build:css
npm run check
bundle exec erb_lint --lint-all
bundle exec rspec spec/models/appointment_spec.rb spec/requests/appointments_spec.rb spec/system/appointments_spec.rb
```

The [README checks](README.md#checks) cover the full suite and browser setup. Check initial load, Turbo
navigation/cache restoration, validation
errors, keyboard/focus, and the native fallback whenever a registered control changes.

Build through the real production pipeline and inspect its output:

```sh
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
wc -c < app/assets/builds/application.js
gzip -9c < app/assets/builds/application.js | wc -c
```

Inspect `public/assets/.manifest.json` for fingerprinted paths. In a production preview's browser Network panel,
confirm the application JS and CSS load successfully and exercise the same control journeys. The size commands
measure local bundle bytes and gzip compression, not HTTP transfer or browser speed. After local production
inspection, run `bin/rails assets:clobber` before returning to development so stale precompiled assets cannot mask
watcher output.

Use the pinned npm version from `package.json` and commit `package-lock.json` with dependency changes. Add or update
a package with `npm install PACKAGE@VERSION` (or `--save-dev` for a build tool), then review the lockfile and run the
asset checks. For copied shadcn components, follow [Updating components](#updating-components-and-checking-changes)
and update the source/version/license record in `licenses/ui-components.json`. Preserve the existing pipeline and
shared tokens when adapting new source.

## Reuse before adding

Read a related screen and the shared partials before introducing a new pattern. Basecoat's `btn`, `card`, `field`,
`input`, native `select.select`, `textarea`, `table`, `badge`, `alert`, and `empty` own the basic visual vocabulary.
Buttons use `data-variant` (`primary`, `outline`, `secondary`, `ghost`, `destructive`, `link`) and `data-size`
(`default`, `sm`, `xs`, `lg`, or an `icon` size). Omit the variant for a primary button. React calls that same
primary variant `default`. Use `sm` for adjacent collection actions and `default` for form/detail actions.

Choose the component's documented size and variant before adding overrides. A Tailwind spacing token is still a
custom component override when a stock preset already fits. Use layout utilities for placement and available
width; keep control styling in the component system. Review related usages for the same drift, while preserving
explicit shared native touch-target adaptations.

Scaffold indexes use one centered `card scaffold-card`, with a heading and authorized Add action in its header.
Default rows show the primary descriptor. Its link opens the record's details when that destination is authorized.
For selected properties, render the ordered label/value pairs as a compact `dl`. An association can
supply its own descriptor link or View action; preserve each destination's authorization and retain authorized text
when a destination is unavailable. Rows contain no nested mutation controls.

Keep shared index presentations in entity partials such as `credits/_list_item` and main show presentations in
`credits/_credit`. Reuse the list partial in associated collections when its fields, links, and actions match.
Different parent projections belong in `movies/_credit` or `people/_credit`, reused by that parent's preview and
full collection page. Compose lists with Rails collection rendering and pass meaningful strict locals. Put a stable
`dom_id` on each replaceable root, with a descriptive context prefix when a record appears more than once. Explicit
Turbo Stream responses can reuse those partials and IDs; this organization adds no automatic broadcasts.

In entity partials, use Tailwind container queries so a property grid stacks in a narrow card and expands when its
own container has room. Add `@container` to the ancestor and breakpoint variants to its descendants; the shared
`record-details` classes supply single-column spacing, not this responsive layout. If an
application adds whole-row links, muted labels and values need `foreground` on hover and keyboard focus to remain
readable against Basecoat's hover fill. Keep that state rule outside the component layer so it overrides utilities.

Details and forms use the same card width. A scalar descriptor already used as the detail title is not repeated.
The title has its own line; the action row below aligns the explicit collection destination (for example, All movies),
Edit, and Delete to the right, including wrapped lines on narrow screens. Native requests omit the collection link and
rely on client navigation. Other typed values start in one column, with muted labels above values and no per-property
dividers; entity partials may add columns with container queries. Associated collections occupy sibling cards with
`h2` headings. Empty states have no nested frame.

Keep record headings and toolbars within the card width. `shared/ui/back` truncates a long destination label while
retaining its full accessible name and hover title. A collection page can use `content-actions flex-nowrap` to keep
that shrinking destination beside Add; detail pages retain wrapping for their larger action groups.

Put `scaffold-form` on the form section to establish its Tailwind container. Form actions use the stock `lg` button
preset and stack at full width until the form reaches the `@md` container breakpoint (28rem), then form a natural-width
row. Cancel is a quiet action. This responds to the form's available width, including a sidebar or dialog.
Edit/Delete use matching ghost buttons with leading decorative Lucide icons. The confirmation action uses a standard
primary button with an explicit Delete label and initial focus on Cancel.

[The application stylesheet](app/assets/stylesheets/application.tailwind.css) owns page composition:
`app-shell`, `page-section`, `scaffold-card`, `page-header`, `page-heading`, `page-description`, `page-eyebrow`,
`content-list`, `content-narrow`, `content-detail`, `record-header`, `record-toolbar`, `record-list-body`,
`record-list`, `record-list-item`, `record-list-title`, `record-details`, `record-list-details`, `related-list`,
`collection-table`, `form-actions`, and `pagination`.
Use the shared patterns and stock theme tokens. Tables remain available when a developed screen needs comparable
columns; the scaffold default is a record list.

The shared header uses a shadcn Sheet below 64rem and a single horizontal navigation row above it. Rails renders
`shared/_main_navigation` once, including authorized links and CSRF-bearing forms; the ResponsiveNavigation island
displays that escaped HTML. Its HTML prop is a trusted Rails rendering seam, never an input for raw user markup.
The navigation contains no element IDs because its hidden fallback and responsive presentations can coexist.
Keep destinations and authorization in ERB. Base UI owns modal focus, Escape, outside dismissal, and scroll locking;
the existing island lifecycle cleans up before Turbo caches or replaces the page. Without JavaScript, the Rails
links remain available through a native details menu at narrow widths and an inline row on desktop. The collapsed
fallback reserves the same header height before enhancement and in Turbo snapshots. The header's unlayered layout
rules also apply when a list carries presentation utilities.

### Shared primitives

Shared strict-local partials live in [shared/ui](app/views/shared/ui):

- `page_heading(title:, description: nil, eyebrow: nil, hide_in_native: false)`.
- `empty_state(title:, description: nil, action_label: nil, action_path: nil)`.
- `field_errors(errors:, id: nil)` and `form_errors(errors:, field_ids:, title:, id:)`.
  The latter needs a stable form-scoped heading ID so repeated forms and Turbo morphs retain their accessible relationship.
- `reference_field(form:, attribute:, options:, label:, value:, required: false, disabled: false, errors: [], id: nil)`.
  Options must be flat Rails `[label, value]` pairs already authorized and loaded by the controller. Grouped
  options and per-option HTML attributes need a different composition; this picker rejects those shapes.
- `date_field` takes the same inputs except `options`, plus optional inclusive `min` and `max` dates. Use a Date or
  ISO date string; temporal objects format to their calendar date as Rails does. Literal values remain unchanged
  for validation responses. Bounds apply to both native and enhanced inputs, disable unavailable calendar days,
  and constrain month navigation; keep the corresponding Rails model validation authoritative. An out-of-range
  value stays editable while its calendar opens at the nearest allowed month. Pass an ordered range (`min <= max`);
  omitted bounds impose no date range.
- `back(url:, label:)` displays the passed destination label for browsers and omits it in Hotwire Native.
- `edit(url:, label:, variant: "ghost", size: "default")` owns the link and pencil icon; its default matches Delete.
- `destroy(url:, params: {}, label:, title:, description:, confirm_label:, cancel_label:, size:, disabled:)` has
  translated defaults for its optional copy and owns an ordinary Rails DELETE form. Pass authorized routes and
  any `return_to` through `params`. Register `ConfirmSubmit` as described under [Assets](#assets) for confirmation;
  the island submits that form after confirmation, while the native fallback submits immediately.

Use form builders for parameter names and translated labels/errors for copy. Namespace repeated forms, or supply
an explicit unique field ID, just as with normal Rails inputs. A cached form partial needs its namespace in the
cache key when rendered more than once. The React controls generate no queries and do not broaden option access.
Remote search for large collections needs its own authorized, paginated endpoint; do not pass an unbounded scope.

```erb
<%= form_with model: @record do |form| %>
  <%= render "shared/ui/reference_field", form: form, attribute: :category_id,
    options: @category_options, label: @record.class.human_attribute_name(:category),
    value: @record.category_id, required: true,
    errors: @record.errors.full_messages_for(:category) %>
  <%= form.button t("actions.save"), class: "btn" %>
<% end %>
```

## Feedback and notifications

Use `redirect_to ..., success: t(...)` for routine confirmations that are safe to miss. These opt in to a quiet
Sonner toast and have a visible Rails fallback without JavaScript. `notice` is persistent guidance, such as the
next step after requesting an email; `alert` is a persistent failure. Both render in normal page flow, or inside
the authentication form card. Keep actionable instructions out of transient messages. Successful sign-in/out
needs no extra announcement when the destination already makes the result clear.
Additional Rails flash keys render as persistent guidance in the notice region.

The layout renders `shared/flash` once, including both empty live regions. For a form card, set
`content_for :inline_flash, true` and always render `shared/flash`, `inline: true` inside that card, even without a
message. Do both together and outside conditional Turbo frames so the page retains exactly one pair of regions.

Keep validation messages beside their inputs and preserve submitted values. Use a summary for a longer form,
with an unboxed heading and list inside the form card. Pass `record.errors` and a `field_ids` hash that maps error
attributes to visible control IDs, such as `{title: form.field_id(:title), category: form.field_id(:category_id)}`.
The partial renders ordinary links to those controls; errors without a visible control remain plain text.
Fields still receive `full_messages_for`. Do not also report the same failure in a banner or toast.

The `form-errors` Stimulus action follows [GOV.UK's error-summary behavior][govuk-errors]: scroll the associated
label into view, then focus its control without scrolling again. It uses the browser's `labels` association,
including for enhanced controls. Labels need no IDs. Without JavaScript, the links target the native controls.

[govuk-errors]: https://design-system.service.gov.uk/components/error-summary/

`FlashToasts` uses the shared shadcn wrapper and semantic colors. Its `app-toaster` class avoids Basecoat's
unrelated `.toaster` pointer-event rule. Its controller records delivery on the island
so Turbo Back does not replay it, removes the delivered fallback, and uses the existing unmount cleanup.
Success toasts last five seconds; Sonner owns dismissal, focus/hover pausing, reduced motion, and polite live
announcements. Mobile offsets include the safe area. The UI still needs real native-client qualification.

Sonner 2.0.8 injects an unnonced stylesheet in its package entrypoint. The JS build omits that one injection and
Tailwind imports the package's exported stylesheet instead. The build rejects changed injection packaging; keep
the enforced CSP and recheck this seam when updating Sonner. No Next.js theme provider is used: the wrapper reads
the same semantic CSS variables as ERB.

## Error pages

The 404, 422, and 500 pages and the reusable 403 view share [`errors/error`](app/views/errors/_error.html.erb), with
required `code`, `title`, and `description` locals. Its centered status, explanation, and recovery action adapt
Shadcn Admin's [404][admin-404] and [500][admin-500] compositions. Copy stays translated and the action uses the stock
Basecoat button. The oversized status number is capped by the viewport width so native text scaling cannot clip its digits;
the descriptive heading and explanation keep their normal text scaling. The surrounding application layout
supplies branding and available navigation.

Render [`errors/forbidden`](app/views/errors/forbidden.html.erb) through the full application layout for denied HTML
actions. It supplies translated Access denied copy and the same recovery action. The handling controller owns
authorization, the 403 status, and responses to other formats.

Back to home is an ordinary Rails link that works without JavaScript or browser history. The error pages share no
React routing or state. HTTP status codes and format-specific responses remain the rendering controller's responsibility.
Keep the [MIT notice](licenses/shadcn-admin-MIT.txt) when reusing this composition.

[admin-404]: https://github.com/satnaing/shadcn-admin/blob/e16c87f213a5ba5e45964e9b67c792105ec74d26/src/features/errors/not-found-error.tsx
[admin-500]: https://github.com/satnaing/shadcn-admin/blob/e16c87f213a5ba5e45964e9b67c792105ec74d26/src/features/errors/general-error.tsx

## Theme and native presentation

[theme.css](app/assets/stylesheets/theme.css) contains the stock shadcn Zinc tokens shared by ERB and React.
Basecoat Vega and the checked-in shadcn components own their control colors, hover fills, and destructive variants.
Do not derive a web palette from native tint or background colors. Keep native client color
assets separate from web component tokens. A deliberate future web theme belongs in this one stylesheet, with
both light and dark states reviewed together. Inspect resolved colors in both states; a mode name alone does not
prove a usable palette. Do not recolor individual primitives to compensate for a palette.

The selected behavior is recorded in [ui_theme.rb](config/initializers/ui_theme.rb). Omitted Plan Appearance means
fixed `light`; `dark` fixes dark. Both render the selected class and attributes on the server and ignore the OS
and stored preferences. They carry no theme module, prepaint script, selector, controller, or OS listener.

`auto` follows the OS with a small prepaint script and live listener, without preference storage or a selector.
`toggle` offers Light / Dark / System, initially System. Manual choices persist only in this browser; System
removes the override and resumes OS-following. The native HTML select supplies keyboard and accessible control
behavior. CSS follows the OS when JavaScript is unavailable, and the selector stays disabled at System.
Denied or full storage leaves a working choice for the current document and its Turbo visits, without reload
persistence. Browser metadata follows the resolved palette; static errors and SVG icons follow the OS, and the
PNG/PWA manifest retain a light fallback. These static assets cannot read a browser preference.

Dynamic modes apply appearance before styles load and before Turbo renders a destination or cached page. The
selector stays permanent across Turbo visits and morphs. Keep
the CSP nonce on the prepaint script. Fixed light/dark keep both token palettes for later development. Changing
between fixed modes also requires matching metadata/icons/static-error colors. Adding a mode whose behavior was
omitted requires ordinary application work in the layout, theme scripts, controller/selector, and browser tests;
changing the initializer alone does not restore missing files. Keep that work on Tailwind/browser/Stimulus APIs.

Native requests use automatic appearance for `toggle`, without the browser selector or stored preference.
The emitted GapSet names the missing native preference control; browser selection does not control the native
shell. Fixed and automatic native choices retain their authored meaning. Keep native assets separate when a
rebrand includes them.

Native requests omit the web header. Keep `data-hotwire-native-app`, concise native titles, and the
`hotwire-native:` variant. Use `sr-only` for headings repeated in native navigation, and `hidden` only for redundant
branding/controls. Shared native rules provide at least 3rem touch targets and wrapping text buttons; the copied
React Button/Calendar have corresponding native-only sizing. WebKit's supported system-body font preserves Dynamic
Type scaling. These browser contracts do not prove actual iPhone or Android behavior; exercise native clients too.
At the default body size, the date adapter reduces native calendar side padding so all seven 3rem cells and both
navigation arrows fit a 360px viewport; wider browser calendars keep the upstream spacing.

The layout deliberately omits `viewport-fit=cover` and general CSS safe-area padding. Before adding either,
exercise both single-navigator and native-tab layouts in a composed Rails+iOS app. A repeatable Simulator UI test
must keep the first and last web controls visible beneath native navigation and tab bars, distinguishing missing
insets from duplicate top/bottom padding. Do not infer safe-area or Dynamic Island support from browser checks.

## One interaction owner

React owns the DOM inside an island and its portaled overlay. No Basecoat JavaScript is loaded. Keep ordinary
navigation, simple inputs, small enum selects, and Rails submissions outside React unless their behavior benefits
from an island. Do not attach another Basecoat/Stimulus widget to React-owned elements.

[IslandController](app/javascript/islands/IslandController.ts) extends the pinned Turbo Mount lifecycle only for
Rails fallback/submission needs. It keeps native controls usable until React commits; the render boundary restores
them and reports the error if enhancement fails. Exactly one native or enhanced control submits each parameter.
Required references retain native constraint validation. Changes update the serialized Turbo props, and native
fallback markup follows server morphs. Before caching or disconnecting, roots unmount so portals and scroll locks
cannot survive their owner. After a cached page morph, preserved controllers use Turbo Mount's idempotent mount
method to restore unchanged islands. Each root receives the initial document's CSP nonce through Base UI's CSPProvider.

ReferencePicker uses the Combobox input-inside-popup pattern with server-authorized options. Base UI renders its
single named, validatable input; the Rails fallback select is disabled after enhancement commits. The invalid event
opens the picker and focuses its trigger. Optional fields offer a translated None item. ConfirmSubmit explicitly
focuses Cancel and closes the controlled dialog before requesting its Rails form submission. Overlay animation and
transitions are disabled by an unlayered reduced-motion rule so state variants cannot override that preference.

Compose app behavior in [islands](app/javascript/islands). Keep reusable shadcn primitives in
[components/ui](app/javascript/components/ui). To add another island, use the existing boundary/controller pattern,
pass translated copy from Rails, and retain a meaningful native fallback. Do not add a React router or duplicate
Rails mutation endpoints merely to use another component.

The registered islands load eagerly with the application bundle. This keeps a single predictable mount path and avoids a
second loading state for the first interaction. Revisit code splitting when additional islands or measured startup
costs justify the extra loading lifecycle.
Measure this application's production bundle and actual load path before deciding whether splitting helps.

## Updating components and checking changes

The current set uses Basecoat 1.0.2, Turbo Mount 0.4.4, Base UI 1.8.0, and shadcn CLI 4.21.0's `base-vega` output.
[Source provenance](licenses/ui-components.json) records the captured registry URLs/hashes and local differences;
[licenses](licenses) retain redistribution notices. The ERB action icons copy the pinned Lucide 1.45.0 paths;
[their license](licenses/lucide-ISC-MIT.txt) also covers the matching React icons. The Button/Calendar native extensions,
formatting, and type-only imports are deliberate local changes. Two narrowly scoped Biome exceptions preserve upstream
InputGroup's noninteractive grouping/click-to-focus behavior; browser accessibility checks still apply.
Upstream primitives retain their original optional English defaults. When composing a new dialog or command
palette, supply translated copy rather than exposing those defaults; the current islands already do this.

[components.json](components.json) selects the matching style, zinc baseline, and Rails aliases. Inspect a component
with the pinned `npx --no-install shadcn add NAME --dry-run --view`, then add it deliberately with
`npx --no-install shadcn add NAME`. Inspect the changed files/dependencies before accepting them. The registry is
mutable; the checked-in source and npm lock are the build inputs. Builds and tests never fetch components.
Upstream shadcn Skills/MCP can assist island discovery; use this application's Rails boundaries for whole screens.

Run `npm run check`, `bundle exec erb_lint --lint-all`, focused RSpec examples, and affected system specs. Inspect
paired ERB/React controls at desktop and narrow widths in both themes, including open overlays. Exercise 422 values,
keyboard/focus, native fallback, failed enhancement, Turbo Back/Forward/Frame/Stream/morph, and deletion Cancel/Escape
before considering a widget complete. Shared layout specs and the [Assets example](#add-the-first-date-picker)
show focused checks; add browser examples for this application's actual forms. Broad widget adapter qualification
stays upstream in Core. Do not substitute
source class comparisons for rendered behavior.
