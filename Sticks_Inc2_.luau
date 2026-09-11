-- Sticks_Inc2_ | Sticks Incremental 2 | Liquid Hub (Nebula UI)
-- Ported from "Sticks Inc 2.luau" (WindUI) onto the new Liquid Hub UI lib.
-- All farm logic (World 1/2/3, Upgrades, Teleports, Misc) is preserved 1:1;
-- only the UI adapter layer changed. Folder: SticksInc2 | Flags: SI2_

-- AUTO Plugin fix for Delta / WindUI (1 loadstring, no external wrapper needed)
pcall(function()
	local set = setthreadidentity or set_thread_identity or setthreadcontext or _G.set_identity
	if set then pcall(set, 8) pcall(set, 7) end
end)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local function getFlag(n) return RS:GetAttribute("SI2_" .. n) end
local function setFlag(n, v) RS:SetAttribute("SI2_" .. n, v) end

-- Every load stamps a unique generation into the DataModel. Loops check it, so a
-- loop left running by an EARLIER execution of this script stops as soon as a new
-- copy loads (prevents duplicate loops fighting over the character).
local LOAD_GEN = math.floor(os.clock() * 100000) % 1000000 + math.random(1, 999) * 1000000
RS:SetAttribute("SI2_LoadGen", LOAD_GEN)
local function isCurrentGen() return RS:GetAttribute("SI2_LoadGen") == LOAD_GEN end

if RS:GetAttribute("SI2_AutoRaidOn") == nil then RS:SetAttribute("SI2_AutoRaidOn", false) end
if RS:GetAttribute("SI2_AutoShrineOn") == nil then RS:SetAttribute("SI2_AutoShrineOn", true) end
if RS:GetAttribute("SI2_AutoFarmOn") == nil then RS:SetAttribute("SI2_AutoFarmOn", false) end
if RS:GetAttribute("SI2_AutoPortalOn") == nil then RS:SetAttribute("SI2_AutoPortalOn", false) end
if RS:GetAttribute("SI2_MagnetOn") == nil then RS:SetAttribute("SI2_MagnetOn", false) end
if RS:GetAttribute("SI2_AutoChestsOn") == nil then RS:SetAttribute("SI2_AutoChestsOn", false) end
if RS:GetAttribute("SI2_AutoUpgradeOn") == nil then RS:SetAttribute("SI2_AutoUpgradeOn", false) end
if RS:GetAttribute("SI2_AutoTreeOn") == nil then RS:SetAttribute("SI2_AutoTreeOn", false) end
if RS:GetAttribute("SI2_AutoReplayOn") == nil then RS:SetAttribute("SI2_AutoReplayOn", false) end
if RS:GetAttribute("SI2_AutoPickOn") == nil then RS:SetAttribute("SI2_AutoPickOn", false) end
if RS:GetAttribute("SI2_NoclipOn") == nil then RS:SetAttribute("SI2_NoclipOn", false) end
if RS:GetAttribute("SI2_HideNameOn") == nil then RS:SetAttribute("SI2_HideNameOn", false) end

local function isPaused() return false end

-- Shared resume table: systems wrapped in do-blocks (chunk-register slimming,
-- the executor caps chunk locals at 200) publish their loop starters here
-- instead of leaking locals to the end of the chunk.
local Resume = {}

-- Clean up any leftover UI from previous versions
pcall(function()
	local __au = game.CoreGui:FindFirstChild("AutoUpgradeUI")
	if __au then __au:Destroy() end
end)
pcall(function()
	local rg = game.CoreGui:FindFirstChild("RobloxGui")
	if rg and rg:FindFirstChild("Luna UI") then rg["Luna UI"]:Destroy() end
	if rg and rg:FindFirstChild("Luna-Old") then rg["Luna-Old"]:Destroy() end
end)

-- Destroy any previous hub window (WindUI/Rayfield/Nebula create a fresh
-- ScreenGui each time). Without this every reload stacks another window.
pcall(function()
	local rg = game.CoreGui:FindFirstChild("RobloxGui")
	local parents = { game.CoreGui }
	if rg then parents[#parents + 1] = rg end
	pcall(function()
		local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
		if pg then parents[#parents + 1] = pg end
	end)
	for _, parent in ipairs(parents) do
		for _, sg in ipairs(parent:GetChildren()) do
			if sg:IsA("ScreenGui") and sg ~= rg then
				local hit = false
				for _, c in ipairs(sg:GetDescendants()) do
					if (c:IsA("TextLabel") or c:IsA("TextButton"))
						and (c.Text == "Auto-Upgrade Items" or c.Text == "Magnet" or c.Text == "Final Swarm Hub" or c.Text == "Liquid Hub" or c.Text == "Auto Raid Farm" or c.Text == "Auto Collect Exp" or c.Text == "Sticks Inc 2") then
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
			warn("[Sticks Inc 2] Compile error: " .. tostring(cerr))
		end
	end
end
if not Liquid then
	warn("[Sticks Inc 2] Failed to load Liquid Hub library from all sources")
	return
end

-- ===================== GAME DETECTION (for the title bar) =====================
local GAME_NAME = "Sticks Incremental 2"
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

-- ===================== OLD-TEMPLATE -> NEBULA ADAPTER =====================
-- Весь фарм-код ниже продолжает звать tab:CreateToggle / CreateSlider /
-- CreateDropdown / CreateSection / CreateButton / Paragraph / window:Notify в
-- старом формате, а здесь они тихо переводятся на Nebula. Логика не тронута.

local function adaptSection(sect)
	local s = {}

	function s:CreateLabel(o)
		return sect:CreateLabel(type(o) == "table" and (o.name or o.Title or "") or o)
	end

	-- WindUI Paragraph: Title + Desc with SetDesc updating only the desc part
	function s:Paragraph(o)
		o = o or {}
		local title = o.Title or o.name or ""
		local prefix = (title ~= "" and (title .. ": ") or "")
		local obj = sect:CreateLabel(prefix .. tostring(o.Desc or o.Value or ""))
		local handle
		handle = {
			SetDesc = function(a, b)
				local v = (b == nil) and a or b -- tolerate :SetDesc("x") and .SetDesc("x")
				pcall(function() obj.Text = prefix .. tostring(v) end)
			end,
			Set = function(a, b)
				local v = (b == nil) and a or b
				pcall(function() obj.Text = prefix .. tostring(v) end)
			end,
		}
		return handle
	end
	s.CreateParagraph = s.Paragraph

	function s:CreateToggle(o)
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
		local initVal = o.value
		local entry = { kind = "dropdown", multi = o.multiSelect or false }
		local function wrappedCb(v)
			entry.current = v
			if o.callback then return o.callback(v) end
		end
		local obj
		if o.multiSelect then
			obj = sect:CreateMultiDropdown(o.name, o.options or {}, initVal or {}, wrappedCb, o.name)
		elseif type(o.options) == "table" and #o.options > 20 then
			obj = sect:CreateSearchDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)
		else
			obj = sect:CreateDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)
		end
		-- wrapper adds the old WindUI :Select() method (dd:Select(list)) on top
		-- of the Nebula Set/Refresh/Get handle
		local wrapper = {
			Set = obj.Set,
			Get = obj.Get,
			Refresh = obj.Refresh,
			Select = function(_, v) pcall(function() obj.Set(v) end) end,
			obj = obj,
		}
		entry.obj = wrapper
		entry.apply = function(v)
			if type(v) ~= "string" and type(v) ~= "table" then return end
			pcall(function() obj.Set(v) end)
			pcall(function() wrappedCb(v) end)
		end
		if o.name and not o.noreg then Reg[o.name] = entry end
		return wrapper
	end

	function s:CreateSection(o)
		-- Nebula nests sections under tabs; a nested call adds a labeled row
		local nm = o and (o.name or o.Title) or ""
		if type(nm) == "string" and nm ~= "" then
			sect:CreateLabel("— " .. nm)
		end
		return s
	end

	function s:CreateButton(o, cb)
		o = normOpts(o, cb)
		return sect:CreateButton(o.name, o.callback)
	end

	function s:CreateStat(o)
		o = normOpts(o)
		local prefix = (o.name or "") .. ": "
		local obj = sect:CreateLabel(prefix .. tostring(o.value))
		return {
			SetDesc = function(a, b)
				local v = (b == nil) and a or b
				pcall(function() obj.Text = prefix .. tostring(v) end)
			end,
			Set = function(a, b)
				local v = (b == nil) and a or b
				pcall(function() obj.Text = prefix .. tostring(v) end)
			end,
		}
	end

	function s:CreateInput(o)
		o = normOpts(o)
		return sect:CreateTextbox(o.name, o.placeholder, o.callback, o.name)
	end

	function s:CreateKeybind(o, cb)
		o = normOpts(o, cb)
		return sect:CreateKeybind(o.name, o.value, o.callback, o.name)
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
	function t:CreateStat(o) return cur():CreateStat(o) end
	function t:CreateInput(o) return cur():CreateInput(o) end
	function t:Paragraph(o) return cur():Paragraph(o) end
	t.CreateParagraph = t.Paragraph

	function t:Divider() end
	function t:Space() end

	return t
end

local window = {}
window._raw = WindowRaw
window._tabIcons = { ["World 1"] = "🌱", ["World 2"] = "🔥", ["World 3"] = "🌊", Upgrades = "⬆️", Teleports = "🗺️", Misc = "🔧", Configs = "💾", Credits = "ℹ️" }
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

-- tab order: World 1, World 2, World 3, Upgrades, Teleports, Misc, Configs, Credits
local w1Tab = window:CreateTab({ name = "World 1" })
local w2Tab = window:CreateTab({ name = "World 2" })
local w3Tab = window:CreateTab({ name = "World 3" })
local upgTab = window:CreateTab({ name = "Upgrades" })
local tpTab = window:CreateTab({ name = "Teleports" })
local misc = window:CreateTab({ name = "Misc" })
local cfgTab = window:CreateTab({ name = "Configs" })
local credits = window:CreateTab({ name = "Credits" })

-- ===================== LIQUID HUB CORE (Real live-reload contract) =====================
-- Every long-running loop polls STATE.alive() and dies the moment a newer
-- generation loads, so re-running never stacks duplicate loops.
local STATE = _G.STATE
if typeof(STATE) ~= "table" then STATE = {} end
STATE.GEN = math.floor(os.clock() * 100000)
RS:SetAttribute("SI2_LiquidGen", STATE.GEN)
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
		return RS:GetAttribute("SI2_LiquidGen") == STATE.GEN and isCurrentGen()
	end
end

local lp = Players.LocalPlayer
local function cur(name)
	return tonumber(lp:GetAttribute("Currency_" .. name)) or 0
end
local function attr(n)
	return lp:GetAttribute(n)
end

-- Interval-driven loop runner: pcall-protected, alive-checked, slider-friendly.
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

local function getHRP()
	local char = lp.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local World = workspace:FindFirstChild("World")
local function posOf(inst)
	if not inst then return nil end
	local p = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position or nil
end

-- Teleport with 2s position verification (detects server anti-teleport).
local function tpTo(pos, label)
	local hrp = getHRP()
	if not hrp or not pos then return false end
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	task.delay(2, function()
		if not STATE.alive() then return end
		local h = getHRP()
		if h and (h.Position - pos).Magnitude > 30 then
			window:Notify({ title = "Teleport", content = (label or "?") .. ": moved back " .. math.floor((h.Position - pos).Magnitude) .. " studs (server check)", duration = 5 })
		end
	end)
	return true
end

-- Beach (World 3): driftwood streams beach along this sand. The beach is one
-- LONG shoreline road, so besides the center point we keep its two ends
-- (derived from BeachGround's long axis) for the patrol sweep.
local BEACH_POS, BEACH_ENDS
do
	local mp = World and World:FindFirstChild("MainParts")
	local bg = mp and mp:FindFirstChild("BeachGround")
	local p = bg and bg:IsA("BasePart") and bg.Position or nil
	BEACH_POS = p or Vector3.new(-628, -19, -34)
	if bg and bg:IsA("BasePart") then
		local s = bg.Size
		if s.X >= s.Z then
			BEACH_ENDS = { BEACH_POS - Vector3.new(s.X * 0.45, 0, 0), BEACH_POS + Vector3.new(s.X * 0.45, 0, 0) }
		else
			BEACH_ENDS = { BEACH_POS - Vector3.new(0, 0, s.Z * 0.45), BEACH_POS + Vector3.new(0, 0, s.Z * 0.45) }
		end
	else
		BEACH_ENDS = { BEACH_POS, BEACH_POS }
	end
end

-- ===================== FARM =====================
do
	-- flags
	if getFlag("AutoFarmOn") == nil then setFlag("AutoFarmOn", false) end
	if getFlag("AutoConvertOn") == nil then setFlag("AutoConvertOn", false) end
	if getFlag("AutoDrywoodOn") == nil then setFlag("AutoDrywoodOn", false) end
	if getFlag("AutoSeedsOn") == nil then setFlag("AutoSeedsOn", false) end
	if getFlag("AutoDriftwoodOn") == nil then setFlag("AutoDriftwoodOn", false) end
	if getFlag("AutoSubmergeOn") == nil then setFlag("AutoSubmergeOn", false) end
	if getFlag("AutoDriftwoodTierOn") == nil then setFlag("AutoDriftwoodTierOn", false) end
	if getFlag("AutoMerchantOn") == nil then setFlag("AutoMerchantOn", false) end
	if getFlag("SmartCharcoalOn") == nil then setFlag("SmartCharcoalOn", false) end
	if getFlag("SmartIgniteOn") == nil then setFlag("SmartIgniteOn", false) end
	-- legacy flags wiped so stale saved-config values cannot re-enable removed features
	setFlag("AutoDriftwoodOn", nil)
	setFlag("DrywoodInterval", nil)

	-- ==================== WORLD 1 ====================
	w1Tab:CreateSection({ name = "Auto Farm Sticks" })

	-- Auto Sticks: glides the character from stick to stick with a Tween; the
	-- game's own pickup loop fires valid StickPickupRequest once we enter
	-- Stat_PickupRadius of each stick.
	w1Tab:CreateToggle({
		name = "Auto Farm Sticks",
		desc = "Tween-glides you between sticks (pickup radius does the rest)",
		value = getFlag("AutoFarmOn"),
		callback = function(v) setFlag("AutoFarmOn", v) end,
	})
	w1Tab:CreateSlider({
		name = "Tween Speed",
		desc = "Glide speed in studs per second",
		range = { 30, 400 },
		increment = 10,
		value = getFlag("TweenSpeed") or 150,
		callback = function(v) setFlag("TweenSpeed", v) end,
	})

	-- Auto Burn: the campfire board's Burn button protocol converts from
	-- anywhere, so sticks burn remotely while farming never stops.
	w1Tab:CreateSection({ name = "Auto Burn" })
	w1Tab:CreateToggle({
		name = "Auto Burn",
		value = getFlag("AutoConvertOn"),
		callback = function(v) setFlag("AutoConvertOn", v) end,
	})
	w1Tab:CreateSlider({
		name = "Burn Every",
		desc = "Seconds between burns",
		range = { 5, 300 },
		increment = 5,
		value = getFlag("ConvertInterval") or 30,
		callback = function(v) setFlag("ConvertInterval", v) end,
	})
	local burnStatus = w1Tab:Paragraph({
		Title = "Burn Status",
		Desc = "off",
	})

	w1Tab:CreateToggle({
		name = "Auto Claim Seeds",
		desc = "Claims seed reward when its 8h cooldown is ready",
		value = getFlag("AutoSeedsOn"),
		callback = function(v) setFlag("AutoSeedsOn", v) end,
	})

	w1Tab:CreateSection({ name = "Smart Auto Rebirth" })
	w1Tab:CreateToggle({
		name = "Smart Auto Rebirth",
		desc = "Rebirths only when the gain pays for the next Rebirth upgrade or Rebirth tree node; burns leftover sticks first so their cash joins the gain; never rebirths when nothing is left to buy",
		value = getFlag("SmartRebirthOn") == true,
		callback = function(v) setFlag("SmartRebirthOn", v) end,
	})
	w1Tab:CreateSection({ name = "Auto Awaken" })

	-- ================= Farm (tween glide) + Auto Burn (remote) =================
	local spawnHolders = (World and World:FindFirstChild("StickSpawns")) or workspace:FindFirstChild("StickSpawns", true)
	local stickContainer = nil
	do
		local s = workspace:FindFirstChild("Stick", true)
		stickContainer = s and s.Parent or nil
	end
	local function settle(hrp)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	local function nearestOf(hrp, candidates)
		local best, bd
		for _, c in ipairs(candidates) do
			local p = posOf(c)
			if p then
				local d = (p - hrp.Position).Magnitude
				if not bd or d < bd then best, bd = c, d end
			end
		end
		return best, bd
	end
	local farmTweenService = game:GetService("TweenService")
	local farmTween, farmTarget, farmWasOn = nil, nil, false
	local function farmRelease(hrp)
		if farmTween then
			pcall(function() farmTween:Cancel() end)
			farmTween = nil
		end
		farmTarget = nil
		if hrp then
			settle(hrp)
			hrp.Anchored = false
			pcall(function()
				local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			end)
		end
	end
	STATE.onCleanup(function()
		farmRelease(getHRP())
	end)
	loop("FarmTween", 0.1, function()
		local farm = getFlag("AutoFarmOn") and true or false
		local hrp = getHRP()
		if not farm then
			if farmWasOn then
				farmWasOn = false
				farmRelease(hrp)
			end
			return
		end
		if not hrp then return end
		farmWasOn = true
		if farmTarget and not farmTarget.Parent then farmTarget = nil end
		local cands = {}
		if stickContainer and stickContainer.Parent then
			for _, c in ipairs(stickContainer:GetChildren()) do
				if c.Name == "Stick" then table.insert(cands, c) end
			end
		end
		local target
		if #cands > 0 then
			target = nearestOf(hrp, cands)
		else
			target = nearestOf(hrp, spawnHolders and spawnHolders:GetChildren() or {})
		end
		if not target then
			farmRelease(hrp)
			return
		end
		if not hrp.Anchored then
			settle(hrp)
			hrp.Anchored = true
		end
		local tweenDone = (not farmTween) or farmTween.PlaybackState == Enum.PlaybackState.Completed
		if farmTarget ~= target or tweenDone then
			local p = posOf(target)
			if not p then farmTarget = nil return end
			local dest = p + Vector3.new(0, 2, 0)
			local dist = (dest - hrp.Position).Magnitude
			farmTarget = target
			if farmTween then
				pcall(function() farmTween:Cancel() end)
				farmTween = nil
			end
			if dist > 1.2 then
				local speed = tonumber(getFlag("TweenSpeed")) or 150
				if speed < 10 then speed = 10 end
				farmTween = farmTweenService:Create(hrp, TweenInfo.new(math.max(0.05, dist / speed), Enum.EasingStyle.Linear), { CFrame = CFrame.new(dest) })
				farmTween:Play()
			end
		end
	end)

	-- ================= Auto Burn (remote campfire burn) =================
	local burnPending, burnNextAt = false, 0
	local burnLastGain = nil
	local burnStatusUpd = 0
	loop("AutoBurn", 0.1, function()
		local now = os.clock()
		local on = getFlag("AutoConvertOn") and true or false
		if not on then
			burnPending = false
		else
			local sticks = cur("Sticks")
			local every = tonumber(getFlag("ConvertInterval")) or 30
			if every < 5 then every = 5 end
			local lastB = getFlag("ConvertLast") or 0
			if lastB > now + 1 then lastB = 0 end -- stale stamp restored from a saved config
			-- STRICT interval only. There is deliberately NO "burn when full"
			-- check: Stat_MaxSticks stays at the base 70 while real capacity
			-- grows into the thousands, so that check meant burning instantly
			-- on every pickup.
			local due = sticks > 0 and (now - lastB >= every)
			if due or (burnPending and sticks > 0) then
				if not burnPending then
					burnPending = true
					burnNextAt = 0
				end
				if now >= burnNextAt then
					burnNextAt = now + 2 -- fallback refire if no result arrives
					pcall(function()
						RS.CampfireNetwork.ConvertRequest:FireServer("Board")
					end)
				end
			end
		end
		-- live status line: the server burn cooldown (30-75s at high levels)
		-- is silent, so without this it looks like nothing is happening
		if now - burnStatusUpd >= 0.5 then
			burnStatusUpd = now
			local sticks = cur("Sticks")
			local txt
			if not on then
				txt = "off"
			elseif burnPending then
				txt = "burning... waiting for the server cooldown"
			elseif sticks <= 0 then
				txt = "waiting for sticks"
			else
				local every = tonumber(getFlag("ConvertInterval")) or 30
				if every < 5 then every = 5 end
				local lastB = getFlag("ConvertLast") or 0
				if lastB > now + 1 then lastB = 0 end
				txt = "next burn in " .. math.max(0, math.ceil(lastB + every - now)) .. "s (" .. math.floor(sticks) .. " sticks waiting)"
			end
			if burnLastGain then
				txt = txt .. " | last: +" .. tostring(math.floor(burnLastGain * 100) / 100)
			end
			pcall(function()
				burnStatus:SetDesc(txt)
			end)
		end
	end)
	-- Burn result protocol: (ok, ?, gain, newCash, status). Failure status is
	-- "Cooldown" (server burn cooldown, grows with progression) or "NoSticks".
	-- Retry 0.45s after every failure, exactly like the game's own client.
	STATE.connect(RS.CampfireNetwork.ConvertResult.OnClientEvent, function(ok, _, gain, newCash, status)
		if not burnPending then return end
		if ok then
			burnPending = false
			burnNextAt = 0
			-- the Burn Every timer counts from the last SUCCESSFUL burn, so
			-- sticks always get the full interval to accumulate
			setFlag("ConvertLast", os.clock())
			burnLastGain = tonumber(gain) or burnLastGain
			pcall(function()
				window:Notify({
					title = "Auto Burn",
					content = "Burned -> +" .. tostring(math.floor((gain or 0) * 100) / 100) .. " cash",
					duration = 4,
				})
			end)
		else
			burnNextAt = os.clock() + 0.45
		end
	end)

	-- ==================== WORLD 2 (drywood click / charcoal / embers) ====================
	w2Tab:CreateSection({ name = "Auto Drywood Click" })
	w2Tab:CreateToggle({
		name = "Auto Drywood Click",
		desc = "Presses as fast as the (upgradeable) server cooldown allows",
		value = getFlag("AutoDrywoodOn"),
		callback = function(v) setFlag("AutoDrywoodOn", v) end,
	})

	w2Tab:CreateSection({ name = "Auto Smart Charcoal" })
	w2Tab:CreateToggle({
		name = "Auto Smart Charcoal",
		desc = "Converts Drywood to Charcoal only when the gain pays for the next Charcoal upgrade or its tree node; never converts when nothing is left to buy",
		value = getFlag("SmartCharcoalOn") == true,
		callback = function(v) setFlag("SmartCharcoalOn", v) end,
	})

	w2Tab:CreateSection({ name = "Auto Smart Ignite (Embers)" })
	w2Tab:CreateToggle({
		name = "Auto Smart Ignite",
		desc = "Ignites only when the Embers gain covers the NEXT Ember milestone threshold (never wastes progress)",
		value = getFlag("SmartIgniteOn") == true,
		callback = function(v) setFlag("SmartIgniteOn", v) end,
	})

	loop("AutoDrywood", 0.1, function()
		if not getFlag("AutoDrywoodOn") then return end
		pcall(function()
			RS.DrywoodNetwork.PressRequest:FireServer()
		end)
	end)

	loop("AutoSeeds", 30, function()
		if not getFlag("AutoSeedsOn") then return end
		pcall(function()
			RS.SeedNetwork.ClaimRequest:FireServer()
		end)
	end)

	-- ==================== WORLD 3 (driftwood / submerge / merchant / tiers) ====================
	w3Tab:CreateSection({ name = "Auto Farm Driftwood" })
	w3Tab:CreateToggle({
		name = "Auto Farm Driftwood",
		desc = "Stands you on the beach; the game auto-picks up beached Driftwood and Oddities",
		value = getFlag("AutoFarmDriftwoodOn"),
		callback = function(v) setFlag("AutoFarmDriftwoodOn", v) end,
	})
	w3Tab:CreateSlider({
		name = "Driftwood Glide Speed",
		desc = "Studs per second while gliding to beached wood",
		range = { 30, 400 },
		increment = 10,
		value = getFlag("DriftGlideSpeed") or 150,
		callback = function(v) setFlag("DriftGlideSpeed", v) end,
	})

	w3Tab:CreateSection({ name = "Auto Submerge" })
	w3Tab:CreateToggle({
		name = "Auto Submerge",
		desc = "Submerges the moment you can afford the next level (resets World 3 progress for bonuses). OFF until you flip it",
		value = getFlag("AutoSubmergeOn") == true,
		callback = function(v) setFlag("AutoSubmergeOn", v) end,
	})

	w3Tab:CreateSection({ name = "Auto Upgrade Driftwood" })
	w3Tab:CreateToggle({
		name = "Auto Upgrade Driftwood",
		desc = "Buys the next Driftwood Tier when affordable (Submerge layer 3+ cuts the cost to 70%)",
		value = getFlag("AutoDriftwoodTierOn") == true,
		callback = function(v) setFlag("AutoDriftwoodTierOn", v) end,
	})

	w3Tab:CreateSection({ name = "Auto Buy Merchant" })
	w3Tab:CreateToggle({
		name = "Auto Buy Merchant",
		desc = "Detects each restock instantly and buys every affordable in-stock card with Coins",
		value = getFlag("AutoMerchantOn") == true,
		callback = function(v) setFlag("AutoMerchantOn", v) end,
	})

	local driftTweenService = game:GetService("TweenService")
	local driftTween, driftTarget, driftWasOn, driftItemDist = nil, nil, false, nil
	local function driftRelease(hrp)
		if driftTween then
			pcall(function() driftTween:Cancel() end)
			driftTween = nil
			driftTarget = nil
		end
		if hrp then
			settle(hrp)
			hrp.Anchored = false
			pcall(function()
				local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			end)
		end
	end
	STATE.onCleanup(function()
		driftRelease(getHRP())
	end)
	-- Pick the beached-item target: the NEAREST streamed item to the character,
	-- with NO distance cap. The beach is a long road and items beach along its
	-- whole length — the old 120-stud radius from the beach center made the
	-- farm camp mid-beach while piles built up at the far ends. While nothing
	-- is in range, patrol the road end-to-end instead of idling at the center.
	local driftPatrolIdx = 1
	local function nearestDriftwood(hrp)
		local f = workspace:FindFirstChild("ClientWorld3StreamVisuals")
		if f then
			local ref = hrp and hrp.Position or BEACH_POS
			local best, bd
			for _, it in ipairs(f:GetChildren()) do
				local p = posOf(it)
				if p then
					local d = (p - ref).Magnitude
					if not bd or d < bd then best, bd = p, d end
				end
			end
			if best then return best, bd end
		end
		-- patrol: walk to one end, turn around, walk to the other
		local pos = hrp and hrp.Position or BEACH_ENDS[1]
		if (pos - BEACH_ENDS[driftPatrolIdx]).Magnitude < 6 then
			driftPatrolIdx = (driftPatrolIdx == 1) and 2 or 1
		end
		return BEACH_ENDS[driftPatrolIdx], nil
	end
	loop("AutoFarmDriftwood", 0.1, function()
		local on = getFlag("AutoFarmDriftwoodOn") and true or false
		local hrp = getHRP()
		if not on then
			if driftWasOn then
				driftWasOn = false
				driftRelease(hrp)
			end
			return
		end
		if not (hrp and World) then return end
		driftWasOn = true
		local dest, itemDist = nearestDriftwood(hrp)
		local dist = (dest - hrp.Position).Magnitude
		if dist > 3 then
			if not hrp.Anchored then
				settle(hrp)
				hrp.Anchored = true
			end
			-- Items beach fast, so chasing every new spawn point-by-point just
			-- jitters in place. Re-target only when the glide finished/arrived,
			-- or when a freshly beached item is meaningfully closer (15+ studs)
			-- than the one we're heading to.
			local arrived = (not driftTween) or driftTween.PlaybackState == Enum.PlaybackState.Completed
			local betterTarget = itemDist and driftItemDist and (itemDist + 15 < driftItemDist)
			if arrived or betterTarget or driftTarget == nil then
				driftTarget = dest
				driftItemDist = itemDist
				if driftTween then
					pcall(function() driftTween:Cancel() end)
					driftTween = nil
				end
				local speed = tonumber(getFlag("DriftGlideSpeed")) or 150
				if speed < 10 then speed = 10 end
				driftTween = driftTweenService:Create(hrp, TweenInfo.new(math.max(0.05, dist / speed), Enum.EasingStyle.Linear), { CFrame = CFrame.new(dest + Vector3.new(0, 3, 0)) })
				driftTween:Play()
			end
		elseif hrp.Anchored then
			settle(hrp)
			hrp.Anchored = false
			driftTarget = nil
			driftItemDist = nil
		end
	end)
end

-- ===================== UPGRADES =====================
do
	-- indirection keeps the static analyzer from trying to resolve DataModel modules
	local function req(m) return require(m) end
	local UC = req(RS.Configs.UpgradeConfig)
	local TC = req(RS.Configs.UpgradeTreeConfig)
	-- exact replica of the game's costFor (UpgradeBoardController): upgrades
	-- with ExtraLevelStartLevel/ExtraLevelBaseCost switch to a much steeper
	-- curve once the level reaches the start level
	local function costForReal(u, lvl)
		local els = tonumber(u.ExtraLevelStartLevel)
		local elb = tonumber(u.ExtraLevelBaseCost)
		if els and elb and els <= lvl then
			return math.max(1, math.floor(elb * ((u.CostMultiplier or 1) ^ (lvl - els)) + 0.5))
		end
		return math.max(1, math.floor((u.BaseCost or 0) * ((u.CostMultiplier or 1) ^ lvl) + 0.5))
	end
	local boardIds = {}
	for id in pairs(UC.Upgrades) do table.insert(boardIds, id) end
	table.sort(boardIds)

	upgTab:CreateSection({ name = "Auto Buy Upgrades" })
	local autoBuyList = { "MoreCash", "MaxCapacity", "SpawnTime" }
	-- Cash upgrade buy priority, 1 = most important (MoreCash 1 | SpawnTime 2 | MaxCapacity 3)
	local CASH_PRIORITY = { MoreCash = 1, SpawnTime = 2, MaxCapacity = 3 }
	local function cashPriority(id) return CASH_PRIORITY[id] or 99 end
	local boardToggle, boardDD
	boardToggle = upgTab:CreateToggle({
		name = "Auto Buy Upgrades",
		desc = "Buys selected upgrades when affordable, in cash-priority order (1 = most important)",
		value = false,
		callback = function(v) setFlag("AutoBuyBoard", v) end,
	})
	boardDD = upgTab:CreateDropdown({
		name = "Upgrades",
		desc = "Upgrades to auto-buy",
		options = boardIds,
		value = { "MoreCash", "MaxCapacity", "SpawnTime" },
		multiSelect = true,
		callback = function(v)
			if type(v) == "table" then
				autoBuyList = v
			elseif type(v) == "string" then
				autoBuyList = { v }
			end
		end,
	})
	-- one-click "buy everything": selects all upgrades and enables auto-buy
	upgTab:CreateButton({
		name = "Select All Upgrades",
		desc = "Marks every upgrade for auto-buy (does not enable Auto Buy)",
		callback = function()
			autoBuyList = {}
			for id in pairs(UC.Upgrades) do table.insert(autoBuyList, id) end
			table.sort(autoBuyList)
			if boardDD then
				task.defer(function()
					pcall(function() boardDD:Select(autoBuyList) end)
				end)
			end
			window:Notify({ title = "Upgrades", content = "Selected all " .. #autoBuyList .. " upgrades - flip Auto Buy Upgrades to start buying" })
		end,
	})
	upgTab:CreateSlider({
		name = "Buy Delay",
		desc = "Seconds between purchase requests",
		range = { 0.3, 5 },
		increment = 0.1,
		value = getFlag("BuyDelay") or 0.5,
		callback = function(v) setFlag("BuyDelay", v) end,
	})

	upgTab:CreateSection({ name = "Purchase Activity" })
	local buyLogPara = upgTab:Paragraph({
		Title = "Purchases",
		Desc = "Waiting for the first purchase...",
	})
	local buyCount, spentCash = 0, 0
	-- PurchaseResult protocol: (upgradeId, ok, newLevel)
	STATE.connect(RS.UpgradeNetwork.PurchaseResult.OnClientEvent, function(id, ok, newLvl)
		if not ok then return end
		buyCount = buyCount + 1
		local u = UC.Upgrades[id]
		local costTxt = "?"
		if u then
			local lvl = tonumber(lp:GetAttribute(u.LevelAttribute)) or 0
			local cost = costForReal(u, math.max(0, lvl - 1))
			if u.CurrencyAttribute == "Currency_Cash" then spentCash = spentCash + cost end
			costTxt = string.format("%s %s", cost, tostring(u.CurrencyName))
		end
		pcall(function()
			buyLogPara:SetDesc(string.format("#%d  %s -> lv%s  (%s)  |  Cash spent: %d", buyCount, tostring(id), tostring(newLvl), costTxt, spentCash))
		end)
	end)

	upgTab:CreateSection({ name = "Auto Upgrade Tree" })
	local treeSel = { "Main" }
	upgTab:CreateToggle({
		name = "Auto Buy Tree Nodes",
		desc = "Buys affordable nodes from every selected tree (multi-select)",
		value = false,
		callback = function(v) setFlag("AutoBuyTree", v) end,
	})
	upgTab:CreateDropdown({
		name = "Trees",
		desc = "Which trees to buy nodes from (multi-select)",
		options = { "Main", "World2", "World3" },
		value = { "Main" },
		multiSelect = true,
		callback = function(v)
			treeSel = {}
			if type(v) == "table" then
				for _, k in ipairs(v) do table.insert(treeSel, tostring(k)) end
			elseif type(v) == "string" then
				treeSel = { v }
			end
			if #treeSel == 0 then treeSel = { "Main" } end
		end,
	})

	local lastRebirthTry = 0
	-- Smart Rebirth gain with the game's own math: floor(Cash/1000) times every
	-- rebirth multiplier.
	local function rebirthGain()
		local cash = tonumber(attr("Currency_Cash")) or 0
		return math.floor(math.floor(cash / 1000)
			* math.max(1, tonumber(attr("Stat_RebirthCashMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_RebirthMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_CharcoalRebirthMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_World2RebirthMultiplier")) or 1))
	end
	-- Burn->Rebirth combo state: while armed, the loop waits for the sticks on
	-- hand to burn (ours or Auto Burn's) before letting the rebirth through.
	local rebirthArmed, armedSticks, armedAt = false, 0, 0
	local comboBurnLanded = false
	-- Rebirth protocol: RebirthNetwork.Request:FireServer() (no args).
	loop("SmartRebirth", 2, function()
		if not getFlag("SmartRebirthOn") then return end
		local gain = rebirthGain()
		-- user rule: rebirth ONLY when there is something to spend rebirths on
		-- AND the gain would pay for the cheapest of it
		local have = tonumber(attr("Currency_Rebirths")) or 0
		local cheapest, cheapestLabel
		for id, u in pairs(UC.Upgrades) do
			if u.Board == "RebirthUpgradeBoard" and u.CurrencyAttribute == "Currency_Rebirths" and u.LevelAttribute then
				local lvl = tonumber(lp:GetAttribute(u.LevelAttribute)) or 0
				local extra = u.ExtraMaxLevelAttribute and (tonumber(lp:GetAttribute(u.ExtraMaxLevelAttribute)) or 0) or 0
				local maxL = (u.MaxLevel or 0) + math.max(0, math.floor(extra))
				if lvl < maxL then
					local cost = costForReal(u, lvl)
					if not cheapest or cost < cheapest then cheapest, cheapestLabel = cost, ("upgrade " .. id) end
				end
			end
		end
		if TC and TC.Trees then
			for treeKey, tree in pairs(TC.Trees) do
				local open = true
				if tree.UnlockAttribute then
					local av = lp:GetAttribute(tree.UnlockAttribute)
					if tree.UnlockValue ~= nil then open = (av == tree.UnlockValue)
					else open = ((tonumber(av) or 0) >= (tree.UnlockMinimum or 0)) end
				end
				if open and tree.Nodes then
					for id, node in pairs(tree.Nodes) do
						local pa = node.PurchaseAttribute
						if node.CurrencyAttribute == "Currency_Rebirths" and pa and lp:GetAttribute(pa) ~= true and node.Cost then
							local cost = tonumber(node.Cost) or 0
							if cost > 0 and (not cheapest or cost < cheapest) then
								cheapest, cheapestLabel = cost, ("tree node " .. tostring(id))
							end
						end
					end
				end
			end
		end
		if not cheapest then return end -- nothing left to buy with rebirths
		if gain < 1 then return end
		if have >= cheapest then return end
		if have + gain < cheapest then return end -- the gain must be what unlocks it
		if os.clock() - lastRebirthTry < 15 then return end
		-- Burn->Rebirth combo (always on): sticks on hand are worth more burned
		-- than wiped by the reset. Arm, burn first, then rebirth.
		if rebirthArmed then
			if comboBurnLanded or cur("Sticks") < armedSticks then
				rebirthArmed = false
				comboBurnLanded = false
				gain = rebirthGain()
				if gain < 1 then return end
			elseif cur("Sticks") > 0 and os.clock() - armedAt < 120 then
				pcall(function()
					RS.CampfireNetwork.ConvertRequest:FireServer("Board")
				end)
				return
			else
				rebirthArmed = false -- waited out: rebirth without the burn
			end
		elseif cur("Sticks") > 0 then
			rebirthArmed = true
			armedSticks = cur("Sticks")
			armedAt = os.clock()
			window:Notify({ title = "Burn -> Rebirth", content = string.format("Burning %.0f sticks first so their cash joins the rebirth gain", armedSticks), duration = 4 })
			pcall(function()
				RS.CampfireNetwork.ConvertRequest:FireServer("Board")
			end)
			return
		end
		-- the rebirth board is physical: stand at it before asking
		local board = workspace:FindFirstChild("RebirthStageBoard", true)
		local bp = board and posOf(board)
		local hrp = getHRP()
		if not (hrp and bp) then return end
		lastRebirthTry = os.clock()
		if (hrp.Position - bp).Magnitude > 25 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(bp + Vector3.new(0, 4, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.35)
			if not STATE.alive() then return end
			hrp = getHRP()
			if not hrp then return end
		end
		pcall(function()
			RS.RebirthNetwork.Request:FireServer()
		end)
		window:Notify({ title = "Smart Rebirth", content = string.format("Rebirthed: +%.0f rebirths (had %.0f) -> next: %s for %.0f", gain, have, cheapestLabel or "?", cheapest or 0), duration = 6 })
		-- hands-free chain: spend the fresh rebirths immediately
		task.delay(1.2, function()
			if not STATE.alive() then return end
			if TC and TC.Trees then
				for treeKey, tree in pairs(TC.Trees) do
					local open = true
					if tree.UnlockAttribute then
						local av = lp:GetAttribute(tree.UnlockAttribute)
						if tree.UnlockValue ~= nil then open = (av == tree.UnlockValue)
						else open = ((tonumber(av) or 0) >= (tree.UnlockMinimum or 0)) end
					end
					if open and tree.Nodes then
						for id, node in pairs(tree.Nodes) do
							if not STATE.alive() then return end
							local pa = node.PurchaseAttribute
							if node.CurrencyAttribute == "Currency_Rebirths" and pa and lp:GetAttribute(pa) ~= true and node.Cost then
								local cost = tonumber(node.Cost) or 0
								if cost > 0 and (tonumber(lp:GetAttribute("Currency_Rebirths")) or 0) >= cost then
									pcall(function()
										RS.UpgradeTreeNetwork.PurchaseRequest:FireServer(treeKey, id)
									end)
									task.wait(0.4)
								end
							end
						end
					end
				end
			end
			for id, u in pairs(UC.Upgrades) do
				if not STATE.alive() then return end
				if u.Board == "RebirthUpgradeBoard" and u.CurrencyAttribute == "Currency_Rebirths" and u.LevelAttribute then
					local lvl = tonumber(lp:GetAttribute(u.LevelAttribute)) or 0
					local extra = u.ExtraMaxLevelAttribute and (tonumber(lp:GetAttribute(u.ExtraMaxLevelAttribute)) or 0) or 0
					local maxL = (u.MaxLevel or 0) + math.max(0, math.floor(extra))
					if lvl < maxL then
						local cost = costForReal(u, lvl)
						if (tonumber(lp:GetAttribute("Currency_Rebirths")) or 0) >= cost then
							pcall(function()
								RS.UpgradeNetwork.PurchaseRequest:FireServer(id, "Max")
							end)
							task.wait(0.4)
						end
					end
				end
			end
		end)
	end)

	-- Burn->Rebirth combo result tap
	STATE.connect(RS.CampfireNetwork.ConvertResult.OnClientEvent, function(ok)
		if ok and rebirthArmed then comboBurnLanded = true end
	end)

	-- Auto Awaken: same protocol as the game's own board button
	STATE.connect(RS.AwakenNetwork.Result.OnClientEvent, function(ok)
		if ok then
			window:Notify({ title = "Auto Awaken", content = "Server confirmed: Awaken level is now " .. tostring(lp:GetAttribute("Awaken_Level")), duration = 6 })
		end
	end)
	local lastAwakenTry = 0
	loop("AutoAwaken", 2, function()
		if not getFlag("AutoAwakenOn") then return end
		local lvl = math.max(0, tonumber(attr("Awaken_Level")) or 0)
		local maxL = 0
		pcall(function()
			local req2 = require
			maxL = tonumber(req2(RS.Configs.AwakenConfig).MaxLevel) or 0
		end)
		if lvl >= maxL then return end
		if lp:GetAttribute("Unlocked_Awakening") ~= true then return end
		local cost
		pcall(function()
			local req2 = require
			local AC = req2(RS.Configs.AwakenConfig)
			cost = AC.Costs and AC.Costs[lvl + 1]
		end)
		if type(cost) ~= "number" then return end
		local cash = tonumber(attr("Currency_Cash")) or 0
		if cash < cost then return end
		if os.clock() - lastAwakenTry < 15 then return end
		local board = workspace:FindFirstChild("AwakenBoard", true)
		local bp = board and posOf(board)
		local hrp = getHRP()
		if not (hrp and bp) then return end
		lastAwakenTry = os.clock()
		if (hrp.Position - bp).Magnitude > 25 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(bp + Vector3.new(0, 4, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.35)
			if not STATE.alive() then return end
			hrp = getHRP()
			if not hrp then return end
		end
		pcall(function()
			RS.AwakenNetwork.Request:FireServer()
		end)
		window:Notify({ title = "Auto Awaken", content = string.format("Awakening to level %d (paid %.0f Cash)", lvl + 1, cost), duration = 6 })
	end)
	-- (Auto Awaken toggle lives on the World 1 tab, created in the FARM block's
	-- "Auto Awaken" section above.)
	w1Tab:CreateToggle({
		name = "Auto Awaken",
		desc = "Awakens the moment you can afford the next level (resets progress for permanent power). OFF until you flip it",
		value = getFlag("AutoAwakenOn") == true,
		callback = function(v) setFlag("AutoAwakenOn", v) end,
	})

	loop("AutoBuyBoard", 1, function()
		if not getFlag("AutoBuyBoard") then return end
		local list = {}
		for _, id in ipairs(autoBuyList) do table.insert(list, id) end
		table.sort(list, function(a, b)
			local pa, pb = cashPriority(a), cashPriority(b)
			if pa ~= pb then return pa < pb end
			return a < b
		end)
		local delay = getFlag("BuyDelay") or 0.5
		for _, id in ipairs(list) do
			if not STATE.alive() then return end
			local u = UC.Upgrades[id]
			if u and u.LevelAttribute then
				local lvl = tonumber(lp:GetAttribute(u.LevelAttribute)) or 0
				local extra = u.ExtraMaxLevelAttribute and (tonumber(lp:GetAttribute(u.ExtraMaxLevelAttribute)) or 0) or 0
				local maxL = (u.MaxLevel or 0) + math.max(0, math.floor(extra))
				if lvl < maxL then
					local cost = costForReal(u, lvl)
					local have = tonumber(lp:GetAttribute(u.CurrencyAttribute)) or 0
					if have >= cost then
						pcall(function()
							RS.UpgradeNetwork.PurchaseRequest:FireServer(id, "Max")
						end)
						task.wait(delay)
					end
				end
			end
		end
	end)

	loop("AutoBuyTree", 1.2, function()
		if not getFlag("AutoBuyTree") then return end
		if not (TC and TC.Trees) then return end
		for _, treeKey in ipairs(treeSel) do
			if not STATE.alive() then return end
			local tree = TC.Trees[treeKey]
			if tree and tree.Nodes then
				local open = true
				if tree.UnlockAttribute then
					local av = lp:GetAttribute(tree.UnlockAttribute)
					if tree.UnlockValue ~= nil then
						if av ~= tree.UnlockValue then open = false end
					elseif (tonumber(av) or 0) < (tree.UnlockMinimum or 0) then
						open = false
					end
				end
				if open then
					for id, node in pairs(tree.Nodes) do
						if not STATE.alive() then return end
						local pa = node.PurchaseAttribute
						if pa and lp:GetAttribute(pa) ~= true and node.Cost then
							local have = tonumber(lp:GetAttribute(node.CurrencyAttribute)) or 0
							if have >= node.Cost then
								pcall(function()
									RS.UpgradeTreeNetwork.PurchaseRequest:FireServer(treeKey, id)
								end)
								task.wait(getFlag("BuyDelay") or 0.5)
							end
						end
					end
				end
			end
		end
	end)

	-- ==================== AUTO SMART CHARCOAL (World 2) ====================
	local function charcoalGain()
		local dw = tonumber(attr("Currency_Drywood")) or 0
		return math.floor(math.floor(dw / 500000)
			* math.max(1, tonumber(attr("Stat_CharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_World2CharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_SeedCharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_TitleCharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_ShopCharcoalMultiplier")) or 1))
	end
	-- tree nodes priced in a currency: unlocked trees only
	local function cheapestNodeInCurrency(curAttr)
		if not (TC and TC.Trees) then return nil end
		local cheapest, cheapestLabel
		for treeKey, tree in pairs(TC.Trees) do
			local open = true
			if tree.UnlockAttribute then
				local av = lp:GetAttribute(tree.UnlockAttribute)
				if tree.UnlockValue ~= nil then open = (av == tree.UnlockValue)
				else open = ((tonumber(av) or 0) >= (tree.UnlockMinimum or 0)) end
			end
			if open and tree.Nodes then
				for id, node in pairs(tree.Nodes) do
					local pa = node.PurchaseAttribute
					if node.CurrencyAttribute == curAttr and pa and lp:GetAttribute(pa) ~= true and node.Cost then
						local cost = tonumber(node.Cost) or 0
						if cost > 0 and (not cheapest or cost < cheapest) then
							cheapest, cheapestLabel = cost, ("tree node " .. tostring(id))
						end
					end
				end
			end
		end
		return cheapest, cheapestLabel
	end
	local lastCharcoalTry = 0
	loop("SmartCharcoal", 2, function()
		local on = getFlag("SmartCharcoalOn") and true or false
		local now = os.clock()
		if not on then return end
		local gain = charcoalGain()
		local cheapest, cheapestLabel = cheapestNodeInCurrency("Currency_Charcoal")
		for id, u in pairs(UC.Upgrades) do
			if u.Board == "CharcoalUpgradeBoard" and u.CurrencyAttribute == "Currency_Charcoal" and u.LevelAttribute then
				local lvl = tonumber(lp:GetAttribute(u.LevelAttribute)) or 0
				local extra = u.ExtraMaxLevelAttribute and (tonumber(lp:GetAttribute(u.ExtraMaxLevelAttribute)) or 0) or 0
				local maxL = (u.MaxLevel or 0) + math.max(0, math.floor(extra))
				if lvl < maxL then
					local cost = costForReal(u, lvl)
					if not cheapest or cost < cheapest then cheapest, cheapestLabel = cost, ("upgrade " .. id) end
				end
			end
		end
		local have = tonumber(attr("Currency_Charcoal")) or 0
		if not cheapest then
			-- nothing left to buy with Charcoal - waiting
		elseif have >= cheapest then
			-- holding: cheapest already affordable
		elseif gain < 1 then
			-- not enough drywood for +1
		elseif have + gain < cheapest then
			-- saving
		elseif now - lastCharcoalTry >= 6 then
			lastCharcoalTry = now
			pcall(function()
				RS.CharcoalNetwork.Request:FireServer()
			end)
			window:Notify({ title = "Auto Smart Charcoal", content = "Converted: +" .. tostring(gain) .. " charcoal (next: " .. cheapestLabel .. " for " .. tostring(cheapest) .. ")", duration = 4 })
		end
	end)

	-- ==================== AUTO SMART IGNITE / EMBERS (World 2) ====================
	local EmberMilestones = nil
	pcall(function()
		local function req(m) return require(m) end
		EmberMilestones = req(RS.Configs.EmberMilestoneConfig).Milestones
	end)
	local function emberGain()
		local ch = tonumber(attr("Currency_Charcoal")) or 0
		return math.floor(math.floor(ch / 500000000) * math.max(1, tonumber(attr("Stat_EmberGainMultiplier")) or 1))
	end
	local function nextMilestone(afterEmbers)
		if type(EmberMilestones) ~= "table" then return nil end
		for _, m in ipairs(EmberMilestones) do
			local th = tonumber(m.Threshold) or 0
			if th > afterEmbers then return th end
		end
		return nil
	end
	local lastIgniteTry = 0
	loop("SmartIgnite", 3, function()
		local on = getFlag("SmartIgniteOn") and true or false
		local now = os.clock()
		if not on then return end
		if lp:GetAttribute("Unlocked_Embers") ~= true then return end
		local embers = tonumber(attr("Currency_Embers")) or 0
		local gain = emberGain()
		local th = nextMilestone(embers)
		if not th then
			-- all milestones reached
		elseif gain < 1 then
			-- need 500M charcoal for +1 ember
		elseif embers + gain < th then
			-- holding: short of the milestone
		elseif now - lastIgniteTry >= 6 then
			lastIgniteTry = now
			pcall(function()
				RS.EmberNetwork.Request:FireServer()
			end)
			window:Notify({ title = "Auto Smart Ignite", content = "Ignited: +" .. tostring(gain) .. " embers -> milestone " .. tostring(th), duration = 5 })
		end
	end)

	-- ==================== AUTO SUBMERGE (World 3) ====================
	local SubmergeConfig = nil
	pcall(function()
		local function req(m) return require(m) end
		SubmergeConfig = req(RS.Configs.SubmergeConfig)
	end)
	local lastSubmergeTry = 0
	loop("AutoSubmerge", 2, function()
		if not getFlag("AutoSubmergeOn") then return end
		if not SubmergeConfig then return end
		local lvl = math.max(0, math.floor(tonumber(attr("Submerge_Level")) or 0))
		local maxL = tonumber(SubmergeConfig.MaxLevel) or 0
		if lvl >= maxL then return end
		local cost = SubmergeConfig.Costs and SubmergeConfig.Costs[lvl + 1]
		if type(cost) ~= "number" then return end
		local drift = tonumber(attr("Currency_Driftwood")) or 0
		if drift < cost then return end
		if os.clock() - lastSubmergeTry < 15 then return end
		local board = workspace:FindFirstChild("SubmergeBoard", true)
		local bp = board and posOf(board)
		local hrp = getHRP()
		if not (hrp and bp) then return end
		lastSubmergeTry = os.clock()
		if (hrp.Position - bp).Magnitude > 25 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(bp + Vector3.new(0, 4, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.35)
			if not STATE.alive() then return end
			hrp = getHRP()
			if not hrp then return end
		end
		pcall(function()
			RS.SubmergeNetwork.Request:FireServer()
		end)
		window:Notify({ title = "Auto Submerge", content = string.format("Submerging to layer %d (paid %.0f Driftwood)", lvl + 1, cost), duration = 6 })
	end)

	-- ==================== AUTO UPGRADE DRIFTWOOD (World 3) ====================
	local DriftwoodTiers = nil
	pcall(function()
		local function req(m) return require(m) end
		DriftwoodTiers = req(RS.Configs.DriftwoodTierConfig).Tiers
	end)
	loop("AutoDriftwoodTier", 2, function()
		if not getFlag("AutoDriftwoodTierOn") then return end
		if type(DriftwoodTiers) ~= "table" then return end
		local tier = math.clamp(math.floor(tonumber(attr("Driftwood_Tier")) or 1), 1, #DriftwoodTiers)
		local next_ = DriftwoodTiers[tier + 1]
		if not next_ then return end -- MAX tier
		local subLvl = tonumber(attr("Submerge_Level")) or 0
		if next_.RequiredLayer and subLvl < (tonumber(next_.RequiredLayer) or 0) then return end
		local cost = math.max(1, (tonumber(next_.Cost) or 1) * (subLvl >= 3 and 0.7 or 1))
		local drift = tonumber(attr("Currency_Driftwood")) or 0
		if drift < cost then return end
		pcall(function()
			RS.DriftwoodTierNetwork.UpgradeRequest:FireServer()
		end)
	end)

	-- ==================== AUTO BUY MERCHANT (World 3) ====================
	-- A restock is DETECTED (server push on MerchantNetwork.Changed, or a 1s
	-- poll noticing `remaining` increase). The sweep buys every in-stock,
	-- not-maxed card the player can afford with Coins (cheapest first).
	local merchantPrev, pendingSweep, sweeping = nil, false, false
	local lastMerchantSweep = 0
	local function affordableCards(st)
		local list = {}
		if type(st) ~= "table" or type(st.cards) ~= "table" then return list end
		local coins = tonumber(attr("Currency_Coins")) or 0
		for id, c in pairs(st.cards) do
			if type(c) == "table" then
				local stock = tonumber(c.stock) or 0
				local lvl = tonumber(c.level) or 0
				local maxL = tonumber(c.max) or 0
				local price = tonumber(c.price) or 0
				if lvl < maxL and stock > 0 and price > 0 and coins >= price then
					table.insert(list, { id = id, price = price })
				end
			end
		end
		table.sort(list, function(a, b)
			if a.price ~= b.price then return a.price < b.price end
			return a.id < b.id
		end)
		return list
	end
	local function merchantSweep()
		local now = os.clock()
		if sweeping or now - lastMerchantSweep < 2 then return end
		sweeping = true
		lastMerchantSweep = now
		task.spawn(function()
			local bought = 0
			local okS, st = pcall(function()
				return RS.MerchantNetwork.GetState:InvokeServer()
			end)
			while okS and type(st) == "table" and STATE.alive() and getFlag("AutoMerchantOn") do
				local pick = affordableCards(st)[1]
				if not pick then break end
				pcall(function()
					RS.MerchantNetwork.Purchase:FireServer(pick.id)
				end)
				bought = bought + 1
				task.wait(getFlag("BuyDelay") or 0.5)
				local okS2, st2 = pcall(function()
					return RS.MerchantNetwork.GetState:InvokeServer()
				end)
				if not okS2 or type(st2) ~= "table" then break end
				-- the buy must land (stock drops or level rises)
				local c1 = st.cards and st.cards[pick.id]
				local c2 = st2.cards and st2.cards[pick.id]
				if c1 and c2
					and (tonumber(c2.stock) or 0) >= (tonumber(c1.stock) or 0)
					and (tonumber(c2.level) or 0) <= (tonumber(c1.level) or 0) then
					break
				end
				st = st2
			end
			sweeping = false
			if bought > 0 then
				window:Notify({ title = "Auto Buy Merchant", content = "Bought " .. bought .. " card(s)", duration = 4 })
			end
		end)
	end
	-- NOTE: the remote is FETCHED with FindFirstChild - dot-indexing a folder
	-- child named "Changed" would grab Instance.Changed (a property) instead.
	local merchantChanged = RS.MerchantNetwork:FindFirstChild("Changed")
	if merchantChanged then
		STATE.connect(merchantChanged.OnClientEvent, function(st)
			if not getFlag("AutoMerchantOn") then return end
			if #affordableCards(st) > 0 then pendingSweep = true end
		end)
	end
	loop("AutoMerchant", 1, function()
		if not getFlag("AutoMerchantOn") then
			merchantPrev = nil
			return
		end
		if pendingSweep then
			pendingSweep = false
			merchantSweep()
			return
		end
		local okS, st = pcall(function()
			return RS.MerchantNetwork.GetState:InvokeServer()
		end)
		if not okS or type(st) ~= "table" then return end
		local rem = tonumber(st.remaining) or 0
		if merchantPrev ~= nil and rem > merchantPrev then
			pendingSweep = true -- restock landed
		end
		merchantPrev = rem
		if #affordableCards(st) > 0 then merchantSweep() end
	end)
end

-- ===================== TELEPORTS =====================
do
	tpTab:CreateSection({ name = "Zones" })
	local spots = {}
	local function addSpot(label, fn)
		table.insert(spots, { label, fn })
	end
	addSpot("Pickup Floor (World 1)", function()
		return posOf(World and World:FindFirstChild("MainParts") and World.MainParts:FindFirstChild("PickupFloor"))
	end)
	addSpot("Campfire", function()
		local z = workspace:FindFirstChild("CampfireBurnZone", true)
		return posOf(z and z:FindFirstChild("InnerDisc"))
	end)
	addSpot("Portal -> World 2", function()
		local portal = World and World:FindFirstChild("Decoration") and World.Decoration:FindFirstChild("World1Portal", true)
		pcall(function() RS.PortalNetwork.RequestTeleport:FireServer("World2") end)
		return posOf(portal and portal:FindFirstChild("PortalShrine", true))
	end)
	addSpot("Portal -> World 3", function()
		local portal = World and World:FindFirstChild("Decoration") and World.Decoration:FindFirstChild("World3Portal", true)
		pcall(function() RS.PortalNetwork.RequestTeleport:FireServer("World3") end)
		return posOf(portal and portal:FindFirstChild("PortalShrine", true))
	end)
	addSpot("Titles Zone", function()
		local z = World and World:FindFirstChild("Decoration") and World.Decoration:FindFirstChild("TitlesZone", true)
		return posOf(z and z:FindFirstChild("MainCircle", true))
	end)
	addSpot("Merchant Zone (W3)", function()
		local z = World and World:FindFirstChild("Decoration") and World.Decoration:FindFirstChild("World3MerchantZone", true)
		return posOf(z and z:FindFirstChild("MainCircle", true))
	end)
	addSpot("Beach Ground (W3)", function()
		return posOf(World and World:FindFirstChild("MainParts") and World.MainParts:FindFirstChild("BeachGround"))
	end)
	addSpot("Desert Ground (W2)", function()
		return posOf(World and World:FindFirstChild("MainParts") and World.MainParts:FindFirstChild("DesertGround"))
	end)
	for _, s in ipairs(spots) do
		tpTab:CreateButton({
			name = "TP: " .. s[1],
			desc = "Teleports + verifies position after 2s",
			callback = function()
				local ok, pos = pcall(s[2])
				if ok and pos then
					tpTo(pos, s[1])
					window:Notify({ title = "Teleport", content = s[1] })
				else
					window:Notify({ title = "Teleport", content = s[1] .. ": not found", duration = 5 })
				end
			end,
		})
	end
end

-- ===================== MISC ADD-ON: Anti-AFK =====================
do
	misc:CreateSection({ name = "Session" })
	misc:CreateToggle({
		name = "Anti-AFK",
		desc = "Keeps the game's 18-min idle rejoin away",
		value = false,
		callback = function(v) setFlag("AntiAFK", v) end,
	})
	loop("AntiAFK", 240, function()
		if not getFlag("AntiAFK") then return end
		pcall(function()
			RS.IdleAutoRejoinNetwork.Activity:FireServer("Activity")
		end)
	end)
end

STATE.onCleanup(function()
	-- release an anchored HRP so a reload never freezes the character
	local h = getHRP()
	if h then
		h.Anchored = false
		h.AssemblyLinearVelocity = Vector3.zero
	end
	local char = lp.Character
	if char and not getFlag("NoclipOn") then
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = true end
		end
	end
end)

-- ===================== MISC =====================
-- Hide Name / Noclip / Walkspeed / Jumpheight / Fly
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function getHumanoid()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function setNoclip(on)
	pcall(function()
		local char = Players.LocalPlayer.Character
		if not char then return end
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not on
			end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CanCollide = not on end
	end)
end

-- Hide Name
local function applyHideName(on)
	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.NameDisplayDistance = on and 0 or 100
			if on then hum.DisplayName = "" else hum.DisplayName = Players.LocalPlayer.DisplayName end
		end
		for _, gui in ipairs(char:GetDescendants()) do
			if gui:IsA("BillboardGui") then
				if on then
					if gui:GetAttribute("HideName_OrigEnabled") == nil then
						gui:SetAttribute("HideName_OrigEnabled", gui.Enabled)
					end
					gui.Enabled = false
				else
					local orig = gui:GetAttribute("HideName_OrigEnabled")
					gui.Enabled = (orig ~= nil and orig) or true
					pcall(function() gui:SetAttribute("HideName_OrigEnabled", nil) end)
				end
				for _, lbl in ipairs(gui:GetDescendants()) do
					if lbl:IsA("TextLabel") then
						if on then
							if lbl:GetAttribute("HideName_OrigVis") == nil then
								lbl:SetAttribute("HideName_OrigVis", lbl.Visible)
							end
							lbl.Visible = false
							lbl.TextTransparency = 1
						else
							local v = lbl:GetAttribute("HideName_OrigVis")
							lbl.Visible = (v ~= nil and v) or true
							lbl.TextTransparency = 0
							pcall(function() lbl:SetAttribute("HideName_OrigVis", nil) end)
						end
					end
				end
			end
		end
	end
	pcall(function()
		local p = Players.LocalPlayer
		local pname, dname = p.Name, p.DisplayName
		local function hideInGui(gui)
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local txt = d.Text
					if txt == pname or txt == dname or txt == "@" .. pname or txt:find(pname, 1, true) then
						d.Visible = not on
					end
				end
			end
		end
		for _, gui in ipairs({ Players.LocalPlayer:FindFirstChild("PlayerGui"), game.CoreGui }) do
			if gui then hideInGui(gui) end
		end
	end)
end

local hideNameOn = getFlag("HideNameOn")
local noclipOn = getFlag("NoclipOn")
local noclipRunning = false
local function noclipLoop()
	noclipRunning = true
	while getFlag("NoclipOn") and isCurrentGen() do
		pcall(function() setNoclip(true) end)
		task.wait(0.2)
	end
	pcall(function() setNoclip(false) end)
	noclipRunning = false
end

-- Walkspeed / Jump
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultJumpHeight = 7.2
pcall(function()
	local h = getHumanoid()
	if h then
		defaultWalkSpeed = h.WalkSpeed
		defaultJumpPower = h.JumpPower
		defaultJumpHeight = h.JumpHeight
	end
end)

local currentWalkSpeed = getFlag("WalkSpeed") or defaultWalkSpeed
if type(currentWalkSpeed) ~= "number" then currentWalkSpeed = defaultWalkSpeed end
local currentJump = getFlag("JumpHeight") or defaultJumpHeight
if type(currentJump) ~= "number" then currentJump = defaultJumpHeight end

local function applyWalkSpeed(v)
	currentWalkSpeed = math.clamp(tonumber(v) or defaultWalkSpeed, 8, 200)
	pcall(function() setFlag("WalkSpeed", currentWalkSpeed) end)
	local hum = getHumanoid()
	if hum then
		pcall(function() hum.WalkSpeed = currentWalkSpeed end)
	end
end

local function applyJump(v)
	currentJump = math.clamp(tonumber(v) or defaultJumpHeight, 0, 200)
	pcall(function() setFlag("JumpHeight", currentJump) end)
	local hum = getHumanoid()
	if hum then
		pcall(function()
			if hum.UseJumpPower then
				hum.JumpPower = currentJump
			else
				hum.JumpHeight = currentJump
			end
		end)
	end
end

-- keep WalkSpeed/Jump from being reset by game
task.spawn(function()
	while isCurrentGen() do
		task.wait(0.5)
		local hum = getHumanoid()
		if hum then
			if math.abs(hum.WalkSpeed - currentWalkSpeed) > 0.5 then
				pcall(function() hum.WalkSpeed = currentWalkSpeed end)
			end
			local targetJump = currentJump
			local curJump = hum.UseJumpPower and hum.JumpPower or hum.JumpHeight
			if math.abs(curJump - targetJump) > 0.5 then
				pcall(function()
					if hum.UseJumpPower then hum.JumpPower = targetJump else hum.JumpHeight = targetJump end
				end)
			end
			if hideNameOn then pcall(function() applyHideName(true) end) end
		end
		if noclipOn and not noclipRunning then task.spawn(noclipLoop) end
	end
end)

-- Fly
local flyOn = getFlag("FlyOn") or false
local flySpeed = getFlag("FlySpeed") or 60
if type(flySpeed) ~= "number" then flySpeed = 60 end
local flyBV, flyBG, flyConn
local flyKeys = { W = false, A = false, S = false, D = false, Space = false, Ctrl = false, Shift = false }

local function stopFly()
	flyOn = false
	pcall(function() setFlag("FlyOn", false) end)
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local hum = getHumanoid()
	if hum then pcall(function() hum.PlatformStand = false end) end
	pcall(function() setNoclip(getFlag("NoclipOn")) end)
end

local function startFly()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = getHumanoid()
	if not hrp or not hum then return end
	flyOn = true
	pcall(function() setFlag("FlyOn", true) end)
	pcall(function() hum.PlatformStand = true end)
	flyBG = Instance.new("BodyGyro")
	flyBG.P = 9e4
	flyBG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyBG.cframe = hrp.CFrame
	flyBG.Parent = hrp
	flyBV = Instance.new("BodyVelocity")
	flyBV.velocity = Vector3.new(0, 0, 0)
	flyBV.maxForce = Vector3.new(9e9, 9e9, 9e9)
	flyBV.Parent = hrp
	setNoclip(true)
	flyConn = RunService.Heartbeat:Connect(function()
		if not flyOn or not isCurrentGen() then stopFly() return end
		local char2 = Players.LocalPlayer.Character
		local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
		if not hrp2 or not flyBV or not flyBG then return end
		local cam = workspace.CurrentCamera
		local move = Vector3.new(0, 0, 0)
		if flyKeys.W then move += cam.CFrame.LookVector end
		if flyKeys.S then move -= cam.CFrame.LookVector end
		if flyKeys.A then move -= cam.CFrame.RightVector end
		if flyKeys.D then move += cam.CFrame.RightVector end
		if flyKeys.Space then move += Vector3.new(0, 1, 0) end
		if flyKeys.Ctrl or flyKeys.Shift then move -= Vector3.new(0, 1, 0) end
		if move.Magnitude > 0 then move = move.Unit * flySpeed end
		flyBV.velocity = move
		flyBG.cframe = cam.CFrame
	end)
end

-- Input for fly
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W then flyKeys.W = true
	elseif k == Enum.KeyCode.A then flyKeys.A = true
	elseif k == Enum.KeyCode.S then flyKeys.S = true
	elseif k == Enum.KeyCode.D then flyKeys.D = true
	elseif k == Enum.KeyCode.Space then flyKeys.Space = true
	elseif k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.LeftShift then flyKeys.Ctrl = true end
end)
UserInputService.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.W then flyKeys.W = false
	elseif k == Enum.KeyCode.A then flyKeys.A = false
	elseif k == Enum.KeyCode.S then flyKeys.S = false
	elseif k == Enum.KeyCode.D then flyKeys.D = false
	elseif k == Enum.KeyCode.Space then flyKeys.Space = false
	elseif k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.LeftShift then flyKeys.Ctrl = false end
end)

-- re-apply on respawn + watch for billboard recreation
Players.LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.6)
	local hum = char:WaitForChild("Humanoid", 6)
	if hum then
		pcall(function() hum.WalkSpeed = currentWalkSpeed end)
		pcall(function()
			if hum.UseJumpPower then hum.JumpPower = currentJump else hum.JumpHeight = currentJump end
		end)
	end
	if hideNameOn then task.wait(0.2) applyHideName(true) end
	if flyOn then task.wait(0.2) startFly() end
	char.DescendantAdded:Connect(function(obj)
		if hideNameOn and obj:IsA("BillboardGui") then
			task.wait(0.05)
			if getFlag("HideNameOn") then applyHideName(true) end
		end
	end)
end)
pcall(function()
	local curChar = Players.LocalPlayer.Character
	if curChar then
		curChar.DescendantAdded:Connect(function(obj)
			if getFlag("HideNameOn") and obj:IsA("BillboardGui") then
				task.wait(0.05)
				applyHideName(true)
			end
		end)
	end
end)

-- UI
do
	local moveSec = misc:CreateSection({ name = "Movement" })
	moveSec:CreateSlider({
		name = "Walkspeed",
		desc = "Default 16 • Max 200",
		range = { 8, 200 },
		increment = 1,
		value = currentWalkSpeed,
		callback = function(v) applyWalkSpeed(v) end,
	})
	moveSec:CreateSlider({
		name = "Jumpheight",
		desc = "JumpHeight / JumpPower (auto)",
		range = { 0, 200 },
		increment = 1,
		value = currentJump,
		callback = function(v) applyJump(v) end,
	})

	local utilSec = misc:CreateSection({ name = "Utilities" })
	utilSec:CreateToggle({
		name = "Hide Name",
		desc = "Hides nametag & overhead",
		value = hideNameOn,
		callback = function(v)
			hideNameOn = v
			setFlag("HideNameOn", v)
			applyHideName(v)
		end,
	})
	utilSec:CreateToggle({
		name = "Noclip",
		desc = "Walk through walls",
		value = noclipOn,
		callback = function(v)
			noclipOn = v
			setFlag("NoclipOn", v)
			if v then
				if not noclipRunning then task.spawn(noclipLoop) end
			else
				setNoclip(false)
			end
		end,
	})

	local flySec = misc:CreateSection({ name = "Flight" })
	flySec:CreateToggle({
		name = "Fly",
		desc = "Enable flight (noclip while flying)",
		value = flyOn,
		callback = function(v)
			if v then startFly() else stopFly() end
		end,
	})
	flySec:CreateSlider({
		name = "Fly Speed",
		desc = "Studs/sec • 10-250",
		range = { 10, 250 },
		increment = 5,
		value = flySpeed,
		callback = function(v)
			flySpeed = math.clamp(tonumber(v) or 60, 10, 250)
			pcall(function() setFlag("FlySpeed", flySpeed) end)
		end,
	})
end

-- init
if hideNameOn then applyHideName(true) end
if noclipOn and not noclipRunning then task.spawn(noclipLoop) end
if flyOn then task.defer(function() task.wait(0.8) if getFlag("FlyOn") then startFly() end end) end

-- ===================== CREDITS =====================
local DISCORD_INVITE = "https://discord.gg/PGyk3JcKht"
local SCRIPT_VERSION = "1.0.0"

do
	-- column 1: team + community
	local teamSec = credits:CreateSection({ name = "Team", column = 1 })
	teamSec:CreateLabel("Owner • sempai.real")
	teamSec:CreateLabel("Game: " .. GAME_NAME)
	local commSec = credits:CreateSection({ name = "Community", column = 1 })
	commSec:CreateButton("Discord Server", function()
		pcall(function() setclipboard(DISCORD_INVITE) end)
		window:Notify({ title = "Discord", content = "Invite copied!" })
	end)
	-- column 2: about
	local aboutSec = credits:CreateSection({ name = "About", column = 2 })
	aboutSec:CreateLabel("Script " .. SCRIPT_VERSION)
	aboutSec:CreateLabel("Liquid Hub v2.3")
	aboutSec:CreateLabel("Report bugs in Discord")
end

-- ===================== CONFIGS =====================
-- Named setups saved to files + optional autoload; same JSON format as before,
-- so previously saved Sticks Inc 2 configs keep working.
do
	local CF_DIR = "SticksInc2/configs"
	local AUTOLOAD_FILE = "SticksInc2/autoload.txt"
	local Http = game:GetService("HttpService")

	local canIO = typeof(writefile) == "function" and typeof(readfile) == "function"
		and typeof(isfile) == "function" and typeof(makefolder) == "function"

	local function ensureDir()
		if not canIO then return false end
		local ok = pcall(function()
			makefolder("SticksInc2")
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
		return data
	end
	local function applyData(data)
		if type(data) ~= "table" then return 0 end
		local n = 0
		for k, sv in pairs(data) do
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
	local autoloadEnabled = false
	local autoT -- forward declaration: the callback must close over the local
	autoT = autoSec:CreateToggle({
		name = "Autoload Selected on Start",
		value = false,
		callback = function(v)
			autoloadEnabled = v
			if v then
				if not selected then
					window:Notify({ title = "Configs", content = "Select a config first" })
					autoT.Set(false)
					autoloadEnabled = false
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
		autoloadEnabled = true
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

window:Notify({ title = "Sticks Inc 2", content = "Loaded! Press RightShift to toggle.", duration = 4 })
