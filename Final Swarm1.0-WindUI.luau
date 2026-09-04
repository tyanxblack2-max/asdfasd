local function withPlugin(fn)
    local get = getthreadidentity or get_thread_identity or function() return 8 end
    local set = setthreadidentity or set_thread_identity or setthreadcontext or set_identity
    local old = get and get() or 8
    if set then pcall(set, 8) end
    local ok, res = pcall(fn)
    if set then pcall(set, old) end
    if not ok then error(res) end
    return res
end

withPlugin(function()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local function getFlag(n) return RS:GetAttribute("LH_"..n) end
local function setFlag(n,v) RS:SetAttribute("LH_"..n, v) end
-- Every load stamps a unique generation into the DataModel. Loops check it, so a
-- loop left running by an EARLIER execution of this script stops as soon as a new
-- copy loads. Without this, re-executing instead of reloading left two raid loops
-- writing the character's CFrame in the same frame, each with its own idea of
-- where to hover -- which looks exactly like the character being unable to decide
-- and shaking between two points. Seeded from the clock so a wipe cannot make a
-- new load collide with a stale stamp.
local LOAD_GEN = math.floor(os.clock() * 100000) % 1000000 + math.random(1, 999) * 1000000
RS:SetAttribute("LH_LoadGen", LOAD_GEN)
local function isCurrentGen() return RS:GetAttribute("LH_LoadGen") == LOAD_GEN end
if RS:GetAttribute("LH_AutoRaidOn")==nil then RS:SetAttribute("LH_AutoRaidOn", false) end
if RS:GetAttribute("LH_AutoShrineOn")==nil then RS:SetAttribute("LH_AutoShrineOn", true) end
if RS:GetAttribute("LH_AutoFarmOn")==nil then RS:SetAttribute("LH_AutoFarmOn", false) end
if RS:GetAttribute("LH_AutoPortalOn")==nil then RS:SetAttribute("LH_AutoPortalOn", false) end
if RS:GetAttribute("LH_MagnetOn")==nil then RS:SetAttribute("LH_MagnetOn", false) end
if RS:GetAttribute("LH_AutoChestsOn")==nil then RS:SetAttribute("LH_AutoChestsOn", false) end
if RS:GetAttribute("LH_AutoUpgradeOn")==nil then RS:SetAttribute("LH_AutoUpgradeOn", false) end
if RS:GetAttribute("LH_AutoTreeOn")==nil then RS:SetAttribute("LH_AutoTreeOn", false) end
if RS:GetAttribute("LH_AutoReplayOn")==nil then RS:SetAttribute("LH_AutoReplayOn", false) end
if RS:GetAttribute("LH_AutoPickOn")==nil then RS:SetAttribute("LH_AutoPickOn", false) end
if RS:GetAttribute("LH_NoclipOn")==nil then RS:SetAttribute("LH_NoclipOn", false) end
if RS:GetAttribute("LH_HideNameOn")==nil then RS:SetAttribute("LH_HideNameOn", false) end
local function isPaused() return false end

-- Shared resume table: systems wrapped in do-blocks (chunk-register slimming,
-- the executor caps chunk locals at 200) publish their loop starters here
-- instead of leaking locals to the end of the chunk.
local Resume = {}


-- Clean up any leftover UI from previous versions
pcall(function() game.CoreGui:FindFirstChild("AutoUpgradeUI"):Destroy() end)
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
						and (c.Text == "Auto-Upgrade Items" or c.Text == "Magnet" or c.Text == "Final Swarm Hub" or c.Text == "Liquid Hub" or c.Text == "Auto Raid Farm" or c.Text == "Auto Collect Exp") then
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
	Title = "Liquid Hub",
	Icon = "rbxassetid://89254216319344",
	Author = "Auto Farm",
	Folder = "FinalSwarmHub",
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
	return t
end

local window = {}
window._raw = WindowRaw
window._tabIcons = { Main = "play", Raid = "zap", Lobby = "package", Misc = "wrench", Credits = "info", Configs = "save" }
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

local tab = window:CreateTab({ name = "Main" })
local raid = window:CreateTab({ name = "Raid" })
local lobby = window:CreateTab({ name = "Lobby" })
local misc = window:CreateTab({ name = "Misc" })
local credits = window:CreateTab({ name = "Credits" })
local cfgTab = window:CreateTab({ name = "Configs" })

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
			if c:IsA("TextLabel") and c.Text == "Liquid Hub" then
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

local function getHumanoid()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- Disconnect the anti-cheat's HipHeight watcher (AntiCheatServiceClient line 199)
-- so it cannot reset HipHeight or report "hipHeight" violations.
local function disableAntiCheatWatcher()
	local hum = getHumanoid()
	if not hum then return end
	local sig = hum:GetPropertyChangedSignal("HipHeight")
	local cons = getconnections(sig)
	for _, c in ipairs(cons) do
		local info = c.Function and debug.getinfo(c.Function) or {}
		if tostring(info.source):find("AntiCheatServiceClient") then
			c:Disconnect()
		end
	end
end

-- Natural HipHeight of a fresh character is ~2.119. Only capture values that
-- look natural (< 5) so a reload never records the already-raised HipHeight
-- as the "original". Stored in getgenv so it survives live-reloads.
local origHeight = getgenv().origHeight

local function captureOrigHeight()
	if getgenv().origHeight then return end
	local hum = getHumanoid()
	if not hum then return end
	local h = hum.HipHeight
	if h < 5 then
		getgenv().origHeight = h
		origHeight = h
	end
end

-- ===================== MAP BOUNDS =====================
-- Keep the movement inside the playable area (workspace.Map.Floor, a 1500x1500
-- platform). Without this the orbit/flee logic can push the character off the map.
local mapBounds = nil
local floorTopY = 3
local function getMapBounds()
	if mapBounds then return mapBounds end
	local map = workspace:FindFirstChild("Map")
	local floor = map and map:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		local half = floor.Size / 2
		local c = floor.Position
		floorTopY = c.Y + half.Y
		local m = 30 -- keep this far from the edge
		mapBounds = {
			minX = c.X - half.X + m,
			maxX = c.X + half.X - m,
			minZ = c.Z - half.Z + m,
			maxZ = c.Z + half.Z - m,
		}
	end
	return mapBounds
end

local function clampToMap(v)
	local b = getMapBounds()
	if not b then return v end
	return Vector3.new(math.clamp(v.X, b.minX, b.maxX), v.Y, math.clamp(v.Z, b.minZ, b.maxZ))
end

-- ===================== SMOOTH VELOCITY MOVEMENT =====================
-- We drive the character's linear velocity so the physics engine integrates it
-- smoothly (no teleport snapping). Tween Speed acts as the travel speed.
local function getVY(p)
	local s, v = pcall(function() return p.Velocity.Y end)
	if s then return v end
	s, v = pcall(function() return p.AssemblyLinearVelocity.Y end)
	if s then return v end
	return 0
end

local function setV(p, x, y, z)
	pcall(function() p.Velocity = Vector3.new(x, y, z) end)
	pcall(function() p.AssemblyLinearVelocity = Vector3.new(x, y, z) end)
end

-- Cast a ray that ignores the local character, enemies and projectile VFX, so it
-- only reports map geometry (walls / obstacles / arena boundary).
local function farmRaycast(fromPos, dir, dist)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { Players.LocalPlayer.Character }
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then ignore[#ignore + 1] = enemies end
	local vfx = workspace:FindFirstChild("VFX")
	if vfx then ignore[#ignore + 1] = vfx end
	-- Shrines must not be treated as walls — the target IS inside the shrine sphere.
	-- Without this the solver's own container (Ball 40x40) is seen as a 69-mag wall
	-- and avoidWalls steers around it, so the bot never enters to charge.
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, m in ipairs(map:GetChildren()) do
			if m.Name == "RaidCrystalShrine" or m.Name == "RaidTomb" then
				ignore[#ignore + 1] = m
			end
		end
		-- Lava safe rocks must not be treated as walls when flying to them — иначе луч упирается в сам камень и уводит в сторону, персонаж зависает рядом и получает урон от лавы
		local pr = map:FindFirstChild("Map") and map.Map:FindFirstChild("PlayerRocks")
		if not pr then pr = map:FindFirstChild("PlayerRocks") end
		if pr then ignore[#ignore + 1] = pr end
	end
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(fromPos, dir * dist, params)
end

-- If the straight flight path is blocked by a wall, steer around it: try rotating
-- the direction in the horizontal plane, then as a last resort bias upward, so the
-- flyer slides along / over obstacles instead of pinning against them and eating hits.
local function avoidWalls(fromPos, dir, dist)
	if not farmRaycast(fromPos, dir, dist) then return dir end
	local base = math.atan2(dir.Z, dir.X)
	local yComp = dir.Y
	local tries = { 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, 2.4 }
	for _, a in ipairs(tries) do
		local ca, sa = math.cos(base + a), math.sin(base + a)
		local cand = Vector3.new(ca, yComp, sa)
		if cand.Magnitude > 0.001 then cand = cand.Unit end
		if not farmRaycast(fromPos, cand, dist) then return cand end
	end
	return Vector3.new(dir.X, math.max(yComp, 0) + 1, dir.Z).Unit
end

local function groundYAt(x, z, yHint)
	yHint = yHint or floorTopY
	local from = Vector3.new(x, yHint + 80, z)
	local ok, hit = pcall(farmRaycast, from, Vector3.new(0, -1, 0), 500)
	if ok and hit and hit.Position then return hit.Position.Y end
	local ok2, hit2 = pcall(farmRaycast, Vector3.new(x, 100, z), Vector3.new(0, -1, 0), 500)
	if ok2 and hit2 and hit2.Position then return hit2.Position.Y end
	return floorTopY
end

-- ===================== AUTO FARM (FLY) =====================
-- The character simply flies in a chosen pattern (Above / Orbit / Under) around
-- an anchor point captured when the farm starts (or when the method changes).
local autoFarmOn = getFlag("AutoFarmOn")
local autoPortalOn = getFlag("AutoPortalOn")
local portalEngaged = false
local targetMultiplier = 10  -- only enter portal once reward multiplier reaches this
local orbitHeight = 0        -- height above the anchor/boss (configurable via Orbit Height) -- 0 puts character at anchor level (near totems)
local tweenSpeed = 30        -- studs per second
local anchor = nil
local orbitAngle = 0
local orbitRadius = 45        -- studs from the anchor center
local orbitSpeed = 12         -- slow studs/sec for the circular patrol

-- ===================== PROJECTILE DODGE =====================
-- (Removed. Will be rewritten from scratch.)

-- Tracks which enemies are actually SHOOTERS (they emit projectiles). An enemy is
-- marked as a shooter whenever one of its projectiles appears near it -- projectiles
-- spawn at the shooter, so the nearest enemy to a fresh projectile is the shooter
-- itself. This is far more reliable than the EnemyData table (which only lists a few
-- types). Auto Farm then only chases shooters; when none are active it hovers at the
-- anchor (center). The marks expire after a few seconds of no fire.
local shooterMark = {}   -- [enemyModel] = lastSeenTick
local shooterRefresh = 0

-- Names of projectile models (cloned into workspace.VFX) used by the shooter
-- tracker to tell which enemies actually shoot. This feeds Auto Farm targeting,
-- not the (removed) dodge system.
local projNames = {}
pcall(function()
	local pf = game.ReplicatedStorage:FindFirstChild("Assets")
	pf = pf and pf:FindFirstChild("Projectiles")
	if pf then
		for _, v in ipairs(pf:GetChildren()) do projNames[v.Name] = true end
	end
end)

local function modelPos(m)
	local ok, pv = pcall(function() return m:GetPivot().Position end)
	if ok then return pv end
	local pp = m:FindFirstChildWhichIsA("BasePart")
	return pp and pp.Position
end

local function updateShooters()
	local vfx = workspace:FindFirstChild("VFX")
	local enemies = workspace:FindFirstChild("Enemies")
	if not vfx or not enemies then return end
	local now = tick()
	local list = enemies:GetChildren()
	for _, p in ipairs(vfx:GetChildren()) do
		if projNames[p.Name] then
			local pp = modelPos(p)
			if pp then
				local best, bestD = nil, 14
				for _, e in ipairs(list) do
					local ep = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox")
					if ep then
						local d = (ep.Position - pp).Magnitude
						if d < bestD then bestD = d; best = e end
					end
				end
				if best then shooterMark[best] = now end
			end
		end
	end
	for k, t in pairs(shooterMark) do
		if not k:IsDescendantOf(workspace) or now - t > 6 then
			shooterMark[k] = nil
		end
	end
end

-- Picks the nearest living SHOOTER enemy (one that fires projectiles), so Auto
-- Farm only chases units that shoot. Returns nil when there are no active shooters
-- (the caller then hovers at the anchor / center).
local function getEnemyHRP()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local pos = hrp and hrp.Position
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies or not pos then return nil end
	local best, bestDist = nil, math.huge
	for _, e in ipairs(enemies:GetChildren()) do
		if not shooterMark[e] then continue end
		local ehrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox")
		local hum = e:FindFirstChildOfClass("Humanoid")
		if ehrp and hum and hum.Health > 0 then
			local d = (pos - ehrp.Position).Magnitude
			if d < bestDist then bestDist = d; best = ehrp end
		end
	end
	return best
end

-- Returns the position of a live BOSS. Every world's boss follows the
-- "Boss<Name>" convention (BossZombie, BossSkeleton, BossSlime, BossYeti,
-- BossMonkey, BossSlime2..4, ...) -- confirmed from WaveGenerator -- so a
-- starts-with-"boss" match catches them all, in any world, with no per-world
-- list needed. Auto Farm orbits the boss instead of the static anchor.
local function getBossHRP()
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return nil end
	for _, e in ipairs(enemies:GetChildren()) do
		if e.Name:lower():sub(1, 4) == "boss" then
			local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox")
			local hum = e:FindFirstChildOfClass("Humanoid")
			if hrp and (not hum or hum.Health > 0) then return hrp.Position end
		end
	end
	return nil
end

local function getTarget()
	local enemy = getEnemyHRP()
	local base
	if enemy then
		base = enemy.Position
	else
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		base = anchor or (hrp and hrp.Position)
	end
	if not base then return nil end
	return base + Vector3.new(0, orbitHeight, 0)
end

local function setAnchorToCurrent()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		anchor = hrp.Position
		orbitAngle = 0
	end
end

-- Reads the on-screen reward multiplier (e.g. "1.48x rewards") from the HUD.
local function getCurrentMultiplier()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return 1 end
	local tv
	pcall(function()
		local fsb = pg:FindFirstChild("HUD") and pg.HUD:FindFirstChild("Top") and pg.HUD.Top:FindFirstChild("FinalSwarmBar")
		if fsb then
			local bg = fsb:FindFirstChild("Background")
			if bg then
				local rm = bg:FindFirstChild("RewardMult")
				if rm then tv = rm:FindFirstChild("TextValue") end
			end
		end
	end)
	if tv and tv:IsA("TextLabel") then
		local num = tv.Text:match("([%d%.]+)%s*x")
		if num then return tonumber(num) or 1 end
	end
	return 1
end

local function getPortal()
	local map = workspace:FindFirstChild("Map")
	local p = map and map:FindFirstChild("BossPortal")
	return (p and p:IsA("Model")) and p or nil
end

-- EARLY lava helpers for autoFarm (defined before raid section so autoFarm can use them)
local function isLavaActive()
	for _,c in ipairs(workspace:GetDescendants()) do
		if c:IsA("BasePart") and c.Name:lower():find("lava") then
			if c.Transparency < 0.9 then return true end
		end
	end
	local lavaM = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Map") and workspace.Map.Map:FindFirstChild("Lava")
	if lavaM then
		for _,ch in ipairs(lavaM:GetDescendants()) do
			if ch:IsA("BasePart") and ch.Transparency < 0.9 and ch.Size.Magnitude > 30 then return true end
		end
	end
	for _,c in ipairs(workspace:GetDescendants()) do
		if c:IsA("BasePart") and c.Color == Color3.fromRGB(255, 120, 40) and c.Position.Y < 8 and c.Size.Magnitude > 100 and c.Transparency < 0.9 then return true end
		if c:IsA("BasePart") and c.Color == Color3.fromRGB(234, 85, 55) and c.Position.Y < 8 and c.Size.Magnitude > 100 and c.Transparency < 0.9 then return true end
	end
	local map = workspace:FindFirstChild("Map")
	if map and (map:GetAttribute("Lava") or map:GetAttribute("RisingLava") or map:GetAttribute("LavaActive")) then return true end
	if lavaM and lavaM:GetAttribute("Active") then return true end
	return false
end
local function getSafeRockPos()
	local pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Map") and workspace.Map.Map:FindFirstChild("PlayerRocks")
	if not pr then pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("PlayerRocks") end
	if not pr then return nil end
	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local pos = hrp and hrp.Position
	if not pos then return nil end
	local best, bestD = nil, math.huge
	for _,r in ipairs(pr:GetChildren()) do
		if r:IsA("BasePart") then
			if r.Transparency >= 0.8 then continue end
			if r.Size.Magnitude < 5 then continue end
			-- цель — строго центр камня, на 3.5 над верхней гранью (100% внутри сейф зоны, даже полёт над лавой дамажит)
			local topY = r.Position.Y + r.Size.Y*0.5
			local p = Vector3.new(r.Position.X, topY + 3.5, r.Position.Z)
			local d = (pos - p).Magnitude
			if d < bestD then bestD = d; best = p end
		end
	end
	return best
end

local function autoFarmLoop()
	if Resume.farmRunning then return end
	Resume.farmRunning = true
	while autoFarmOn do
		if portalEngaged then task.wait(0.1); continue end
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hrp.Parent and hum and hum.Health > 0 then
			local portal = getPortal()
			if portal and autoPortalOn then
				-- End of run: the boss portal is up. Only drive into it when Auto
				-- Portal is enabled -- otherwise keep farming and let the player enter
				-- manually. (Auto Portal OFF must actually mean "don't enter".)
				-- Stop chasing enemies and just
				-- park next to the portal, waiting for the reward multiplier to reach
				-- the target before entering (so we bank the highest multiplier).
				local pivot = portal:GetPivot().Position
				local target = clampToMap(Vector3.new(pivot.X, pivot.Y + 2, pivot.Z))
				local dir = target - hrp.Position
				if dir.Magnitude > 4 then
					dir = dir.Unit
					local sp = math.max(tweenSpeed, 35)
					setV(hrp, dir.X * sp, dir.Y * sp, dir.Z * sp)
				else
					setV(hrp, 0, 0, 0)
					if getCurrentMultiplier() >= targetMultiplier then
						local prompt = portal:FindFirstChild("PortalPrompt")
						if prompt and prompt:IsA("ProximityPrompt") then
							pcall(function() fireproximityprompt(prompt) end)
						end
					end
				end
				task.wait(0.05)
				continue
			end
			shooterRefresh = shooterRefresh - 0.05
			if shooterRefresh <= 0 then
				updateShooters()
				shooterRefresh = 0.4
			end
			local target
			local boss = getBossHRP()
			if boss then
				-- A boss is up: orbit its live position instead of the static anchor.
				orbitAngle = orbitAngle + (orbitSpeed * 0.05) / math.max(orbitRadius, 1)
				target = Vector3.new(
					boss.X + math.cos(orbitAngle) * orbitRadius,
					boss.Y + orbitHeight,
					boss.Z + math.sin(orbitAngle) * orbitRadius
				)
			elseif anchor then
				orbitAngle = orbitAngle + (orbitSpeed * 0.05) / math.max(orbitRadius, 1)
				target = Vector3.new(
					anchor.X + math.cos(orbitAngle) * orbitRadius,
					anchor.Y + orbitHeight,
					anchor.Z + math.sin(orbitAngle) * orbitRadius
				)
			else
				target = getTarget()
			end
			local moveDir = nil
			local vy = 0
			if target then
				target = clampToMap(target)
				local dir = target - hrp.Position
				local horiz = Vector3.new(dir.X, 0, dir.Z)
				if horiz.Magnitude > 0.5 then
					moveDir = horiz.Unit
				end
				-- Vertical hold kept separate and stiff: at the slow orbit speed the
				-- horizontal vector alone could not fight gravity, so the character
				-- bobbed. A dedicated altitude correction (gain 8, clamped) holds the
				-- target height steadily.
				vy = (target.Y - hrp.Position.Y) * 8
				if vy > 80 then vy = 80 elseif vy < -80 then vy = -80 end
			end
			local speed = orbitSpeed
			if moveDir then
				local dist = target and (target - hrp.Position).Magnitude or 20
				pcall(function()
					moveDir = avoidWalls(hrp.Position, moveDir, math.min(math.max(dist, 10), 30))
				end)
				setV(hrp, moveDir.X * speed, vy, moveDir.Z * speed)
			else
				setV(hrp, 0, vy, 0)
			end
		end
		task.wait(0.05)
	end
	Resume.farmRunning = false
end

-- ===================== AUTO PORTAL =====================
local function portalLoop()
	if Resume.portalRunning then return end
	Resume.portalRunning = true
	while autoPortalOn do
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local portal = getPortal()
		local curMult = getCurrentMultiplier()
		portalEngaged = (curMult >= targetMultiplier)
		if hrp and hrp.Parent and hum and hum.Health > 0 and portal and portalEngaged then
			local pivot = portal:GetPivot().Position
			-- aim at ground level so we enter the ProximityPrompt radius
			local target = Vector3.new(pivot.X, pivot.Y + 2, pivot.Z)
			target = clampToMap(target)
			local dir = target - hrp.Position
			local dist = dir.Magnitude
			if dist > 4 then
				dir = dir.Unit
				local sp = math.max(tweenSpeed, 35)
				setV(hrp, dir.X * sp, dir.Y * sp, dir.Z * sp)
			else
				setV(hrp, 0, 0, 0)
				local prompt = portal:FindFirstChild("PortalPrompt")
				if prompt and prompt:IsA("ProximityPrompt") then
					pcall(function() fireproximityprompt(prompt) end)
				end
			end
		else
			task.wait(0.3)
		end
		task.wait(0.1)
	end
	portalEngaged = false
	Resume.portalRunning = false
end
-- ===================== RAID AUTO FARM =====================
local autoRaidOn = getFlag("AutoRaidOn")
local autoShrineOn = getFlag("AutoShrineOn")
local raidOrbitRadius = 35
local raidOrbitHeight = 8
local raidOrbitSpeed = 16
pcall(function() RS:SetAttribute("LH_RaidOrbitSpeed", raidOrbitSpeed) end)
pcall(function() RS:SetAttribute("LH_RaidOrbitRadius", raidOrbitRadius) end)
pcall(function() RS:SetAttribute("LH_RaidOrbitHeight", raidOrbitHeight) end)
local raidOrbitAngle = 0
local raidAnchor = nil
-- Speed used while working a shrine. It has to be well above the orbit speed:
-- dodging inside the zone means crossing a chunk of it before the telegraph
-- lands, and at orbit speed the character simply cannot get out of the way.
local raidShrineSpeed = 35
local raidCircleTombOn = false
local tempNoclipUntil = 0
local raidCircleIdx = 1
local raidCircleAt = 0
local RAID_CIRCLE_DWELL = 0.4
local bossCenterArrivedAt = 0
local tombEspOn = true
local tombEspRunning = false
local function setNoclip(on)
	pcall(function()
		local char = Players.LocalPlayer.Character
		if not char then return end
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not on
			end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CanCollide = not on end
	end)
end
local function hasTombsOnMap()
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return false end
	for _,e in ipairs(enemies:GetChildren()) do
		if e.Name:lower():find("tomb") then return true end
	end
	return false
end

local function setRaidAnchorToCurrent()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then raidAnchor = hrp.Position; raidOrbitAngle = 0 end
end

local function tombEspLoop()
	tombEspRunning = true
	while tombEspOn do
		pcall(function()
			local enemies = workspace:FindFirstChild("Enemies")
			if enemies then
				for _,e in ipairs(enemies:GetChildren()) do
					if e.Name:lower():find("tomb") then
						local root = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart or e:FindFirstChildWhichIsA("BasePart")
						if root then
							local hl = e:FindFirstChild("TombESP_HL")
							if not hl then
								hl = Instance.new("Highlight")
								hl.Name = "TombESP_HL"
								hl.Adornee = e
								hl.FillColor = Color3.fromRGB(255, 80, 80)
								hl.OutlineColor = Color3.fromRGB(255, 255, 255)
								hl.FillTransparency = 0.5
								hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
								hl.Parent = e
							end
							local bb = e:FindFirstChild("TombESP_BB")
							if not bb then
								bb = Instance.new("BillboardGui")
								bb.Name = "TombESP_BB"
								bb.Adornee = root
								bb.Size = UDim2.new(0, 120, 0, 40)
								bb.StudsOffset = Vector3.new(0, 5, 0)
								bb.AlwaysOnTop = true
								bb.Parent = e
								local tl = Instance.new("TextLabel")
								tl.Name = "Label"
								tl.Size = UDim2.new(1,0,1,0)
								tl.BackgroundTransparency = 1
								tl.TextScaled = true
								tl.Font = Enum.Font.GothamBold
								tl.TextStrokeTransparency = 0.2
								tl.TextColor3 = Color3.new(1,1,1)
								tl.Parent = bb
							end
							local bb2 = e:FindFirstChild("TombESP_BB")
							if bb2 then
								local tl = bb2:FindFirstChild("Label")
								local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
								local d = hrp and math.floor((hrp.Position - root.Position).Magnitude) or 0
								if tl then tl.Text = e.Name .. " ["..d.."m]" end
							end
						end
					end
				end
			end
		end)
		task.wait(0.5)
	end
	pcall(function()
		local enemies = workspace:FindFirstChild("Enemies")
		if enemies then
			for _,e in ipairs(enemies:GetChildren()) do
				local hl = e:FindFirstChild("TombESP_HL")
				if hl then hl:Destroy() end
				local bb = e:FindFirstChild("TombESP_BB")
				if bb then bb:Destroy() end
			end
		end
	end)
	tombEspRunning = false
end
task.defer(function()
	if tombEspOn and not tombEspRunning then
		task.spawn(tombEspLoop)
	end
end)

local function getRaidBossHPFrac()
	local ok, frac = pcall(function()
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local top = pg and pg:FindFirstChild("HUD") and pg.HUD:FindFirstChild("Top")
		local rb = top and top:FindFirstChild("RaidBoss")
		if rb then
			local percentLbl = rb:FindFirstChild("ProgressBar") and rb.ProgressBar:FindFirstChild("Bar") and rb.ProgressBar.Bar:FindFirstChild("CurrentPercent")
			if percentLbl and percentLbl:IsA("TextLabel") then
				local n = percentLbl.Text:match("(%d+)%s*%%")
				if n then return tonumber(n)/100 end
			end
			local bg = rb:FindFirstChild("Background") and rb.Background:FindFirstChild("TextValue")
			if bg and bg:IsA("TextLabel") then
				local a,b = bg.Text:match("([%d%.]+)%a*%s*/%s*([%d%.]+)%a*")
				if a and b then
					local function parseNum(s) s = s:match("([%d%.]+)"); return tonumber(s) or 0 end
					local ca, cb = parseNum(a), parseNum(b)
					if cb > 0 then return ca/cb end
				end
			end
		end
		return nil
	end)
	if ok and type(frac) == "number" then return math.clamp(frac, 0, 1) end
	return nil
end

local function getRaidBossInfo()
	local enemies = workspace:FindFirstChild("Enemies")
	local bossPos = nil
	if enemies then
		for _, e in ipairs(enemies:GetChildren()) do
			local nm = e.Name:lower()
			if nm:find("raidboss") or e.Name == "ZombieRaidBoss" then
				local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox") or e.PrimaryPart
				if hrp then bossPos = hrp.Position; break end
			end
		end
		if not bossPos then
			for _, e in ipairs(enemies:GetChildren()) do
				if e.Name:lower():sub(1,4) == "boss" then
					local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox")
					if hrp then bossPos = hrp.Position; break end
				end
			end
		end
	end
	local frac = getRaidBossHPFrac()
	if frac == nil and enemies and bossPos then
		for _, e in ipairs(enemies:GetChildren()) do
			local nm = e.Name:lower()
			if nm:find("raidboss") or e.Name == "ZombieRaidBoss" then
				local hum = e:FindFirstChildOfClass("Humanoid")
				if hum then frac = hum.Health / math.max(hum.MaxHealth, 1) end
			end
		end
	end
	return bossPos, frac
end

-- ===================== RAID SHRINES (TOTEMS) =====================
-- The charge zone of a shrine is its "container" part, and the game decides who is
-- inside it in RaidShrineClient.containsPoint: for the ball container that is a
-- sphere of radius Size/2 around container.Position, plus 4 studs of extra
-- VERTICAL grace. Reproducing that exactly is what lets the bot hover above the
-- ground attacks and keep charging, and it is also what tells us when two shrine
-- zones overlap -- then one spot charges both at once instead of flying between them.
local SHRINE_NAMES = { RaidCrystalShrine = true, RaidTomb = true }
local SHRINE_VERT_GRACE = 4

local function readShrine(m)
	local c = m:FindFirstChild("container", true) or m:FindFirstChild("Container", true)
	if not (c and c:IsA("BasePart")) then return nil end
	local half = c.Size * 0.5
	local r
	if c:IsA("Part") and c.Shape == Enum.PartType.Ball then
		r = math.max(half.X, half.Y, half.Z)
	else
		r = math.min(half.X, half.Z)
	end
	local prog = 0
	local v = m:FindFirstChild("Value", true)
	if v and v:IsA("GuiObject") then prog = v.Size.X.Scale end
	return { model = m, center = c.Position, radius = r, progress = prog }
end

local function getShrines()
	local out = {}
	local function scan(root)
		if not root then return end
		for _, m in ipairs(root:GetChildren()) do
			if SHRINE_NAMES[m.Name] then
				local s = readShrine(m)
				if s then out[#out + 1] = s end
			end
		end
	end
	scan(workspace:FindFirstChild("Map"))
	scan(workspace:FindFirstChild("Enemies"))
	return out
end

local function insideShrine(s, pos)
	local d = s.center - pos
	local dy = math.max(0, math.abs(d.Y) - SHRINE_VERT_GRACE)
	return Vector3.new(d.X, dy, d.Z).Magnitude <= s.radius
end

local function isLavaPhase()
	for _,c in ipairs(workspace:GetDescendants()) do
		if c:IsA("BasePart") and c.Name:lower():find("lava") then
			if c.Transparency < 0.9 then return true end
		end
	end
	local lavaM = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Map") and workspace.Map.Map:FindFirstChild("Lava")
	if lavaM then
		for _,ch in ipairs(lavaM:GetDescendants()) do
			if ch:IsA("BasePart") and ch.Transparency < 0.9 and ch.Size.Magnitude > 30 then return true end
		end
	end
	for _,c in ipairs(workspace:GetDescendants()) do
		if c:IsA("BasePart") and c.Color == Color3.fromRGB(255, 120, 40) and c.Position.Y < 8 and c.Size.Magnitude > 100 and c.Transparency < 0.9 then return true end
		if c:IsA("BasePart") and c.Color == Color3.fromRGB(234, 85, 55) and c.Position.Y < 8 and c.Size.Magnitude > 100 and c.Transparency < 0.9 then return true end
	end
	local map = workspace:FindFirstChild("Map")
	if map and (map:GetAttribute("Lava") or map:GetAttribute("RisingLava") or map:GetAttribute("LavaActive")) then return true end
	if lavaM and lavaM:GetAttribute("Active") then return true end
	return false
end
local function getNearestSafeRock()
	local pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Map") and workspace.Map.Map:FindFirstChild("PlayerRocks")
	if not pr then pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("PlayerRocks") end
	if not pr then return nil end
	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local pos = hrp and hrp.Position
	if not pos then return nil end
	local best, bestD = nil, math.huge
	for _,r in ipairs(pr:GetChildren()) do
		if r:IsA("BasePart") then
			if r.Transparency >= 0.8 then continue end
			if r.Size.Magnitude < 5 then continue end
			local p = r.Position + Vector3.new(0, 5, 0)
			local d = (pos - p).Magnitude
			if d < bestD then bestD = d; best = p end
		end
	end
	return best
end
local function getMapCenterPos()
	-- центр карты — фиксировано около (17, -43) где босс спавнится, Y 12 чтобы быть над землёй
	return Vector3.new(17, 12, -43)
end
local function getUnderBossPos(bossPos)
	if not bossPos then return nil end
	local rockY = nil
	pcall(function() local r = getNearestSafeRock(); if r then rockY = r.Y end end)
	local y = rockY or (bossPos.Y - 8)
	return Vector3.new(bossPos.X, y, bossPos.Z)
end
local function getBossCenterTarget(bossPos)
	if not bossPos then bossCenterArrivedAt = 0; return nil end
	-- если есть живые томбы — не в центр, надо их убивать
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _,e in ipairs(enemies:GetChildren()) do
			if e.Name:lower():find("tomb") then
				local hum = e:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health > 0 then bossCenterArrivedAt = 0; return nil end
			end
		end
	end
	-- если лава активна — не в центр
	local lavaChk = false
	pcall(function() lavaChk = isLavaPhase() end)
	if lavaChk then bossCenterArrivedAt = 0; return nil end
	local shrines = getShrines()
	local needCenter = false
	if #shrines == 0 then needCenter = true
	else
		local allDone = true
		for _,s in ipairs(shrines) do if s.progress < 0.99 then allDone=false; break end end
		if allDone then needCenter = true end
	end
	if not needCenter then bossCenterArrivedAt = 0; return nil end
	local center = getMapCenterPos()
	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp and center then
		local d1 = (hrp.Position - center).Magnitude
		local d2 = (bossPos - center).Magnitude
		-- если босс уже очень близко к центру — ждать не надо, сразу кружить.
		-- Порог зависит от размера туши: парковаться в центре, когда туда пришло
		-- 50-стадовое тело, = смерть в хитбоксе (перс застревает внутри коллизии).
		local bossR = 20
		pcall(function() bossR = bossBody() end)
		if d2 < math.max(15, bossR + 15) then
			bossCenterArrivedAt = 0
			raidOrbitAngle = raidOrbitAngle + (raidOrbitSpeed * 0.033) / math.max(raidOrbitRadius, 1)
			return Vector3.new(bossPos.X + math.cos(raidOrbitAngle) * raidOrbitRadius, bossPos.Y + raidOrbitHeight, bossPos.Z + math.sin(raidOrbitAngle) * raidOrbitRadius)
		end
		if d1 < 12 then
			if bossCenterArrivedAt == 0 then bossCenterArrivedAt = tick() end
			if tick() - bossCenterArrivedAt < 10 then
				return center
			else
				-- 10 сек постоял — кружиться вокруг босса в центре
				raidOrbitAngle = raidOrbitAngle + (raidOrbitSpeed * 0.033) / math.max(raidOrbitRadius, 1)
				return Vector3.new(bossPos.X + math.cos(raidOrbitAngle) * raidOrbitRadius, bossPos.Y + raidOrbitHeight, bossPos.Z + math.sin(raidOrbitAngle) * raidOrbitRadius)
			end
		else
			bossCenterArrivedAt = 0
			return center
		end
	end
	return center
end
local lastLavaRockPos, lastLavaRockAt = nil, 0
local function getNearestSafeRockAvoidDanger()
	local pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Map") and workspace.Map.Map:FindFirstChild("PlayerRocks")
	if not pr then pr = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("PlayerRocks") end
	if not pr then return getNearestSafeRock() end
	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local pos = hrp and hrp.Position
	if not pos then return getNearestSafeRock() end
	local dangers = {}
	pcall(function() dangers = updateDangers() end)
	-- VFX rock threat: boss attacks on rocks via VFX not in dangerTables
	local vfx = workspace:FindFirstChild("VFX")
	if vfx then
		for _,v in ipairs(vfx:GetChildren()) do
			local n = v.Name:lower()
			if n:find("danger") or n:find("stone") or n:find("lava") or n:find("spike") or n:find("ice") or n:find("slash") then
				local vp = nil
				pcall(function()
					if v:IsA("BasePart") then vp = v.Position
					elseif v:IsA("Model") then vp = v:GetPivot().Position
					else local part = v:FindFirstChildWhichIsA("BasePart", true) if part then vp = part.Position end end
				end)
				if vp then dangers[#dangers+1] = {pos = vp, radius = 18} end
			end
		end
	end
	local lavaEarly = false
	pcall(function() lavaEarly = isLavaPhase() end)
	if (not dangers or #dangers==0) and not lavaEarly then return getNearestSafeRock() end
	if lavaEarly and (not dangers or #dangers==0) then dangers = {} end -- в лаве даже без опасностей форсим смену камня
	local best, bestD = nil, math.huge
	local fallback, fallbackD = nil, math.huge
	for _,r in ipairs(pr:GetChildren()) do
		if r:IsA("BasePart") then
			local topY = r.Position.Y + r.Size.Y*0.5
			local p = Vector3.new(r.Position.X, topY + 3.5, r.Position.Z)
			local d = (pos - p).Magnitude
			local threat = 0
			for _,dg in ipairs(dangers) do
				local dx,dz = p.X - dg.pos.X, p.Z - dg.pos.Z
				local hd = math.sqrt(dx*dx+dz*dz)
				local need = dg.radius + (dg.isWall and 14 or 9)
				if hd < need then threat = threat + (need - hd) end
			end
			if threat == 0 then
				if d < bestD then bestD=d; best=p end
			else
				local score = threat*150 + d*2
				if score < fallbackD then fallbackD=score; fallback=p end
			end
		end
	end
	local now = tick()
	-- лава: босс бьёт по камню всегда — не ждать, сразу на другой камень, не калибаясь рядом
	local lavaForce = false
	pcall(function() lavaForce = isLavaPhase() end)
	if lavaForce and lastLavaRockPos and now - lastLavaRockAt > 0.7 then
		local needSwitch = false
		if best and (best - lastLavaRockPos).Magnitude < 5 then needSwitch = true end
		if not needSwitch and not best and fallback and (fallback - lastLavaRockPos).Magnitude < 5 then needSwitch = true end
		-- также принудительно меняем если уже 1.8 сек стоим на одном камне — не даём боссу залить
		if not needSwitch and now - lastLavaRockAt > 1.8 then needSwitch = true end
		if needSwitch then
			local alt, altScore = nil, math.huge
			for _,r2 in ipairs(pr:GetChildren()) do
				if r2:IsA("BasePart") then
					if r2.Transparency >= 0.8 then continue end
					if r2.Size.Magnitude < 5 then continue end
					local topY2 = r2.Position.Y + r2.Size.Y*0.5
					local p2 = Vector3.new(r2.Position.X, topY2 + 3.5, r2.Position.Z)
					if (p2 - lastLavaRockPos).Magnitude < 3 then continue end
					local d2 = (pos - p2).Magnitude
					local threat2 = 0
					for _,dg in ipairs(dangers) do local dx,dz = p2.X - dg.pos.X, p2.Z - dg.pos.Z local hd = math.sqrt(dx*dx+dz*dz) local need = dg.radius + (dg.isWall and 14 or 9) if hd < need then threat2 = threat2 + (need - hd) end end
					local score2 = threat2*80 + d2*1.5
					if score2 < altScore then altScore = score2; alt = p2 end
				end
			end
			if alt then lastLavaRockPos = alt; lastLavaRockAt = now; return alt end
		end
	end
	if best and lastLavaRockPos and (best - lastLavaRockPos).Magnitude < 1 and now - lastLavaRockAt < 1.0 then
		local secondBest, secondScore = nil, math.huge
		for _,r2 in ipairs(pr:GetChildren()) do
			if r2:IsA("BasePart") then
				if r2.Transparency >= 0.8 then continue end
				if r2.Size.Magnitude < 5 then continue end
				local topY2 = r2.Position.Y + r2.Size.Y*0.5
				local p2 = Vector3.new(r2.Position.X, topY2 + 3.5, r2.Position.Z)
				if (p2 - best).Magnitude < 1 then continue end
				local d2 = (pos - p2).Magnitude
				local threat2 = 0
				for _,dg in ipairs(dangers) do local dx,dz = p2.X - dg.pos.X, p2.Z - dg.pos.Z local hd = math.sqrt(dx*dx+dz*dz) local need = dg.radius + (dg.isWall and 14 or 9) if hd < need then threat2 = threat2 + (need - hd) end end
				local score2 = threat2*150 + d2*2
				if score2 < secondScore then secondScore = score2; secondBest = p2 end
			end
		end
		if secondBest then lastLavaRockPos = secondBest; lastLavaRockAt = now; return secondBest end
	end
	local chosen = best or fallback
	if chosen then
		if not lastLavaRockPos or (chosen - lastLavaRockPos).Magnitude >= 1 then
			lastLavaRockPos = chosen
			lastLavaRockAt = now
		end
		return chosen
	end
	return getNearestSafeRock()
end

-- ===================== RAID DANGER (BOSS TELEGRAPHS) =====================
-- Every boss ground attack is telegraphed by a DangerArea / DangerAreaFloor /
-- SlashZone / IceAttack model that EnemyServiceClient keeps in its own lists
-- together with the attack's real targetRadius and the tick it lands on. Reading
-- those lists is exact; the previous approach (walking workspace looking for
-- "suspicious" parts) matched grass, rocks and our own weapon VFX and missed the
-- actual attacks entirely.
--
-- The lists are found by SHAPE, not by upvalue index, so a game update that
-- reorders them cannot silently break the dodge: any upvalue table is kept, and
-- at read time only entries that look like a telegraph (a .model plus a hit /
-- rise tick) are used. NOTE Real's debug.getupvalue returns the VALUE only, not
-- (name, value) like standard Lua -- getupvalues is used instead.
local EnemyClient = nil
local dangerTables = nil

local function discoverDangerTables()
	if dangerTables then return dangerTables end
	if not EnemyClient then
		local ok, m = pcall(function()
			return require(game.ReplicatedStorage.Shared.Services.EnemyService.EnemyServiceClient)
		end)
		if not ok then return nil end
		EnemyClient = m
	end
	if type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then return nil end
	local found, seen = {}, {}
	for _, fname in ipairs({ "BossAttack", "IcicleLine", "DasherAim", "ArcherAim",
		"SniperAim", "LaserSweepAim", "ConeAim", "LaserSweepBurst", "GroundSlam", "Spires", "WallAttack", "SpikeAttack", "GrabAim" }) do
		local f = EnemyClient[fname]
		if type(f) == "function" then
			local ok, ups = pcall(debug.getupvalues, f)
			if ok and type(ups) == "table" then
				for _, val in pairs(ups) do
					if type(val) == "table" and not seen[val] then
						seen[val] = true
						found[#found + 1] = val
					end
				end
			end
		end
	end
	if #found > 0 then dangerTables = found end
	return dangerTables
end

local function modelRadius(m)
	local ok, size = pcall(function()
		local _, sz = m:GetBoundingBox()
		return sz
	end)
	if ok and size then return math.max(size.X, size.Z) * 0.5 end
	return nil
end

local function modelPivotPos(m)
	local ok, p = pcall(function() return m:GetPivot().Position end)
	if ok then return p end
	if m:IsA("BasePart") then return m.Position end
	return nil
end

-- Live list of { pos, radius } for every telegraphed attack on the ground.
local dangers = {}
local dangerScanAt = 0

local function updateDangers()
	if tick() - dangerScanAt < 0.05 then return dangers end
	dangerScanAt = tick()
	local out = {}
	local tabs = discoverDangerTables()
	if tabs then
		for _, t in ipairs(tabs) do
			for _, e in ipairs(t) do
				-- Only real telegraph entries: a VFX model plus the tick it lands
				-- on. This is what tells them apart from the enemy lists, which
				-- live in the same upvalue set.
				if type(e) == "table" and e.model
					and (e.hitTick or e.riseTick or e.endTick) then
					local m = e.model
					if typeof(m) == "Instance" and m.Parent then
						local pos = e.basePos or modelPivotPos(m)
						local r = e.targetRadius or e.attackRadius or modelRadius(m)
						if pos and r and r > 0 then
							local isWall = false
							pcall(function() local nm = e.model and e.model.Name and e.model.Name:lower() or ""; isWall = nm:find("wall") or nm:find("line") or nm:find("spire") or nm:find("slam") or nm:find("spike") end)
							out[#out + 1] = { pos = pos, radius = r, isWall = isWall and true or nil }
						end
					end
				end
			end
		end
	end
	-- Fallback: if the upvalue lists could not be read, at least catch the
	-- telegraph models by name in workspace.VFX.
	if #out == 0 then
		local vfx = workspace:FindFirstChild("VFX")
		if vfx then
			for _, c in ipairs(vfx:GetChildren()) do
				local n = c.Name
				if n:find("Danger") or n:find("Slash") or n:find("Ice") or n:find("Stone") or n:find("Wall") or n:find("Spire") or n:find("Spike") or n:find("Line") or n:find("Slam") or n:find("Laser") or n:find("Beam") or n:find("Ground") or n:find("Grab") or n:find("Zone") then
					local pos = modelPivotPos(c)
					local r = modelRadius(c)
					if pos and r and r > 1 then local isWall = n:lower():find("wall") or n:lower():find("line") or n:lower():find("spire") or n:lower():find("slam") or n:lower():find("spike") or n:lower():find("laser") or n:lower():find("beam") if isWall then out[#out + 1] = { pos = pos, radius = r, isWall = true } else out[#out + 1] = { pos = pos, radius = r } end end
				end
			end
		end
	end
	dangers = out
	return dangers
end

-- Horizontal half-extent and top of the boss body, so we can hover clear of its
-- contact damage without hardcoding a number per boss.
-- FIX: GetBoundingBox берет ВСЮ модель (мечи/эффекты) и завышает радиус до 50-70, из-за чего орбита 35 всегда внутри и додж не может выйти (кандидаты 48 < need). Берем HRP/hitbox если есть.
local function bossBody()
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return 20, nil end
	for _, e in ipairs(enemies:GetChildren()) do
		local nm = e.Name:lower()
		if nm:find("raidboss") or nm:sub(1, 4) == "boss" then
			-- prefer HRP/hitbox over full model bbox
			local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox")
			if hrp and hrp:IsA("BasePart") then
				local ok2, sz = pcall(function() return hrp.Size end)
				if ok2 and sz then
					return math.max(sz.X, sz.Z) * 0.6 + 6, hrp.Position.Y + sz.Y * 0.5
				end
			end
			local ok, cf, sz = pcall(function()
				local a, b = e:GetBoundingBox()
				return a, b
			end)
			if ok and sz then
				-- clamp crazy bbox (если модель 100 стадов — режем до 28)
				local r = math.max(sz.X, sz.Z) * 0.5
				if r > 32 then r = 28 end
				return r, cf.Position.Y + sz.Y * 0.5
			end
		end
	end
	return 20, nil
end
-- DODGE — атака важнее отхода от босса: сначала доджим телеграфы, только потом хитбокс. Босс хитбокс — притык 2, и только когда Raid Auto farm включён.
local function getRaidDodgePos(myPos, fallbackPos)
	local dangers = updateDangers()
	local bossR, bossTopY = bossBody()
	local bossPos2 = nil
	pcall(function() bossPos2 = (getRaidBossInfo()) end)
	local function isDanger(p)
		for _,d in ipairs(dangers) do
			local dx,dz = p.X - d.pos.X, p.Z - d.pos.Z
			if math.sqrt(dx*dx+dz*dz) < d.radius + (d.isWall and 14 or 9) then return true end
		end
		return false
	end
	local function isBoss(p) return false end -- REMOVED: boss hitbox dodge disabled per request
	local inDanger = isDanger(myPos)
	local inBoss = false
	if #dangers==0 then return nil end
	if not inDanger then return nil end
	-- приоритет шрайнов: если можно безопасно остаться внутри шрайна — остаёмся
	local shrinesForDodge = {}
	local hasActiveShrine = false
	pcall(function()
		shrinesForDodge = getShrines()
		for _,s in ipairs(shrinesForDodge) do if s.progress < 0.99 then hasActiveShrine = true; break end end
		if hasActiveShrine and not getFlag("AutoShrineOn") then hasActiveShrine = false end
	end)
	local bestAny, bestAnyDist = nil, math.huge
	local bestInShrine, bestInShrineDist = nil, math.huge
	-- если в опасности — ищем точку вне опасности (босс вторичен, только штраф)
	-- если только в боссе — ищем вне босса и вне опасностей
	local function candidateOK(cand)
		if inDanger then
			if isDanger(cand) then return false end
			-- в опасности босс не обязателен, но предпочитаем вне босса
			return true
		else
			if isBoss(cand) then return false end
			if isDanger(cand) then return false end
			return true
		end
	end
	local function candidateScore(cand, dist)
		local s = dist
		if fallbackPos then s = s + (cand - fallbackPos).Magnitude * 0.3 end
		-- когда доджим атаку, босс — только мягкий штраф а не блок
		if inDanger and isBoss(cand) then s = s + 18 end
		return s
	end
	for _, ang in ipairs({0, 0.392, 0.785, 1.178, 1.57, 1.963, 2.35, 2.748, 3.14, 3.534, 3.927, 4.319, 4.71, 5.105, 5.498, 5.89}) do
		for _, dist in ipairs({22, 32, 45, 62, 85}) do
			-- check two heights: current Y and above boss (vertical escape)
			local yVariants = { myPos.Y }
			if bossTopY then yVariants[2] = bossTopY + 7 end
			for _, y in ipairs(yVariants) do
				local cand = Vector3.new(myPos.X + math.cos(ang)*dist, y, myPos.Z + math.sin(ang)*dist)
				if not candidateOK(cand) then continue end
				local ok, hit = pcall(farmRaycast, myPos, (cand - myPos).Unit, (cand - myPos).Magnitude)
				if ok and hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.6 then continue end
				local d = candidateScore(cand, (cand - myPos).Magnitude)
				if d < bestAnyDist then bestAnyDist=d; bestAny=cand end
				local inside = false
				for _,s in ipairs(shrinesForDodge) do
					if s.progress < 1 and insideShrine(s, cand) then inside = true; break end
				end
				if inside and d < bestInShrineDist then bestInShrineDist=d; bestInShrine=cand end
			end
		end
	end
	if hasActiveShrine and bestInShrine then return bestInShrine end
	return bestAny
end

-- ===================== RAID HOVER SOLVER =====================
-- Instead of "pick one shrine, then shove the target around when something is
-- near", the bot scores candidate hover points and commits to the best one.
-- Coverage is the first term, so when two shrine zones overlap the point inside
-- BOTH always wins -- that is what stops the fly-there-fly-back oscillation and
-- charges two totems at once instead of neither. Danger and boss clearance are
-- penalties, so a dodge is just a lower-scoring spot losing to a safer one that
-- is STILL inside the zone; the bot never has to abandon the totem to survive.
local raidHoverY = 12            -- studs above the shrine container centre (ниже чтобы гарантированно внутри сферы r20 с grace 4)
local raidDangerPad = 4          -- extra clearance around a telegraphed attack (уменьшено чтобы не улетать когда есть место)
local raidBossPad = 2            -- extra clearance around the boss body (1-2 притык, приоритет шрайны)
local RAID_SPOT_DWELL = 0.35     -- seconds to stay committed before reconsidering
local RAID_SPOT_MARGIN = 900     -- score a rival must beat the current spot by
local RAID_BAIL_THREAT = 16      -- studs of overlap with an attack that forces a step out (ещё выше чтобы держаться в круге пока есть место)
local raidSpot = nil
local raidSpotAt = 0

-- Highest Y at (x,z) that is still inside every shrine covering that column.
local function shrineCeilingAt(x, z, shrines)
	local best = nil
	for _, s in ipairs(shrines) do
		local dx, dz = x - s.center.X, z - s.center.Z
		local h2 = dx * dx + dz * dz
		if h2 <= s.radius * s.radius then
			local top = s.center.Y + math.sqrt(s.radius * s.radius - h2) + SHRINE_VERT_GRACE - 0.75
			if best == nil or top < best then best = top end
		end
	end
	return best
end

-- How deep a point sits inside the TELEGRAPHED ATTACKS, in studs. This is the
-- only thing allowed to drive the bot out of a shrine zone, because it is the
-- only thing that actually one-shots it. Height above a ground attack helps but
-- is not immunity, so altitude only reduces the depth.
local function threatAt(p, dangerList)
	local threat = 0
	for _, d in ipairs(dangerList) do
		local dx, dz = p.X - d.pos.X, p.Z - d.pos.Z
		local hd = math.sqrt(dx * dx + dz * dz)
		local need = d.radius + (d.isWall and 8 or raidDangerPad)
		if hd < need then
			local relief = math.clamp((p.Y - d.pos.Y - 6) / 16, 0, 1)
			threat = threat + (need - hd) * (1 - 0.55 * relief)
		end
	end
	return threat
end

-- Boss proximity is a PREFERENCE, never a reason to leave the totem. The boss
-- walking up to a shrine is the normal case -- it heals off the shrine, so it
-- comes to defend it -- and treating that as a hazard is what made the old
-- version fly away and let the totem tick back up. Its contact damage needs
-- actual contact, so hovering above the body cancels the penalty entirely.
local function bossPenalty(p, bossPos, bossR, bossTopY) return 0 end -- REMOVED: boss hitbox disabled

-- Returns score, coverage, threat. score is nil when the point charges nothing.
local function scoreSpot(p, shrines, dangerList, bossPos, bossR, bossTopY, myPos)
	local cover, bestProgress = 0, 0
	for _, s in ipairs(shrines) do
		if s.progress < 1 and insideShrine(s, p) then
			cover = cover + 1
			if s.progress > bestProgress then bestProgress = s.progress end
		end
	end
	local threat = threatAt(p, dangerList)
	if cover == 0 then return nil, 0, threat end
	-- Coverage dominates: two zones at once is always worth more than one, and
	-- both outrank any amount of boss discomfort.
	local score = cover * 5000 + bestProgress * 400
		- threat * 150 - bossPenalty(p, bossPos, bossR, bossTopY)
	if myPos then score = score - (p - myPos).Magnitude * 4 end
	return score, cover, threat
end

-- Build the candidate hover points: the centre and rings inside each shrine, and
-- the centroid of every overlapping group (the spot that charges them together).
-- The outer ring (fr > 1) is the bail-out tier: used only when every charging
-- point is inside an attack, so the bot steps out for a moment instead of eating it.
local function buildCandidates(shrines, myPos)
	local cands = {}
	local function push(x, z)
		local ceil = shrineCeilingAt(x, z, shrines)
		local base = nil
		for _, s in ipairs(shrines) do
			local dx, dz = x - s.center.X, z - s.center.Z
			local rr = (s.radius + 26)
			if dx * dx + dz * dz <= rr * rr then
				if base == nil or s.center.Y > base then base = s.center.Y end
			end
		end
		if not base then return end
		local y = base + raidHoverY
		if ceil then y = math.min(y, ceil) end
		cands[#cands + 1] = Vector3.new(x, y, z)
	end
	for _, s in ipairs(shrines) do
		if s.progress < 1 then
			push(s.center.X, s.center.Z)
			for k = 0, 15 do
				local a = (k / 16) * math.pi * 2
				local ca, sa = math.cos(a), math.sin(a)
				for _, fr in ipairs({ 0.25, 0.40, 1.35 }) do
					push(s.center.X + ca * s.radius * fr, s.center.Z + sa * s.radius * fr)
				end
			end
		end
	end
	-- Overlap centroids: for each shrine, the average centre of every other
	-- shrine whose zone it reaches. This is the point that covers them all.
	for i, a in ipairs(shrines) do
		if a.progress < 1 then
			local sx, sz, n = a.center.X, a.center.Z, 1
			for j, b in ipairs(shrines) do
				if i ~= j and b.progress < 1 then
					local d = Vector3.new(a.center.X - b.center.X, 0, a.center.Z - b.center.Z).Magnitude
					if d < a.radius + b.radius then
						sx = sx + b.center.X; sz = sz + b.center.Z; n = n + 1
					end
				end
			end
			if n > 1 then push(sx / n, sz / n) end
		end
	end
	if raidSpot then push(raidSpot.X, raidSpot.Z) end
	if myPos then push(myPos.X, myPos.Z) end
	return cands
end

-- Returns the hover point to fly to, or nil when no shrine is chargeable.
-- Commits to a spot for RAID_SPOT_DWELL seconds and only switches when a rival
-- beats it by RAID_SPOT_MARGIN, so the character stops trembling between two
-- equally good options -- the actual cause of the fly-there-fly-back bug. A
-- freshly telegraphed attack landing on the current spot breaks the commitment
-- immediately, otherwise the dwell would hold us in the blast.
local function pickShrineSpot(bossPos)
	local shrines = getShrines()
	if #shrines == 0 then
		raidSpot = nil
		return nil
	end
	-- FIX: if all shrines charged (progress 1) don't block boss orbit
	local hasChargeable = false
	for _, s in ipairs(shrines) do if s.progress < 0.99 then hasChargeable = true; break end end
	if not hasChargeable then raidSpot = nil; return nil end
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local myPos = hrp and hrp.Position
	local dangerList = updateDangers()
	local bossR, bossTopY = 0, nil
	if bossPos then bossR, bossTopY = bossBody() end

	-- Is the spot we already committed to still valid and still safe enough?
	local curScore, _, curThreat = nil, nil, nil
	if raidSpot then
		curScore, _, curThreat = scoreSpot(raidSpot, shrines, dangerList, bossPos, bossR, bossTopY, myPos)
	end
	if curScore and (curThreat or 0) < RAID_BAIL_THREAT
		and tick() - raidSpotAt < RAID_SPOT_DWELL then
		return raidSpot
	end

	local cands = buildCandidates(shrines, myPos)
	local best, bestScore = nil, -math.huge
	for _, p in ipairs(cands) do
		local sc, _, th = scoreSpot(p, shrines, dangerList, bossPos, bossR, bossTopY, myPos)
		if sc and th < RAID_BAIL_THREAT and sc > bestScore then bestScore = sc; best = p end
	end
	if not best then
		-- Every charging point is inside an attack. Take the least dangerous
		-- point we can reach -- charging is worthless if we die doing it -- and
		-- prefer one that still charges something when the threat is equal.
		local bailBest, bailVal = nil, -math.huge
		for _, p in ipairs(cands) do
			-- skip points deep inside boss body even in bail
			if bossPos and bossR then
				local bdx, bdz = p.X - bossPos.X, p.Z - bossPos.Z
				if math.sqrt(bdx * bdx + bdz * bdz) < bossR then continue end
			end
			local _, cover, th = scoreSpot(p, shrines, dangerList, bossPos, bossR, bossTopY, myPos)
			-- FIX: if point charges nothing (cover 0) don't pick it in bail, else we stuck on myPos when shrines done
			if (cover or 0) == 0 then continue end
			local v = -th * 200 + (cover or 0) * 300
			if myPos then v = v - (p - myPos).Magnitude * 4 end
			if v > bailVal then bailVal = v; bailBest = p end
		end
		if not bailBest then
			raidSpot = nil
			return nil
		end
		raidSpot = bailBest
		raidSpotAt = tick()
		return bailBest
	end
	if curScore and (curThreat or 0) < RAID_BAIL_THREAT
		and bestScore <= curScore + RAID_SPOT_MARGIN then
		return raidSpot
	end
	-- nudge 3 studs внутрь ближайшего shrine чтобы гарантированно быть в зоне (фикс "немного за зоной")
	if best then
		local nearest, minD = nil, math.huge
		for _,s in ipairs(shrines) do
			if insideShrine(s, best) then
				local d = Vector3.new(best.X - s.center.X, 0, best.Z - s.center.Z).Magnitude
				if d < minD then minD=d; nearest=s end
			end
		end
		if nearest and minD > 0.5 then
			local dir = Vector3.new(nearest.center.X - best.X, 0, nearest.center.Z - best.Z)
			if dir.Magnitude > 0.5 then
				dir = dir.Unit * 3
				local nudged = Vector3.new(best.X + dir.X, best.Y, best.Z + dir.Z)
				if insideShrine(nearest, nudged) then best = nudged end
			end
		end
	end
	raidSpot = best
	raidSpotAt = tick()
	return best
end


local RunService = game:GetService("RunService")
local raidLoopRunning = false
local function raidFarmLoop()
	-- One loop only. Two copies both writing hrp.CFrame every frame is
	-- indistinguishable from the character being unable to pick a target.
	if raidLoopRunning then return end
	raidLoopRunning = true
	while getFlag("AutoRaidOn") and isCurrentGen() do
		local dt = RunService.Heartbeat:Wait()
		if not (getFlag("AutoRaidOn") and isCurrentGen()) then break end
		if dt <= 0 or dt > 0.08 then dt = 0.033 end
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if isPaused() then
			if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); hrp.Velocity = Vector3.new(0,0,0) end) end
			task.wait(0.2)
			continue
		end
		if hrp and hrp.Parent and hum and hum.Health > 0 then
			-- Noclip для Circle Tombs и для лавы (камень — узкая зона, коллизия стенок мешает встать точно в центр)
			local _lavaForNoclip = false
			pcall(function() _lavaForNoclip = isLavaPhase() end)
			local bossPos = getRaidBossInfo()
			pcall(function() setNoclip(raidCircleTombOn or _lavaForNoclip or tick() < tempNoclipUntil or getFlag("NoclipOn")) end)
			local target = nil
			local isShrineTarget = false
			local isBossCenter = false
			-- LAVA — абсолютный приоритет: пока лава активна надо быть 100% внутри сейф зоны, иначе даже полёт над лавой дамажит. Додж босса уже учтён при выборе камня (getNearestSafeRockAvoidDanger).
			local lavaNow = false
			pcall(function() lavaNow = isLavaPhase() end)
			local dodgePos = nil
			if not lavaNow then pcall(function() dodgePos = getRaidDodgePos(hrp.Position, bossPos) end) end
			-- Пока доджим (атака или туша босса) — держим временный ноклип, иначе
			-- выбраться из 50-стадового хитбокса нельзя: движок каждый кадр
			-- возвращает перса назад (пенетрация), и бот вечно дрожит внутри.
			if dodgePos then tempNoclipUntil = tick() + 1 end
			if lavaNow then
				local rock = nil
				pcall(function() rock = getNearestSafeRockAvoidDanger() end)
				if not rock then pcall(function() rock = getNearestSafeRock() end) end
				if rock then target = rock; isShrineTarget = true end
				-- если лава но камень уже и додж — камень важнее, игнорим додж чтобы не выйти из сейф зоны
			elseif dodgePos then
				target = dodgePos
				isShrineTarget = false
			end
			-- CIRCLE TOMBS — летать по кругу с одного tomb на другой (когда лавы нет и нет доджа)
			if not target and raidCircleTombOn then
				local tombs = {}
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies then
					for _,e in ipairs(enemies:GetChildren()) do
						if e.Name:lower():find("tomb") then
							local pp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("hitbox") or e.PrimaryPart
							local pos = pp and pp.Position
							if not pos then pcall(function() pos = e:GetPivot().Position end) end
							if pos then
								local hum2 = e:FindFirstChildOfClass("Humanoid")
								if not hum2 or hum2.Health > 0 then
									tombs[#tombs+1] = {center = pos, model = e}
								end
							end
						end
					end
				end
				if #tombs >= 2 then
					local cx,cz=0,0
					for _,t2 in ipairs(tombs) do cx=cx+t2.center.X; cz=cz+t2.center.Z end
					cx=cx/#tombs; cz=cz/#tombs
					table.sort(tombs, function(a,b)
						return math.atan2(a.center.Z-cz, a.center.X-cx) < math.atan2(b.center.Z-cz, b.center.X-cx)
					end)
					if raidCircleIdx > #tombs then raidCircleIdx=1 end
					local dangersForCircle = {}
					pcall(function() dangersForCircle = updateDangers() end)
					local function isBehindWall(fromPos, toPos)
						local dir = toPos - fromPos
						local dist = dir.Magnitude
						if dist < 3 then return false end
						local ok, hit = pcall(farmRaycast, fromPos, dir.Unit, math.min(dist, 60))
						if ok and hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.6 then
							return true
						end
						return false
					end
					local curValid = false
					if tick() - raidCircleAt < RAID_CIRCLE_DWELL and tombs[raidCircleIdx] then
						local cand = tombs[raidCircleIdx]
						local candHoriz = Vector3.new(cand.center.X, hrp.Position.Y, cand.center.Z)
						local threatenedCur = false
						for _,d in ipairs(dangersForCircle) do
							local dx,dz = cand.center.X - d.pos.X, cand.center.Z - d.pos.Z
							if math.sqrt(dx*dx+dz*dz) < d.radius + 9 then threatenedCur=true; break end
							dx,dz = candHoriz.X - d.pos.X, candHoriz.Z - d.pos.Z
							if math.sqrt(dx*dx+dz*dz) < d.radius + 9 then threatenedCur=true; break end
						end
						if not threatenedCur then
						if isBehindWall(hrp.Position, candHoriz) then tempNoclipUntil = tick() + 3 end
						curValid = true
					end
					end
					if not curValid then
						local tries=0
						while tries < #tombs do
							local cand = tombs[raidCircleIdx]
							local candHoriz = Vector3.new(cand.center.X, hrp.Position.Y, cand.center.Z)
							local threatened = false
							if #dangersForCircle>0 then
								for _,d in ipairs(dangersForCircle) do
									local dx,dz = cand.center.X - d.pos.X, cand.center.Z - d.pos.Z
									local hd = math.sqrt(dx*dx+dz*dz)
									if hd < d.radius + 9 then threatened=true; break end
									dx,dz = candHoriz.X - d.pos.X, candHoriz.Z - d.pos.Z
									hd = math.sqrt(dx*dx+dz*dz)
									if hd < d.radius + 9 then threatened=true; break end
								end
							end
							if not threatened then
							if isBehindWall(hrp.Position, candHoriz) then tempNoclipUntil = tick() + 3 end
							break
						end
							raidCircleIdx = raidCircleIdx % #tombs + 1
							tries = tries + 1
						end
					end
					local cur = tombs[raidCircleIdx]
					do
						local candHoriz2 = Vector3.new(cur.center.X, hrp.Position.Y, cur.center.Z)
						local stillThreat = false
						for _,d in ipairs(dangersForCircle) do
							local dx,dz = cur.center.X - d.pos.X, cur.center.Z - d.pos.Z
							if math.sqrt(dx*dx+dz*dz) < d.radius + 9 then stillThreat=true; break end
							dx,dz = candHoriz2.X - d.pos.X, candHoriz2.Z - d.pos.Z
							if math.sqrt(dx*dx+dz*dz) < d.radius + 9 then stillThreat=true; break end
						end
						local behind2 = false
						do
							local dir = candHoriz2 - hrp.Position
							local dist = dir.Magnitude
							if dist >= 3 then
								local ok, hit = pcall(farmRaycast, hrp.Position, dir.Unit, math.min(dist, 60))
								if ok and hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.6 then behind2 = true end
							end
						end
						if not stillThreat then
							if behind2 then tempNoclipUntil = tick() + 3 end
							local y = cur.center.Y + 6
							target = Vector3.new(cur.center.X, y, cur.center.Z)
							isShrineTarget = true
							raidCircleAt = tick()
							if (Vector3.new(target.X, hrp.Position.Y, target.Z) - Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)).Magnitude < 8 then
								raidCircleIdx = raidCircleIdx % #tombs + 1
								raidCircleAt = tick()
							end
						end
					end
				elseif #tombs==1 then
					local cur=tombs[1]
					local candHoriz = Vector3.new(cur.center.X, hrp.Position.Y, cur.center.Z)
					local threatenedSingle = false
					do
						local d = {}
						pcall(function() d = updateDangers() end)
						if #d>0 then
							for _,dg in ipairs(d) do
								local dx,dz = cur.center.X - dg.pos.X, cur.center.Z - dg.pos.Z
								local hd = math.sqrt(dx*dx+dz*dz)
								if hd < dg.radius + 9 then threatenedSingle=true; break end
								dx,dz = candHoriz.X - dg.pos.X, candHoriz.Z - dg.pos.Z
								hd = math.sqrt(dx*dx+dz*dz)
								if hd < dg.radius + 9 then threatenedSingle=true; break end
							end
						end
					end
					local ok, hit = pcall(farmRaycast, hrp.Position, (candHoriz - hrp.Position).Unit, math.min((candHoriz - hrp.Position).Magnitude, 60))
					local behind = ok and hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.6
					if not threatenedSingle then
						if behind then tempNoclipUntil = tick() + 3 end
						local y = cur.center.Y + 6
						target = Vector3.new(cur.center.X, y, cur.center.Z)
						isShrineTarget = true
					end
				end
			end
			if not target and getFlag("AutoShrineOn") then
				local spot = pickShrineSpot(bossPos)
				if spot then
					target = spot
					isShrineTarget = true
				end
			elseif not target and not getFlag("AutoShrineOn") then
				raidSpot = nil
			end
			-- BOSS CENTER — только когда нет мини-игр (нет томб/шрайнов/лавы), летит в центр карты чтобы босс шёл в центр и там кружиться
			if not target and bossPos then
				local center = nil
				pcall(function() center = getBossCenterTarget(bossPos) end)
				if center then target = center; isBossCenter = true end
			end
			if not target then
				if bossPos then
					if isLavaPhase() then
						local rock = nil
						-- сначала под боссом
						pcall(function() rock = getUnderBossPos(bossPos) end)
						if rock then
							local threatened = false
							local dangers = {}
							pcall(function() dangers = updateDangers() end)
							for _,d in ipairs(dangers) do
								local dx,dz = rock.X - d.pos.X, rock.Z - d.pos.Z
								if math.sqrt(dx*dx+dz*dz) < d.radius + 9 then threatened=true; break end
							end
							local behind = false
							do
								local dir = Vector3.new(rock.X - hrp.Position.X, 0, rock.Z - hrp.Position.Z)
								local dist = dir.Magnitude
								if dist >= 3 then
									local ok, hit = pcall(farmRaycast, hrp.Position, dir.Unit, math.min(dist, 60))
									if ok and hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.6 then behind = true end
								end
							end
							if threatened or behind then rock = nil end
						end
						if not rock then
							pcall(function() rock = getNearestSafeRockAvoidDanger() end)
							if not rock then rock = getNearestSafeRock() end
						end
						if rock then target = rock else target = bossPos + Vector3.new(0, 25, 0) end
					else
						raidOrbitAngle = raidOrbitAngle + (raidOrbitSpeed * dt) / math.max(raidOrbitRadius, 1)
						local cy = bossPos.Y + raidOrbitHeight
						-- FIX: keep orbit above boss body, else hitbox triggers dodge and looks like "pull to boss"
						local bR2, bTop = 20, nil
						pcall(function() bR2, bTop = bossBody() end)
						if bTop and cy < bTop + 6 then cy = bTop + 6 end
						target = Vector3.new(bossPos.X + math.cos(raidOrbitAngle) * raidOrbitRadius, cy, bossPos.Z + math.sin(raidOrbitAngle) * raidOrbitRadius)
					end
				elseif raidAnchor then
					raidOrbitAngle = raidOrbitAngle + (raidOrbitSpeed * dt) / math.max(raidOrbitRadius, 1)
					local gy = groundYAt(raidAnchor.X, raidAnchor.Z, raidAnchor.Y)
					local cy = (gy ~= nil) and (gy + raidOrbitHeight) or (raidAnchor.Y + raidOrbitHeight)
					-- FIX: keep above floor
					if cy < floorTopY + 4 then cy = floorTopY + 8 end
					target = Vector3.new(raidAnchor.X + math.cos(raidOrbitAngle) * raidOrbitRadius, cy, raidAnchor.Z + math.sin(raidOrbitAngle) * raidOrbitRadius)
				end
			end
			if target then
				if not isShrineTarget then target = clampToMap(target) end
				-- Inside a zone the bot must be able to cross the zone faster
				-- than an attack lands, so shrine work gets the high speed; the
				-- boss orbit stays slow so it does not overshoot.
				local speed = isShrineTarget and raidShrineSpeed or raidOrbitSpeed
				if lavaNow and target then speed = 35
				elseif dodgePos and target == dodgePos then speed = 38 -- FIX: был 16, слишком медленно чтобы выйти из туши 30+ радиуса
				elseif isBossCenter and target then speed = 35
				elseif raidCircleTombOn and target and not lavaNow then speed = raidOrbitSpeed end
				pcall(function() hrp.Anchored = false end)
				pcall(function() hum.WalkSpeed = math.max(22, speed) end)
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
				do
					local gy = groundYAt(target.X, target.Z, target.Y)
					if gy then
						local wantHip = target.Y - gy
						if wantHip > 0 then pcall(function() hum.HipHeight = math.clamp(wantHip, isShrineTarget and 0.2 or 2, 120) end) end
					end
				end
				local dir = target - hrp.Position
				local dist = dir.Magnitude
				if dist > 0.3 then
					local moveDir = dir.Unit
					-- для лавы — строго в центр камня без объезда стен, иначе зависает "рядом" и получает урон (даже полёт над лавой дамажит)
					-- Шрайны у стены раньше игнорили стены (not isShrineTarget) -> врезался
					-- Теперь объезжаем всегда кроме лавы
					if not lavaNow and dist > 4 and not (tick() < tempNoclipUntil) then
						pcall(function()
							local horiz = Vector3.new(dir.X, 0, dir.Z)
							if horiz.Magnitude > 0.5 then
								local wallDir = avoidWalls(hrp.Position, horiz.Unit, math.min(math.max(dist, 10), 30))
								-- если стена прямо по курсу, wallDir будет повернут; для шрайнов
								-- не режем Y-компоненту сильно, чтобы не задирать
								moveDir = Vector3.new(wallDir.X, dir.Unit.Y, wallDir.Z).Unit
							end
						end)
					end
					local step = math.min(dist, speed * dt)
					local newPos = hrp.Position + moveDir * step
					-- Последний гард: если прямо по шагу упираемся в крупную стену,
					-- чуть сдвинуть таргет вбок вместо упора лбом (как в основном фарме)
					pcall(function()
						local ok, hit = pcall(farmRaycast, hrp.Position, moveDir, math.min(dist, 12))
						if ok and hit and hit.Instance and hit.Instance:IsA("BasePart") then
							if hit.Instance.Size.Magnitude > 30 and math.abs(hit.Normal.Y) < 0.5 then
								newPos = hrp.Position + moveDir * math.max(step * 0.6, 1)
							end
						end
					end)
					hrp.CFrame = CFrame.new(newPos)
					pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
				end
			end
		end
	end
	raidLoopRunning = false
end


tab:CreateToggle({
	name = "Auto Farm",
	value = false,
	callback = function(Value)
		autoFarmOn = Value
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = getHumanoid()
		if Value then
			if hum then
				disableAntiCheatWatcher()
				hum.HipHeight = origHeight or 2.1191835403442383
			end
			setAnchorToCurrent()
			task.spawn(autoFarmLoop)
		elseif hrp then
			setV(hrp, 0, getVY(hrp), 0)
		end
	end,
})

tab:CreateSlider({
	name = "Orbit Radius",
	range = {10, 120},
	increment = 5,
	value = orbitRadius,
	callback = function(Value)
		orbitRadius = Value
	end,
})

tab:CreateSlider({
	name = "Orbit Speed",
	range = {3, 60},
	increment = 1,
	value = orbitSpeed,
	callback = function(Value)
		orbitSpeed = Value
	end,
})

tab:CreateSlider({
	name = "Orbit Height",
	range = {-50, 120},
	increment = 5,
	value = orbitHeight,
	callback = function(Value)
		orbitHeight = Value
	end,
})

-- ===================== MAGNET =====================
-- Forces every active orb (xp/collectables) to home onto the player regardless of
-- distance, via the game's own CollectableService.Collected("collectAll").
local magnetOn = getFlag("MagnetOn")
local magnetRunning = false
local CollectableClient = nil
local function getCollectableClient()
	if not CollectableClient then
		CollectableClient = require(game.ReplicatedStorage.Shared.Services.CollectableService.CollectableServiceClient)
	end
	return CollectableClient
end

local function magnetLoop()
	magnetRunning = true
	while magnetOn do
		pcall(function() getCollectableClient():Collected("collectAll") end)
		task.wait(0.5)
	end
	magnetRunning = false
end

tab:CreateToggle({
	name = "Auto Collect Exp",
	value = false,
	callback = function(Value)
		magnetOn = Value
		if Value and not magnetRunning then
			task.spawn(magnetLoop)
		end
	end,
})

tab:CreateSection({ name = " " })

tab:CreateToggle({
	name = "Auto Portal",
	value = false,
	callback = function(Value)
		autoPortalOn = Value
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = getHumanoid()
		if Value then
			if hum then
				disableAntiCheatWatcher()
				hum.HipHeight = origHeight or 2.1191835403442383
			end
			task.spawn(portalLoop)
		elseif hrp then
			setV(hrp, 0, getVY(hrp), 0)
		end
	end,
})

tab:CreateSlider({
	name = "Target Multiplier",
	range = {1, 50},
	increment = 0.5,
	value = targetMultiplier,
	callback = function(Value)
		targetMultiplier = Value
	end,
})

-- ===================== RAID TAB UI =====================
raid:CreateSection({ name = "Raid Farm" })

raid:CreateToggle({
	name = "Auto Raid Farm",
	value = false,
	callback = function(Value)
		autoRaidOn = Value; setFlag("AutoRaidOn", Value)
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = getHumanoid()
		if Value then
			if hum then
				disableAntiCheatWatcher()
				hum.HipHeight = origHeight or 2.1191835403442383
			end
			setRaidAnchorToCurrent()
			task.spawn(raidFarmLoop)
		elseif hrp then
			pcall(function() hrp.Anchored = false end)
			setV(hrp, 0, getVY(hrp), 0)
			pcall(function() setNoclip(raidCircleTombOn or getFlag("NoclipOn")) end)
			local hum2 = getHumanoid()
			if hum2 then
				pcall(function() hum2.HipHeight = origHeight or 2.1191835403442383 end)
				pcall(function() hum2.WalkSpeed = 16 end)
				pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Running) end)
			end
			pcall(function()
				hrp.Anchored = false
				hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, 5, hrp.Position.Z))
				task.wait(0.05)
				hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, 5, hrp.Position.Z))
				hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
			end)
			raidSpot = nil
		end
	end,
})

raid:CreateToggle({
	name = "Circle Tombs",
	value = false,
	callback = function(Value)
		raidCircleTombOn = Value
		if Value then raidCircleIdx = 1 end
	end,
})

raid:CreateToggle({
	name = "Auto Shrines (Totems)",
	value = true,
	callback = function(Value)
		autoShrineOn = Value; setFlag("AutoShrineOn", Value)
	end,
})

raid:CreateSlider({
	name = "Raid Orbit Radius",
	range = {10, 120},
	increment = 5,
	value = raidOrbitRadius,
	callback = function(Value)
		local n = tonumber(Value)
		if n then
			raidOrbitRadius = math.clamp(n, 10, 120)
			pcall(function() RS:SetAttribute("LH_RaidOrbitRadius", raidOrbitRadius) end)
			raidSpot = nil -- FIX: reset shrine dwell so orbit rebuilds with new radius
			print("[LiquidHub] Raid Orbit Radius = " .. tostring(raidOrbitRadius) .. " (only when no active shrines / Circle Tombs / lava)")
		end
	end,
})

raid:CreateSlider({
	name = "Raid Orbit Speed",
	range = {3, 60},
	increment = 1,
	value = raidOrbitSpeed,
	callback = function(Value)
		local n = tonumber(Value)
		if n then
			raidOrbitSpeed = math.clamp(n, 3, 60)
			pcall(function() RS:SetAttribute("LH_RaidOrbitSpeed", raidOrbitSpeed) end)
			print("[LiquidHub] Raid Orbit Speed = " .. tostring(raidOrbitSpeed))
		end
	end,
})

raid:CreateSlider({
	name = "Raid Orbit Height",
	range = {-50, 120},
	increment = 5,
	value = raidOrbitHeight,
	callback = function(Value)
		local n = tonumber(Value)
		if n then
			raidOrbitHeight = math.clamp(n, -50, 120)
			pcall(function() RS:SetAttribute("LH_RaidOrbitHeight", raidOrbitHeight) end)
			raidSpot = nil
			print("[LiquidHub] Raid Orbit Height = " .. tostring(raidOrbitHeight))
		end
	end,
})

-- DEBUG: shows why orbit not active (shrines/lava/dodge/center)
local raidDebugStat = raid:CreateStat({ name = "Raid State", value = "init..." })
task.spawn(function()
	while true do
		task.wait(0.7)
		pcall(function()
			if not getFlag("AutoRaidOn") then raidDebugStat:Set("OFF"); return end
			local lava = false; pcall(function() lava = isLavaPhase() end)
			if lava then raidDebugStat:Set("LAVA -> rock (radius ignored)"); return end
			local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local bossPos = nil; pcall(function() bossPos = getRaidBossInfo() end)
			local dodge = nil; if hrp and not lava then pcall(function() dodge = getRaidDodgePos(hrp.Position, bossPos) end) end
			if dodge then raidDebugStat:Set("DODGE (attack) -> radius ignored"); return end
			if raidCircleTombOn then
				local enemies = workspace:FindFirstChild("Enemies")
				local cnt=0; if enemies then for _,e in ipairs(enemies:GetChildren()) do if e.Name:lower():find("tomb") then local hum=e:FindFirstChildOfClass("Humanoid") if not hum or hum.Health>0 then cnt=cnt+1 end end end end
				if cnt>0 then raidDebugStat:Set("CIRCLE TOMBS ("..cnt..") -> radius ignored"); return end
			end
			if getFlag("AutoShrineOn") then
				local shrines = getShrines(); local need=0; for _,s in ipairs(shrines) do if s.progress < 0.99 then need=need+1 end end
				if need>0 then raidDebugStat:Set("SHRINES "..need.." -> orbit paused (disable Auto Shrines for pure orbit) R="..tostring(raidOrbitRadius)); return end
			end
			local center = nil; if bossPos then pcall(function() center = getBossCenterTarget(bossPos) end) end
			if center then raidDebugStat:Set("CENTER -> fly to center (R="..tostring(raidOrbitRadius)..")"); return end
			if bossPos then raidDebugStat:Set("ORBIT BOSS R="..tostring(raidOrbitRadius).." H="..tostring(raidOrbitHeight).." S="..tostring(raidOrbitSpeed)); return end
			if raidAnchor then raidDebugStat:Set("ORBIT ANCHOR R="..tostring(raidOrbitRadius)); return end
			raidDebugStat:Set("no target")
		end)
	end
end)

-- Shrine Dodge настройки оставлены (raidHoverY=12, raidShrineSpeed=60, raidDangerPad=9, raidBossPad=14), но UI убран

local clickAt -- forward declaration: the real definition lives in the Auto Pick
-- do-block below (chunk-register slimming); needed here by clickDeathContinue.
-- ===================== AUTO REPLAY =====================
-- After a run ends -- by WIN (VictoryFrame splash, then RoundEnd with Again) or by
-- DEATH (DeathFrame with Continue/Spectate) -- we restart in the arena. We NEVER
-- click the lobby buttons (those navigate to the lobby); instead we call
-- GameServiceClient:PlayAgain() directly, which fires the "PlayAgain" networker.
-- On death we first click DeathFrame.Continue, which (per DeathScreen) reveals the
-- RoundEnd screen or the victory splash -- it does NOT go to the lobby -- and then
-- PlayAgain fires as normal. We wait REPLAY_DELAY seconds after the screen first
-- appears so you can see the result, then restart. Fires once per run and re-arms
-- after the screen is gone.
local autoReplayOn = getFlag("AutoReplayOn")
local autoReplayRunning = false

local GameServiceClient = nil
local function getGameClient()
	if not GameServiceClient then
		GameServiceClient = require(game.ReplicatedStorage.Shared.Services.GameService.GameServiceClient)
	end
	return GameServiceClient
end

local function getFrames()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	return pg and pg:FindFirstChild("Frames")
end

local function isVictoryUp()
	local frames = getFrames()
	if not frames then return false end
	local vf = frames:FindFirstChild("VictoryFrame")
	if vf and vf.Visible then return true end
	local re = frames:FindFirstChild("RoundEnd")
	if re and re.Visible then
		local again = re:FindFirstChild("Buttons") and re.Buttons:FindFirstChild("Again")
		if again and again.Visible then return true end
	end
	return false
end

local function isDeathUp()
	local frames = getFrames()
	if not frames then return false end
	local df = frames:FindFirstChild("DeathFrame")
	return df and df.Visible
end

local function clickDeathContinue()
	local frames = getFrames()
	local df = frames and frames:FindFirstChild("DeathFrame")
	local c = df and df:FindFirstChild("Buttons") and df.Buttons:FindFirstChild("Continue")
	if not (c and c.Visible) then return end
	-- Try VIM click
	pcall(function() clickAt(c) end)
	task.wait(0.15)
	-- Try connections
	pcall(function()
		for _,conn in ipairs(getconnections(c.MouseButton1Click)) do conn:Fire() end
		for _,conn in ipairs(getconnections(c.Activated)) do conn:Fire() end
	end)
	pcall(function()
		if c:IsA("GuiButton") then
			pcall(function() firesignal(c.MouseButton1Click) end)
			pcall(function() firesignal(c.Activated) end)
		end
	end)
	pcall(function() if c:IsA("GuiButton") then c:Activate() end end)
	-- Also try the TextLabel inside
	pcall(function()
		local txt = c:FindFirstChild("Text")
		if txt and txt:IsA("GuiObject") then
			local btn2 = txt.Parent
			if btn2 and btn2:IsA("GuiButton") then btn2:Activate() end
		end
	end)
end

local REPLAY_DELAY = 10

local function replayLoop()
	if autoReplayRunning then return end
	autoReplayRunning = true
	local detectedAt = 0
	while isCurrentGen() do
		local shouldReplay = getFlag("AutoReplayOn")
		pcall(function()
			if isVictoryUp() then
				if detectedAt == 0 then detectedAt = tick() end
				if tick() - detectedAt >= REPLAY_DELAY and shouldReplay then
					pcall(function() getGameClient():PlayAgain() end)
					detectedAt = tick()
				end
			elseif isDeathUp() then
				if detectedAt == 0 then detectedAt = tick() end
				if tick() - detectedAt >= REPLAY_DELAY then
					clickDeathContinue()
					detectedAt = tick()
				end
			else
				detectedAt = 0
			end
		end)
		task.wait(1)
		if not isCurrentGen() then break end
	end
	autoReplayRunning = false
end

tab:CreateSection({ name = " " })

-- ===================== AUTO PICK CARDS (SMART) =====================
-- On level-up it ranks the 3 offered cards by what actually wins the run.
-- A fixed avoid-list (cards the player wants picked LAST, in order: first =
-- worst / only if nothing else, last = least bad of the bad) is combined with
-- the game's own rarity/stat data as a tie-breaker. Anything NOT on the list
-- is always preferred. If every offered card is on the avoid-list and rerolls
-- remain, it rerolls (capped) to fish for a wanted card.
do -- Auto Pick scope: everything below is used only inside this block, so its
-- ~28 locals don't stay alive to the end of the chunk (200-register limit).
-- The loop starter is published to Resume for the tail auto-resume below.
local autoPickOn = getFlag("AutoPickOn")

-- Cards to pick LAST. Order matters: index 1 = worst (pick only if no choice),
-- last index = least bad among the unwanted. Everything else is preferred.
local avoidOrder = {
	"Movement Speed", "Piercing", "Regen", "Extra Jump", "Ricochet",
	"Size", "Thorns", "Freeze", "Blaze", "Health", "Perilous Fervor",
	"Giant's Strength", "Demon Slayer", "Wind Blessing",
}
local avoidPos = {}
for i, nm in ipairs(avoidOrder) do avoidPos[nm] = i end
local AVOID_N = #avoidOrder

-- Cards to pick FIRST (index 1 = highest priority). Evaluated before neutral
-- and before the avoid-list.
local priorityOrder = {
	"Luck", "Multishot", "Power Trio", "Bolt", "Damage",
	"Attack Speed", "Projectile Count", "Lifesteal",
}
local priorityPos = {}
for i, nm in ipairs(priorityOrder) do priorityPos[nm] = i end
local PRIORITY_N = #priorityOrder

-- Weapon pick priority (1 = most wanted). Fed into the card picker so that when
-- a weapon card is offered it is taken over neutral/avoid cards, ordered by this
-- list, but still below the core stat priority (Luck, Multishot, ...). Weapons
-- NOT in this list fall through to neutral. Names must match the card ItemTitle.
local WEAPON_PRIORITY = {
	["Void Scythe"] = 1,
	["Trident"] = 2,
	["Firestaff"] = 3,
	["Bananarang"] = 4,
	["Revolver"] = 5,
	["Ninja Star"] = 6,
	["Shotgun"] = 7,
	["Daggers"] = 8,
	["Bow"] = 9,
	["Ban Hammer"] = 10,
}
local WEAPON_PRIORITY_N = #WEAPON_PRIORITY

-- Per-world Luck caps (%). Luck is the top priority only until the run's luck
-- stat reaches the cap for the CURRENT world; once capped it is forced into the
-- never-pick tier. Unknown worlds fall back to DEFAULT_LUCK_CAP.
local WORLD_LUCK_CAP = {
	["Grasslands"] = 150,
	["Desert"] = 200,
	["Swamp"] = 300,
	["Jungle"] = 450,
	["Frost Forest"] = 600,
	["Starting grounds"] = 150,
}
local DEFAULT_LUCK_CAP = 600

local function getCurrentWorld()
	local map = workspace:FindFirstChild("Map")
	local nm = map and map.Name
	if type(nm) ~= "string" or nm == "" then return nil end
	local low = string.lower(nm)
	for w in pairs(WORLD_LUCK_CAP) do
		if low:find(string.lower(w)) then return w end
	end
	return nil
end

local function getLuckCap()
	local w = getCurrentWorld()
	return WORLD_LUCK_CAP[w] or DEFAULT_LUCK_CAP
end

-- Read the LUCK value the HUD actually shows (e.g. "1340%"). The raw stat
-- stats.upgrades.luck stores the number of luck levels taken, which is NOT the
-- displayed percent -- comparing that to the per-world cap was why Luck kept
-- getting picked even past 600%. Parse the on-screen percent instead.
local function getLuckPercent()
	local ok, txt = pcall(function()
		local n = Players.LocalPlayer:FindFirstChild("PlayerGui")
		n = n and n:FindFirstChild("Frames")
		n = n and n:FindFirstChild("PauseFrame")
		n = n and n:FindFirstChild("Left Frame")
		n = n and n:FindFirstChild("StatsList")
		n = n and n:FindFirstChild("luck")
		local sa = n and n:FindFirstChild("StatAmount")
		return sa and sa.Text
	end)
	if ok and type(txt) == "string" then
		local num = txt:match("([%d%.]+)%s*%%")
		if num then return tonumber(num) or 0 end
	end
	-- Fallback: raw stored level count (different units; only if HUD is missing).
	local ok2, DS = pcall(function() return require(game.ReplicatedStorage.Packages.DataService) end)
	if ok2 and DS and DS.client then
		local s, v = pcall(function() return DS.client:get({ "stats", "upgrades", "luck" }) end)
		if s and type(v) == "number" then return v end
	end
	return 0
end

local VIM = game:GetService("VirtualInputManager")

-- Rarity tiers mapped to a sortable rank (higher = better).
local RARITY_RANK = { Basic = 1, Common = 2, Uncommon = 3, Rare = 4, Epic = 5, Legendary = 6, Mythic = 7 }
local function rarityRankOf(r)
	r = type(r) == "string" and r or ""
	return RARITY_RANK[r] or 2
end

-- name -> { rank, score } built from the game's own data modules so the picker
-- knows what each card actually is worth, not just its on-screen text.
local cardDB = {}
do
	local RS = game:GetService("ReplicatedStorage")
	local function statBonus(v)
		if type(v) ~= "table" then return 0 end
		local s = 0
		if type(v.statChange) == "number" then s = s + math.abs(v.statChange) end
		if type(v.stats) == "table" then
			for _, val in pairs(v.stats) do
				if type(val) == "number" then s = s + math.abs(val) end
			end
		end
		return s
	end
	local function add(mod)
		local ok, m = pcall(function() return require(RS.Shared.Modules.Data[mod]) end)
		if not (ok and m) then return end
		for k, v in pairs(m) do
			if type(v) == "table" then
				local nm = v.name or v.displayName or k
				if type(nm) == "string" and nm ~= "" then
					local rank = rarityRankOf(v.Rarity or v.rarity)
					local score = rank * 1000 + statBonus(v)
					if not cardDB[nm] or score > cardDB[nm].score then
						cardDB[nm] = { rank = rank, score = score }
					end
				end
			end
		end
	end
	add("UpgradeData"); add("WeaponData"); add("ArmorData"); add("GearData")
end

local function getUpgradeFrame()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local f = pg and pg:FindFirstChild("Frames")
	return f and f:FindFirstChild("Upgrades")
end

clickAt = function(frame) -- assigns the forward-declared chunk local above
	local ok, ap = pcall(function() return frame.AbsolutePosition end)
	local ok2, as = pcall(function() return frame.AbsoluteSize end)
	if not (ok and ok2) then return end
	local x = ap.X + as.X / 2
	local y = ap.Y + as.Y / 2
	VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
	task.wait(0.03)
	VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- This game listens to real mouse input, not GuiObject events, so click the
-- card with a synthetic mouse event at its center. Activate() is a harmless
-- backup in case a standard handler is also wired.
local function activateGui(obj)
	if not obj or not obj.Parent then return end
	pcall(function() if obj:IsA("GuiButton") then obj:Activate() end end)
	clickAt(obj)
end

local function getOfferedCards()
	local up = getUpgradeFrame()
	if not up or not up.Visible then return nil end
	local holder = up:FindFirstChild("Holder")
	if not holder then return nil end
	local cards = {}
	for i = 1, 12 do
		local sel = holder:FindFirstChild("Selection" .. i)
		if sel and sel.Visible then
			local nameLbl = sel:FindFirstChild("ItemTitle")
			local rarLbl = sel:FindFirstChild("TitleLabel")
			local name = nameLbl and nameLbl.Text or ""
			local rarity = rarLbl and rarLbl.Text or ""
			if name ~= "" then
				cards[#cards + 1] = { frame = sel, name = name, rarity = rarity }
			end
		end
	end
	return #cards > 0 and cards or nil
end

-- Resolve a card to (tier, subrank):
--   tier 3 = priority list  (subrank: 1=highest priority .. PRIORITY_N)
--   tier 2 = neutral        (subrank 0, tie-broken by dbScore)
--   tier 1 = avoid list     (subrank: 1=worst .. AVOID_N=least bad)
-- Luck is forced to tier 1 once the run's luck stat reaches the world's cap.
local function cardTier(card)
	local nm = card.name
	if nm == "Luck" and getLuckPercent() >= getLuckCap() then
		return 1, 0
	end
	local ppos = nm and priorityPos[nm]
	if ppos then
		return 3, (PRIORITY_N - ppos + 1)
	end
	local apos = nm and avoidPos[nm]
	if apos then
		return 1, apos
	end
	-- Weapon priority: sit just below the core stat priority (tier 3) but above
	-- neutral (tier 2) and avoid (tier 1). Among weapons, the user's order wins.
	local wp = nm and WEAPON_PRIORITY[nm]
	if wp then
		return 2.5, (WEAPON_PRIORITY_N - wp + 1)
	end
	return 2, 0
end

-- value = tier*1e9 + subrank*1e5 + dbScore (dbScore = rarity/stat tie-breaker).
-- MAX value wins: any priority card beats neutral, any neutral beats avoid, and
-- among the avoid-list the least-bad (latest in list) one is preferred.
local function cardValue(card)
	local db = card.name and cardDB[card.name]
	local dbScore = db and db.score or 1
	local tier, sub = cardTier(card)
	return tier * 1000000000 + sub * 100000 + dbScore
end

-- Locate the reroll button inside the Upgrades frame. The game renders it as
-- RerollFrame.RerollButton; fall back to any button whose name mentions reroll.
local function getRerollInfo()
	local up = getUpgradeFrame()
	if not up then return nil, 0 end
	local btn = nil
	local rf = up:FindFirstChild("RerollFrame")
	if rf then btn = rf:FindFirstChild("RerollButton") end
	if not btn then
		for _, d in ipairs(up:GetDescendants()) do
			if d:IsA("GuiButton") and d.Name:lower():find("reroll") then btn = d; break end
		end
	end
	local count = 0
	for _, d in ipairs(up:GetDescendants()) do
		if d:IsA("TextLabel") then
			local m = d.Text:match("(%d+)%s*/%s*%d+")
			if m then count = tonumber(m) or 0 end
		end
	end
	return btn, count
end

local pickRunning = false

-- Skip card spin animation (~2.5s). Works even without FastUpgrade owned
-- by faking DataService.client:get({"stats","skillTree","FastUpgrade"}) -> true
-- and then sending the click that Upgrade:2215 listens for.
local function trySkipCardsAnimation()
	pcall(function()
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local frames = pg and pg:FindFirstChild("Frames")
		local up = frames and frames:FindFirstChild("Upgrades")
		if not (up and up.Visible) then return end
		local spin = up:FindFirstChild("SpinHolder")
		if not (spin and spin.Visible) then return end
		if not getgenv()._fastHooked then
			getgenv()._fastHooked = true
			local okDS, DS = pcall(function() return require(game.ReplicatedStorage.Packages.DataService) end)
			if okDS and DS and DS.client and DS.client.get then
				local orig = DS.client.get
				DS.client.get = function(self, path)
					if type(path)=="table" and path[1]=="stats" and path[2]=="skillTree" and path[3]=="FastUpgrade" then
						return true
					end
					return orig(self, path)
				end
			end
		end
		local VIM = game:GetService("VirtualInputManager")
		local cam = workspace.CurrentCamera
		local sz = cam and cam.ViewportSize or Vector2.new(960,540)
		local x, y = sz.X*0.5, sz.Y*0.5
		VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(0.05)
		VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
end

local function autoPickLoop()
	if pickRunning then return end
	pickRunning = true
	local lastSig = nil
	local rerollAttempts = 0
	local MAX_REROLLS = 5
	while autoPickOn do
		local ok, err = pcall(function()
			local cards = getOfferedCards()
			if not cards then
				trySkipCardsAnimation()
				lastSig = nil
				rerollAttempts = 0
				return
			end
			local sig = {}
			for _, c in ipairs(cards) do
				sig[#sig + 1] = (c.name or "?")
			end
			sig = table.concat(sig, "|")
			if sig == lastSig then return end
			lastSig = sig
			rerollAttempts = 0
			local names = {}
			for _, c in ipairs(cards) do names[#names + 1] = c.name end
			print("AutoPick: offered -> " .. table.concat(names, ", "))

			-- Pick the highest-value offered card (non-avoided preferred, then
			-- least-bad of the avoid-list, then rarity/stat as tie-breaker).
			local chosen, bestVal = nil, -1
			for _, card in ipairs(cards) do
				local s = cardValue(card)
				if s > bestVal then bestVal = s; chosen = card end
			end

			-- Smart reroll: if even the best on offer is unwanted (avoid-list or
			-- a Luck card past its cap) and rerolls remain, fish for a wanted one.
			if chosen then
				local pos = chosen.name and avoidPos[chosen.name]
				local luckCapped = chosen.name == "Luck" and getLuckPercent() >= getLuckCap()
				if (pos or luckCapped) and rerollAttempts < MAX_REROLLS then
					local rb, rc = getRerollInfo()
					if rb and rc > 0 then
						activateGui(rb)
						rerollAttempts = rerollAttempts + 1
						lastSig = nil
						return
					end
				end
			end

			if chosen and chosen.frame and chosen.frame.Parent then
				print("AutoPick: picking -> " .. tostring(chosen.name))
				task.wait(0.08)
				activateGui(chosen.frame)
				lastSig = nil
				task.wait(0.5)
			end
		end)
		if not ok then
			warn("AutoPick error:", err)
		end
		task.wait(0.2)
	end
	pickRunning = false
end

tab:CreateToggle({
	name = "Auto Pick Cards (Smart)",
	value = false,
	callback = function(Value)
		autoPickOn = Value
		if Value and not pickRunning then task.spawn(autoPickLoop) end
	end,
})

Resume.autoPickLoop = autoPickLoop
end -- end Auto Pick do (chunk-register slimming, see Resume)

-- ===================== AUTO OPEN CHESTS =====================
local function getChestRemote()
	local idx = game.ReplicatedStorage.Packages._Index
	for _, nw in ipairs(idx:GetChildren()) do
		if nw.Name:match("networker") then
			local net = nw:FindFirstChild("networker")
			local rem = net and net:FindFirstChild("_remotes")
			local cs = rem and rem:FindFirstChild("ChestService")
			local re = cs and cs:FindFirstChild("RemoteEvent")
			if re then return re end
		end
	end
	return nil
end

local autoChestsOn = getFlag("AutoChestsOn")
local DataServiceChest = require(game.ReplicatedStorage.Packages.DataService)

local function openSingleChest(remote, name)
	if name == "VoidChest" then
		remote:FireServer("OpenChest", name, "void")
	else
		remote:FireServer("OpenChest", name)
	end
end

local function openChestsLoop()
	if Resume.chestsRunning then return end
	Resume.chestsRunning = true
	while autoChestsOn do
		local remote = getChestRemote()
		if remote then
			local ok, inv = pcall(function() return DataServiceChest.client:get({"inventory", "chests"}) end)
			if ok and inv then
				for name, count in pairs(inv) do
					if type(count) == "number" and count > 0 then
						local bulkOk = false
						if count > 1 then
							if name == "VoidChest" then
								bulkOk = pcall(function() remote:FireServer("OpenMultipleChests", name, count, "void") end)
							else
								bulkOk = pcall(function() remote:FireServer("OpenMultipleChests", name, count) end)
							end
							if bulkOk then task.wait(0.3) end
						end
						if not bulkOk then
							for _ = 1, count do
								pcall(openSingleChest, remote, name)
								task.wait(0.15)
							end
						end
					end
				end
			end
		end
		task.wait(2)
	end
	Resume.chestsRunning = false
end

lobby:CreateToggle({
	name = "Auto Open Chests",
	value = false,
	callback = function(Value)
		autoChestsOn = Value
		if Value then task.spawn(openChestsLoop) end
	end,
})

lobby:CreateSection({ name = " " })

-- ===================== AUTO UPGRADE (WindUI via adapter) =====================
local allItems = {}
local nameToItem = {}
do
	local WD = require(game.ReplicatedStorage.Shared.Modules.Data.WeaponData)
	local AD = require(game.ReplicatedStorage.Shared.Modules.Data.ArmorData)
	local GD = require(game.ReplicatedStorage.Shared.Modules.Data.GearData)
	local function add(tbl, tp)
		for name, data in pairs(tbl) do
			local disp = (data and data.displayName) or name
			allItems[#allItems+1] = { name = name, type = tp, display = disp, rarity = (data and data.rarity) or "?" }
			nameToItem[name] = allItems[#allItems]
		end
	end
	add(WD, "weapon"); add(AD, "armor"); add(GD, "gear")
end

local function getUpgradeRemote()
	local idx = game.ReplicatedStorage.Packages._Index
	for _, nw in ipairs(idx:GetChildren()) do
		if nw.Name:match("networker") then
			local net = nw:FindFirstChild("networker")
			local rem = net and net:FindFirstChild("_remotes")
			local svc = rem and rem:FindFirstChild("InventoryService")
			local re = svc and svc:FindFirstChild("RemoteEvent")
			if re then return re end
		end
	end
	return nil
end
local upgradeRemote = getUpgradeRemote()
local DataServiceUpg = require(game.ReplicatedStorage.Packages.DataService)

local selectedUpgrade = {}
local autoUpgradeOn = getFlag("AutoUpgradeOn")

local dropdownOptions = {}
for _, it in ipairs(allItems) do
	dropdownOptions[#dropdownOptions+1] = it.name
end

local UpgradeDropdown = lobby:CreateDropdown({
	name = "Auto-Upgrade Items",
	multiSelect = true,
	options = dropdownOptions,
	value = {},
	placeholder = "Select items to auto-upgrade",
	callback = function(selected)
		for k in pairs(selectedUpgrade) do selectedUpgrade[k] = nil end
		for _, nm in ipairs(selected) do
			if nameToItem[nm] then selectedUpgrade[nm] = true end
		end
	end,
})

for _, nm in ipairs(UpgradeDropdown.value) do
	if nameToItem[nm] then selectedUpgrade[nm] = true end
end

lobby:CreateToggle({
	name = "Auto Upgrade",
	value = false,
	callback = function(Value)
		autoUpgradeOn = Value
	end,
})

lobby:CreateSection({ name = " " })

local autoTreeOn = getFlag("AutoTreeOn")
local autoTreeRunning = false
local SkillTreeData = nil
local TreeNet = nil

local function autoTreeLoop()
	autoTreeRunning = true
	if not SkillTreeData then
		SkillTreeData = require(game.ReplicatedStorage.Shared.Modules.Data.SkillTreeData)
	end
	if not TreeNet then
		TreeNet = require(game.ReplicatedStorage.Packages.Networker).client.new("SkillTree", {})
	end
	while autoTreeOn do
		local ok, err = pcall(function()
			local keys = DataServiceUpg.client:get({ "stats", "keys" }) or 0
			local remaining = keys
			local owned = {}
			for id, node in pairs(SkillTreeData) do
				if DataServiceUpg.client:get({ "stats", "skillTree", id }) then
					owned[id] = true
				end
			end
			for id, node in pairs(SkillTreeData) do
				if not autoTreeOn or remaining <= 0 then break end
				if node.opensPage or node.gamepass or node.enabled == false then continue end
				if not node.cost or node.cost.currency ~= "keys" then continue end
				if owned[id] then continue end
				if node.dependency and not owned[node.dependency] then continue end
				if node.cost.amount <= remaining then
					TreeNet:fire("purchaseSkill", id)
					owned[id] = true
					remaining = remaining - node.cost.amount
					task.wait(0.2)
				end
			end
		end)
		if not ok then warn("AutoTree error:", err) end
		task.wait(1.5)
	end
	autoTreeRunning = false
end

lobby:CreateToggle({
	name = "Auto Upgrade Tree",
	value = false,
	callback = function(Value)
		autoTreeOn = Value
		if Value and not autoTreeRunning then
			task.spawn(autoTreeLoop)
		end
	end,
})

do -- Auto Grade scope (keeps locals from leaking and blowing 200-register limit)
-- ===================== AUTO GRADE (Stat Reroll) =====================
-- Costs 1 Grade Crystal per attempt. Keeps only if rolled grade >= target.
if RS:GetAttribute("LH_AutoGradeOn")==nil then RS:SetAttribute("LH_AutoGradeOn", false) end
local gradeOrder = {"F","D","C","B","A","S","SS","SSS","Omega"}
local gradeRank = {}
for i, g in ipairs(gradeOrder) do gradeRank[g]=i end
gradeRank["\206\169"]=gradeRank["Omega"]
gradeRank["Ω"]=gradeRank["Omega"]

local function getGradeNet()
	local ok, cli = pcall(function() return require(game.ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceClient) end)
	if ok and cli and cli._networker then return cli._networker end
	local Networker = require(game.ReplicatedStorage.Packages.Networker)
	return Networker.client.new("InventoryService", {})
end

local gradeItems = {}
for _, it in ipairs(allItems) do
	if it.type=="armor" or it.type=="gear" then gradeItems[#gradeItems+1]=it end
end
local gradeDropdownOptions = {}
for _, it in ipairs(gradeItems) do gradeDropdownOptions[#gradeDropdownOptions+1]=it.name end

local selectedGrade = {}
local targetGrade = "S"
local autoGradeOn = getFlag("AutoGradeOn")
local autoGradeRunning = false

local function getItemSaveForGrade(name)
	local info = nameToItem[name]
	if not info then return nil end
	local path = {"inventory", info.type.."s", name}
	local ok, val = pcall(function() return DataServiceUpg.client:get(path) end)
	if ok then return val end
	return nil
end
local function currentGradeOf(name)
	local save = getItemSaveForGrade(name)
	if save and save.grade then return save.grade end
	return "F"
end
local function isGradeAtLeast(cur, target)
	local cr = gradeRank[cur] or 0
	local tr = gradeRank[target] or 9
	if cur=="\206\169" or cur=="Ω" then cr=gradeRank["Omega"] end
	if target=="\206\169" or target=="Ω" then tr=gradeRank["Omega"] end
	return cr >= tr
end

local function autoGradeLoop()
	if autoGradeRunning then return end
	autoGradeRunning=true
	while autoGradeOn and isCurrentGen() do
		if not getFlag("AutoGradeOn") then break end
		local crystals = DataServiceUpg.client:get({"stats","gradeCrystals"}) or 0
		if crystals < 1 then task.wait(2); continue end
		local didWork=false
		for _, it in ipairs(gradeItems) do
			if not autoGradeOn or not isCurrentGen() or not getFlag("AutoGradeOn") then break end
			if not selectedGrade[it.name] then continue end
			local cur = currentGradeOf(it.name)
			if isGradeAtLeast(cur, targetGrade) then continue end
			crystals = DataServiceUpg.client:get({"stats","gradeCrystals"}) or 0
			if crystals < 1 then break end
			local net = getGradeNet()
			local ok, res = pcall(function() return net:fetch("startGrading", it.name) end)
			if not ok or type(res)~="table" or type(res.grade)~="string" then
				task.wait(0.5)
				continue
			end
			didWork=true
			local rolled = res.grade
			local keep = isGradeAtLeast(rolled, targetGrade)
			task.wait(0.2)
			pcall(function() net:fire("finishGrading", it.name, res.grade, keep) end)
			task.wait(0.6)
			if keep then task.wait(0.3) end
			break
		end
		if not didWork then task.wait(1.5)
		else task.wait(0.5) end
	end
	autoGradeRunning=false
end

lobby:CreateSection({ name = "Auto Grade (Reroll)" })

local GradeItemsDropdown = lobby:CreateDropdown({
	name = "Grade Items (Armor/Gear)",
	multiSelect = true,
	options = gradeDropdownOptions,
	value = {},
	placeholder = "Select items to auto-grade",
	callback = function(selected)
		for k in pairs(selectedGrade) do selectedGrade[k]=nil end
		for _, nm in ipairs(selected) do if nameToItem[nm] then selectedGrade[nm]=true end end
	end,
})

lobby:CreateDropdown({
	name = "Target Grade",
	options = gradeOrder,
	value = targetGrade,
	placeholder = "Target",
	callback = function(Value)
		if type(Value)=="table" then
			targetGrade = Value[1] or targetGrade
		else
			targetGrade = Value
		end
		if targetGrade=="\206\169" or targetGrade=="Ω" then targetGrade="Omega" end
	end,
})

lobby:CreateToggle({
	name = "Auto Grade (Auto Reroll)",
	value = false,
	callback = function(Value)
		autoGradeOn = Value; setFlag("AutoGradeOn", Value)
		if Value and not autoGradeRunning then task.spawn(autoGradeLoop) end
	end,
})

local GradeCrystalsStat = lobby:CreateStat({
	name = "Grade Crystals",
	value = DataServiceUpg.client:get({"stats","gradeCrystals"}) or 0,
})
task.spawn(function()
	while true do
		task.wait(1.5)
		local v = DataServiceUpg.client:get({"stats","gradeCrystals"}) or 0
		pcall(function() GradeCrystalsStat:Set(v) end)
	end
end)

-- resume after live-reload (inside do, sees locals)
task.defer(function()
	task.wait(1.2)
	if getFlag("AutoGradeOn") and not autoGradeRunning then task.spawn(autoGradeLoop) end
end)
end -- end Auto Grade do

lobby:CreateSection({ name = " " })

local KeysStat = lobby:CreateStat({
	name = "Keys",
	value = DataServiceUpg.client:get({"stats", "keys"}) or 0,
})

task.spawn(function()
	while true do
		task.wait(2)
		local keys = DataServiceUpg.client:get({"stats", "keys"}) or 0
		KeysStat:Set(keys)
	end
end)

task.spawn(function()
	while true do
		task.wait(2)
		if not autoUpgradeOn then continue end
		if not upgradeRemote then upgradeRemote = getUpgradeRemote() end
		local keys = DataServiceUpg.client:get({"stats", "keys"}) or 0
		if keys <= 0 then continue end
		for _, it in ipairs(allItems) do
			if not selectedUpgrade[it.name] then continue end
			local inv = DataServiceUpg.client:get({"inventory", it.type .. "s", it.name})
			if not inv then continue end
			upgradeRemote:FireServer("upgradeItem", it.name, it.type)
			task.wait(0.3)
		end
	end
end)

local function onCharacterAdded()
	task.wait(1)
	disableAntiCheatWatcher()
	captureOrigHeight()
end

if Players.LocalPlayer.Character then onCharacterAdded() end
Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ===================== MISC TAB =====================
local antiAfkOn = false
local antiAfkRunning = false
local VirtualUser = game:GetService("VirtualUser")

local function antiAfkLoop()
	antiAfkRunning = true
	local conn = Players.LocalPlayer.Idled:Connect(function()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:Button2Down(Vector2.new())
			VirtualUser:Button2Up(Vector2.new())
		end)
	end)
	while antiAfkOn do
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:Button2Down(Vector2.new())
			VirtualUser:Button2Up(Vector2.new())
		end)
		task.wait(20)
	end
	if conn then conn:Disconnect() end
	antiAfkRunning = false
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
	pcall(function() setNoclip(raidCircleTombOn or tick() < tempNoclipUntil) end)
	noclipRunning = false
end
local hideNameRunning = false
local function applyHideName(on)
	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.NameDisplayDistance = on and 0 or 100
			if on then hum.DisplayName = "" else hum.DisplayName = Players.LocalPlayer.DisplayName end
		end
		local ot = char:FindFirstChild("OverheadTitle", true)
		if ot and ot:IsA("BillboardGui") then
			local nl = ot:FindFirstChild("NameLabel")
			if nl then nl.Visible = not on end
		end
	end
	local p = Players.LocalPlayer
	local pname = p.Name
	local dname = p.DisplayName
	local function hideInGui(gui)
		pcall(function()
			for _,d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					local txt = d.Text
					if txt:find(pname, 1, true) or (dname ~= "" and txt:find(dname, 1, true)) then
						d.Visible = not on
					end
				end
			end
		end)
	end
	pcall(function() hideInGui(p.PlayerGui) end)
	pcall(function() hideInGui(game.CoreGui) end)
	pcall(function()
		local pg = p.PlayerGui
		local nf = pg:FindFirstChild("Frames") and pg.Frames:FindFirstChild("Upgrades") and pg.Frames.Upgrades:FindFirstChild("NameFrame")
		if nf then nf.Visible = not on end
	end)
	pcall(function()
		local lb = p.PlayerGui:FindFirstChild("Leaderboard")
		if lb then
			local entry = lb:FindFirstChild("Leaderboard") and lb.Leaderboard:FindFirstChild("Players") and lb.Leaderboard.Players:FindFirstChild(tostring(p.UserId))
			if entry then entry.Visible = not on end
		end
	end)
end
local function hideNameLoop()
	hideNameRunning = true
	while hideNameOn and isCurrentGen() do
		pcall(function() applyHideName(true) end)
		task.wait(0.5)
	end
	hideNameRunning = false
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if hideNameOn then pcall(applyHideName, true) end
end)

misc:CreateSection({ name = " " })

misc:CreateToggle({
	name = "Anti AFK",
	value = false,
	callback = function(Value)
		antiAfkOn = Value
		if Value and not antiAfkRunning then
			task.spawn(antiAfkLoop)
		end
	end,
})

misc:CreateToggle({
	name = "Hide Name",
	value = false,
	callback = function(Value)
		hideNameOn = Value; setFlag("HideNameOn", Value)
		pcall(applyHideName, Value)
		if Value and not hideNameRunning then task.spawn(hideNameLoop) end
	end,
})

task.defer(function()
	task.wait(1)
	if getFlag("HideNameOn") and not hideNameRunning then task.spawn(hideNameLoop) end
end)

misc:CreateToggle({
	name = "Noclip",
	value = false,
	callback = function(Value)
		noclipOn = Value; setFlag("NoclipOn", Value)
		if Value then
			pcall(function() setNoclip(true) end)
			if not noclipRunning then task.spawn(noclipLoop) end
		else
			pcall(function() setNoclip(false) end)
		end
	end,
})

task.defer(function()
	task.wait(1)
	if getFlag("NoclipOn") and not noclipRunning then task.spawn(noclipLoop) end
end)

misc:CreateSection({ name = " " })

local allCodes = {
	"skillz",
	"supdoggy",
	"firstswarm",
	"nocheaters",
	"frosty",
	"H4MM3RT1M3",
	"Jungl3",
	"Update1",
	"freevoid",
}

local CodesClient = nil
local function getCodesClient()
	if not CodesClient then
		CodesClient = require(game.ReplicatedStorage.Shared.Services.CodesService.CodesServiceClient)
	end
	return CodesClient
end

local function redeemCode(code)
	code = code and code:match("^%s*(.-)%s*$")
	if not code or code == "" then return end
	local ok, res = pcall(function() return getCodesClient():redeem(code) end)
	if not ok then
		warn("Redeem failed for", code, ":", res)
	end
end

local function redeemAllCodes()
	for _, code in ipairs(allCodes) do
		redeemCode(code)
		task.wait(0.6)
	end
end

misc:CreateButton({
	name = "Redeem All Codes",
	callback = function()
		task.spawn(redeemAllCodes)
	end,
})

misc:CreateSection({ name = " " })

misc:CreateToggle({
	name = "Auto Replay",
	value = false,
	callback = function(Value)
		autoReplayOn = Value
		if Value and not autoReplayRunning then
			task.spawn(replayLoop)
		end
	end,
})

-- ===================== CREDITS =====================
credits:CreateSection({ name = "Credits" })

credits:CreateSection({ name = "Owner: enf404_" })

credits:CreateButton({
	name = "Discord Server",
	callback = function()
		pcall(function() setclipboard("https://discord.gg/PGyk3JcKht") end)
		window:Notify({ title = "Discord", content = "Invite link copied to clipboard!" })
	end,
})

-- ===================== CONFIGS =====================
-- Named setups (toggles/sliders/dropdowns) saved to files + optional autoload
-- applied a few seconds after (re)start, so the farm resumes by itself after
-- a rejoin once the script is executed (manually or via the executor's
-- auto-execute). Everything lives in one do-block: no chunk registers leak.
do
	local CF_DIR = "FinalSwarmHub/configs"
	local AUTOLOAD_FILE = "FinalSwarmHub/autoload.txt"
	local Http = game:GetService("HttpService")

	local canIO = typeof(writefile) == "function" and typeof(readfile) == "function"
		and typeof(isfile) == "function" and typeof(makefolder) == "function"

	local function ensureDir()
		if not canIO then return false end
		local ok = pcall(function()
			makefolder("FinalSwarmHub")
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

-- auto-resume after live-reload
task.defer(function()
	task.wait(1)
	if getFlag("AutoRaidOn") then task.spawn(raidFarmLoop) end
	if getFlag("AutoFarmOn") then task.spawn(autoFarmLoop) end
	if getFlag("AutoPortalOn") then task.spawn(portalLoop) end
	if getFlag("MagnetOn") then task.spawn(magnetLoop) end
	if getFlag("AutoChestsOn") then task.spawn(openChestsLoop) end
	if getFlag("AutoPickOn") and Resume.autoPickLoop then task.spawn(Resume.autoPickLoop) end
	task.spawn(replayLoop) -- always for Give Up, PlayAgain checks flag inside
end)
end) -- withPlugin end