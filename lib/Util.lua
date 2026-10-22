-- GodField/lib/Util.lua
local Util = {}

local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")

function Util.service(name)
    local s = game:GetService(name)
    return if cloneref then cloneref(s) else s
end

function Util.tween(inst, props, dur, style, dir)
    return TweenService:Create(
        inst,
        TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Exponential, dir or Enum.EasingDirection.Out),
        props
    )
end

function Util.tweenPlay(inst, props, dur, style, dir)
    local t = Util.tween(inst, props, dur, style, dir)
    t:Play()
    return t
end

function Util.packColor(c)
    return {
        R = math.floor(c.R * 255 + 0.5),
        G = math.floor(c.G * 255 + 0.5),
        B = math.floor(c.B * 255 + 0.5),
    }
end

function Util.unpackColor(t)
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end

function Util.sanitizeFolder(value)
    local text = string.gsub(string.gsub(tostring(value), "\\", "/"), "[:%c]", "")
    local prev
    repeat prev = text; text = string.gsub(text, "%.%.", "") until text == prev
    text = string.gsub(text, "/+", "/")
    return (string.gsub(text, "^/+", ""))
end

function Util.sanitizeFile(value)
    local text = string.gsub(tostring(value), "[/\\%c]", "")
    local prev
    repeat prev = text; text = string.gsub(text, "%.%.", "") until text == prev
    return text
end

function Util.ensureFolder(path)
    if isfolder and not isfolder(path) then pcall(makefolder, path) end
end

function Util.callSafe(fn, ...)
    if not fn then return false end
    local ok, res = pcall(fn, ...)
    if not ok then warn("GodField | call failed: " .. tostring(res)) end
    return ok and res or false
end

function Util.encode(tbl)
    local ok, s = pcall(function() return HttpService:JSONEncode(tbl) end)
    return ok and s or nil
end

function Util.decode(str)
    local ok, t = pcall(function() return HttpService:JSONDecode(str) end)
    return ok and t or nil
end

-- Deep-copy for config snapshots.
function Util.deepcopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Util.deepcopy(v) end
    return out
end

-- Debounce wrapper: returns a function that delays N ms before firing.
function Util.debounce(fn, ms)
    local last = 0
    return function(...)
        local now = os.clock() * 1000
        if now - last < (ms or 100) then return end
        last = now
        return fn(...)
    end
end

return Util