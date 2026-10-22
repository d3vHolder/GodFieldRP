# GodField

A code-built Roblox UI library. No CDN asset, no `game:GetObjects`, no
build-mismatch warnings, no baked-in analytics endpoint.

- Every window is constructed from `Instance.new`.
- Every element is a small Lua module.
- Every config file is versioned.

## Load

Remote (recommended):

local GodField = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-org/GodField/main/build/godfield.lua"))()
