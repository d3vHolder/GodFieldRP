-- GodField/lib/Signals.lua
local Signals = {}
Signals.__index = Signals

local Signal = {}
Signal.__index = Signal

function Signals.new()
    return setmetatable({ _signals = {}, _conns = {} }, Signals)
end

function Signals:define(name)
    local s = setmetatable({ _handlers = {}, _next = 0 }, Signal)
    self._signals[name] = s
    return s
end

function Signals:get(name) return self._signals[name] end

function Signals:fire(name, ...)
    local s = self._signals[name]
    if not s then return 0 end
    return s:_fire(...)
end

function Signals:connect(name, fn)
    local s = self._signals[name]
    if not s then error("GodField.Signals: unknown signal " .. name, 2) end
    local handle = s:_connect(fn)
    table.insert(self._conns, handle)
    return handle
end

function Signals:sweep()
    for _, c in ipairs(self._conns) do pcall(c.Disconnect, c) end
    table.clear(self._conns)
end

function Signal:_connect(fn)
    self._next += 1
    local id = self._next
    self._handlers[id] = fn
    return { Disconnect = function() self._handlers[id] = nil end }
end

function Signal:_fire(...)
    local args = { ... }
    local n = 0
    for _, fn in pairs(self._handlers) do
        n += 1
        local ok, err = pcall(fn, table.unpack(args))
        if not ok then warn("GodField.Signal | handler error: " .. tostring(err)) end
    end
    return n
end

return Signals