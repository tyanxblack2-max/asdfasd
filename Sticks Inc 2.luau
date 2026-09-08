--!nolint UnknownGlobal
--!nolint UnknownRequire
-- Sticks Incremental 2 | Liquid Hub
-- Ported Credits + Configs from Final Swarm (enf404_)
-- Folder: SticksInc2 | WindUI | Credits + Configs preserved

-- AUTO Plugin fix for Delta / WindUI (1 loadstring, no external wrapper needed)

pcall(function()

    local set = setthreadidentity or set_thread_identity or setthreadcontext or _G.set_identity

    if set then pcall(set, 8) pcall(set, 7) end

end)

local Players = game:GetService("Players")

local RS = game:GetService("ReplicatedStorage")

local function getFlag(n) return RS:GetAttribute("SI2_"..n) end

local function setFlag(n,v) RS:SetAttribute("SI2_"..n, v) end

-- Every load stamps a unique generation into the DataModel. Loops check it, so a

-- loop left running by an EARLIER execution of this script stops as soon as a new

-- copy loads. Without this, re-executing instead of reloading left two raid loops

-- writing the character's CFrame in the same frame, each with its own idea of

-- where to hover -- which looks exactly like the character being unable to decide

-- and shaking between two points. Seeded from the clock so a wipe cannot make a

-- new load collide with a stale stamp.

local LOAD_GEN = math.floor(os.clock() * 100000) % 1000000 + math.random(1, 999) * 1000000

RS:SetAttribute("SI2_LoadGen", LOAD_GEN)

local function isCurrentGen() return RS:GetAttribute("SI2_LoadGen") == LOAD_GEN end

if RS:GetAttribute("SI2_AutoRaidOn")==nil then RS:SetAttribute("SI2_AutoRaidOn", false) end

if RS:GetAttribute("SI2_AutoShrineOn")==nil then RS:SetAttribute("SI2_AutoShrineOn", true) end

if RS:GetAttribute("SI2_AutoFarmOn")==nil then RS:SetAttribute("SI2_AutoFarmOn", false) end

if RS:GetAttribute("SI2_AutoPortalOn")==nil then RS:SetAttribute("SI2_AutoPortalOn", false) end

if RS:GetAttribute("SI2_MagnetOn")==nil then RS:SetAttribute("SI2_MagnetOn", false) end

if RS:GetAttribute("SI2_AutoChestsOn")==nil then RS:SetAttribute("SI2_AutoChestsOn", false) end

if RS:GetAttribute("SI2_AutoUpgradeOn")==nil then RS:SetAttribute("SI2_AutoUpgradeOn", false) end

if RS:GetAttribute("SI2_AutoTreeOn")==nil then RS:SetAttribute("SI2_AutoTreeOn", false) end

if RS:GetAttribute("SI2_AutoReplayOn")==nil then RS:SetAttribute("SI2_AutoReplayOn", false) end

if RS:GetAttribute("SI2_AutoPickOn")==nil then RS:SetAttribute("SI2_AutoPickOn", false) end

if RS:GetAttribute("SI2_NoclipOn")==nil then RS:SetAttribute("SI2_NoclipOn", false) end

if RS:GetAttribute("SI2_HideNameOn")==nil then RS:SetAttribute("SI2_HideNameOn", false) end

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



-- Destroy any previous hub window (Rayfield/WindUI create a fresh ScreenGui each

-- time). Without this every reload stacks another window on top of the old ones.

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



local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()



local WindowRaw = WindUI:CreateWindow({

	Title = "Sticks Inc 2",

	Icon = "rbxassetid://89254216319344",

	Author = "Auto Farm",

	Folder = "SticksInc2",

	Size = UDim2.fromOffset(580, 460),

	Theme = "Dark",

	ToggleKey = Enum.KeyCode.RightShift,

})

-- Config registry: adaptTab records every Toggle/Slider/Dropdown (name -> element

-- + last value + applier) so the Configs tab can save/apply whole setups.

-- Elements with noreg = true (meta UI) are skipped.

local Reg = {}



-- Rayfield -> WindUI adapter: весь фарм-код ниже продолжает звать

-- tab:CreateToggle / CreateSlider / CreateDropdown / CreateSection / CreateButton / CreateStat

-- и window:Notify в старом формате, а здесь они тихо переводятся на WindUI.

-- Логика не тронута, меняется только отрисовка.

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

		pcall(function()

			dd.value = initVal or {}

		end)

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

	-- Expose raw WindUI tab + rich elements for Credits (Paragraph with Image/Buttons, Divider, Space, Code, Image)
	t._raw = wtab
	function t:Paragraph(o) return wtab:Paragraph(o) end
	function t:CreateParagraph(o) return wtab:Paragraph(o) end
	function t:Divider() return wtab:Divider() end
	function t:Space(v) if v then return wtab:Space(v) else return wtab:Space() end end
	function t:Code(o) return wtab:Code(o) end
	function t:Image(o) return wtab:Image(o) end

	return t

end

local window = {}

window._raw = WindowRaw

window._tabIcons = { ["World 1"] = "sprout", ["World 2"] = "flame", ["World 3"] = "waves", Upgrades = "arrow-up-circle", Teleports = "map-pin", Misc = "wrench", Configs = "save", Credits = "info" }

function window:CreateTab(o)

	local wt = WindowRaw:Tab({

		Title = o.name,

		Icon = self._tabIcons[o.name] or "menu",

	})

	return adaptTab(wt)

end

function window:Notify(o)

	return WindUI:Notify({

		Title = o.title or o.Title or "Sticks Inc 2",

		Content = o.content or o.Content or "",

		Duration = o.duration or o.Duration or 3,

	})

end



-- tab order: World 1, World 2, World 3, Upgrades, Teleports, Misc, Configs,
-- Credits (Credits last). The old single "Farm" tab is split per world:
-- World 1 (sticks/burn/seeds/awaken), World 2 (drywood/rebirth/charcoal/
-- embers), World 3 (driftwood/submerge/merchant/tiers).
local w1Tab = window:CreateTab({ name = "World 1" })
local w2Tab = window:CreateTab({ name = "World 2" })
local w3Tab = window:CreateTab({ name = "World 3" })
local upgTab = window:CreateTab({ name = "Upgrades" })
local tpTab = window:CreateTab({ name = "Teleports" })
local misc = window:CreateTab({ name = "Misc" })
local cfgTab = window:CreateTab({ name = "Configs" })
local credits = window:CreateTab({ name = "Credits" })



-- Hub icon: drop the script-hub logo to the LEFT of the window title.

-- Sirius builds the title bar as a horizontal UIListLayout row that holds the

-- title+subtitle block; parenting an ImageLabel there with a lower LayoutOrder

-- places it leftmost, beside the title.

pcall(function()

	local ICON = "rbxassetid://89254216319344"

	task.wait(1.5)

	local roots = { game.CoreGui }

	local rg = game.CoreGui:FindFirstChild("RobloxGui")

	if rg then roots[#roots + 1] = rg end

	local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")

	if pg then roots[#roots + 1] = pg end

	local label

	for _, rt in ipairs(roots) do

		for _, c in ipairs(rt:GetDescendants()) do

			if c:IsA("TextLabel") and (c.Text == "Sticks Inc 2" or c.Text == "Liquid Hub") then

				label = c

				break

			end

		end

		if label then break end

	end

	if not label then return end

	local row = label.Parent.Parent -- horizontal row that contains the title block

	if not row or not row:FindFirstChildOfClass("UIListLayout") then return end

	local existing = row:FindFirstChild("HubIcon")

	if existing then existing:Destroy() end

	local icon = Instance.new("ImageLabel")

	icon.Name = "HubIcon"

	icon.Image = ICON

	icon.BackgroundTransparency = 1

	icon.Size = UDim2.new(0, 28, 0, 28)

	icon.ScaleType = Enum.ScaleType.Fit

	icon.LayoutOrder = 0 -- leftmost in the horizontal row

	icon.Parent = row

end)




-- ===================== STICKS INC 2: MAIN =====================
-- Add your Sticks Incremental 2 features below. Example:
-- tab:CreateToggle({ name = "Auto Farm Sticks", value = false, callback = function(v) print("Sticks farm", v) end })
-- tab:CreateSlider({ name = "Farm Speed", range = {1, 100}, increment = 1, value = 30, callback = function(v) print(v) end })
-- ===================== LIQUID HUB CORE (Real live-reload contract) =====================
-- Loaded via Real MCP live-reload: STATE is provided by the runner when present.
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

-- Beach center (World 3): driftwood streams beach along this sand; one
-- canonical fallback glide target for the driftwood farm.
local BEACH_POS
	do
		local mp = World and World:FindFirstChild("MainParts")
		local bg = mp and mp:FindFirstChild("BeachGround")
		local p = bg and bg:IsA("BasePart") and bg.Position or nil
		BEACH_POS = p or Vector3.new(-628, -19, -34)
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
		name = "Burn Every",		desc = "Seconds between burns",
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
	-- Sticks are workspace instances ("Stick") and the game picks them up
	-- client-side within Stat_PickupRadius of the character, so the farm
	-- GLIDES the anchored character from stick to stick with a Tween instead
	-- of CFrame hops - smooth, speed-adjustable, and nothing can fall through
	-- the map because physics is off while gliding. Burning is fully remote:
	-- the campfire board's Burn button protocol ConvertRequest:FireServer(
	-- "Board") converts from anywhere (verified 40+ studs away), so there are
	-- no campfire trips at all and farming never stops.
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
	-- The click button has a server cooldown that shrinks with upgrades:
	-- press period = Stat_DrywoodCooldown / (Stat_DrywoodSpeedMultiplier x
	-- Stat_World2DrywoodSpeedMultiplier) (exact game formula, values now e.g.
	-- 0.2 / (1.5 x 2.25) = 0.059s). No user interval: fire as fast as allowed.
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
	-- Driftwood items stream from the ocean to the beach; only "Beached"
	-- items on the sand can be picked up (the game's own Heartbeat loop fires
	-- DriftwoodNetwork.PickupRequest(id) when the character's HRP touches the
	-- item's parts within the beach radius - exactly like the sticks farm,
	-- minus the tween). Oddities drift in as separate "Oddity" items and are
	-- picked up by the very same loop, so one toggle collects both.
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
		name = "Auto Buy Merchant",			desc = "Detects each restock instantly (the timer speeds up with Faster Merchant Restocks) and buys every affordable in-stock card with Coins",
		value = getFlag("AutoMerchantOn") == true,
		callback = function(v) setFlag("AutoMerchantOn", v) end,
	})

	local driftTweenService = game:GetService("TweenService")
	local driftTween, driftTarget, driftWasOn = nil, nil, false
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
	-- Pick the beached-item ground target: prefer a fresh "Beached" item, else
	-- the beach center, so the character always sweeps the shoreline where
	-- pickups trigger.
	local function driftGroundPos()
		local f = workspace:FindFirstChild("ClientWorld3StreamVisuals")
		if f then
			local best, bd
			for _, it in ipairs(f:GetChildren()) do
				local p = posOf(it)
				if p then
					local d = (p - BEACH_POS).Magnitude
					if d < 120 and (not bd or d < bd) then best, bd = p, d end
				end
			end
			if best then return best end
		end
		return BEACH_POS
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
		local dest = driftGroundPos()
		local dist = (dest - hrp.Position).Magnitude
		if dist > 3 then
			if not hrp.Anchored then
				settle(hrp)
				hrp.Anchored = true
			end
			if driftTarget ~= dest or (not driftTween or driftTween.PlaybackState ~= Enum.PlaybackState.Completed) then
				driftTarget = dest
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
	-- curve once the level reaches the start level (rebirth upgrades do —
	-- using the plain formula there made Smart Rebirth rebirth instantly)
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
	-- tables cannot live in DataModel attributes; keep the selection here.
	-- Declared first so the Select-All button below closes over them properly.
	local autoBuyList = { "MoreCash", "MaxCapacity", "SpawnTime" }
	-- Cash upgrade buy priority, 1 = most important (user spec: MoreCash 1 |
	-- SpawnTime 2 | MaxCapacity 3). AutoBuyBoard sorts its list by this every
	-- tick: while a higher priority is affordable the "Max" buy soaks all the
	-- cash, so lower priorities only ever get what is left over. Unlisted
	-- upgrades buy after these three, alphabetically.
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
	-- (Cash Priority info paragraph removed from the UI on request; the
	-- CASH_PRIORITY ordering above still drives the buy order.)
	-- one-click "buy everything": selects all upgrades and enables auto-buy
	upgTab:CreateButton({
		name = "Select All Upgrades",
		desc = "Marks every upgrade for auto-buy (does not enable Auto Buy)",
		callback = function()
			autoBuyList = {}
			for id in pairs(UC.Upgrades) do table.insert(autoBuyList, id) end
			table.sort(autoBuyList)
			-- exactly ONE deferred UI refresh: WindUI rebuilds the whole dropdown
			-- on every Select, so Select-per-item rebuilt it n^2 times on the UI
			-- thread and froze the game.
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
	-- Trees cannot live in DataModel attributes; keep the selection here.
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

	-- (Smart Auto Rebirth toggle lives on the World 1 tab; the loop stays in
	-- this block because it needs UpgradeConfig for the costs. The old
	-- "Burn -> Rebirth Combo" toggle is gone: burning leftover sticks before
	-- a rebirth is now ALWAYS part of Smart Rebirth.)
	local lastRebirthTry = 0
	-- Smart Rebirth gain with the game's own math: floor(Cash/1000) times every
	-- rebirth multiplier. The Burn->Rebirth combo recomputes with this after a
	-- burn lands so the burned sticks' cash joins the gain.
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
	-- Rebirth protocol: RebirthNetwork.Request:FireServer() (no args). The
	-- game's own gate: floor(Cash / 1000) * multipliers >= 1. "Rebirth
	-- Upgrades" are UpgradeConfig entries on RebirthUpgradeBoard bought with
	-- Rebirths via the normal PurchaseRequest(id, "Buy") protocol.
	loop("SmartRebirth", 2, function()
		if not getFlag("SmartRebirthOn") then return end
		local gain = rebirthGain() -- game's own formula, shared with the combo
		-- user rule: rebirth ONLY when there is something to spend rebirths on
		-- AND the gain would pay for the cheapest of it. Candidates:
		--   1) not-maxed Rebirth Upgrades (bought with Rebirths)
		--   2) not-yet-bought tree nodes that cost Rebirths (unlocked trees only,
		--      locked trees' nodes cannot be purchased so they do not count)
		-- When NO candidate exists at all, rebirths would be wasted -> never rebirth.
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
				-- mirror the game's tree unlock gate (same as Auto Buy Tree Nodes)
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
		-- count the rebirths already owned: if they alone cover the cheapest
		-- item, buying it needs no rebirth — wait for a gain that matters
		if have >= cheapest then return end
		if have + gain < cheapest then return end -- the gain must be what unlocks it
		if os.clock() - lastRebirthTry < 15 then return end
		-- Burn->Rebirth combo (always on since the toggle was removed): sticks
		-- on hand are worth more burned than wiped by the reset. Arm, burn
		-- first, and only let the rebirth through once the burn has landed, so
		-- its cash counts toward the rebirth gain.
		if rebirthArmed then
				if comboBurnLanded or cur("Sticks") < armedSticks then
					-- a burn landed (ours or Auto Burn's): the sticks are cash
					-- now, recompute the gain so the burn counts toward it
					rebirthArmed = false
					comboBurnLanded = false
					gain = rebirthGain()
					if gain < 1 then return end
				elseif cur("Sticks") > 0 and os.clock() - armedAt < 120 then
					-- server burn cooldown still running (30-75s at high
					-- levels): refire on this loop's cadence, re-check next pass
					pcall(function()
						RS.CampfireNetwork.ConvertRequest:FireServer("Board")
					end)
					return
				else
					rebirthArmed = false -- waited out: rebirth without the burn
				end
			elseif cur("Sticks") > 0 then
				-- arm: snapshot the sticks, fire the first burn, give it time
				-- to land before the reset wipes them
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
		-- hands-free chain: spend the fresh rebirths immediately — rebirth-cost
		-- tree nodes first (they persist across rebirths), then any not-maxed
		-- rebirth upgrades — and the loop re-evaluates on its next tick
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

	-- Burn->Rebirth combo result tap: a successful burn while the combo is
	-- armed marks it landed, so the rebirth fires on the next loop pass even
	-- if farming already refilled sticks past the armed snapshot.
	STATE.connect(RS.CampfireNetwork.ConvertResult.OnClientEvent, function(ok)
		if ok and rebirthArmed then comboBurnLanded = true end
	end)

	-- Auto Awaken: same protocol as the game's own board button
	-- (AwakenNetwork.Request:FireServer(), no args). The game's gate:
	-- Unlocked_Awakening + Awaken_Level < MaxLevel + Cash >= Costs[level+1].
	-- Awaken trades ALL progress for permanent power-ups, so the toggle ships
	-- OFF and only fires when you flip it.
	local okAwaken, AwakenConfig = pcall(function() return req(RS.Configs.AwakenConfig) end)
	w1Tab:CreateToggle({
		name = "Auto Awaken",
		desc = "Awakens the moment you can afford the next level (resets progress for permanent power). OFF until you flip it",
		value = getFlag("AutoAwakenOn") == true,
		callback = function(v) setFlag("AutoAwakenOn", v) end,
	})
	STATE.connect(RS.AwakenNetwork.Result.OnClientEvent, function(ok)
		if ok then
			window:Notify({ title = "Auto Awaken", content = "Server confirmed: Awaken level is now " .. tostring(lp:GetAttribute("Awaken_Level")), duration = 6 })
		end
	end)
	local lastAwakenTry = 0
	loop("AutoAwaken", 2, function()
		if not getFlag("AutoAwakenOn") then return end
		if not (okAwaken and AwakenConfig) then return end
		local lvl = math.max(0, tonumber(attr("Awaken_Level")) or 0)
		local maxL = tonumber(AwakenConfig.MaxLevel) or 0
		if lvl >= maxL then return end -- maxed: nothing to buy
		if lp:GetAttribute("Unlocked_Awakening") ~= true then return end
		local cost = AwakenConfig.Costs and AwakenConfig.Costs[lvl + 1]
		if type(cost) ~= "number" then return end
		local cash = tonumber(attr("Currency_Cash")) or 0
		if cash < cost then return end -- exact same gate as the game's own button
		if os.clock() - lastAwakenTry < 15 then return end
		-- the board is physical: stand at it before asking
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

	loop("AutoBuyBoard", 1, function()
		if not getFlag("AutoBuyBoard") then return end
		-- priority order, rebuilt each tick so dropdown edits apply live
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
					-- exact game cost curve (see costForReal above)
					local cost = costForReal(u, lvl)
					local have = tonumber(lp:GetAttribute(u.CurrencyAttribute)) or 0
					if have >= cost then
						-- protocol: (upgradeId, mode), mode "Max" = buy as many
						-- levels as affordable in one request
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
				-- mirror the game's tree unlock gate so locked trees are never spammed
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
	-- Charcoal board button protocol: CharcoalNetwork.Request:FireServer() (no
	-- args, works from anywhere - the client gate is only gain > 0). Gain with
	-- the game's own math: floor(Drywood / 500000) x Stat_CharcoalMultiplier x
	-- Stat_World2CharcoalMultiplier x Stat_SeedCharcoalMultiplier x
	-- Stat_TitleCharcoalMultiplier x Stat_ShopCharcoalMultiplier. Smart gate
	-- mirrors Smart Rebirth: convert only when the gain pays for the cheapest
	-- not-maxed CharcoalUpgradeBoard upgrade or a not-yet-bought tree node
	-- priced in Charcoal (unlocked trees only); never convert otherwise.
	local function charcoalGain()
		local dw = tonumber(attr("Currency_Drywood")) or 0
		return math.floor(math.floor(dw / 500000)
			* math.max(1, tonumber(attr("Stat_CharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_World2CharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_SeedCharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_TitleCharcoalMultiplier")) or 1)
			* math.max(1, tonumber(attr("Stat_ShopCharcoalMultiplier")) or 1))
	end
	-- tree nodes priced in a currency: unlocked trees only (locked trees'
	-- nodes cannot be bought, so they never count as targets)
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
		-- candidates: not-maxed CharcoalUpgradeBoard upgrades + Charcoal-cost
		-- tree nodes in unlocked trees
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
		local txt
		if not cheapest then
			txt = "nothing left to buy with Charcoal - waiting"
		elseif have >= cheapest then
			txt = "holding: " .. cheapestLabel .. " already affordable (buy it first)"
		elseif gain < 1 then
			txt = "need " .. math.floor(500000 / math.max(1, math.floor((tonumber(attr("Stat_CharcoalMultiplier")) or 1) * (tonumber(attr("Stat_World2CharcoalMultiplier")) or 1) * (tonumber(attr("Stat_SeedCharcoalMultiplier")) or 1) * (tonumber(attr("Stat_TitleCharcoalMultiplier")) or 1) * (tonumber(attr("Stat_ShopCharcoalMultiplier")) or 1)))) .. "K Drywood for +1"
		elseif have + gain < cheapest then
			txt = "saving: need " .. tostring(math.floor(cheapest - have - gain)) .. " more charcoal-power for " .. cheapestLabel
		elseif now - lastCharcoalTry >= 6 then
			lastCharcoalTry = now
			pcall(function()
				RS.CharcoalNetwork.Request:FireServer()
			end)
			txt = "converting " .. tostring(gain) .. " charcoal -> " .. cheapestLabel
			window:Notify({ title = "Auto Smart Charcoal", content = "Converted: +" .. tostring(gain) .. " charcoal (next: " .. cheapestLabel .. " for " .. tostring(cheapest) .. ")", duration = 4 })			else
			txt = "converting..."
		end
	end)

	-- ==================== AUTO SMART IGNITE / EMBERS (World 2) ====================
	-- Ignite board button protocol: EmberNetwork.Request:FireServer() (no
	-- args, anywhere; client gate is gain > 0). Gain with the game's own math:
	-- floor(Charcoal / 500000000) x Stat_EmberGainMultiplier. Igniting resets
	-- Cash/Rebirths/Leaves (World 2 layer), so only fire when the gain covers
	-- the NEXT Ember milestone threshold - milestones grant AutoDrywood,
	-- UnlockWorld3, AutoBuyCharcoal, multipliers and more.
	local EmberMilestones = nil
	pcall(function()
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
		local txt
		if not th then
			txt = "all milestones reached - waiting"
		elseif gain < 1 then
			txt = "need 500M charcoal for +1 ember"
		elseif embers + gain < th then
			txt = "holding: " .. math.floor(th - embers - gain) .. " embers short of the " .. tostring(th) .. " milestone"
		elseif now - lastIgniteTry >= 6 then
			lastIgniteTry = now
			pcall(function()
				RS.EmberNetwork.Request:FireServer()
			end)
			txt = "igniting +" .. tostring(gain) .. " embers -> milestone " .. tostring(th)
			window:Notify({ title = "Auto Smart Ignite", content = "Ignited: +" .. tostring(gain) .. " embers -> milestone " .. tostring(th), duration = 5 })
		else
			txt = "igniting..."
		end
	end)

	-- ==================== AUTO SUBMERGE (World 3) ====================
	-- Same shape as Auto Awaken: SubmergeNetwork.Request:FireServer() (no
	-- args). Game gate (client canPurchase): Submerge_Level <
	-- SubmergeConfig.MaxLevel (7) AND Currency_Driftwood >= Costs[level+1].
	-- Unlocked by default once World 3 is reachable; trades World 3 progress
	-- for permanent layers, so the toggle ships OFF and only fires when
	-- flipped.
	local okSubmerge, SubmergeConfig = pcall(function() return req(RS.Configs.SubmergeConfig) end)
	local lastSubmergeTry = 0
	loop("AutoSubmerge", 2, function()
		if not getFlag("AutoSubmergeOn") then return end
		if not (okSubmerge and SubmergeConfig) then return end
		local lvl = math.max(0, math.floor(tonumber(attr("Submerge_Level")) or 0))
		local maxL = tonumber(SubmergeConfig.MaxLevel) or 0
		if lvl >= maxL then return end
		local cost = SubmergeConfig.Costs and SubmergeConfig.Costs[lvl + 1]
		if type(cost) ~= "number" then return end
		local drift = tonumber(attr("Currency_Driftwood")) or 0
		if drift < cost then return end -- exact same gate as the game's own button
		if os.clock() - lastSubmergeTry < 15 then return end
		-- the board is physical: stand at it before asking
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
	-- Tier board protocol: DriftwoodTierNetwork.UpgradeRequest:FireServer()
	-- (no args, no proximity needed - verified live). Game math: next tier =
	-- Tiers[clamp(Driftwood_Tier+1, 1, #Tiers)]; cost = tier.Cost x
	-- (Submerge_Level >= 3 and 0.7 or 1); gated by Submerge_Level >=
	-- tier.RequiredLayer (nil = 0).
	local DriftwoodTiers = nil
	pcall(function()
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
	-- ==================== AUTO BUY MERCHANT (World 3) ====================
	-- The restock interval is NOT fixed 300s: the World-3 tree node
	-- "FasterMerchantRestocks" (UpgradeTreeConfig) shortens it. So the timer
	-- is never assumed - a restock is DETECTED instead, two ways:
	--   1) the server pushes fresh state on MerchantNetwork.Changed (the
	--      same event the game's own shop UI refreshes on),
	--   2) a 1s poll notices `remaining` INCREASE (it counts down otherwise).
	-- The sweep buys every in-stock, not-maxed card the player can afford
	-- with Coins (cheapest first) and verifies each purchase actually
	-- landed before continuing. Premium cards also carry Coins prices, so
	-- nothing is skipped for having a Robux button.
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
				-- the buy must land (stock drops or level rises): a refused
				-- purchase means stop instead of hammering the server
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
	-- event-driven restock: the server pushes state exactly when it restocks.
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
			pendingSweep = true -- restock landed (timer is upgradeable, never fixed)
		end
		merchantPrev = rem
		-- also sweep whenever something affordable sits in stock: covers the
		-- first poll after enabling and coins arriving after a restock
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
	-- release a convert trip (anchored HRP) so a reload never freezes the character
	local h = getHRP()
	if h then
		h.Anchored = false
		h.AssemblyLinearVelocity = Vector3.zero
	end
	-- restore collisions (setNoclip is declared further down, keep this self-contained)
	local char = lp.Character
	if char and not getFlag("NoclipOn") then
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = true end
		end
	end
end)

-- ===================== MISC =====================
-- Hide Name / Noclip / Walkspeed / Jumpheight / Fly
-- Uses SI2_ flags + Reg so Configs can save them

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

-- Hide Name — Sticks Inc 2 uses Head.PlayerInfo (ContainerFrame.PlayerUserName)
local function applyHideName(on)
    local char = Players.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.NameDisplayDistance = on and 0 or 100
            if on then hum.DisplayName = "" else hum.DisplayName = Players.LocalPlayer.DisplayName end
        end
        -- Sticks Inc 2 overhead: Head.PlayerInfo billboard + any other BillboardGui on char
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
    -- fallback: hide any TextLabel in PlayerGui/CoreGui that shows name (extra safety)
    pcall(function()
        local p = Players.LocalPlayer
        local pname, dname = p.Name, p.DisplayName
        local function hideInGui(gui)
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    local txt = d.Text
                    if txt == pname or txt == dname or txt == "@"..pname or txt:find(pname, 1, true) then
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
            -- support both JumpHeight and JumpPower
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
local flyKeys = { W=false, A=false, S=false, D=false, Space=false, Ctrl=false, Shift=false }

local function stopFly()
    flyOn = false
    pcall(function() setFlag("FlyOn", false) end)
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyBV then flyBV:Destroy() flyBV=nil end
    if flyBG then flyBG:Destroy() flyBG=nil end
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
    flyBV.velocity = Vector3.new(0,0,0)
    flyBV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Parent = hrp
    setNoclip(true)
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyOn or not isCurrentGen() then stopFly() return end
        local char2 = Players.LocalPlayer.Character
        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 or not flyBV or not flyBG then return end
        local cam = workspace.CurrentCamera
        local move = Vector3.new(0,0,0)
        if flyKeys.W then move += cam.CFrame.LookVector end
        if flyKeys.S then move -= cam.CFrame.LookVector end
        if flyKeys.A then move -= cam.CFrame.RightVector end
        if flyKeys.D then move += cam.CFrame.RightVector end
        if flyKeys.Space then move += Vector3.new(0,1,0) end
        if flyKeys.Ctrl or flyKeys.Shift then move -= Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit * flySpeed end
        flyBV.velocity = move
        flyBG.cframe = cam.CFrame
    end)
end

-- Input for fly
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W=true
    elseif k == Enum.KeyCode.A then flyKeys.A=true
    elseif k == Enum.KeyCode.S then flyKeys.S=true
    elseif k == Enum.KeyCode.D then flyKeys.D=true
    elseif k == Enum.KeyCode.Space then flyKeys.Space=true
    elseif k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.LeftShift then flyKeys.Ctrl=true end
end)
UserInputService.InputEnded:Connect(function(input)
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W=false
    elseif k == Enum.KeyCode.A then flyKeys.A=false
    elseif k == Enum.KeyCode.S then flyKeys.S=false
    elseif k == Enum.KeyCode.D then flyKeys.D=false
    elseif k == Enum.KeyCode.Space then flyKeys.Space=false
    elseif k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.LeftShift then flyKeys.Ctrl=false end
end)

-- re-apply on respawn + watch for PlayerInfo recreation (Sticks re-creates billboard)
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
    -- instant hide if PlayerInfo billboard spawns late
    char.DescendantAdded:Connect(function(obj)
        if hideNameOn and obj:IsA("BillboardGui") then
            task.wait(0.05)
            if getFlag("HideNameOn") then applyHideName(true) end
        end
    end)
end)

-- also watch current character (if already spawned)
pcall(function()
    local cur = Players.LocalPlayer.Character
    if cur then
        cur.DescendantAdded:Connect(function(obj)
            if getFlag("HideNameOn") and obj:IsA("BillboardGui") then
                task.wait(0.05)
                applyHideName(true)
            end
        end)
    end
end)

-- UI
local moveSec = misc._raw:Section({ Title = "Movement", Icon = "activity", Desc = "Speed & jump", Opened = true })
misc:CreateSlider({
    name = "Walkspeed",
    desc = "Default 16 • Max 200",
    range = {8, 200},
    increment = 1,
    value = currentWalkSpeed,
    callback = function(v) applyWalkSpeed(v) end,
})
misc:CreateSlider({
    name = "Jumpheight",
    desc = "JumpHeight / JumpPower (auto)",
    range = {0, 200},
    increment = 1,
    value = currentJump,
    callback = function(v) applyJump(v) end,
})

misc._raw:Space()

local utilSec = misc._raw:Section({ Title = "Utilities", Icon = "wrench", Opened = true })

misc:CreateToggle({
    name = "Hide Name",
    desc = "Hides nametag & overhead",
    value = hideNameOn,
    callback = function(v)
        hideNameOn = v
        setFlag("HideNameOn", v)
        applyHideName(v)
    end,
})

misc:CreateToggle({
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

misc._raw:Space()

local flySec = misc._raw:Section({ Title = "Flight", Icon = "rocket", Desc = "WASD + Space/Ctrl", Opened = true })
misc:CreateToggle({
    name = "Fly",
    desc = "Enable flight (noclip while flying)",
    value = flyOn,
    callback = function(v)
        if v then startFly() else stopFly() end
    end,
})
misc:CreateSlider({
    name = "Fly Speed",
    desc = "Studs/sec • 10-250",
    range = {10, 250},
    increment = 5,
    value = flySpeed,
    callback = function(v)
        flySpeed = math.clamp(tonumber(v) or 60, 10, 250)
        pcall(function() setFlag("FlySpeed", flySpeed) end)
    end,
})

-- init
if hideNameOn then applyHideName(true) end
if noclipOn and not noclipRunning then task.spawn(noclipLoop) end
if flyOn then task.defer(function() task.wait(0.8) if getFlag("FlyOn") then startFly() end end) end


-- ===================== CREDITS (BEAUTIFUL) =====================
local DISCORD_INVITE = "https://discord.gg/PGyk3JcKht"
local SCRIPT_VERSION = "1.0.0"
local GAME_NAME = "Sticks Incremental 2"

-- Team
local teamSec = credits._raw:Section({
	Title = "Team",
	Icon = "crown",
	Desc = "Creators & contributors",
	Opened = true,
})

teamSec:Paragraph({
	Title = "Owner  •  sempai.real",
	Desc = "Lead Developer | Hub Owner",
	Image = "crown",
	ImageSize = 18,
	Color = "White",
	Buttons = {
		{
			Title = "Copy Username",
			Icon = "copy",
			Callback = function()
				pcall(function() setclipboard("sempai.real") end)
				window:Notify({ title = "Copied", content = "sempai.real copied!" })
			end,
		},
	},
})

teamSec:Paragraph({
	Title = "Sticks Inc 2",
	Desc = "Game: Sticks Incremental 2  •  Roblox",
	Image = "gamepad-2",
	ImageSize = 18,
})

credits._raw:Space()

-- Community
local commSec = credits._raw:Section({
	Title = "Community",
	Icon = "message-circle",
	Desc = "Join us, report bugs, suggest features",
	Opened = true,
})

commSec:Button({
	Title = "Discord Server",
	Desc = "Main hub • invites, updates, support",
	Icon = "messages-square",
	Callback = function()
		pcall(function() setclipboard(DISCORD_INVITE) end)
		window:Notify({ title = "Discord", content = "Invite copied! Join via browser." })
	end,
})

credits._raw:Space()

credits._raw:Divider()
credits._raw:Paragraph({
	Title = "Made with ♥  •  Liquid Hub",
	Desc = "Thanks for using Liquid Hub • Report issues in Discord",
	Image = "heart",
	ImageSize = 16,
	Color = "Grey",
})



-- ===================== CONFIGS =====================

-- Named setups (toggles/sliders/dropdowns) saved to files + optional autoload

-- applied a few seconds after (re)start, so the farm resumes by itself after

-- a rejoin once the script is executed (manually or via the executor's

-- auto-execute). Everything lives in one do-block: no chunk registers leak.

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

	-- Snapshot of every registered element's last value (tracked in adapter).

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
	local fileSec = cfgTab._raw:Section({
		Title = "Config Files",
		Icon = "folder",
		Desc = "",
		Opened = true,
	})

	local stat = fileSec:Paragraph({
		Title = "Status",
		Desc = canIO and "Ready • File I/O available" or "File functions missing — executor unsupported",
		Image = canIO and "check-circle" or "alert-triangle",
		ImageSize = 18,
	})

	local function setStatus(msg) pcall(function() stat:SetDesc(msg) end) end

	local pendingName = ""

	fileSec:Input({
		Title = "Config Name",
		Desc = "Name for new save (no slashes)",
		Placeholder = "my setup",
		Value = "",
		Callback = function(v) pendingName = tostring(v or "") end,
	})

	local selected = nil

	local listDD = fileSec:Dropdown({
		Title = "Saved Configs",
		Desc = "Pick one, then Load / Delete / Autoload",
		Values = {},
		Value = nil,
		AllowNone = true,
		Callback = function(v)
			if type(v) == "table" then selected = v[1] else selected = v end
		end,
	})

	local function refreshList()
		local names = listConfigs()
		pcall(function() listDD:Refresh(names) end)
		if selected and not table.find(names, selected) then selected = nil end
		return names
	end

	fileSec:Space()

	-- Actions
	local actSec = cfgTab._raw:Section({
		Title = "Actions",
		Icon = "zap",
		Desc = "Save, load or remove setups",
		Opened = true,
	})

	actSec:Button({
		Title = "Save Current Setup",
		
		Icon = "save",
		Callback = function()
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
				window:Notify({ title = "Configs", content = "Saved " .. name, Icon = "check" })
			else
				setStatus("Save failed")
			end
		end,
	})

	actSec:Button({
		Title = "Load Selected",
		
		Icon = "download",
		Callback = function()
			if not selected then setStatus("Select a config first") return end
			local ok, txt = pcall(function() return readfile(cfgPath(selected)) end)
			if not ok or type(txt) ~= "string" then setStatus("Read failed") return end
			local ok2, data = pcall(function() return Http:JSONDecode(txt) end)
			if not ok2 or type(data) ~= "table" then setStatus("Bad file") return end
			local n = applyData(data)
			setStatus("Loaded " .. selected .. " (" .. n .. ")")
			window:Notify({ title = "Configs", content = "Loaded " .. selected .. " (" .. n .. ")" })
		end,
	})

	actSec:Button({
		Title = "Delete Selected",
		
		Icon = "trash",
		Color = Color3.fromRGB(220, 80, 80),
		Callback = function()
			if not selected then setStatus("Select a config first") return end
			pcall(function() delfile(cfgPath(selected)) end)
			if getAutoload() == selected then clearAutoload() end
			selected = nil
			refreshList()
			setStatus("Deleted")
			window:Notify({ title = "Configs", content = "Deleted" })
		end,
	})

	cfgTab._raw:Space()

	-- Autoload
	local autoSec = cfgTab._raw:Section({
		Title = "Autoload",
		Icon = "refresh-cw",
		Desc = "Auto-apply on start (3s delay)",
		Opened = true,
	})

	local autoT

	autoT = autoSec:Toggle({
		Title = "Autoload Selected on Start",
		Desc = "Applies chosen config 3s after load",
		Value = false,
		Callback = function(v)
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

						setStatus("Autoloaded " .. a .. " (" .. n .. ")")

					end

				end

			end

		end)

	end)

end
