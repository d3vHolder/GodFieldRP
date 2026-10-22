# GodField

A code-built, modular Roblox UI library. No CDN ScreenGui asset, no
`game:GetObjects`, no build-mismatch warnings, no baked-in analytics
endpoint. The entire interface is constructed from `Instance.new` in
`lib/Create.lua`; every element is a Lua table that owns one frame.

**Version:** 2.0.0
**Compatibility:** Roblox executors that expose `loadstring`, `getgenv`,
and (optionally) `request` / `http_request`. Studio works if
`GODFIELD_BASE` points at the local folder.

---

## 1. What GodField is

GodField is an independent UI library. It is not a fork or a rebrand of
any other project — every module is written from scratch against the
public Roblox `Instance` API. The public API shape (`CreateWindow`,
`CreateTab`, `CreateButton`, …) is deliberately kept familiar so a
script that used a similar library can migrate in minutes; see §6 for
the migration table.

What changed versus the common "asset-drop" UI pattern:

| Old pattern | GodField |
|---|---|
| `game:GetObjects("rbxassetid://…")` loads a ScreenGui from the CDN | `Instance.new` tree built in `lib/Create.lua` |
| Every UI tweak needs a new asset upload | Edit a Lua file, reload |
| Build-mismatch warning when asset and code disagree | No version negotiation, no warning |
| 2 400-line monolith in one `source.lua` | 22 modules, one responsibility each |
| Elements copy-paste 80-line Tween blocks | Element factory + shared `Util.tween` |
| Per-element `RenderStepped` loops leak on teardown | Single signal bus with `:sweep()` |
| `settings.rfld` with no schema version | `settings.json` with `__version` |
| Baked-in analytics collector and token | Zero default endpoint; opt-in only |

---

## 2. Installation

### Mode A — remote (recommended)

```lua
local GodField = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<user>/<repo>/<branch>/GodField/init.lua"
))()
```

`init.lua` derives its own base URL from `debug.info(1, "s")`, so every
module URL is resolved relative to it. Nothing else to configure.

If your executor strips `debug.info`, set the base explicitly before
loading:

```lua
getgenv().GODFIELD_BASE = "https://raw.githubusercontent.com/<user>/<repo>/<branch>/GodField/"
local GodField = loadstring(game:HttpGet(getgenv().GODFIELD_BASE .. "init.lua"))()
```

### Mode B — local (executor workspace)

Copy the whole `GodField/` folder into the executor's workspace root.
`init.lua` detects `readfile` and switches to `readfile(BASE .. path)`.
Load with:

```lua
local GodField = loadstring(readfile("GodField/init.lua"))()
```

### Mode C — single file

Ship only `build/godfield.lua`:

```lua
local GodField = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<user>/<repo>/<branch>/GodField/build/godfield.lua"
))()
```

Trade-offs: every module is in memory from the start (≈40 KB larger than
`init.lua` + tree), no lazy loading, but one HTTP request and one
`loadstring`.

---

## 3. Quickstart

```lua
local GodField = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<user>/<repo>/<branch>/GodField/init.lua"
))()

local Window = GodField:CreateWindow({
    Name       = "My Hub",
    Theme      = "Default",
    FolderName = "MyHub",
    ConfigFile = true,
})

local Tab = Window:CreateTab("Main", "home")

Tab:CreateButton({
    Name = "Click me",
    Callback = function()
        print("clicked")
    end,
})

Tab:CreateToggle({
    Name = "Enable feature",
    Flag = "feature.enabled",
    CurrentValue = false,
    Callback = function(on)
        print("feature", on)
    end,
})

Tab:CreateSlider({
    Name = "Speed",
    Flag = "feature.speed",
    Range = { 16, 200 },
    Increment = 1,
    CurrentValue = 50,
    Suffix = "studs/s",
    Callback = function(v)
        print("speed", v)
    end,
})

-- Long task with a progress modal
local task = Window:NotifyProgress({ Title = "Loading assets" })
task:Update(0.25, "25% — downloading")
task:Update(0.75, "75% — applying")
task:Done("Ready")

-- Confirm dialog before a destructive action
if Window:Confirm({ Title = "Reset?", Body = "This will clear your settings." }) then
    print("confirmed")
end
```

---

## 4. API reference

### `GodField:CreateWindow(settings) → Window`

| field | type | default | meaning |
|---|---|---|---|
| `Name` | string | `"GodField"` | Window title |
| `Theme` | string \| table | `"Default"` | Named theme (`Default`, `Ocean`, `Amethyst`, `Light`) or a token table |
| `FolderName` | string | `"GodField"` | Disk root for this window's config |
| `ConfigFile` | boolean | `true` | Whether `settings.json` is written |
| `DisableConfig` | boolean | `false` | If true, `Store:load()` is never called — no config is read |
| `ScriptID` | string | nil | Developer-assigned ID, forwarded to the reporter if analytics is on |
| `VerificationToken` | string | nil | Optional token, forwarded to the reporter |

Returns a `Window` object.

### `Window`

| method | signature | notes |
|---|---|---|
| `:CreateTab` | `(name, icon?, ext?) → Tab` | `ext=true` hides the tab button (used internally) |
| `:CreateTabGroup` | `(name) → table` | Named group handle; purely organisational |
| `:ModifyTheme` | `(nameOrTable)` | Fires `theme:changed`; every element re-reads tokens |
| `:SetVisible` | `(bool)` | Fires `window:shown` / `window:hidden` |
| `:IsVisible` | `() → bool` | |
| `:NotifyProgress` | `(opts) → handle` | Returns `{ Update(pct, text?), Done(text?), Fail(text?) }` |
| `:Confirm` | `(opts) → bool` | Blocking modal yes/no. `{ Title, Body, ConfirmText?, CancelText? }` |
| `:Prompt` | `(opts) → string?` | Blocking modal text input. `{ Title, Placeholder?, Default? }` |
| `:OnKeybind` | `(id, key, cb)` | Named hotkey registry. Re-registering the same `id` replaces the old binding |
| `:Bind` | `(storeKey, getter)` | Registers a reactive getter into the store; fires `setting:changed` on updates |
| `:CreateConfigManager` | `() → Config` | Named save slots; see `Config` below |
| `:LoadConfiguration` / `:SaveConfiguration` | `()` | Manual config control |
| `:Destroy` | `()` | Tears down the GUI, sweeps signal connections, disconnects hotkeys |

### `Tab`

| method | signature |
|---|---|
| `:CreateSearch` | `() → Frame` | Adds a filter box at the top of the tab; filters elements by name |
| `:CreateButton` | `(opts)` — `{ Name, Callback, Flag? }` |
| `:CreateToggle` | `(opts)` — `{ Name, CurrentValue?, Callback, Flag? }` |
| `:CreateSlider` | `(opts)` — `{ Name, Range, Increment, CurrentValue?, Suffix?, Callback, Flag? }` |
| `:CreateInput` | `(opts)` — `{ Name, CurrentValue?, Placeholder?, RemoveTextAfterFocusLost?, Callback, Flag? }` |
| `:CreateKeybind` | `(opts)` — `{ Name, CurrentKeybind?, HoldToInteract?, Callback, Flag? }` |
| `:CreateDropdown` | `(opts)` — `{ Name, Options, CurrentOption?, MultipleOptions?, Callback, Flag? }` |
| `:CreateColorPicker` | `(opts)` — `{ Name, Color?, Callback, Flag? }` |
| `:CreateLabel` | `(text) → handle` |
| `:CreateParagraph` | `(opts)` — `{ Title, Content }` |
| `:CreateSection` | `(name) → handle` |
| `:CreateDivider` | `() → handle` |
| `:SetVisible` / `:IsVisible` | `(bool) / () → bool` |
| `:Destroy` | `()` — destroys every element, the search bar, the button, the page |

### Element handles

Every element returns the same handle shape:

| method | notes |
|---|---|
| `:Set(value)` | Programmatic update. Fires the element's `Callback` |
| `:get()` | Returns the current value — used by the store during config flush |
| `:SetVisible(bool)` | Show/hide without destroying |
| `:SetEnabled(bool)` | Gray out + block callbacks |
| `:SetDescription(text)` | Tooltip / subtext under the element |
| `:Destroy()` | Removes the frame and disconnects its listeners |

### `Config` (from `Window:CreateConfigManager()`)

| method | notes |
|---|---|
| `:Save(name)` | Snapshot the store's current data into `GodField/Configs/<WindowName>/<name>.json` |
| `:Load(name)` | Apply a saved snapshot, firing `config:loaded` |
| `:List()` | Names of all saved snapshots |
| `:Delete(name)` | Remove a snapshot |

### Flags and config

Every element accepts an optional `Flag` string. When `Window.settings.ConfigFile`
is `true`, the store auto-registers the element and writes its `:get()`
value into `settings.json` on `Destroy` or explicit flush. On reload, the
saved value is applied to the element before `Callback` fires.

Naming convention: `scope.name`, e.g. `feature.enabled`, `aim.fov`.
Elements without a `Flag` are not persisted.

---

## 5. Architecture

### Tree

```
GodField/
├── init.lua                 entry point
├── manifest.json            optional integrity map
├── README.md
├── DOC.md
├── lib/
│   ├── Util.lua             tween, sanitize, encode/decode, debounce
│   ├── Signals.lua          signal bus with sweep
│   ├── Store.lua            versioned config + flag registry
│   ├── Theme.lua            token tables
│   ├── Create.lua           ScreenGui construction, modals, hotkeys, bind
│   ├── Icons.lua            Lucide sheet from Rayfield's pinned commit
│   ├── Config.lua           named save slots
│   └── Reporter.lua         opt-in analytics (no default endpoint)
├── ui/
│   ├── Window.lua           public Window wrapper
│   ├── Tab.lua              every element factory, inline
│   └── Section.lua          section handle
├── elements/                one-line forwarders per element type
│   ├── init.lua
│   ├── Button.lua … Divider.lua
├── tools/
│   └── bundle.lua           build script — not shipped to users
└── build/
    ├── godfield.lua         single-file build
    └── godfield.min.lua     comment-stripped variant
```

### Load order (enforced by `init.lua`)

```
Util → Signals → Store → Theme → Icons → Create → Window → Tab
→ Section → elements/init → Config → Reporter
```

Each module is a function that takes its dependencies as an argument and
returns itself. No `require`, no cycles.

### Signal contract

Defined on the window's bus in `lib/Create.lua`, fired everywhere:

| signal | payload | when |
|---|---|---|
| `theme:changed` | `theme` table | `Window:ModifyTheme` |
| `tab:changed` | `name` | tab click |
| `element:changed` | `{ element, value }` | any element `:Set` or user interaction |
| `window:shown` / `window:hidden` | `bool` | `Window:SetVisible` |
| `window:destroyed` | — | `Window:Destroy` |
| `modal:open` / `modal:close` | `frame` | Confirm / Prompt / Progress |
| `config:loaded` | `data` | `Store:load` / `Config:Load` |
| `setting:changed` | `{ scope, name, value, overridden? }` | `Store:set` / `Store:override` |

### Which layer does what

- **`lib/`** — no `ScreenGui` references. Pure logic.
- **`ui/`** — builds frames, composes elements, owns the signal bus.
- **`elements/`** — one-line forwarders so a host can override a single
  element's visuals without touching `ui/Tab.lua`.
- **`tools/`** — release-side build script. Never fetched at runtime.
- **`build/`** — generated distributables. Never touched by the tree loader.

### Building the single-file release

`build/godfield.lua` is generated. Do not edit it by hand — any change is
lost on the next release. To rebuild:

```sh
cd GodField
lua tools/bundle.lua
```

`tools/bundle.lua` reads every module in `ORDER`, inlines each body into
`EMBEDDED[<path>]`, and appends a `fetch()` loader identical in behaviour
to `init.lua`'s URL fetcher. The emitted file is a drop-in replacement
for `init.lua` in Mode C.

---

## 6. Migration from a v1-style asset-drop library

The API shape is preserved. Rename only what changed on disk and in
`getgenv()` keys:

| Old identifier | GodField identifier |
|---|---|
| `Rayfield:CreateWindow` | `GodField:CreateWindow` |
| `Rayfield:Notify` | `GodField:NotifyProgress` / `GodField:Confirm` / `GodField:Prompt` (see §4) |
| `Rayfield:Destroy` | `GodField:Destroy` |
| `Rayfield/Configurations/` | `GodField/Configurations/` (via `Store:setRoot`) |
| `Rayfield/settings.rfld` | `GodField/settings.json` |
| `RAYFIELD_ANALYTICS` | `GODFIELD_ANALYTICS` |
| `DISABLE_RAYFIELD_REQUESTS` | `DISABLE_GODFIELD_REQUESTS` |
| `RAYFIELD_ASSET_ID` | `GODFIELD_ASSET_ID` (unused; kept for parity) |
| `RAYFIELD_SECURE` | `GODFIELD_SECURE` (unused; kept for parity) |

An old `Rayfield:Notify({ Title, Content, Image, Duration })` call maps to
nothing on GodField — that toast surface has no equivalent, and GodField
does not install one. Use `print` or a custom notification component
built on `Window:NotifyProgress` if a toast is needed.

Elements themselves are unchanged: `CreateButton`, `CreateToggle`,
`CreateSlider`, `CreateInput`, `CreateKeybind`, `CreateDropdown`,
`CreateColorPicker`, `CreateLabel`, `CreateParagraph`, `CreateSection`,
`CreateDivider` all take the same settings tables.

---

## 7. Privacy

**No analytics endpoint is baked in.**

`lib/Reporter.lua` is a generic POST client — it does nothing unless a
caller constructs one with a URL:

```lua
local Reporter = GodField.Reporter.new({
    url     = "https://your-collector.example/ingest",
    token   = "your-token",
    product = "MyHub",
})
Reporter:windowCreated({ script_name = "MyHub" })
```

If you never construct one, no reporter exists, nothing is sent, and the
module is never even fetched (`init.lua` does not pre-load it — see
§5 load order). There is no vendor collector, no baked-in token, no
uptime ping, no automatic kick reporting.

Config files written to disk are entirely local:

- `GodField/settings.json` — this window's saved flags
- `GodField/Configs/<Window>/<name>.json` — named snapshots
- `GodField/Assets/lucide-48.png` — cached icon sprite

None of these leave the user's machine.

### Environment variables

| variable | meaning |
|---|---|
| `GODFIELD_BASE` | Override the base URL `init.lua` derives from `debug.info` |
| `GODFIELD_ANALYTICS` | Ignored in 2.0.0 — Reporter has no built-in path, so there is nothing to gate |
| `DISABLE_GODFIELD_REQUESTS` | Ignored in 2.0.0 — no requests are made unless the caller constructs a Reporter |
| `GODFIELD_ASSET_ID` | Ignored in 2.0.0 — the ScreenGui is code-built, not asset-driven |
| `GODFIELD_SECURE` | Ignored in 2.0.0 — no silent-mode toggle exists |

The last four exist only so a v1 script that sets them does not error. They
have no effect.

---

## 8. Troubleshooting

| symptom | cause | fix |
|---|---|---|
| `GodField: could not load lib/Util.lua` | `init.lua` cannot derive its own URL | Set `getgenv().GODFIELD_BASE` before loading |
| `GodField.Icons: sprite download failed` | Executor has no `writefile`/`getcustomasset`, or the pinned Rayfield commit no longer serves `assets/lucide.png` | Either use numeric icon IDs instead of Lucide names, or bump `COMMIT` in `lib/Icons.lua` to a live commit |
| Window renders but tabs do not switch | `UIPageLayout` not supported on this executor | Not fixable without a different layout implementation; report with the executor name |
| `settings.json` never written | Executor has no `writefile` | Expected — config is best-effort, and the library degrades to in-memory only |
| Elements missing after adding a `Flag` | `settings.json` from an older version has a conflicting type | Delete `GodField/settings.json` and reload |