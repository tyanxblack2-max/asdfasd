--[[───────────────────────────────────────────────────────────────
    💧 LIQUID HUB — one-file loader
    Paste this whole file into your executor, or upload it to GitHub
    and use the loadstring below.
───────────────────────────────────────────────────────────────]]

local SOURCE_URL = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Source.lua"

local ok, Liquid = pcall(function()
    return loadstring(game:HttpGet(SOURCE_URL))()
end)

if not ok or type(Liquid) ~= "table" then
    warn("[Liquid Hub] Library failed to load: " .. tostring(Liquid))
    return
end

local Window = Liquid:CreateWindow({
    Title    = "Liquid Hub",
    SubTitle = "v2.0",
    ToggleKey = Enum.KeyCode.RightControl,
})

-- // MAIN //--
local Main = Window:CreateTab("Main", "💧")

local farm = Main:CreateSection("Auto Farm", 1)
farm:CreateToggle("Enable Auto Farm", false, function(state)
    print("Auto Farm:", state)
end, "AutoFarm")

farm:CreateSlider("Farm Radius", 10, 500, 100, function(v)
    print("Radius:", v)
end, "FarmRadius", " studs")

local targets = Main:CreateSection("Targets", 2)
local creatures = {
    "Bluebird", "Budling", "Chirpa", "Doragon", "Emberling",
    "Fluffle", "Glimmerwing", "Hoppity", "Ignis", "Jellyfin",
}
targets:CreateSearchDropdown("Target Creature", creatures, nil, function(choice)
    print("Targeting:", choice)
end, "TargetCreature")
targets:CreateMultiDropdown("Multi Targets", creatures, { "Bluebird" }, function(list)
    print("Multi:", table.concat(list, ", "))
end, "MultiTargets")

-- // SETTINGS //--
local Settings = Window:CreateTab("Settings", "⚙️")
local cfg = Settings:CreateSection("Config", 1)
cfg:CreateButton("Save Config", function() Window:SaveConfig("default") end)
cfg:CreateButton("Load Config", function() Window:LoadConfig("default") end)
cfg:CreateDropdown("Theme", { "Ocean", "Midnight", "Aqua", "Blood" }, "Ocean", function(choice)
    Window:SetTheme(choice)
end, "Theme")

Window:Notify("Liquid Hub", "Loaded successfully — press RightCtrl to hide/show", 5)
