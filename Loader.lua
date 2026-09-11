--[[───────────────────────────────────────────────────────────────
    💧 LIQUID HUB — loader v2.3 (self-diagnosing)

    What changed vs v2.1:
      • waits for the player to exist (running too early killed everything)
      • downloads with a cache-busting parameter + jsDelivr mirror
        (stale cached copies could be served as the "current" library)
      • EVERY failure (download / compile / library / window) now shows a
        red on-screen box with the exact error — no more silent nothing
───────────────────────────────────────────────────────────────]]

local VERSION = "v2.3"
local SOURCES = {
    "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Source.lua",
    "https://cdn.jsdelivr.net/gh/tyanxblack2-max/asdfasd@main/Source.lua",
}

print("[Liquid Hub] Loading " .. VERSION .. " ...")

-- // Wait for the player: executing before spawn breaks everything below //--
local Players = game:GetService("Players")
local waited = 0
while not Players.LocalPlayer and waited < 10 do
    task.wait(0.1)
    waited = waited + 0.1
end

-- // Visible error box: warn() alone looks like "nothing happened" //--
local function showLoaderError(msg)
    warn("[Liquid Hub] " .. msg)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "LiquidHubLoaderError"
        gui.ResetOnSpawn = false
        local parented = pcall(function()
            gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        end)
        if not parented then
            gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end

        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 1)
        f.Position = UDim2.new(0.5, 0, 1, -20)
        f.Size = UDim2.new(0, 440, 0, 120)
        f.BackgroundColor3 = Color3.fromRGB(26, 12, 12)
        f.BorderSizePixel = 0
        f.Parent = gui
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local st = Instance.new("UIStroke", f)
        st.Color = Color3.fromRGB(235, 60, 60)
        st.Thickness = 1.5

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 1, -16)
        t.Position = UDim2.new(0, 10, 0, 8)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 130, 130)
        t.TextSize = 13
        t.Font = Enum.Font.Code
        t.TextWrapped = true
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
        t.Text = "💧 Liquid Hub " .. VERSION .. " — load error:\n" .. msg
        t.Parent = f

        task.delay(20, function() gui:Destroy() end)
    end)
end

-- // Download with cache-busting + mirror fallback //--
local source, lastErr
for _, url in ipairs(SOURCES) do
    local ok, res = pcall(function()
        return game:HttpGet(url .. "?nocache=" .. tostring(os.time()))
    end)
    if ok and type(res) == "string" and #res > 2000 then
        source = res
        print("[Liquid Hub] Library downloaded from: " .. url)
        break
    end
    lastErr = res
end

if not source then
    showLoaderError("Не удалось скачать библиотеку (download failed):\n" .. tostring(lastErr))
    return
end

-- // Compile //--
local chunk, compileErr = (loadstring or load)(source)
if not chunk then
    showLoaderError("Ошибка компиляции (compile error):\n" .. tostring(compileErr))
    return
end

-- // Run the library //--
local okLib, Liquid = pcall(chunk)
if not okLib or type(Liquid) ~= "table" then
    showLoaderError("Ошибка запуска библиотеки (library error):\n" .. tostring(Liquid))
    return
end

-- // Build the window //--
local okWin, Window = pcall(function()
    return Liquid:CreateWindow({
        Title     = "Liquid Hub",
        SubTitle  = VERSION,
        ToggleKey = Enum.KeyCode.RightControl,
        Width     = 680,
        Height    = 440,
    })
end)
if not okWin or type(Window) ~= "table" then
    showLoaderError("Ошибка создания окна (CreateWindow error):\n" .. tostring(Window))
    return
end

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
