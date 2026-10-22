-- GodField/lib/Theme.lua
local Theme = {}

Theme.Default = {
    name = "Default",
    tokens = {
        text             = Color3.fromRGB(240, 240, 240),
        background       = Color3.fromRGB(25, 25, 25),
        topbar           = Color3.fromRGB(34, 34, 34),
        shadow           = Color3.fromRGB(20, 20, 20),
        tabBackground    = Color3.fromRGB(80, 80, 80),
        tabStroke        = Color3.fromRGB(85, 85, 85),
        tabSelected      = Color3.fromRGB(210, 210, 210),
        tabText          = Color3.fromRGB(240, 240, 240),
        tabTextSelected  = Color3.fromRGB(50, 50, 50),
        element          = Color3.fromRGB(35, 35, 35),
        elementHover     = Color3.fromRGB(40, 40, 40),
        elementStroke    = Color3.fromRGB(50, 50, 50),
        secondary        = Color3.fromRGB(25, 25, 25),
        secondaryStroke  = Color3.fromRGB(40, 40, 40),
        input            = Color3.fromRGB(30, 30, 30),
        inputStroke      = Color3.fromRGB(65, 65, 65),
        slider           = Color3.fromRGB(50, 138, 220),
        sliderProgress   = Color3.fromRGB(50, 138, 220),
        toggleOn         = Color3.fromRGB(0, 146, 214),
        toggleOff        = Color3.fromRGB(100, 100, 100),
        dropdownSelected   = Color3.fromRGB(40, 40, 40),
        dropdownUnselected = Color3.fromRGB(30, 30, 30),
        placeholder      = Color3.fromRGB(178, 178, 178),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(50, 138, 220),
    },
}

Theme.Ocean = {
    name = "Ocean",
    tokens = {
        text             = Color3.fromRGB(230, 240, 240),
        background       = Color3.fromRGB(20, 30, 30),
        topbar           = Color3.fromRGB(25, 40, 40),
        shadow           = Color3.fromRGB(15, 20, 20),
        tabBackground    = Color3.fromRGB(40, 60, 60),
        tabStroke        = Color3.fromRGB(50, 70, 70),
        tabSelected      = Color3.fromRGB(100, 180, 180),
        tabText          = Color3.fromRGB(210, 230, 230),
        tabTextSelected  = Color3.fromRGB(20, 50, 50),
        element          = Color3.fromRGB(30, 50, 50),
        elementHover     = Color3.fromRGB(40, 60, 60),
        elementStroke    = Color3.fromRGB(45, 70, 70),
        secondary        = Color3.fromRGB(30, 45, 45),
        secondaryStroke  = Color3.fromRGB(40, 65, 65),
        input            = Color3.fromRGB(30, 50, 50),
        inputStroke      = Color3.fromRGB(50, 70, 70),
        slider           = Color3.fromRGB(0, 110, 110),
        sliderProgress   = Color3.fromRGB(0, 140, 140),
        toggleOn         = Color3.fromRGB(0, 130, 130),
        toggleOff        = Color3.fromRGB(70, 90, 90),
        dropdownSelected   = Color3.fromRGB(30, 60, 60),
        dropdownUnselected = Color3.fromRGB(25, 40, 40),
        placeholder      = Color3.fromRGB(140, 160, 160),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(0, 140, 140),
    },
}

Theme.Amethyst = {
    name = "Amethyst",
    tokens = {
        text             = Color3.fromRGB(240, 240, 240),
        background       = Color3.fromRGB(30, 20, 40),
        topbar           = Color3.fromRGB(40, 25, 50),
        shadow           = Color3.fromRGB(20, 15, 30),
        tabBackground    = Color3.fromRGB(60, 40, 80),
        tabStroke        = Color3.fromRGB(70, 45, 90),
        tabSelected      = Color3.fromRGB(180, 140, 200),
        tabText          = Color3.fromRGB(230, 230, 240),
        tabTextSelected  = Color3.fromRGB(50, 20, 50),
        element          = Color3.fromRGB(45, 30, 60),
        elementHover     = Color3.fromRGB(50, 35, 70),
        elementStroke    = Color3.fromRGB(70, 50, 85),
        secondary        = Color3.fromRGB(40, 30, 55),
        secondaryStroke  = Color3.fromRGB(65, 45, 80),
        input            = Color3.fromRGB(45, 30, 60),
        inputStroke      = Color3.fromRGB(80, 50, 110),
        slider           = Color3.fromRGB(100, 60, 150),
        sliderProgress   = Color3.fromRGB(130, 80, 180),
        toggleOn         = Color3.fromRGB(120, 60, 150),
        toggleOff        = Color3.fromRGB(94, 47, 117),
        dropdownSelected   = Color3.fromRGB(50, 35, 70),
        dropdownUnselected = Color3.fromRGB(35, 25, 50),
        placeholder      = Color3.fromRGB(178, 150, 200),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(130, 80, 180),
    },
}

Theme.Light = {
    name = "Light",
    tokens = {
        text             = Color3.fromRGB(40, 40, 40),
        background       = Color3.fromRGB(245, 245, 245),
        topbar           = Color3.fromRGB(230, 230, 230),
        shadow           = Color3.fromRGB(200, 200, 200),
        tabBackground    = Color3.fromRGB(235, 235, 235),
        tabStroke        = Color3.fromRGB(215, 215, 215),
        tabSelected      = Color3.fromRGB(255, 255, 255),
        tabText          = Color3.fromRGB(80, 80, 80),
        tabTextSelected  = Color3.fromRGB(0, 0, 0),
        element          = Color3.fromRGB(240, 240, 240),
        elementHover     = Color3.fromRGB(225, 225, 225),
        elementStroke    = Color3.fromRGB(210, 210, 210),
        secondary        = Color3.fromRGB(235, 235, 235),
        secondaryStroke  = Color3.fromRGB(210, 210, 210),
        input            = Color3.fromRGB(240, 240, 240),
        inputStroke      = Color3.fromRGB(180, 180, 180),
        slider           = Color3.fromRGB(150, 180, 220),
        sliderProgress   = Color3.fromRGB(100, 150, 200),
        toggleOn         = Color3.fromRGB(0, 146, 214),
        toggleOff        = Color3.fromRGB(150, 150, 150),
        dropdownSelected   = Color3.fromRGB(230, 230, 230),
        dropdownUnselected = Color3.fromRGB(220, 220, 220),
        placeholder      = Color3.fromRGB(140, 140, 140),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(100, 150, 200),
    },
}

function Theme:get(name)
    if type(name) == "table" then return name end
    local found = Theme[name]
    if not found then
        warn("GodField.Theme: unknown theme " .. tostring(name) .. " — using Default")
        return Theme.Default
    end
    return found
end

return Theme