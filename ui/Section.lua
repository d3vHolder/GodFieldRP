-- GodField/ui/Section.lua
-- Sections are visual groupings; Tab:CreateSection already builds one.
-- This module exists so callers can hold a section handle across API
-- changes without re-importing.

local Section = {}
Section.__index = Section

function Section.new(name, tab)
    return setmetatable({ name = name, tab = tab }, Section)
end

function Section:Set(name)
    self.name = name
end

return Section