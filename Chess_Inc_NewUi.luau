-- Chess_Inc_NewUi | Chess Incremental | Liquid Hub (Nebula UI)
-- Ported from "ChessInc.luau" (WindUI) onto the new Liquid Hub UI lib.
-- All feature logic (farm, upgrades, codes, teleports, configs) is preserved
-- 1:1; only the UI adapter layer changed. Folder: ChessInc | Flags: CHS_
-- Plus: Anti-AFK (VirtualUser idleness, same as Sticks_Inc2_).

-- AUTO Plugin fix for Delta / WindUI (1 loadstring, no external wrapper needed)
pcall(function()
	local set = setthreadidentity or set_thread_identity or setthreadcontext or _G.set_identity
	if set then pcall(set, 8) pcall(set, 7) end
end)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function getFlag(n) return RS:GetAttribute("CHS_" .. n) end
local function setFlag(n, v) RS:SetAttribute("CHS_" .. n, v) end

-- Every load stamps a unique generation into the DataModel. Loops check it, so
-- a loop left running by an EARLIER execution of this script stops as soon as
-- a new copy loads (prevents duplicate loops fighting over the same remotes).
local LOAD_GEN = math.floor(os.clock() * 100000) % 1000000 + math.random(1, 999) * 1000000
RS:SetAttribute("CHS_LoadGen", LOAD_GEN)
local function isCurrentGen() return RS:GetAttribute("CHS_LoadGen") == LOAD_GEN end

-- ===================== LIQUID HUB CORE (live-reload contract) =====================
local STATE = _G.STATE
if typeof(STATE) ~= "table" then STATE = {} end
STATE.GEN = math.floor(os.clock() * 100000)
RS:SetAttribute("CHS_LiquidGen", STATE.GEN)
local __cleanups = {}
if type(STATE.onCleanup) ~= "function" then
	function STATE.onCleanup(fn)
		if type(fn) == "function" then table.insert(__cleanups, fn) end
	end
end
if type(STATE.connect) ~= "function" then
	function STATE.connect(signal, fn)
		return signal:Connect(fn)
	end
end
if type(STATE.alive) ~= "function" then
	function STATE.alive()
		return RS:GetAttribute("CHS_LiquidGen") == STATE.GEN and isCurrentGen()
	end
end

-- Interval-driven loop runner: pcall-protected, alive-checked.
local function loop(name, interval, fn)
	task.spawn(function()
		while STATE.alive() do
			local ok, err = pcall(fn)
			if not ok then
				warn("[LiquidHub/" .. name .. "] " .. tostring(err))
			end
			local t = 0
			while t < interval and STATE.alive() do
				local dt = task.wait(0.1)
				t = t + (dt or 0.1)
			end
		end
	end)
end

-- ===================== GAME REMOTES =====================
local Remotes = RS:WaitForChild("Remotes", 10)
if not Remotes then
	warn("[LiquidHub] Remotes not found")
	return
end

local BoardRemote = Remotes:FindFirstChild("BoardRemote")
local UpgradePurchase = Remotes:FindFirstChild("UpgradePurchase")
local ShopRedeemCode = Remotes:FindFirstChild("ShopRedeemCode")
local FragmentsClick = Remotes:FindFirstChild("FragmentsClick")
local RubinsExchangeRequest = Remotes:FindFirstChild("RubinsExchangeRequest")
local PrestigeRequest = Remotes:FindFirstChild("PrestigeRequest")
local Collect = Remotes:FindFirstChild("Collect")

-- Destroy any previous hub window (Nebula/WindUI/Rayfield create a fresh
-- ScreenGui each time). Without this every reload stacks another window.
pcall(function()
	local rg = game.CoreGui:FindFirstChild("RobloxGui")
	local parents = { game.CoreGui }
	if rg then parents[#parents + 1] = rg end
	pcall(function()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		if pg then parents[#parents + 1] = pg end
	end)
	for _, parent in ipairs(parents) do
		for _, sg in ipairs(parent:GetChildren()) do
			if sg:IsA("ScreenGui") and sg ~= rg then
				local hit = false
				for _, c in ipairs(sg:GetDescendants()) do
					if (c:IsA("TextLabel") or c:IsA("TextButton"))
						and (c.Text == "Liquid Hub" or c.Text == "Chess Incremental" or c.Text == "Sticks Inc 2" or c.Text == "UI Template") then
						hit = true
						break
					end
				end
				if hit then sg:Destroy() end
			end
		end
	end
end)

-- ===================== LIBRARY LOAD (Nebula / Liquid Hub) =====================
local LIB_SOURCES = {
	"https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Source.lua",
	"https://cdn.jsdelivr.net/gh/tyanxblack2-max/asdfasd@main/Source.lua",
}
local Liquid = nil
for _, url in ipairs(LIB_SOURCES) do
	local ok, res = pcall(function()
		return game:HttpGet(url .. "?nocache=" .. tostring(os.time()))
	end)
	if ok and type(res) == "string" and #res > 2000 then
		local chunk, cerr = (loadstring or load)(res)
		if chunk then
			local okLib, lib = pcall(chunk)
			if okLib and type(lib) == "table" then
				Liquid = lib
				break
			end
		else
			warn("[ChessInc] Compile error: " .. tostring(cerr))
		end
	end
end
if not Liquid then
	warn("[ChessInc] Failed to load Liquid Hub library from all sources")
	return
end

-- ===================== GAME DETECTION (for the title bar) =====================
local GAME_NAME = "Chess Incremental"
do
	local pid = game.PlaceId
	local ok, name = pcall(function()
		local Http = game:GetService("HttpService")
		local res = game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. pid .. "/universe")
		local universeId = Http:JSONDecode(res).universeId
		local res2 = game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. universeId)
		return Http:JSONDecode(res2).data[1].name
	end)
	if ok and type(name) == "string" and #name > 0 then
		GAME_NAME = name
	end
end

local WindowRaw = Liquid:CreateWindow({
	Title     = "Liquid Hub",
	SubTitle  = "1.0.0",
	GameName  = GAME_NAME,
	ToggleKey = Enum.KeyCode.RightShift,
	Width     = 680,
	Height    = 440,
})

-- ===================== OLD-SCRIPT -> NEBULA ADAPTER =====================
-- The ChessInc feature code below still calls tab:CreateToggle / CreateSlider /
-- CreateDropdown / CreateButton / window:Notify in the old table format; these
-- shims translate them to Nebula. Logic untouched.

-- Config registry: adapter records every Toggle/Slider/Dropdown (name -> element
-- + last value + applier) so the Configs tab can save/apply whole setups.
-- Elements with noreg = true (meta UI) are skipped.
local Reg = {}

-- elements can be called the OLD positional way ("Name", callback) or with a
-- table ({name=..., callback=...}); normalize both to a table
local function normOpts(o, cb)
	if type(o) == "string" then return { name = o, callback = cb } end
	return o or {}
end

local function adaptSection(sect)
	local s = {}

	function s:CreateLabel(o)
		return sect:CreateLabel(type(o) == "table" and (o.name or o.Title or "") or o)
	end

	function s:CreateToggle(o)
		o = normOpts(o)
		local entry = { kind = "toggle", current = o.value and true or false }
		local function wrappedCb(v)
			entry.current = v
			if o.callback then return o.callback(v) end
		end
		local obj = sect:CreateToggle(o.name, o.value and true or false, wrappedCb, o.name)
		entry.obj = obj
		entry.apply = function(v)
			if type(v) ~= "boolean" then return end
			pcall(function() obj.Set(v) end)
			pcall(function() wrappedCb(v) end)
		end
		if o.name and not o.noreg then Reg[o.name] = entry end
		return obj
	end

	function s:CreateSlider(o)
		o = normOpts(o)
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
		local obj = sect:CreateSlider(o.name, mn, mx, o.value, wrappedCb, o.name)
		entry.obj = obj
		entry.apply = function(v)
			if type(v) ~= "number" then return end
			pcall(function() obj.Set(v) end)
			pcall(function() wrappedCb(v) end)
		end
		if o.name and not o.noreg then Reg[o.name] = entry end
		return obj
	end

	function s:CreateDropdown(o)
		o = normOpts(o)
		local initVal = o.value
		local entry = { kind = "dropdown", multi = o.multiSelect or false }
		local function wrappedCb(v)
			entry.current = v
			if o.callback then return o.callback(v) end
		end
		local obj
		if o.multiSelect then
			obj = sect:CreateMultiDropdown(o.name, o.options or {}, type(initVal) == "table" and initVal or {}, wrappedCb, o.name)
		elseif type(o.options) == "table" and #o.options > 20 then
			obj = sect:CreateSearchDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)
		else
			obj = sect:CreateDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)
		end
		entry.obj = obj
		entry.apply = function(v)
			if type(v) ~= "string" and type(v) ~= "table" then return end
			pcall(function() obj.Set(v) end)
			pcall(function() wrappedCb(v) end)
		end
		if o.name and not o.noreg then Reg[o.name] = entry end
		return obj
	end

	function s:CreateButton(o, cb)
		o = normOpts(o, cb)
		return sect:CreateButton(o.name, o.callback)
	end

	function s:CreateInput(o)
		o = normOpts(o)
		return sect:CreateTextbox(o.name, o.placeholder, o.callback, o.name)
	end

	return s
end

local function adaptTab(wtab)
	local t = {}
	t._raw = wtab
	t._cur = nil -- current section: tab-level element calls land here

	function t:CreateSection(o)
		local nm = o and (o.name or o.Title) or ""
		local col = o and o.column or nil -- nil = lib auto-balances across columns
		local sect = wtab:CreateSection(type(nm) == "string" and nm ~= "" and nm or nil, col)
		t._cur = adaptSection(sect)
		return t._cur
	end

	-- tab-level element methods route into the current section (the old UI was
	-- flat: elements sat directly on tabs)
	local function cur()
		if not t._cur then t:CreateSection({ name = "Features" }) end
		return t._cur
	end
	function t:CreateToggle(o) return cur():CreateToggle(o) end
	function t:CreateSlider(o) return cur():CreateSlider(o) end
	function t:CreateDropdown(o) return cur():CreateDropdown(o) end
	function t:CreateButton(o, cb) return cur():CreateButton(o, cb) end
	function t:CreateInput(o) return cur():CreateInput(o) end

	function t:Divider() end
	function t:Space() end

	return t
end

local window = {}
window._raw = WindowRaw
window._tabIcons = { Farm = "⚡", Upgrades = "⬆️", Misc = "🎁", Teleports = "🗺️", Configs = "💾" }
function window:CreateTab(o)
	return adaptTab(WindowRaw:CreateTab(o.name, self._tabIcons[o.name]))
end
function window:Notify(o)
	return WindowRaw:Notify(
		o.title or o.Title or "Liquid Hub",
		o.content or o.Content or "",
		o.duration or o.Duration or 3
	)
end
local function notify(title, content, dur)
	pcall(function()
		window:Notify({ title = title, content = content, duration = dur or 3 })
	end)
	print("[LiquidHub] " .. title .. " - " .. content)
end

-- ===================== SHARED FARM STATE =====================
local Flags = {
	AutoBoard = false,
	AutoUpgrades = false,
	AutoFragments = false,
	AutoRubins = false,
	AutoPrestige = false,
	AutoChests = false,
	DualStand = false,
}
local STATE2 = {
	ChestSelection = getFlag("ChestSelection") or "All Chests",
	ReturnToStart = false,
	FragInterval = 0.2,
	UpInterval = 0.2,
	RubinsInterval = 1.5,
	ZoneTarget = "Aura",
}

-- ===================== TABS (order: Farm, Upgrades, Misc, Teleports, Configs) =====================
local TabFarm = window:CreateTab({ name = "Farm" })
local TabUpgrades = window:CreateTab({ name = "Upgrades" })
local TabShop = window:CreateTab({ name = "Misc" })
local TabTele = window:CreateTab({ name = "Teleports" })
local cfgTab = window:CreateTab({ name = "Configs" })

-- ===================== FARM TAB =====================
do
	local chestSec = TabFarm:CreateSection({ name = "Auto Chests" })

	-- NOTE: Flags.AutoBoard had a loop in the original but no visible toggle;
	-- exposed here so the feature is actually usable
	chestSec:CreateToggle({
		name = "Auto Board",
		value = false,
		callback = function(v)
			Flags.AutoBoard = v
			notify(v and "Auto Board Enabled" or "Auto Board Disabled")
		end,
	})

	chestSec:CreateToggle({
		name = "Auto Chests",
		value = Flags.AutoChests,
		callback = function(v)
			Flags.AutoChests = v
			notify(v and "Auto Chests Enabled" or "Auto Chests Disabled", v and "Collecting..." or "Stopped")
		end,
	})

	chestSec:CreateDropdown({
		name = "Chest Selection",
		options = { "All Chests", "Normal Chests Only", "Mythic Chest Only" },
		value = STATE2.ChestSelection,
		callback = function(v)
			STATE2.ChestSelection = v
			setFlag("ChestSelection", v)
		end,
		noreg = true,
	})

	chestSec:CreateToggle({
		name = "Return to Start",
		value = STATE2.ReturnToStart,
		callback = function(v)
			STATE2.ReturnToStart = v
			notify(v and "Return Enabled" or "Return Disabled")
		end,
		noreg = true,
	})

	local fragSec = TabFarm:CreateSection({ name = "Auto Fragments" })
	fragSec:CreateToggle({
		name = "Auto Fragments Click",
		value = Flags.AutoFragments,
		callback = function(v)
			Flags.AutoFragments = v
			notify(v and "Fragments Enabled" or "Fragments Disabled", "")
		end,
	})
	fragSec:CreateSlider({
		name = "Fragments Interval",
		range = { 0.03, 1 },
		increment = 0.05,
		value = STATE2.FragInterval,
		callback = function(v) STATE2.FragInterval = v end,
		noreg = true,
	})

	local rubSec = TabFarm:CreateSection({ name = "Auto Rubins" })
	rubSec:CreateToggle({
		name = "Auto Rubins Exchange",
		value = Flags.AutoRubins,
		callback = function(v)
			Flags.AutoRubins = v
			notify(v and "Rubins Enabled" or "Rubins Disabled")
		end,
	})
	rubSec:CreateSlider({
		name = "Rubins Interval",
		range = { 0.5, 10 },
		increment = 0.5,
		value = STATE2.RubinsInterval,
		callback = function(v) STATE2.RubinsInterval = v end,
		noreg = true,
	})

	local presSec = TabFarm:CreateSection({ name = "Auto Prestige" })
	presSec:CreateToggle({
		name = "Auto Prestige",
		value = Flags.AutoPrestige,
		callback = function(v)
			Flags.AutoPrestige = v
			notify(v and "Auto Prestige Enabled" or "Auto Prestige Disabled")
		end,
	})

	local dualSec = TabFarm:CreateSection({ name = "Dual Stand" })
	dualSec:CreateToggle({
		name = "Dual Stand (Diamonds + Books)",
		value = Flags.DualStand,
		callback = function(v)
			Flags.DualStand = v
			notify(v and "Dual Stand Enabled" or "Dual Stand Disabled")
		end,
	})
end

STATE.onCleanup(function()
	Flags.AutoBoard = false
	Flags.AutoFragments = false
	Flags.AutoRubins = false
	Flags.AutoUpgrades = false
	Flags.AutoPrestige = false
	Flags.AutoChests = false
	Flags.DualStand = false
	print("[LiquidHub] loops cleaned GEN=" .. STATE.GEN)
end)

-- ===================== FARM LOOPS (1:1 from ChessInc) =====================
-- Auto Board
loop("AutoBoard", 0.15, function()
	if Flags.AutoBoard and BoardRemote then
		pcall(function() BoardRemote:FireServer("RequestMove") end)
	end
end)

-- Auto Fragments: task.wait directly so the interval slider applies live
-- (the fixed-interval loop() runner can't go below its 0.1s poll granularity)
task.spawn(function()
	while STATE.alive() do
		if Flags.AutoFragments and FragmentsClick then
			pcall(function() FragmentsClick:FireServer() end)
		end
		task.wait(math.max(0.03, tonumber(STATE2.FragInterval) or 0.2))
	end
end)

-- Auto Rubins: task.wait directly so the interval slider applies live
task.spawn(function()
	while STATE.alive() do
		if Flags.AutoRubins and RubinsExchangeRequest then
			pcall(function() RubinsExchangeRequest:InvokeServer(1) end)
		end
		task.wait(math.max(0.5, tonumber(STATE2.RubinsInterval) or 1.5))
	end
end)

-- Auto Prestige
loop("AutoPrestige", 2, function()
	if Flags.AutoPrestige and PrestigeRequest then
		local ok, res = pcall(function() return PrestigeRequest:InvokeServer("State") end)
		if ok and res and res.State and res.State.CanPrestige then
			pcall(function() PrestigeRequest:InvokeServer("Prestige") end)
			notify("Prestige", "Prestiged!", 3)
		end
	end
end)

-- Dual Stand farm: alternates between Diamonds and Books buttons to get both currencies
do
	local diamondPos = nil
	local bookPos = nil
	pcall(function() diamondPos = workspace.UpgradesFolder.Diamonds.DiamondButton:GetPivot().Position end)
	pcall(function() bookPos = workspace.UpgradesFolder.Books.BookButton:GetPivot().Position end)
	if not diamondPos then diamondPos = Vector3.new(-96.9, 2.5, -64) end
	if not bookPos then bookPos = Vector3.new(86.3, 2.6, -81.7) end
	loop("DualStand", 0.5, function()
		if not Flags.DualStand then return end
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Method 1: Try firetouchinterest for both without moving (if available)
			local dTop = workspace.UpgradesFolder.Diamonds.DiamondButton:FindFirstChild("Top")
			local bTop = workspace.UpgradesFolder.Books.BookButton:FindFirstChild("Top")
			local bZone = workspace.UpgradesFolder.Books.BookZone and workspace.UpgradesFolder.Books.BookZone:FindFirstChild("Zone")
			if firetouchinterest and dTop and bTop then
				pcall(function() firetouchinterest(hrp, dTop, 0) firetouchinterest(hrp, bTop, 0) if bZone then firetouchinterest(hrp, bZone, 0) end end)
				task.wait(0.1)
				pcall(function() firetouchinterest(hrp, dTop, 1) firetouchinterest(hrp, bTop, 1) if bZone then firetouchinterest(hrp, bZone, 1) end end)
			end
			-- Method 2: Rapid teleport between the two (ensures server sees standing)
			pcall(function() hrp.CFrame = CFrame.new(diamondPos + Vector3.new(0, 3, 0)) end)
			task.wait(0.25)
			pcall(function() hrp.CFrame = CFrame.new(bookPos + Vector3.new(0, 3, 0)) end)
			task.wait(0.25)
			-- Method 3: Enlarge hitboxes on client to cover both (if server checks client size, helps)
			pcall(function()
				if dTop then dTop.Size = Vector3.new(500, 10, 500) dTop.CanTouch = true end
				if bTop then bTop.Size = Vector3.new(500, 10, 500) bTop.CanTouch = true end
				if bZone then bZone.Size = Vector3.new(500, 10, 500) bZone.CanTouch = true end
			end)
		end
	end)
end

-- Auto Chests farm: mythic first (global instant), then normal private, with return
do
	local function tryCollect(id)
		if Collect then
			pcall(function() Collect:FireServer(id) end)
			task.wait(0.2)
			if not workspace:FindFirstChild("ClientChests") or not workspace.ClientChests:FindFirstChild("Chest_" .. id) then return true end
			pcall(function() Collect:FireServer(tostring(id)) end)
			task.wait(0.2)
			if not workspace.ClientChests:FindFirstChild("Chest_" .. id) then return true end
			pcall(function() Collect:FireServer() end)
			task.wait(0.2)
			if not workspace.ClientChests:FindFirstChild("Chest_" .. id) then return true end
		end
		return false
	end
	loop("AutoChests", 1, function()
		if not Flags.AutoChests then return end
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local startPos = hrp.CFrame
		local did = false
		-- Mythic FIRST - global, must be instant
		if STATE2.ChestSelection ~= "Normal Chests Only" and RS:GetAttribute("GlobalChestActive") == true then
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
							pcall(function() hrp.CFrame = CFrame.new(gpos + Vector3.new(0, 4, 0)) end)
							task.wait(0.4)
							local gid = RS:GetAttribute("GlobalChestId")
							if gid and Collect then pcall(function() Collect:FireServer(gid) end) task.wait(0.2) pcall(function() Collect:FireServer(tostring(gid)) end) task.wait(0.2) pcall(function() Collect:FireServer() end) task.wait(0.2) end
							task.wait(0.3)
						end
					end
				end
			end
		end
		-- Normal chests - private, only if mythic not just done (to avoid double TP)
		if STATE2.ChestSelection ~= "Mythic Chest Only" then
			local mythicActive = RS:GetAttribute("GlobalChestActive") == true and STATE2.ChestSelection ~= "Normal Chests Only" and workspace:FindFirstChild("GlobalChestClient") and workspace.GlobalChestClient:FindFirstChild("GlobalChest")
			if not mythicActive then
				local chestsFolder = workspace:FindFirstChild("ClientChests")
				if chestsFolder then
					for _, chest in ipairs(chestsFolder:GetChildren()) do
						if not Flags.AutoChests or not STATE.alive() then break end
						-- If mythic spawns mid-loop, break and handle it next cycle
						if RS:GetAttribute("GlobalChestActive") == true and STATE2.ChestSelection ~= "Normal Chests Only" and workspace:FindFirstChild("GlobalChestClient") and workspace.GlobalChestClient:FindFirstChild("GlobalChest") then break end
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
						pcall(function() hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, 3, 0)) end)
						task.wait(0.5)
						local collected = tryCollect(id)
						if not collected then
							for _ = 1, 2 do
								if not Flags.AutoChests then break end
								local hum2 = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
								if hum2 and hum2.MoveDirection.Magnitude > 0.15 then break end
								pcall(function() hrp.CFrame = CFrame.new(chestPos + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))) end)
								task.wait(0.4)
								if not workspace.ClientChests:FindFirstChild("Chest_" .. id) then break end
							end
						end
						did = true
						task.wait(0.5)
					end
				end
			end
		end
		if did and STATE2.ReturnToStart and startPos then
			local hum4 = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
			if not hum4 or hum4.MoveDirection.Magnitude < 0.1 then
				pcall(function() hrp.CFrame = startPos end)
				task.wait(0.3)
			end
		end
	end)
end

-- ===================== UPGRADES TAB =====================
local upgradeIds = { "ChessMulti", "ChessVicPointsMulti", "ClickSpeed", "GoldenChance", "MoveSpeed", "WinChance", "VicAuraMulti", "VicBooksMulti", "VicChessMulti", "VicDiamondsMulti", "VicPointsMulti", "VicRubiesMulti", "DiamondBooksMulti", "DiamondButtonSpeed", "DiamondChessMulti", "DiamondDiamondsMulti", "DiamondMoreBulk", "DiamondMoreDiamonds", "DiamondRubiesMulti", "BookAuraMulti", "BookBooksMulti", "BookButtonSpeed", "BookMoreKeys", "BookRuneLuck", "BookRuneSpeed", "AuraAuraMulti", "AuraAuraSpeed", "AuraChessMulti", "AuraMoreAura", "AuraMoreBulk", "AuraRuneLuck", "AuraStatsMulti", "SquaresAuraMulti", "SquaresChessMulti", "SquaresFragmentsMulti", "SquaresMagnetRange", "SquaresMaxItems", "SquaresMulti", "SquaresMutationChance", "SquaresSpawnRate", "SquaresVicPointsMulti", "FragmentAutoClicker", "FragmentBulkMulti", "FragmentClickSpeed", "FragmentDuplicateChance", "FragmentFragmentsMulti", "FragmentMoreFragments", "RubinBooksMulti", "RubinChessMulti", "RubinDiamondsMulti", "RubinKeysChance", "RubinMoreBulk", "RubinRubiesMulti" }
local selectedUpgrades = { "ChessMulti" }
local buyMode = "Buy"

do
	local selSec = TabUpgrades:CreateSection({ name = "Auto Buy Upgrades" })

	local selectUpgradesDD = selSec:CreateDropdown({
		name = "Select Upgrades",
		options = upgradeIds,
		value = { "ChessMulti" },
		multiSelect = true,
		callback = function(val)
			if type(val) == "table" then
				selectedUpgrades = val
			elseif type(val) == "string" then
				selectedUpgrades = { val }
			elseif val == nil then
				selectedUpgrades = {}
			end
			if selectedUpgrades and #selectedUpgrades > 0 then
				print("[LiquidHub] selected " .. table.concat(selectedUpgrades, ", "))
			else
				print("[LiquidHub] selected none")
			end
		end,
		noreg = true,
	})

	selSec:CreateButton("Select All / Deselect All", function()
		if selectedUpgrades and #selectedUpgrades == #upgradeIds then
			selectedUpgrades = {}
			pcall(function() selectUpgradesDD.Set({}) end)
			notify("Upgrades", "Deselected all", 2)
		else
			selectedUpgrades = {}
			for _, id in ipairs(upgradeIds) do table.insert(selectedUpgrades, id) end
			pcall(function() selectUpgradesDD.Set(upgradeIds) end)
			notify("Upgrades", "Selected all (" .. #upgradeIds .. ")", 2)
		end
	end)

	selSec:CreateDropdown({
		name = "Buy Mode",
		options = { "Buy", "BuyMax" },
		value = "Buy",
		callback = function(v) buyMode = v end,
		noreg = true,
	})

	selSec:CreateToggle({
		name = "Auto Upgrade",
		value = Flags.AutoUpgrades,
		callback = function(v)
			Flags.AutoUpgrades = v
			notify(v and "Auto Upgrade Enabled" or "Auto Upgrade Disabled", "Mode: " .. buyMode)
		end,
	})

	selSec:CreateButton("Upgrade All Once", function()
		for _, id in ipairs(upgradeIds) do
			pcall(function() UpgradePurchase:InvokeServer(id, buyMode) end)
			task.wait(0.05)
		end
		notify("Upgrade All", "All upgrades attempted (" .. buyMode .. ")")
	end)

	-- Auto Upgrade loop
	loop("AutoUpgrades", 0.2, function()
		if Flags.AutoUpgrades and UpgradePurchase then
			for _, id in ipairs(selectedUpgrades) do
				pcall(function() UpgradePurchase:InvokeServer(id, buyMode) end)
				task.wait(0.05)
			end
		end
	end)
end

-- ===================== MISC TAB =====================
do
	local knownCodes = { "SorryForThat", "3kccu", "5kFavs", "500ccu", "150ccu", "RELEASE", "REBALANCE", "Frog", "1MVisits", "100KVisits", "30KVisits", "100Likes", "100ccu", "1kLikes" }

	local codeSec = TabShop:CreateSection({ name = "Codes" })
	codeSec:CreateButton("Redeem All Codes", function()
		task.spawn(function()
			for _, code in ipairs(knownCodes) do
				local ok, res = pcall(function() return ShopRedeemCode:InvokeServer(code) end)
				local msg = ok and (res.Success and "Success" or tostring(res.Reason)) or "Error"
				notify("Code: " .. code, msg, 2)
				task.wait(0.65)
			end
			notify("Codes", "All codes processed")
		end)
	end)

	-- ===================== ANTI-AFK (same as Sticks_Inc2_) =====================
	local afkSec = TabShop:CreateSection({ name = "Session" })
	afkSec:CreateToggle({
		name = "Anti-AFK",
		value = false,
		callback = function(v) setFlag("AntiAFK", v) end,
	})
	-- Two layers: (1) if the game ships an idle-rejoin remote (Sticks-style),
	-- poke it on a timer; (2) universal fallback — on the client's Idled signal,
	-- simulate input via VirtualUser so Roblox's own ~20-min idle kick never
	-- fires. The Idled connection is made ONCE (connecting it inside a loop
	-- would stack a new handler every cycle); the flag gates whether it acts.
	pcall(function()
		local vu = game:GetService("VirtualUser")
		LocalPlayer.Idled:Connect(function()
			if not getFlag("AntiAFK") then return end
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end)
	loop("AntiAFK", 240, function()
		if not getFlag("AntiAFK") then return end
		pcall(function()
			local net = RS:FindFirstChild("IdleAutoRejoinNetwork")
			if net and net:FindFirstChild("Activity") then
				net.Activity:FireServer("Activity")
			end
		end)
	end)
end

-- ===================== TELEPORTS TAB =====================
do
	local tpFolder = workspace:FindFirstChild("PrestigeTeleports")
	local tpNames = {}
	if tpFolder then
		for _, v in ipairs(tpFolder:GetChildren()) do table.insert(tpNames, v.Name) end
		table.sort(tpNames)
	else
		tpNames = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
	end

	local islSec = TabTele:CreateSection({ name = "Prestige Islands" })
	islSec:CreateButton("Teleport All Prestige Islands", function()
		task.spawn(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not hrp or not tpFolder then notify("Teleport", "Failed") return end
			for _, name in ipairs(tpNames) do
				local t = tpFolder:FindFirstChild(name)
				if t then hrp.CFrame = CFrame.new(t.Position + Vector3.new(0, 5, 0)) task.wait(0.5) end
			end
			notify("Teleport", "Done")
		end)
	end)

	local zoneSec = TabTele:CreateSection({ name = "Zones" })
	zoneSec:CreateDropdown({
		name = "Select Zone",
		options = { "Aura", "Books", "Diamonds", "Rubins", "Fragments", "Squares" },
		value = STATE2.ZoneTarget,
		callback = function(v) STATE2.ZoneTarget = v end,
		noreg = true,
	})
	zoneSec:CreateButton("Teleport To Zone", function()
		local zone = workspace:FindFirstChild("UpgradesFolder") and workspace.UpgradesFolder:FindFirstChild(STATE2.ZoneTarget)
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if zone and hrp then
			local dest = nil
			for _, d in ipairs(zone:GetDescendants()) do
				if d:IsA("BasePart") then dest = d break end
			end
			if dest then
				hrp.CFrame = CFrame.new(dest.Position + Vector3.new(0, 5, 0))
				notify("Zone", "Teleported to " .. STATE2.ZoneTarget)
			else
				notify("Zone", "No part found")
			end
		else
			notify("Teleport", "Failed")
		end
	end)
	zoneSec:CreateButton("Back To Spawn", function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(0, 5, 0)
			notify("Teleport", "Back to spawn")
		end
	end)
end

-- ===================== CREDITS =====================
-- (kept minimal here: the original ChessInc had none of its own beyond the
-- window header; the Configs tab takes the remaining space)

-- ===================== CONFIGS =====================
-- Named setups saved to files + optional autoload; same JSON format as the
-- other Liquid Hub scripts, folder ChessInc so configs don't clash.
do
	local CF_DIR = "ChessInc/configs"
	local AUTOLOAD_FILE = "ChessInc/autoload.txt"
	local Http = game:GetService("HttpService")

	local canIO = typeof(writefile) == "function" and typeof(readfile) == "function"
		and typeof(isfile) == "function" and typeof(makefolder) == "function"

	local function ensureDir()
		if not canIO then return false end
		local ok = pcall(function()
			makefolder("ChessInc")
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
		-- main-hub flags + intervals are persisted too (the _Flags block,
		-- same idea as the original ChessInc snapshot)
		data["_Flags"] = { t = "f", v = {
			AutoChests = Flags.AutoChests,
			AutoFragments = Flags.AutoFragments,
			AutoRubins = Flags.AutoRubins,
			AutoPrestige = Flags.AutoPrestige,
			AutoUpgrades = Flags.AutoUpgrades,
			DualStand = Flags.DualStand,
			ChestSelection = STATE2.ChestSelection,
			ReturnToStart = STATE2.ReturnToStart,
			FragInterval = STATE2.FragInterval,
			UpInterval = STATE2.UpInterval,
			RubinsInterval = STATE2.RubinsInterval,
			SelectedUpgrades = selectedUpgrades,
			BuyMode = buyMode,
		} }
		return data
	end
	local function applyData(data)
		if type(data) ~= "table" then return 0 end
		local n = 0
		for k, sv in pairs(data) do
			if k == "_Flags" and sv.t == "f" and type(sv.v) == "table" then
				local f = sv.v
				if type(f.AutoChests) == "boolean" then Flags.AutoChests = f.AutoChests end
				if type(f.AutoFragments) == "boolean" then Flags.AutoFragments = f.AutoFragments end
				if type(f.AutoRubins) == "boolean" then Flags.AutoRubins = f.AutoRubins end
				if type(f.AutoPrestige) == "boolean" then Flags.AutoPrestige = f.AutoPrestige end
				if type(f.AutoUpgrades) == "boolean" then Flags.AutoUpgrades = f.AutoUpgrades end
				if type(f.DualStand) == "boolean" then Flags.DualStand = f.DualStand end
				if type(f.ChestSelection) == "string" then STATE2.ChestSelection = f.ChestSelection end
				if type(f.ReturnToStart) == "boolean" then STATE2.ReturnToStart = f.ReturnToStart end
				if type(f.FragInterval) == "number" then STATE2.FragInterval = f.FragInterval end
				if type(f.UpInterval) == "number" then STATE2.UpInterval = f.UpInterval end
				if type(f.RubinsInterval) == "number" then STATE2.RubinsInterval = f.RubinsInterval end
				if type(f.SelectedUpgrades) == "table" then selectedUpgrades = f.SelectedUpgrades end
				if type(f.BuyMode) == "string" then buyMode = f.BuyMode end
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

	-- File management
	local fileSec = cfgTab:CreateSection({ name = "Config Files" })
	fileSec:CreateLabel(canIO and "Ready • File I/O available" or "File functions missing — executor unsupported")

	local pendingName = ""
	fileSec:CreateInput({
		name = "Config Name",
		placeholder = "my setup (no slashes)",
		callback = function(v) pendingName = tostring(v or "") end,
		noreg = true,
	})

	local selected = nil
	local listDD = fileSec:CreateDropdown({
		name = "Saved Configs",
		options = {},
		value = nil,
		callback = function(v)
			if type(v) == "table" then selected = v[1] else selected = v end
		end,
		noreg = true,
	})

	local function refreshList()
		local names = listConfigs()
		pcall(function() listDD.Refresh(names) end)
		if selected and not table.find(names, selected) then selected = nil end
		return names
	end

	-- Actions
	local actSec = cfgTab:CreateSection({ name = "Actions" })

	actSec:CreateButton("Save Current Setup", function()
		local name = safeName(pendingName)
		if not name then window:Notify({ title = "Configs", content = "Type a config name first" }) return end
		if not canIO then window:Notify({ title = "Configs", content = "File functions missing" }) return end
		ensureDir()
		local ok = pcall(function()
			writefile(cfgPath(name), Http:JSONEncode(snapshot()))
		end)
		if ok then
			refreshList()
			listDD.Set(name)
			selected = name
			window:Notify({ title = "Configs", content = "Saved " .. name })
		else
			window:Notify({ title = "Configs", content = "Save failed" })
		end
	end)

	actSec:CreateButton("Load Selected", function()
		if not selected then window:Notify({ title = "Configs", content = "Select a config first" }) return end
		local ok, txt = pcall(function() return readfile(cfgPath(selected)) end)
		if not ok or type(txt) ~= "string" then window:Notify({ title = "Configs", content = "Read failed" }) return end
		local ok2, data = pcall(function() return Http:JSONDecode(txt) end)
		if not ok2 or type(data) ~= "table" then window:Notify({ title = "Configs", content = "Bad file" }) return end
		local n = applyData(data)
		window:Notify({ title = "Configs", content = "Loaded " .. selected .. " (" .. n .. ")" })
	end)

	actSec:CreateButton("Delete Selected", function()
		if not selected then window:Notify({ title = "Configs", content = "Select a config first" }) return end
		pcall(function() delfile(cfgPath(selected)) end)
		if getAutoload() == selected then clearAutoload() end
		selected = nil
		refreshList()
		listDD.Set(nil)
		window:Notify({ title = "Configs", content = "Deleted" })
	end)

	-- ===================== THEMES =====================
	local themeSec = cfgTab:CreateSection({ name = "Theme" })
	themeSec:CreateDropdown({
		name = "UI Theme",
		options = { "Ocean", "Midnight", "Aqua", "Blood" },
		value = "Ocean",
		callback = function(choice)
			if type(choice) == "string" then
				pcall(function() WindowRaw:SetTheme(choice) end)
			end
		end,
		noreg = true,
	})

	-- Autoload
	local autoSec = cfgTab:CreateSection({ name = "Autoload" })
	local autoT -- forward declaration: the callback must close over the local
	autoT = autoSec:CreateToggle({
		name = "Autoload Selected on Start",
		value = false,
		callback = function(v)
			if v then
				if not selected then
					window:Notify({ title = "Configs", content = "Select a config first" })
					autoT.Set(false)
					return
				end
				if setAutoload(selected) then
					window:Notify({ title = "Configs", content = "Autoload: " .. selected })
				else
					window:Notify({ title = "Configs", content = "Autoload failed" })
				end
			else
				clearAutoload()
				window:Notify({ title = "Configs", content = "Autoload off" })
			end
		end,
		noreg = true,
	})

	local names = refreshList()
	local auto = getAutoload()
	if auto and table.find(names, auto) then
		selected = auto
		pcall(function() listDD.Set(auto) end)
		pcall(function() autoT.Set(true) end)
	end

	-- Autoload: apply a few seconds after start so the whole UI exists.
	task.delay(3, function()
		pcall(function()
			local a = getAutoload()
			if a and a ~= "" then
				local ok, txt = pcall(function() return readfile(cfgPath(a)) end)
				if ok and type(txt) == "string" then
					local ok2, data = pcall(function() return Http:JSONDecode(txt) end)
					if ok2 and type(data) == "table" then
						local n = applyData(data)
						window:Notify({ title = "Configs", content = "Autoloaded " .. a .. " (" .. n .. ")" })
					end
				end
			end
		end)
	end)
end

notify("Liquid Hub Loaded", "Press RightShift to toggle. GEN=" .. STATE.GEN, 4)
print("[LiquidHub] ChessInc Ready GEN=" .. STATE.GEN)
