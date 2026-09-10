--[[───────────────────────────────────────────────────────────────
    💧 LIQUID HUB — one-file demo hub
    Paste this whole file into your executor, or upload it to GitHub
    and use the loadstring from README.md.
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
    Title     = "Liquid Hub",
    SubTitle  = "v2.0",
    ToggleKey = Enum.KeyCode.RightControl,
    Width     = 680,
    Height    = 440,
})

-- // TABS //--
local MainTab     = Window:CreateTab("Main", "💧")
local VisualsTab  = Window:CreateTab("Visuals", "👁")
local SettingsTab = Window:CreateTab("Settings", "⚙️")

-- // MAIN — left column //--
local farm = MainTab:CreateSection("Auto Farm", 1)
farm:CreateToggle("Enable Auto Farm", false, function(state)
    print("Auto Farm:", state)
end, "AutoFarm")

farm:CreateSlider("Farm Radius", 10, 500, 100, function(v)
    print("Radius:", v)
end, "FarmRadius", " studs")

local util = MainTab:CreateSection("Utilities", 1)
util:CreateButton("Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
end)
util:CreateKeybind("Rejoin Keybind", Enum.KeyCode.R, function()
    print("Rejoining...")
end, "RejoinKey")
util:CreateDropdown("Theme", { "Ocean", "Midnight", "Aqua", "Blood" }, "Ocean", function(choice)
    Window:SetTheme(choice)
end, "Theme")

-- // MAIN — right column //--
local targets = MainTab:CreateSection("Targets", 2)
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

-- // VISUALS //--
local esp = VisualsTab:CreateSection("ESP", 1)
esp:CreateToggle("Player ESP", false, function(state) print("ESP:", state) end, "PlayerESP")
esp:CreateColorPicker("ESP Color", Color3.fromRGB(59, 234, 255), function(c)
    print("ESP Color:", c)
end, "ESPColor")

-- // SETTINGS //--
local cfg = SettingsTab:CreateSection("Config", 1)
cfg:CreateButton("Save Config", function() Window:SaveConfig("default") end)
cfg:CreateButton("Load Config", function() Window:LoadConfig("default") end)
cfg:CreateTextbox("Webhook URL", "https://discord.com/api/webhooks/...", function(text)
    print("Webhook:", text)
end, "Webhook")

Window:Notify("Liquid Hub", "Loaded! Press RightCtrl to hide/show.", 5)
