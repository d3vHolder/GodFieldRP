-- GodField/lib/Reporter.lua
-- Analytics. Opt-in only. No default endpoint is baked in — the operator
-- passes their own URL if they want it. Nothing is sent unless it is on.

local Reporter = {}
Reporter.__index = Reporter

local HS = game:GetService("HttpService")

local function findRequestFunc()
    if syn and syn.request then return syn.request end
    if fluxus and fluxus.request then return fluxus.request end
    if http and http.request then return http.request end
    if http_request then return http_request end
    if request then return request end
    return nil
end

function Reporter.new(cfg)
    local self = setmetatable({
        _url = cfg.url,
        _token = cfg.token,
        _product = cfg.product or "GodField",
        _disabled = false,
        _request = findRequestFunc(),
    }, Reporter)
    return self
end

function Reporter:_send(event, data)
    if self._disabled or not self._request or not self._url then return end
    local payload = {
        event    = event,
        product  = self._product,
        place    = tostring(game.PlaceId),
        universe = tostring(game.GameId),
        data     = data or {},
    }
    local ok, encoded = pcall(function() return HS:JSONEncode(payload) end)
    if not ok then return end
    task.spawn(function()
        pcall(self._request, {
            Url = self._url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-GodField-Token"] = self._token or "",
            },
            Body = encoded,
        })
    end)
end

function Reporter:windowCreated(data) self:_send("window_created", data) end
function Reporter:watchForKick(data) self:_send("watch_start", data) end
function Reporter:disable() self._disabled = true end

return Reporter