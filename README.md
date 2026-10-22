# GodField

A code-built Roblox UI library. No CDN ScreenGui asset, no `game:GetObjects`,
no build-mismatch warnings, no baked-in analytics endpoint.

- Every window is constructed from `Instance.new`.
- Every element is a small Lua module.
- Every config file is versioned.

**Version:** 2.0.0

## Load

Remote (recommended):

```lua
local GodField = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d3vHolder/GodFieldRP/main/init.lua"
))()
```

Single-file:

```lua
local GodField = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d3vHolder/GodFieldRP/main/build/godfield.lua"
))()
```

## Use

```lua
local Window = GodField:CreateWindow({
    Name       = "My Hub",
    Theme      = "Default",
    FolderName = "MyHub",
})

local Tab = Window:CreateTab("Main", "home")

Tab:CreateButton({
    Name = "Click me",
    Callback = function() print("clicked") end,
})

Tab:CreateToggle({
    Name = "Feature",
    Flag = "feature.enabled",
    Callback = function(on) print(on) end,
})
```

## Everything documented

See [`DOC.md`](DOC.md) for:

- Full API reference for `Window`, `Tab`, every element, and `Config`
- Architecture and load order
- Migration table from older UI libraries
- Privacy: no default analytics endpoint, opt-in only

## Structure

```
GodFieldRP/
├── init.lua         ← what you loadstring
├── DOC.md
├── README.md
├── manifest.json
├── lib/             ← logic (no ScreenGui references)
├── ui/              ← window, tab, section
├── elements/        ← one file per element type
├── tools/           ← build script (not shipped to users)
└── build/           ← single-file distributables
```

## Rebuilding `build/`

```sh
cd GodFieldRP
lua tools/bundle.lua
```

Emits `build/godfield.lua` and `build/godfield.min.lua`.

## Requirements

A Roblox executor that exposes `loadstring` and `getgenv`. `writefile`,
`readfile`, `makefolder`, and `getcustomasset` are optional — the library
degrades gracefully without them (config saving and icon rendering are
disabled, everything else works).

## License

Add a `LICENSE` file of your choice to the repo root. The code ships
without one; pick MIT, Apache-2.0, or whatever fits.
