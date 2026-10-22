-- GodField/lib/Icons.lua
-- Lucide icon sheet access. Fetches the sprite + generated name→coords map
-- from the Rayfield repo (pinned commit), caches the sprite into
-- GodField/Assets/, and resolves names via getcustomasset().
--
-- No Rayfield code runs here — only the two static asset URLs are consumed:
--   * the sprite PNG (icons packed in a grid)
--   * icons.lua  (the generated lookup table that maps name → grid coords)

local Icons = {}
Icons.__index = Icons

local FOLDER     = "GodField/Assets"
local SPRITE_NAME = "lucide-48.png"

-- Pinned commit rather than a branch, so a push to Rayfield's main branch
-- cannot change the icon set under a running script. Bump to ship a newer
-- sheet.
local COMMIT = "3ef72398fb4c8ba6fd1801e98704991d3cc9cbc2"
local REPO   = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/" .. COMMIT .. "/"

local SPRITE_URL = REPO .. "assets/lucide.png"
local MAP_URL    = REPO .. "icons.lua"

local _map, _loaded

local function ensure(p)
    if isfolder and not isfolder(p) then pcall(makefolder, p) end
end

local function fetchSprite()
    if not (writefile and readfile and getcustomasset) then return nil end
    ensure(FOLDER)
    local path = FOLDER .. "/" .. SPRITE_NAME
    if not (isfile and isfile(path)) then
        local ok, body = pcall(function() return game:HttpGet(SPRITE_URL) end)
        if not ok or #body == 0 then
            warn("GodField.Icons: sprite download failed")
            return nil
        end
        pcall(writefile, path, body)
    end
    local ok, uri = pcall(getcustomasset, path)
    return ok and uri or nil
end

local function fetchMap()
    local ok, raw = pcall(function() return game:HttpGet(MAP_URL) end)
    if not ok or #raw == 0 then
        warn("GodField.Icons: map download failed")
        return nil
    end
    local ok2, tbl = pcall(function() return (loadstring(raw) :: any)() end)
    if not ok2 or type(tbl) ~= "table" then
        warn("GodField.Icons: map body did not return a table")
        return nil
    end
    return tbl
end

function Icons:load()
    if _loaded then return _map end
    _loaded = true

    local sheet = fetchSprite()
    local tbl   = fetchMap()

    if not sheet or not tbl then
        _map = {}
        return _map
    end

    tbl.__sheet = sheet
    _map = tbl
    return _map
end

function Icons:get(name)
    if not _map then self:load() end
    name = string.lower(tostring(name or ""))
    local sized = _map and _map["48px"]
    local entry = sized and sized[name]
    if not entry then return nil end
    return {
        id         = _map.__sheet,
        rectSize   = Vector2.new(entry[2][1], entry[2][2]),
        rectOffset = Vector2.new(entry[3][1], entry[3][2]),
    }
end

return Icons