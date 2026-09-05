-- Liquid Hub | Chess Incremental | WindUI Delta | GEN math.floor(os.clock()*100000)
if game.PlaceId ~= 72119929635167 then warn("[LiquidHub] Wrong place: "..game.PlaceId) end
STATE = STATE or {}
STATE.alive = STATE.alive or function() return true end
STATE.onCleanup = STATE.onCleanup or function() end
STATE.GEN = STATE.GEN or math.floor(os.clock()*100000)
local GEN = STATE.GEN
print("[LiquidHub] GEN="..GEN.." loading")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes",10)
if not Remotes then warn("[LiquidHub] Remotes not found") return end

local BoardRemote = Remotes:FindFirstChild("BoardRemote")
local UpgradePurchase = Remotes:FindFirstChild("UpgradePurchase")
local ShopRedeemCode = Remotes:FindFirstChild("ShopRedeemCode")
local ShopPurchase = Remotes:FindFirstChild("ShopPurchase")
local ShopState = Remotes:FindFirstChild("ShopState")
local InventoryState = Remotes:FindFirstChild("InventoryState")
local InventoryUsePotion = Remotes:FindFirstChild("InventoryUsePotion")
local RankRollRequest = Remotes:FindFirstChild("RankRollRequest")
local FragmentsClick = Remotes:FindFirstChild("FragmentsClick")
local RubinsExchangeRequest = Remotes:FindFirstChild("RubinsExchangeRequest")
local PrestigeRequest = Remotes:FindFirstChild("PrestigeRequest")
local Collect = Remotes:FindFirstChild("Collect")
local ChestSpawned = Remotes:FindFirstChild("ChestSpawned")

-- WindUI
local WindUI
local ok,err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end
WindUI:SetNotificationLower(true)

local Window = WindUI:CreateWindow({
    Title = "Liquid Hub",
    Icon = "droplets",
    Author = "Chess Incremental | v1875",
    Folder = "LiquidHub",
    Size = UDim2.fromOffset(620, 520),
    Theme = "Dark",
    SideBarWidth = 170,
    ToggleKey = Enum.KeyCode.RightShift,
    OpenButton = {
        Title = "Open Liquid Hub",
        Icon = "droplets",
        CornerRadius = UDim.new(0,16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("00AAFF"), Color3.fromHex("0088CC")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    },
})

local TabFarm = Window:Tab({ Title = "Farm", Icon = "zap" })
local TabUpgrades = Window:Tab({ Title = "Upgrades", Icon = "arrow-up" })
local TabShop = Window:Tab({ Title = "Misc", Icon = "gift" })
local TabTele = Window:Tab({ Title = "Teleports", Icon = "map-pin" })

STATE.Flags = STATE.Flags or {
    AutoBoard = false,
    BoardInterval = 0.15,
    AutoUpgrades = false,
    AutoFragments = false,
    AutoRubins = false,
    AutoPrestige = false,
    AutoChests = false,
    DualStand = false,
}
local Flags = STATE.Flags
STATE.FragInterval = STATE.FragInterval or 0.2
STATE.UpInterval = STATE.UpInterval or 0.8
STATE.RubinsInterval = STATE.RubinsInterval or 1.5
STATE.ZoneTarget = STATE.ZoneTarget or "Aura"

local function notify(title, content, icon, dur)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Icon = icon or "info", Duration = dur or 3 })
    end)
    print("[LiquidHub] "..title.." - "..content)
end

local function getTickets()
    local ok2,res2 = pcall(function() return ShopState:InvokeServer() end)
    if ok2 and res2 and type(res2)=="table" then return res2.Tickets or 0 end
    return 0
end

-- ===== FARM =====
local autoChestsToggle = TabFarm:Toggle({
    Title = "Auto Chests",
    Desc = "Farms chests",
    Value = Flags.AutoChests or false,
    Callback = function(v) Flags.AutoChests=v notify(v and "Auto Chests Enabled" or "Auto Chests Disabled", v and "Collecting..." or "Stopped") end
})

local chestSelectionDD = TabFarm:Dropdown({
    Title = "Chest Selection",
    Desc = "Choose which chests to collect",
    Values = {"All Chests", "Normal Chests Only", "Mythic Chest Only"},
    Value = STATE.ChestSelection or "All Chests",
    Callback = function(v) STATE.ChestSelection = v print("[LiquidHub] chest selection "..tostring(v)) end
})
STATE.ChestSelection = STATE.ChestSelection or "All Chests"
STATE.ReturnToStart = STATE.ReturnToStart or false

local returnToStartToggle = TabFarm:Toggle({
    Title = "Return to Start",
    Desc = "Return to position before farming",
    Value = STATE.ReturnToStart,
    Callback = function(v) STATE.ReturnToStart = v notify(v and "Return Enabled" or "Return Disabled") end
})

local autoFragmentsToggle = TabFarm:Toggle({
    Title = "Auto Fragments Click",
    Desc = "Spam FragmentsClick",
    Value = Flags.AutoFragments,
    Callback = function(v) Flags.AutoFragments=v notify(v and "Fragments Enabled" or "Fragments Disabled","") end
})

local fragIntervalSlider = TabFarm:Slider({
    Title = "Fragments Interval",
    Desc = "Fragments click interval",
    Value = { Min = 0.03, Max = 1, Default = STATE.FragInterval },
    Step = 0.05,
    Callback = function(val) STATE.FragInterval = val end
})

local autoRubinsToggle = TabFarm:Toggle({
    Title = "Auto Rubins Exchange",
    Desc = "Auto exchange Rubins",
    Value = Flags.AutoRubins,
    Callback = function(v) Flags.AutoRubins=v notify(v and "Rubins Enabled" or "Rubins Disabled") end
})

local rubinsIntervalSlider = TabFarm:Slider({
    Title = "Rubins Interval",
    Desc = "Delay between exchanges",
    Value = { Min = 0.5, Max = 10, Default = STATE.RubinsInterval },
    Step = 0.5,
    Callback = function(v) STATE.RubinsInterval = v end
})

local autoPrestigeToggle = TabFarm:Toggle({
    Title = "Auto Prestige",
    Desc = "Automatically prestiges when requirement met",
    Value = Flags.AutoPrestige or false,
    Callback = function(v) Flags.AutoPrestige=v notify(v and "Auto Prestige Enabled" or "Auto Prestige Disabled") end
})

STATE.onCleanup(function()
    Flags.AutoBoard = false
    Flags.AutoFragments = false
    Flags.AutoRubins = false
    Flags.AutoUpgrades = false
    Flags.AutoPrestige = false
    Flags.AutoChests = false
    Flags.DualStand = false
    print("[LiquidHub] loops cleaned GEN="..GEN)
end)

task.spawn(function()
    while STATE.alive() do
        if Flags.AutoBoard and BoardRemote then
            pcall(function() BoardRemote:FireServer("RequestMove") end)
        end
        task.wait(Flags.BoardInterval)
    end
end)

task.spawn(function()
    while STATE.alive() do
        if Flags.AutoFragments and FragmentsClick then
            pcall(function() FragmentsClick:FireServer() end)
        end
        task.wait(STATE.FragInterval or 0.2)
    end
end)

task.spawn(function()
    while STATE.alive() do
        if Flags.AutoRubins and RubinsExchangeRequest then
            pcall(function() RubinsExchangeRequest:InvokeServer(1) end)
        end
        task.wait(STATE.RubinsInterval or 1.5)
    end
end)

task.spawn(function()
    while STATE.alive() do
        if Flags.AutoPrestige and PrestigeRequest then
            local ok, res = pcall(function() return PrestigeRequest:InvokeServer("State") end)
            if ok and res and res.State and res.State.CanPrestige then
                pcall(function() PrestigeRequest:InvokeServer("Prestige") end)
                notify("Prestige", "Prestiged!", "star", 3)
            end
        end
        task.wait(2)
    end
end)

-- Dual Stand farm: alternates between Diamonds and Books buttons to get both currencies
task.spawn(function()
    local diamondPos = nil
    local bookPos = nil
    pcall(function() diamondPos = workspace.UpgradesFolder.Diamonds.DiamondButton:GetPivot().Position end)
    pcall(function() bookPos = workspace.UpgradesFolder.Books.BookButton:GetPivot().Position end)
    if not diamondPos then diamondPos = Vector3.new(-96.9, 2.5, -64) end
    if not bookPos then bookPos = Vector3.new(86.3, 2.6, -81.7) end
    while STATE.alive() do
        if Flags.DualStand then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Method 1: Try firetouchinterest for both without moving (if available)
                local dTop = workspace.UpgradesFolder.Diamonds.DiamondButton:FindFirstChild("Top")
                local bTop = workspace.UpgradesFolder.Books.BookButton:FindFirstChild("Top")
                local bZone = workspace.UpgradesFolder.Books.BookZone:FindFirstChild("Zone")
                if firetouchinterest and dTop and bTop then
                    pcall(function() firetouchinterest(hrp, dTop, 0) firetouchinterest(hrp, bTop, 0) if bZone then firetouchinterest(hrp, bZone, 0) end end)
                    task.wait(0.1)
                    pcall(function() firetouchinterest(hrp, dTop, 1) firetouchinterest(hrp, bTop, 1) if bZone then firetouchinterest(hrp, bZone, 1) end end)
                end
                -- Method 2: Rapid teleport between the two (ensures server sees standing)
                pcall(function() hrp.CFrame = CFrame.new(diamondPos + Vector3.new(0,3,0)) end)
                task.wait(0.25)
                pcall(function() hrp.CFrame = CFrame.new(bookPos + Vector3.new(0,3,0)) end)
                task.wait(0.25)
                -- Method 3: Enlarge hitboxes on client to cover both (if server checks client size, helps)
                pcall(function()
                    if dTop then dTop.Size = Vector3.new(500,10,500) dTop.CanTouch = true end
                    if bTop then bTop.Size = Vector3.new(500,10,500) bTop.CanTouch = true end
                    if bZone then bZone.Size = Vector3.new(500,10,500) bZone.CanTouch = true end
                end)
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Chests farm: mythic first (global instant), then normal private, with return
task.spawn(function()
    local function tryCollect(id)
        if Collect then
            pcall(function() Collect:FireServer(id) end)
            task.wait(0.2)
            if not workspace:FindFirstChild("ClientChests") or not workspace.ClientChests:FindFirstChild("Chest_"..id) then return true end
            pcall(function() Collect:FireServer(tostring(id)) end)
            task.wait(0.2)
            if not workspace.ClientChests:FindFirstChild("Chest_"..id) then return true end
            pcall(function() Collect:FireServer() end)
            task.wait(0.2)
            if not workspace.ClientChests:FindFirstChild("Chest_"..id) then return true end
        end
        return false
    end
    while STATE.alive() do
        if Flags.AutoChests then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local startPos = hrp.CFrame
                local did = false
                -- Mythic FIRST - global, must be instant
                if STATE.ChestSelection ~= "Normal Chests Only" and ReplicatedStorage:GetAttribute("GlobalChestActive") == true then
                    local globalFolder = workspace:FindFirstChild("GlobalChestClient")
                    if globalFolder then
                        local gc = globalFolder:FindFirstChild("GlobalChest")
                        if gc then
                            local gpos
                            pcall(function() gpos = gc:GetPivot().Position end)
                            if gpos then
                                local humM = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
                                if not humM or humM.MoveDirection.Magnitude < 0.15 then
                                    did = true
                                    pcall(function() hrp.CFrame = CFrame.new(gpos + Vector3.new(0,4,0)) end)
                                    task.wait(0.4)
                                    local gid = ReplicatedStorage:GetAttribute("GlobalChestId")
                                    if gid and Collect then pcall(function() Collect:FireServer(gid) end) task.wait(0.2) pcall(function() Collect:FireServer(tostring(gid)) end) task.wait(0.2) pcall(function() Collect:FireServer() end) task.wait(0.2) end
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                end
                -- Normal chests - private, only if mythic not just done (to avoid double TP)
                if STATE.ChestSelection ~= "Mythic Chest Only" then
                    -- If mythic was active and we just did it, skip normal this cycle to not leave at mythic pos without return check
                    local mythicActive = ReplicatedStorage:GetAttribute("GlobalChestActive") == true and STATE.ChestSelection ~= "Normal Chests Only" and workspace:FindFirstChild("GlobalChestClient") and workspace.GlobalChestClient:FindFirstChild("GlobalChest")
                    if not mythicActive then
                        local chestsFolder = workspace:FindFirstChild("ClientChests")
                        if chestsFolder then
                            for _, chest in ipairs(chestsFolder:GetChildren()) do
                                if not Flags.AutoChests or not STATE.alive() then break end
                                -- If mythic spawns mid-loop, break and handle it next cycle
                                if ReplicatedStorage:GetAttribute("GlobalChestActive") == true and STATE.ChestSelection ~= "Normal Chests Only" and workspace:FindFirstChild("GlobalChestClient") and workspace.GlobalChestClient:FindFirstChild("GlobalChest") then break end
                                local id = tonumber(chest.Name:match("%d+"))
                                if not id then continue end
                                local chestPos
                                pcall(function() chestPos = chest:GetPivot().Position end)
                                if not chestPos then continue end
                                do
                                    local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
                                    if hum and hum.MoveDirection.Magnitude > 0.15 then continue end
                                end
                                task.wait(1)
                                if not Flags.AutoChests then break end
                                pcall(function() hrp.CFrame = CFrame.new(chestPos + Vector3.new(0,3,0)) end)
                                task.wait(0.5)
                                local collected = tryCollect(id)
                                if not collected then
                                    for i=1,2 do
                                        if not Flags.AutoChests then break end
                                        local hum2 = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
                                        if hum2 and hum2.MoveDirection.Magnitude > 0.15 then break end
                                        pcall(function() hrp.CFrame = CFrame.new(chestPos + Vector3.new(math.random(-1,1),0,math.random(-1,1))) end)
                                        task.wait(0.4)
                                        if not workspace.ClientChests:FindFirstChild("Chest_"..id) then break end
                                    end
                                end
                                did = true
                                task.wait(0.5)
                            end
                        end
                    end
                end
                if did and STATE.ReturnToStart and startPos then
                    local hum4 = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
                    if not hum4 or hum4.MoveDirection.Magnitude < 0.1 then
                        pcall(function() hrp.CFrame = startPos end)
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- ===== UPGRADES =====
local upgradeIds = {"ChessMulti","ChessVicPointsMulti","ClickSpeed","GoldenChance","MoveSpeed","WinChance","VicAuraMulti","VicBooksMulti","VicChessMulti","VicDiamondsMulti","VicPointsMulti","VicRubiesMulti","DiamondBooksMulti","DiamondButtonSpeed","DiamondChessMulti","DiamondDiamondsMulti","DiamondMoreBulk","DiamondMoreDiamonds","DiamondRubiesMulti","BookAuraMulti","BookBooksMulti","BookButtonSpeed","BookMoreKeys","BookRuneLuck","BookRuneSpeed","AuraAuraMulti","AuraAuraSpeed","AuraChessMulti","AuraMoreAura","AuraMoreBulk","AuraRuneLuck","AuraStatsMulti","SquaresAuraMulti","SquaresChessMulti","SquaresFragmentsMulti","SquaresMagnetRange","SquaresMaxItems","SquaresMulti","SquaresMutationChance","SquaresSpawnRate","SquaresVicPointsMulti","FragmentAutoClicker","FragmentBulkMulti","FragmentClickSpeed","FragmentDuplicateChance","FragmentFragmentsMulti","FragmentMoreFragments","RubinBooksMulti","RubinChessMulti","RubinDiamondsMulti","RubinKeysChance","RubinMoreBulk","RubinRubiesMulti"}
local selectedUpgrades = {"ChessMulti"}
local buyMode = "Buy"

local selectUpgradesDD = TabUpgrades:Dropdown({
    Title = "Select Upgrades",
    Desc = "Choose upgrades for auto-buy (multi-select)",
    Values = upgradeIds,
    Value = {"ChessMulti"},
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        if type(val) == "table" then
            selectedUpgrades = val
        elseif type(val) == "string" then
            selectedUpgrades = {val}
        elseif val == nil then
            selectedUpgrades = {}
        end
        if selectedUpgrades and #selectedUpgrades > 0 then
            print("[LiquidHub] selected "..table.concat(selectedUpgrades, ", "))
        else
            print("[LiquidHub] selected none")
        end
    end
})

TabUpgrades:Button({
    Title = "Select All / Deselect All",
    Desc = "Press to select all, press again to clear",
    Callback = function()
        if selectedUpgrades and #selectedUpgrades == #upgradeIds then
            selectedUpgrades = {}
            pcall(function() selectUpgradesDD:Select({}) end)
            -- Also try clear via Select nil
            pcall(function() selectUpgradesDD:Select(nil) end)
            notify("Upgrades", "Deselected all", "x", 2)
            print("[LiquidHub] deselected all")
        else
            selectedUpgrades = {}
            for _, id in ipairs(upgradeIds) do table.insert(selectedUpgrades, id) end
            pcall(function() selectUpgradesDD:Select(upgradeIds) end)
            notify("Upgrades", "Selected all ("..#upgradeIds..")", "check", 2)
            print("[LiquidHub] selected all "..#upgradeIds)
        end
    end
})

TabUpgrades:Dropdown({
    Title = "Buy Mode",
    Desc = "Buy = 1 level, BuyMax = as many as possible",
    Values = {"Buy","BuyMax"},
    Value = "Buy",
    Callback = function(v) buyMode=v end
})

local autoUpgradesToggle = TabUpgrades:Toggle({
    Title = "Auto Upgrade",
    Desc = "Automatically buys selected upgrade",
    Value = Flags.AutoUpgrades,
    Callback = function(v) Flags.AutoUpgrades=v notify(v and "Auto Upgrade Enabled" or "Auto Upgrade Disabled","Mode: "..buyMode) end
})

TabUpgrades:Button({
    Title = "Upgrade All Once",
    Desc = "Buys every upgrade at once with current Buy Mode",
    Callback = function()
        for _, id in ipairs(upgradeIds) do
            pcall(function() UpgradePurchase:InvokeServer(id, buyMode) end)
            task.wait(0.05)
        end
        notify("Upgrade All", "All upgrades attempted ("..buyMode..")", "check")
    end
})

-- Interval fixed at 0.8s (slider removed per request)
STATE.UpInterval = 0.2

task.spawn(function()
    while STATE.alive() do
        if Flags.AutoUpgrades and UpgradePurchase then
            for _,id in ipairs(selectedUpgrades) do
                pcall(function() UpgradePurchase:InvokeServer(id, buyMode) end)
                task.wait(0.05)
            end
        end
        task.wait(STATE.UpInterval)
    end
end)

-- ===== MISC =====
local knownCodes = {"SorryForThat","3kccu","5kFavs","500ccu","150ccu","RELEASE","REBALANCE","Frog","1MVisits","100KVisits","30KVisits","100Likes","100ccu","1kLikes"}

TabShop:Button({
    Title = "Redeem All Codes",
    Desc = "Tries all known codes with 0.65s delay to avoid rate limit",
    Callback = function()
        task.spawn(function()
            for _,code in ipairs(knownCodes) do
                local ok,res = pcall(function() return ShopRedeemCode:InvokeServer(code) end)
                local msg = ok and (res.Success and "Success" or tostring(res.Reason)) or "Error"
                notify("Code: "..code, msg, res and res.Success and "gift" or "circle-x", 2)
                print("[LiquidHub] code "..code.." -> "..msg)
                task.wait(0.65)
            end
            notify("Codes", "All codes processed", "check")
        end)
    end
})

-- ===== TELEPORTS =====
local tpFolder = workspace:FindFirstChild("PrestigeTeleports")
local tpNames = {}
if tpFolder then
    for _,v in ipairs(tpFolder:GetChildren()) do table.insert(tpNames, v.Name) end
    table.sort(tpNames)
else
    tpNames = {"1","2","3","4","5","6","7","8","9"}
end

TabTele:Button({
    Title = "Teleport All Prestige Islands",
    Desc = "Sequentially teleports through all 9 islands",
    Callback = function()
        task.spawn(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not tpFolder then notify("Teleport","Failed","x") return end
            for _,name in ipairs(tpNames) do
                local t = tpFolder:FindFirstChild(name)
                if t then hrp.CFrame=CFrame.new(t.Position+Vector3.new(0,5,0)) print("[LiquidHub] tp "..name) task.wait(0.5) end
            end
            notify("Teleport", "Done", "check")
        end)
    end
})

TabTele:Dropdown({
    Title = "Select Zone",
    Desc = "Choose UpgradesFolder zone",
    Values = {"Aura","Books","Diamonds","Rubins","Fragments","Squares"},
    Value = STATE.ZoneTarget,
    Callback = function(v) STATE.ZoneTarget=v end
})

TabTele:Button({
    Title = "Teleport To Zone",
    Desc = "Teleport to selected zone",
    Callback = function()
        local zone = workspace:FindFirstChild("UpgradesFolder") and workspace.UpgradesFolder:FindFirstChild(STATE.ZoneTarget)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if zone and hrp then
            local dest=nil
            for _,d in ipairs(zone:GetDescendants()) do if d:IsA("BasePart") then dest=d break end end
            if dest then hrp.CFrame = CFrame.new(dest.Position+Vector3.new(0,5,0)) notify("Zone","Teleported to "..STATE.ZoneTarget,"map-pin") else notify("Zone","No part found","x") end
        else
            notify("Teleport","Failed","x")
        end
    end
})

TabTele:Button({
    Title = "Back To Spawn",
    Desc = "Return to spawn location",
    Callback = function()
        local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame=CFrame.new(0,5,0) notify("Teleport","Back to spawn","home") end
    end
})


-- ===================== CONFIGS (TAKEN FROM FINAL SWARM, UNTOUCHED LOGIC) =====================
-- Reg + adaptTab + window wrapper are exact copy, not modified. Only cfgTab is created via existing Window.
local Reg = {}
local function adaptTab(wtab)
    local t = {}
    function t:CreateToggle(o)
        local entry = { kind = "toggle", current = o.value }
        local function wrappedCb(v)
            entry.current = v
            if o.callback then return o.callback(v) end
        end
        local obj = wtab:Toggle({
            Title = o.name,
            Desc = o.desc,
            Value = o.value,
            Callback = wrappedCb,
        })
        entry.obj = obj
        entry.apply = function(v)
            pcall(function() obj:Set(v) end)
            pcall(function() wrappedCb(v) end)
        end
        if o.name and not o.noreg then Reg[o.name] = entry end
        return obj
    end
    function t:CreateSlider(o)
        local mn, mx = 0, 100
        if type(o.range) == "table" then
            mn = o.range[1] or 0
            mx = o.range[2] or 100
        end
        local entry = { kind = "slider", current = o.value }
        local function wrappedCb(v)
            entry.current = v
            if o.callback then return o.callback(v) end
        end
        local obj = wtab:Slider({
            Title = o.name,
            Desc = o.desc,
            Value = { Min = mn, Max = mx, Default = o.value },
            Step = o.increment or 1,
            Callback = wrappedCb,
        })
        entry.obj = obj
        entry.apply = function(v)
            if type(v) ~= "number" then return end
            pcall(function() obj:Set(v) end)
            pcall(function() wrappedCb(v) end)
        end
        if o.name and not o.noreg then Reg[o.name] = entry end
        return obj
    end
    function t:CreateDropdown(o)
        local initVal = o.value
        local createVal = initVal
        if type(createVal) == "table" and #createVal == 0 then
            createVal = nil
        end
        local search = false
        if type(o.options) == "table" and #o.options > 20 then
            search = true
        end
        local entry = { kind = "dropdown" }
        local function wrappedCb(v)
            entry.current = v
            if o.callback then return o.callback(v) end
        end
        local dd = wtab:Dropdown({
            Title = o.name,
            Desc = o.placeholder,
            Values = o.options,
            Value = createVal,
            Multi = o.multiSelect or false,
            AllowNone = true,
            SearchBarEnabled = search,
            Callback = wrappedCb,
        })
        entry.obj = dd
        entry.apply = function(v)
            if type(v) ~= "string" and type(v) ~= "table" then return end
            pcall(function() dd:Select(v) end)
            pcall(function() wrappedCb(v) end)
        end
        if o.name and not o.noreg then Reg[o.name] = entry end
        pcall(function() dd.value = initVal or {} end)
        return dd
    end
    function t:CreateSection(o)
        local nm = o and o.name or ""
        if type(nm) ~= "string" or nm:match("^%s*$") then
            local ok, r = pcall(function() return wtab:Divider() end)
            if ok and r then return r end
            return wtab:Section({ Title = " " })
        end
        return wtab:Section({ Title = nm })
    end
    function t:CreateButton(o)
        return wtab:Button({
            Title = o.name,
            Desc = o.desc,
            Callback = o.callback,
        })
    end
    function t:CreateStat(o)
        local para = wtab:Paragraph({
            Title = o.name,
            Desc = tostring(o.value),
        })
        function para:Set(v)
            pcall(function() para:SetDesc(tostring(v)) end)
        end
        return para
    end
    function t:CreateInput(o)
        return wtab:Input({
            Title = o.name,
            Desc = o.desc,
            Placeholder = o.placeholder,
            Value = o.value,
            Callback = o.callback,
        })
    end
    return t
end

-- Use existing Window as WindowRaw to avoid second window
local WindowRaw = Window
local window = {}
window._raw = WindowRaw
window._tabIcons = { Configs = "save" }
function window:CreateTab(o)
    local wt = WindowRaw:Tab({
        Title = o.name,
        Icon = self._tabIcons[o.name] or "menu",
    })
    return adaptTab(wt)
end
function window:Notify(o)
    return WindUI:Notify({
        Title = o.title or o.Title or "Liquid Hub",
        Content = o.content or o.Content or "",
        Duration = o.duration or o.Duration or 3,
    })
end

local cfgTab = window:CreateTab({ name = "Configs" })

-- Config files logic (exact copy from Final Swarm, folder kept as LiquidHub to not clash, but logic untouched)
do
    local CF_DIR = "LiquidHub/configs"
    local AUTOLOAD_FILE = "LiquidHub/autoload.txt"
    local Http = game:GetService("HttpService")

    local canIO = typeof(writefile) == "function" and typeof(readfile) == "function"
        and typeof(isfile) == "function" and typeof(makefolder) == "function"

    local function ensureDir()
        if not canIO then return false end
        local ok = pcall(function()
            makefolder("LiquidHub")
            makefolder(CF_DIR)
        end)
        return ok
    end
    local function cfgPath(name) return CF_DIR .. "/" .. name .. ".json" end
    local function safeName(name)
        name = tostring(name or ""):match("^%s*(.-)%s*$")
        if not name or name == "" then return nil end
        if name:find("[/\\]") then return nil end
        if #name > 40 then name = name:sub(1, 40) end
        return name
    end
    local function listConfigs()
        local out = {}
        if not canIO then return out end
        pcall(function()
            for _, p in ipairs(listfiles(CF_DIR)) do
                local n = p:match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end)
        table.sort(out)
        return out
    end
    local function snapshot()
        local data = {}
        for k, e in pairs(Reg) do
            if e.kind == "toggle" and type(e.current) == "boolean" then
                data[k] = { t = "b", v = e.current }
            elseif e.kind == "slider" and type(e.current) == "number" then
                data[k] = { t = "n", v = e.current }
            elseif e.kind == "dropdown" then
                local v = e.current
                if type(v) == "string" or type(v) == "table" then
                    data[k] = { t = "d", v = v }
                end
            end
        end
        -- Also save LiquidHub Flags and intervals (so main hub state is persisted)
        data["_Flags"] = { t = "f", v = {
            AutoChests = Flags.AutoChests,
            AutoFragments = Flags.AutoFragments,
            AutoRubins = Flags.AutoRubins,
            AutoPrestige = Flags.AutoPrestige,
            AutoUpgrades = Flags.AutoUpgrades,
            DualStand = Flags.DualStand,
            ChestSelection = STATE.ChestSelection,
            ReturnToStart = STATE.ReturnToStart,
            FragInterval = STATE.FragInterval,
            UpInterval = STATE.UpInterval,
            RubinsInterval = STATE.RubinsInterval,
            SelectedUpgrades = selectedUpgrades,
            BuyMode = buyMode,
        }}
        return data
    end
    local function applyData(data)
        if type(data) ~= "table" then return 0 end
        local n = 0
        for k, sv in pairs(data) do
            if k == "_Flags" and sv.t == "f" and type(sv.v) == "table" then
                local f = sv.v
                if type(f.AutoChests) == "boolean" then Flags.AutoChests = f.AutoChests pcall(function() autoChestsToggle:Set(f.AutoChests) end) end
                if type(f.AutoFragments) == "boolean" then Flags.AutoFragments = f.AutoFragments pcall(function() autoFragmentsToggle:Set(f.AutoFragments) end) end
                if type(f.AutoRubins) == "boolean" then Flags.AutoRubins = f.AutoRubins pcall(function() autoRubinsToggle:Set(f.AutoRubins) end) end
                if type(f.AutoPrestige) == "boolean" then Flags.AutoPrestige = f.AutoPrestige pcall(function() autoPrestigeToggle:Set(f.AutoPrestige) end) end
                if type(f.AutoUpgrades) == "boolean" then Flags.AutoUpgrades = f.AutoUpgrades pcall(function() autoUpgradesToggle:Set(f.AutoUpgrades) end) end
                if type(f.ChestSelection) == "string" then STATE.ChestSelection = f.ChestSelection pcall(function() chestSelectionDD:Select(f.ChestSelection) end) end
                if type(f.ReturnToStart) == "boolean" then STATE.ReturnToStart = f.ReturnToStart pcall(function() returnToStartToggle:Set(f.ReturnToStart) end) end
                if type(f.FragInterval) == "number" then STATE.FragInterval = f.FragInterval pcall(function() fragIntervalSlider:Set(f.FragInterval) end) end
                if type(f.UpInterval) == "number" then STATE.UpInterval = f.UpInterval end
                if type(f.RubinsInterval) == "number" then STATE.RubinsInterval = f.RubinsInterval pcall(function() rubinsIntervalSlider:Set(f.RubinsInterval) end) end
                if type(f.SelectedUpgrades) == "table" then selectedUpgrades = f.SelectedUpgrades pcall(function() selectUpgradesDD:Select(selectedUpgrades) end) end
                if type(f.BuyMode) == "string" then buyMode = f.BuyMode end
                -- DualStand is not in _Flags yet, but handle if present
                if type(f.DualStand) == "boolean" then Flags.DualStand = f.DualStand pcall(function() dualStandToggle:Set(f.DualStand) end) end
                n = n + 1
            else
                local e = Reg[k]
                if e and type(sv) == "table" and sv.t then
                    local okType = false
                    if sv.t == "b" and e.kind == "toggle" and type(sv.v) == "boolean" then
                        okType = true
                    elseif sv.t == "n" and e.kind == "slider" and type(sv.v) == "number" then
                        okType = true
                    elseif sv.t == "d" and e.kind == "dropdown"
                        and (type(sv.v) == "string" or type(sv.v) == "table") then
                        okType = true
                    end
                    if okType then
                        pcall(e.apply, sv.v)
                        n = n + 1
                    end
                end
            end
        end
        -- Re-apply visuals for main toggles (since they are not in Reg)
        pcall(function()
            -- Force UI to reflect loaded Flags (WindUI Set method)
            -- Note: main toggles are not in Reg, so we just keep Flags, UI will update on next reload via Value
        end)
        return n
    end
    local function getAutoload()
        if not canIO then return nil end
        local ok, txt = pcall(function() return readfile(AUTOLOAD_FILE) end)
        if not ok or type(txt) ~= "string" then return nil end
        return safeName(txt)
    end
    local function setAutoload(name)
        if not canIO then return false end
        ensureDir()
        local ok = pcall(function() writefile(AUTOLOAD_FILE, name) end)
        return ok
    end
    local function clearAutoload()
        if not canIO then return end
        pcall(function() delfile(AUTOLOAD_FILE) end)
    end

    cfgTab:CreateSection({ name = "Config files" })
    local stat = cfgTab:CreateStat({ name = "Status", value = canIO and "Ready" or "File functions missing" })
    local function setStatus(t) pcall(function() stat:Set(t) end) end
    local pendingName = ""
    cfgTab:CreateInput({
        name = "Config name",
        placeholder = "my setup",
        value = "",
        callback = function(v) pendingName = tostring(v or "") end,
    })
    local selected = nil
    local listDD = cfgTab:CreateDropdown({
        name = "Saved configs",
        noreg = true,
        multiSelect = false,
        options = {},
        value = nil,
        placeholder = "Pick one, then Load/Delete",
        callback = function(v)
            if type(v) == "table" then selected = v[1] else selected = v end
        end,
    })
    local function refreshList()
        local names = listConfigs()
        pcall(function() listDD:Refresh(names) end)
        if selected and not table.find(names, selected) then selected = nil end
        return names
    end
    cfgTab:CreateButton({
        name = "Save current setup",
        callback = function()
            local name = safeName(pendingName)
            if not name then setStatus("Type a config name first") return end
            if not canIO then setStatus("File functions missing") return end
            ensureDir()
            local ok = pcall(function()
                writefile(cfgPath(name), Http:JSONEncode(snapshot()))
            end)
            if ok then
                refreshList()
                setStatus("Saved " .. name)
            else
                setStatus("Save failed")
            end
        end,
    })
    cfgTab:CreateButton({
        name = "Load selected",
        callback = function()
            if not selected then setStatus("Select a config first") return end
            local ok, txt = pcall(function() return readfile(cfgPath(selected)) end)
            if not ok or type(txt) ~= "string" then setStatus("Read failed") return end
            local ok2, data = pcall(function() return Http:JSONDecode(txt) end)
            if not ok2 or type(data) ~= "table" then setStatus("Bad file") return end
            local n = applyData(data)
            setStatus("Loaded " .. selected .. " (" .. n .. ")")
        end,
    })
    cfgTab:CreateButton({
        name = "Delete selected",
        callback = function()
            if not selected then setStatus("Select a config first") return end
            pcall(function() delfile(cfgPath(selected)) end)
            if getAutoload() == selected then clearAutoload() end
            selected = nil
            refreshList()
            setStatus("Deleted")
        end,
    })
    local autoT
    autoT = cfgTab:CreateToggle({
        name = "Autoload selected on start",
        noreg = true,
        value = false,
        callback = function(v)
            if v then
                if not selected then
                    setStatus("Select a config first")
                    pcall(function() autoT:Set(false) end)
                    return
                end
                if setAutoload(selected) then
                    setStatus("Autoload: " .. selected)
                else
                    setStatus("Autoload failed")
                end
            else
                clearAutoload()
                setStatus("Autoload off")
            end
        end,
    })
    local names = refreshList()
    local cur = getAutoload()
    if cur and table.find(names, cur) then
        selected = cur
        pcall(function() listDD:Select(cur) end)
        pcall(function() autoT:Set(true) end)
    end
    task.delay(3, function()
        pcall(function()
            local a = getAutoload()
            if a and a ~= "" then
                local ok, txt = pcall(function() return readfile(cfgPath(a)) end)
                if ok and type(txt) == "string" then
                    local ok2, data = pcall(function() return Http:JSONDecode(txt) end)
                    if ok2 and type(data) == "table" then
                        local n = applyData(data)
                        setStatus("Autoloaded " .. a .. " (" .. n .. ")")
                    end
                end
            end
        end)
    end)
end

notify("Liquid Hub Loaded","GEN="..GEN.." | Delta Ready","droplets",4)
print("[LiquidHub] Ready GEN="..GEN)
