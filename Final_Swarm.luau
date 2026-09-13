-- Final Swarm Hub | Liquid Hub (Nebula UI lib v2.3)
-- Built from the working NewUi template (UI-Template-NewUi.luau) — same adapter layer,
-- same Configs/Misc/Credits tabs. Game-specific code lives in the tabs below.
-- Folder: FinalSwarm | Flags: TPL_ | Nebula (Liquid Hub) | Executor: Delta-compatible

-- ===================== VISIBLE ERROR BOX =====================
-- Any load or runtime error is shown directly in-game instead of failing silently.
local function showErrorBox(where, err)
	pcall(function()
		local parent = nil
		pcall(function()
			if gethui then parent = gethui() end
		end)
		if not parent then
			pcall(function() parent = game:GetService("CoreGui") end)
		end
		if not parent then
			pcall(function() parent = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
		end
		if not parent then return end
		local old = parent:FindFirstChild("FS_ErrorBox")
		if old then old:Destroy() end
		local sg = Instance.new("ScreenGui")
		sg.Name = "FS_ErrorBox"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 999999
		sg.IgnoreGuiInset = true
		sg.Parent = parent
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(0, 580, 0, 340)
		bg.Position = UDim2.new(0.5, -290, 0.5, -170)
		bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		bg.BorderSizePixel = 0
		bg.Parent = sg
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = bg
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 60, 60)
		stroke.Thickness = 2
		stroke.Parent = bg
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -24, 0, 34)
		title.Position = UDim2.new(0, 12, 0, 8)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 20
		title.TextColor3 = Color3.fromRGB(255, 90, 90)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "⚠ Final Swarm Hub — ERROR (" .. tostring(where) .. ")"
		title.Parent = bg
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.new(1, -24, 1, -92)
		msg.Position = UDim2.new(0, 12, 0, 48)
		msg.BackgroundTransparency = 1
		msg.Font = Enum.Font.Code
		msg.TextSize = 14
		msg.TextColor3 = Color3.fromRGB(230, 230, 230)
		msg.TextWrapped = true
		msg.TextXAlignment = Enum.TextXAlignment.Left
		msg.TextYAlignment = Enum.TextYAlignment.Top
		msg.Text = tostring(err)
		msg.Parent = bg
		local close = Instance.new("TextButton")
		close.Size = UDim2.new(0, 110, 0, 32)
		close.Position = UDim2.new(1, -122, 1, -40)
		close.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 15
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Text = "Close"
		close.Parent = bg
		local ccorner = Instance.new("UICorner")
		ccorner.CornerRadius = UDim.new(0, 6)
		ccorner.Parent = close
		close.MouseButton1Click:Connect(function() sg:Destroy() end)
		warn("[Final Swarm] " .. tostring(where) .. ": " .. tostring(err))
	end)
end

-- Run the whole hub inside xpcall: any error pops the red box on screen.
xpcall(function()

local Players = game:GetService("Players")

local RS = game:GetService("ReplicatedStorage")

local function getFlag(n) return RS:GetAttribute("TPL_"..n) end

local function setFlag(n,v) RS:SetAttribute("TPL_"..n, v) end

-- Live-reload generation stamping removed; kept as a no-op for loop guards.

local function isCurrentGen() return true end

if RS:GetAttribute("TPL_AutoRaidOn")==nil then RS:SetAttribute("TPL_AutoRaidOn", false) end

if RS:GetAttribute("TPL_AutoShrineOn")==nil then RS:SetAttribute("TPL_AutoShrineOn", true) end

if RS:GetAttribute("TPL_AutoFarmOn")==nil then RS:SetAttribute("TPL_AutoFarmOn", false) end

if RS:GetAttribute("TPL_AutoPortalOn")==nil then RS:SetAttribute("TPL_AutoPortalOn", false) end

if RS:GetAttribute("TPL_MagnetOn")==nil then RS:SetAttribute("TPL_MagnetOn", false) end

if RS:GetAttribute("TPL_AutoChestsOn")==nil then RS:SetAttribute("TPL_AutoChestsOn", false) end

if RS:GetAttribute("TPL_AutoUpgradeOn")==nil then RS:SetAttribute("TPL_AutoUpgradeOn", false) end

if RS:GetAttribute("TPL_AutoTreeOn")==nil then RS:SetAttribute("TPL_AutoTreeOn", false) end

if RS:GetAttribute("TPL_AutoReplayOn")==nil then RS:SetAttribute("TPL_AutoReplayOn", false) end

if RS:GetAttribute("TPL_AutoPickOn")==nil then RS:SetAttribute("TPL_AutoPickOn", false) end

if RS:GetAttribute("TPL_NoclipOn")==nil then RS:SetAttribute("TPL_NoclipOn", false) end

if RS:GetAttribute("TPL_HideNameOn")==nil then RS:SetAttribute("TPL_HideNameOn", false) end

if RS:GetAttribute("TPL_AutoEnterPortalOn")==nil then RS:SetAttribute("TPL_AutoEnterPortalOn", false) end

if RS:GetAttribute("TPL_PortalTargetMult")==nil then RS:SetAttribute("TPL_PortalTargetMult", 3) end

-- one-time migration: Farm Mode was renamed "Auto-Dodge (Hover)" -> "Auto-Dodge"
if RS:GetAttribute("TPL_FarmMode") == "Auto-Dodge (Hover)" then RS:SetAttribute("TPL_FarmMode", "Auto-Dodge") end
-- Orbit Center is the default farm mode: set it only when the attribute was
-- never saved (nil) so an explicit "Auto-Dodge" pick is never overwritten
if RS:GetAttribute("TPL_FarmMode") == nil then RS:SetAttribute("TPL_FarmMode", "Orbit Center") end

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

-- Destroy any previous hub window (Nebula/WindUI/Rayfield create a fresh ScreenGui
-- each time). Without this every reload stacks another window on top of the old
-- ones. (Nebula also removes its own leftover "NebulaUI" on load.)

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

						and (c.Text == "Auto-Upgrade Items" or c.Text == "Magnet" or c.Text == "Final Swarm Hub" or c.Text == "UI Template" or c.Text == "Liquid Hub" or c.Text == "Auto Raid Farm" or c.Text == "Auto Collect Exp") then

						hit = true

						break

					end

				end

				if hit then sg:Destroy() end

			end

		end

	end

end)

-- ===================== ANTICHEAT BYPASS =====================
-- AntiCheatServiceClient watches WalkSpeed/JumpHeight/HipHeight/PlatformStand/
-- humanoid state/CanCollide and destroys non-whitelisted BodyMovers, reporting
-- everything through Networker("AntiCheat"):fire("ReportViolation", name).
-- Wrap that channel once: eat violations, pass ClientHeartbeat (heartbeat
-- timeout still kicks server-side, so it must stay alive).
-- Also tag our own BodyMovers with the game's own whitelist attribute
-- (Configs.GameVFXAttribute) so the AC's DescendantAdded destroyer skips them.
do
	pcall(function()
		local AC = require(RS.Shared.Services.AntiCheatService.AntiCheatServiceClient)
		if type(AC) == "table" and AC._networker and not AC._networker.__fsPatched then
			local realFire = AC._networker.fire
			AC._networker.fire = function(self, msg, ...)
				if msg == "ReportViolation" then return end
				return realFire(self, msg, ...)
			end
			AC._networker.__fsPatched = true
		end
	end)
end
local FS_AC_WHITELIST_ATTR = "GameOwnedVFX"
local function fsWhitelist(inst)
	pcall(function() inst:SetAttribute(FS_AC_WHITELIST_ATTR, true) end)
	return inst
end

-- ===================== LIBRARY LOAD (Nebula / Liquid Hub) =====================

-- Same sources the Liquid Hub loader uses (raw + jsDelivr). Speed: the lib is
-- cached to disk after the first fetch, so later starts load instantly with no
-- HTTP round trip; the network is only touched when the cache is missing or
-- the cached copy fails to compile.

local LIB_SOURCES = {

	"https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Source.lua",

	"https://cdn.jsdelivr.net/gh/tyanxblack2-max/asdfasd@main/Source.lua",

}

local LIB_CACHE = "UITemplate/lib_cache.luau"

local Liquid = nil

local function compileLib(res)

	if type(res) ~= "string" or #res <= 2000 then return nil end

	local chunk, cerr = (loadstring or load)(res)

	if not chunk then

		warn("[UI-Template] Compile error: " .. tostring(cerr))

		return nil

	end

	local okLib, lib = pcall(chunk)

	if okLib and type(lib) == "table" then return lib end

	return nil

end

local canCacheLib = typeof(readfile) == "function" and typeof(writefile) == "function"

	and typeof(isfile) == "function" and typeof(isfolder) == "function"

if canCacheLib and isfile(LIB_CACHE) then

	local okR, cached = pcall(readfile, LIB_CACHE)

	if okR then

		Liquid = compileLib(cached)

		if not Liquid then pcall(function() delfile(LIB_CACHE) end) end

	end

end

if not Liquid then

	for _, url in ipairs(LIB_SOURCES) do

		local ok, res = pcall(function()

			return game:HttpGet(url)

		end)

		if ok then

			Liquid = compileLib(res)

			if Liquid then

				if canCacheLib then

					pcall(function()

						if not isfolder("UITemplate") then makefolder("UITemplate") end

						writefile(LIB_CACHE, res)

					end)

				end

				break

			end

		end

	end

end

if not Liquid then

	warn("[UI-Template] Failed to load Liquid Hub library from all sources")

	if showErrorBox then showErrorBox("library", "Could not download the Liquid Hub (Nebula) UI library.\n\nCheck your internet connection / executor HTTP, then re-execute the script.") end

	return

end

-- forward decl: the async game-name resolver patches this Credits label
-- (must be declared BEFORE the resolver below captures it as a global)
creditsTeamGameLabel = nil

-- ===================== GAME DETECTION =====================
-- Resolved ASYNC after the window exists so script startup never blocks on
-- HTTP: a placeholder goes into the title bar instantly, and the real name
-- patches the title once the web API answers. (Priority once resolved:
-- Roblox web API -> ReplicatedStorage attributes -> Place <id>.)
local GAME_NAME = "Final Swarm"
do
	local pid = game.PlaceId
	task.spawn(function()
		local resolved = nil
		local ok, name = pcall(function()
			local Http = game:GetService("HttpService")
			local res = game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. pid .. "/universe")
			local universeId = Http:JSONDecode(res).universeId
			local res2 = game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. universeId)
			return Http:JSONDecode(res2).data[1].name
		end)
	if ok and type(name) == "string" and #name > 0 then
		resolved = name
	else
		pcall(function()
			local rs = game:GetService("ReplicatedStorage")
			for _, attr in ipairs({ "GameName", "PlaceName", "DisplayName" }) do
				local v = rs:GetAttribute(attr)
				if type(v) == "string" and #v > 0 then resolved = v break end
			end
		end)
		if not resolved and pid ~= 0 then
			resolved = "Place " .. pid
		end
	end
	if not resolved then return end
	GAME_NAME = resolved
	pcall(function()
		-- patch the title bar text live (same rich-text shape the lib builds;
		-- the title TextLabel is the first one parented to TitleBar)
		local gui = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("NebulaUI")
		local titleBar = gui and gui:FindFirstChild("Main") and gui.Main:FindFirstChild("TitleBar")
		local title = titleBar and titleBar:FindFirstChildOfClass("TextLabel")
		if title then
			title.Text = "💧  Liquid Hub  <font color=\"#3beaff\">|</font>  v2.3"
				.. "  <font color=\"#8c8c9b\">•  " .. GAME_NAME .. "</font>"
		end
	end)
	pcall(function()
		local lbl = creditsTeamGameLabel and creditsTeamGameLabel()
		if lbl then lbl.Text = "Game: " .. GAME_NAME end
	end)
	end)
end

local WindowRaw = Liquid:CreateWindow({

	Title     = "Liquid Hub",

	SubTitle  = "1.0.0",

	GameName  = GAME_NAME,

	ToggleKey = Enum.KeyCode.RightShift,

	Width     = 680,

	Height    = 440,

	-- "Auto Minimize on Start" (Configs tab): persisted in its own file so it
	-- applies BEFORE the window builds — the pop-in is skipped entirely.
	StartMinimized = (function()
		local ok, v = pcall(function()
			if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return false end
			if not isfile("UITemplate/startmin.txt") then return false end
			return readfile("UITemplate/startmin.txt") == "1"
		end)
		return ok and v or false
	end)(),

})

-- Config registry: adaptSection records every Toggle/Slider/Dropdown (name -> element
-- + last value + applier) so the Configs tab can save/apply whole setups.
-- Elements with noreg = true (meta UI) are skipped.

local Reg = {}

-- Old-template -> Nebula adapter: весь фарм-код ниже продолжает звать
-- tab:CreateToggle / CreateSlider / CreateDropdown / CreateSection / CreateButton / CreateStat
-- и window:Notify в старом формате, а здесь они тихо переводятся на Nebula.
-- Логика не тронута, меняется только отрисовка.

-- A tab adapter hands out section adapters (Nebula: tab -> section -> elements).
-- Sections go to column 1 by default; pass o.column = 2 for the right column.

-- elements can be called the OLD positional way ("Name", callback) or with a
-- table ({name=..., callback=...}); normalize both to a table
local function normOpts(o, cb)
	if type(o) == "string" then return { name = o, callback = cb } end
	return o or {}
end

local function adaptSection(sect)

	local s = {}

	function s:CreateLabel(o)
		return sect:CreateLabel(type(o) == "table" and o.name or o)
	end

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

		local obj			if o.multiSelect then

				-- old template passed a full list as value for multi
				obj = sect:CreateMultiDropdown(o.name, o.options or {}, initVal or {}, wrappedCb, o.name)

			elseif o.search or (type(o.options) == "table" and #o.options > 20) then

			-- long lists get the searchable variant (mirrors the old SearchBarEnabled)
			obj = sect:CreateSearchDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)

		else

			obj = sect:CreateDropdown(o.name, o.options or {}, initVal, wrappedCb, o.name)

		end

		-- searchable multi-select: the library has no native variant, so wrap a
		-- SearchDropdown as a toggle-style picker (clicking an option adds/removes
		-- it from the selection; the summary label shows how many are picked)
		if o.multiSearch then

			local pickedList = {}

			local pickedSet = {}

			local function syncPicked(v)

				if type(v) == "table" then

					pickedList, pickedSet = {}, {}

					for _, n in ipairs(v) do

						if not pickedSet[n] then

							pickedSet[n] = true

							table.insert(pickedList, n)

						end

					end

				elseif type(v) == "string" and v ~= "" then

					if pickedSet[v] then

						pickedSet[v] = nil

						for i, n in ipairs(pickedList) do

							if n == v then table.remove(pickedList, i) break end

						end

					else

						pickedSet[v] = true

						table.insert(pickedList, v)

					end

				end

				entry.current = pickedList

				if o.callback then return o.callback(pickedList) end

			end

			syncPicked(initVal or {})

			local searchObj = obj

			-- re-route the wrapped callback so the SearchDropdown's single choice
			-- toggles membership instead of replacing the selection
			entry.apply = function(v)

				if type(v) == "table" then

					pcall(function() searchObj.Set(v[1] or "") end)

					syncPicked(v)

				elseif type(v) == "string" then

					syncPicked(v)

				end

			end

			local multiHandle = {

				Set = function(list)

					syncPicked(list or {})

					if pickedList[1] then

						pcall(function() searchObj.Set(pickedList[#pickedList]) end)

					else
						pcall(function() searchObj.Set("---") end)

					end

				end,

				Get = function() return pickedList end,

			}

			entry.obj = multiHandle

			entry.apply = multiHandle.Set

			return multiHandle

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

	function s:CreateSection(o)

		-- Nebula nests sections under tabs, not under sections; a nested call
		-- just adds a labeled divider row to keep the old layout readable
		local nm = o and o.name or ""

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

			-- tolerates BOTH stat.Set("...") and stat:Set("...") (a colon call
			-- passes the table itself as the first argument — absorb it)

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

	function t:CreateSection(o)

		local nm = o and o.name or ""

		-- pass the column ONLY when explicitly set: column=nil lets the lib's
		-- auto-balancer spread 3+ sections across both columns; forcing 1 here
		-- (the old default) pinned everything to the left forever

		local col = o and o.column or nil

		local sect = wtab:CreateSection(type(nm) == "string" and nm ~= "" and nm or nil, col)

		return adaptSection(sect)

	end

	-- WindUI-style passthroughs used by old code (mapped where Nebula allows)

	function t:Divider() end

	function t:Space() end

	return t

end

local window = {}

window._raw = WindowRaw

window._tabIcons = { Main = "🎮", Lobby = "🎲", Misc = "🔧", Credits = "ℹ️", Configs = "💾" }

function window:CreateTab(o)

	return adaptTab(WindowRaw:CreateTab(o.name, self._tabIcons[o.name]))

end

function window:Notify(o)

	return WindowRaw:Notify(

		o.title or o.Title or "UI Template",

		o.content or o.Content or "",

		o.duration or o.Duration or 3

	)

end

_G.FS_Notify = function(title, content, dur)

	pcall(function() window:Notify({ title = title, content = content, duration = dur or 4 }) end)

end

local tab = window:CreateTab({ name = "Main" })

local lobby = window:CreateTab({ name = "Lobby" })

local misc = window:CreateTab({ name = "Misc" })

local credits = window:CreateTab({ name = "Credits" })

local cfgTab = window:CreateTab({ name = "Configs" })

-- ===================== MAIN =====================

-- The Main tab now hosts the Auto Farm section (hover flight + projectile
-- dodge + optional orb swoop). The old placeholder Status section was removed.

-- ===================== LOBBY: AUTO JOIN =====================
-- Auto Join: picks a map from the in-game world-selection UI and queues it, so the
-- player is standing in the right circle when the countdown completes. The queue
-- itself lives server-side: WorldSelection SetWorld -> SetDifficulty -> EnterQueue
-- (verified against the game's own WorldSelectionFrame client code), and the lobby
-- only starts the round while the player is inside their assigned queue circle.
-- The raid (Colosseum) is a separate zone: standing inside its circle auto-queues
-- a raid (uses a daily ticket), so Auto Raid just walks/parks the character there.

local RunService = game:GetService("RunService")

local WORLDS = { "Grasslands", "Desert", "Swamp", "Jungle", "Frost Forest", "Volcano" }

local DIFFICULTIES = { "Normal", "Hard", "Nightmare" }

-- Human labels -> exact WaveData world names the server expects
local WORLD_LABELS = {
	["Grasslands"] = "Grasslands",
	["Desert"] = "Desert",
	["Swamp"] = "Swamp",
	["Jungle"] = "Jungle",
	["Frost Forest"] = "Frost Forest",
	["Volcano"] = "Volcano",
}

if getFlag("Lobby_World") == nil then RS:SetAttribute("TPL_Lobby_World", "Grasslands") end

if getFlag("Lobby_Difficulty") == nil then RS:SetAttribute("TPL_Lobby_Difficulty", "Normal") end

local autoJoinOn = getFlag("AutoJoinOn")

local autoRaidOn = getFlag("AutoRaidQueueOn")

local currentMap = getFlag("Lobby_World")

local currentDiff = getFlag("Lobby_Difficulty")

local Networker = nil

pcall(function() Networker = require(RS:WaitForChild("Packages"):WaitForChild("Networker")) end)

local function getCharacterHRP()

	local char = Players.LocalPlayer.Character

	return char and char:FindFirstChild("HumanoidRootPart")

end

-- Teleports the character into the middle of a zone part and keeps it there
-- for `hold` seconds (the lobby physics can push a falling character off).
local function standInPart(part, yOffset, hold)

	if not part or not part:IsA("BasePart") then return false end

	local hrp = getCharacterHRP()

	if not hrp then return false end

	local deadline = os.clock() + (hold or 3)

	while os.clock() < deadline do

		pcall(function() hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, yOffset or 3, 0)) end)

		task.wait(0.25)

	end

	return true

end

-- Fires the game's own world-selection messages. Returns true when the server
-- accepted the queue request.
local function queueWorld(worldName, difficulty)

	local net = nil

	pcall(function() net = Networker.client.new("WorldSelection", {}) end)

	if not net then return false, "no networker" end

	local ok1 = pcall(function() net:fire("SetWorld", worldName) end)

	task.wait(0.2)

	local ok2 = pcall(function() net:fire("SetDifficulty", difficulty) end)

	task.wait(0.2)

	local okR, res = pcall(function() return net:fetch("EnterQueue") end)

	return okR and res == true, tostring(res)

end

local function isInQueue()

	local ok, vis = pcall(function()

		return Players.LocalPlayer.PlayerGui.HUD.Bottom.ButtonsHolder.LeaveButton.Visible

	end)

	return ok and vis

end

-- ===================== AUTO JOIN LOOP =====================
do

	local joinRunning = false

	local function autoJoinLoop()

		if joinRunning then return end

		joinRunning = true

		while autoJoinOn and isCurrentGen() do

			local lobbyRoot = workspace:FindFirstChild("Lobby")

			if not lobbyRoot then

				-- not in the lobby (in a match or still loading)
				task.wait(2)

			else

				-- 1) send the selection exactly like the world-selection UI does
				local ok, why = queueWorld(WORLD_LABELS[currentMap] or currentMap, currentDiff)

				if ok then

					-- solo party: pick size 1 and Create, like the Party frame does
					pcall(function()

						local netQ = Networker.client.new("QueueService", {})

						netQ:fire("PartySizeSelected", 1)

					end)

					task.wait(0.3)

					pcall(function()

						local netQ = Networker.client.new("QueueService", {})

						netQ:fire("Created")

					end)

					-- 2) the server drops us into an elevated queue circle; it only
					-- starts the round while we are physically inside it, so hold
					-- the character on the platform until the lobby disappears
					-- (= the teleport into the match happened).
					local deadline = os.clock() + 30

					while autoJoinOn and isCurrentGen() and os.clock() < deadline do

						local lb = workspace:FindFirstChild("Lobby")

						if not lb then break end -- teleported into the match: done

						local hrp = getCharacterHRP()

						if hrp then

							local areas = lb:FindFirstChild("Areas")

							local qFolder = areas and areas:FindFirstChild("Queue")

							local best, bd = nil, math.huge

							if qFolder then

								for _, q in ipairs(qFolder:GetChildren()) do

									if q:IsA("Model") and q:FindFirstChild("Container") then

										local c = q.Container.Position

										local d = (Vector3.new(c.X, 0, c.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude

										if d < bd then bd = d; best = q end

									end

								end

							end

							if best and bd < 80 then

								pcall(function() hrp.CFrame = CFrame.new(best.Container.Position + Vector3.new(0, 4, 0)) end)

							end

						end

						task.wait(0.3)

					end

				else

					task.wait(2)

				end

				task.wait(0.5)

			end

		end

		joinRunning = false

	end

	task.spawn(autoJoinLoop)

	-- publish for the toggle callback below
	_G.FS_StartAutoJoin = function(on)

		autoJoinOn = on

		if on then task.spawn(autoJoinLoop) end

	end

end

-- ===================== AUTO RAID (Colosseum) LOOP =====================
do

	local raidRunning = false

	local function autoRaidQueueLoop()

		if raidRunning then return end

		raidRunning = true

		while autoRaidOn and isCurrentGen() do

			local lb = workspace:FindFirstChild("Lobby")

			if not lb then

				-- not in the lobby: nothing to stand in
				task.wait(2)

			else

				local areas = lb:FindFirstChild("Areas")

				local raids = areas and areas:FindFirstChild("Raids")

				local queues = raids and raids:FindFirstChild("RaidQueues")

				local q1 = queues and queues:FindFirstChild("Queue1")

				if q1 and q1:FindFirstChild("Container") then

					-- raid join is purely physical: stand inside the raid circle and
					-- the zone auto-queues (uses a daily ticket when the round starts)
					standInPart(q1.Container, 3, 2)

				else

					task.wait(1)

				end

			end

			task.wait(0.5)

		end

		raidRunning = false

	end

	task.spawn(autoRaidQueueLoop)

_G.FS_StartAutoRaid = function(on)

	autoRaidOn = on

	if on then task.spawn(autoRaidQueueLoop) end

	end
end

-- ===================== ROUND-END SCREEN HELPERS =====================
-- Win OR death, the run ends behind TWO gate screens before the RoundEnd
-- reward screen appears (verified in the game's DeathScreen/RoundEnd clients):
--   1. DeathFrame  -> its "Continue" button advances to RoundEnd/Victory
--   2. VictoryFrame -> ANY click/touch dismisses it into RoundEnd:Show()
-- Without clicking through these, Auto Replay / Auto Return Lobby never see
-- RoundEnd become visible and wait forever.
do
	local function fsFrame(name)
		local f = nil
		pcall(function()
			local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
			local frames = pg and pg:FindFirstChild("Frames")
			f = frames and frames:FindFirstChild(name)
		end)
		return f
	end

	-- fires a GuiButton the way the game itself would: its own connections first
	-- (getconnections on BOTH click signals), then firesignal, then a synthetic
	-- click at its center as the last resort. Returns true if any path fired.
	function _G.FS_PressButton(btn)
		if not (btn and btn:IsA("GuiButton")) then return false end
		local fired = false
		if getconnections then
			pcall(function()
				for _, sig in ipairs({ btn.MouseButton1Click, btn.Activated }) do
					for _, conn in ipairs(getconnections(sig)) do
						local ok = pcall(function() conn:Fire() end)
						if ok then fired = true end
					end
				end
			end)
		end
		if not fired and firesignal then
			pcall(function()
				firesignal(btn.MouseButton1Click)
				fired = true
			end)
		end
		if not fired then
			pcall(function()
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(960, 540)
				local VIM = game:GetService("VirtualInputManager")
				local x, y = vp.X / 2, vp.Y / 2
				pcall(function()
					local ap, as = btn.AbsolutePosition, btn.AbsoluteSize
					x, y = ap.X + as.X / 2, ap.Y + as.Y / 2
				end)
				VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
				task.wait(0.05)
				VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
				fired = true
			end)
		end
		return fired
	end

	-- click through the death screen and victory splash if they are up
	function _G.FS_ClickThroughEndGates()
		local death = fsFrame("DeathFrame")
		if death and death.Visible then
			-- the death screen has TWO advance paths: Continue (DeathScreen client
			-- line 65 -> RoundEnd:Show/showVictory) and Give Up. Try every visible
			-- GuiButton in Buttons until one of them clears the frame — some skins
			-- bury Continue or name the button differently, so don't hard-code it.
			local buttons = death:FindFirstChild("Buttons")
			local pressed = false
			if buttons then
				local cont = buttons:FindFirstChild("Continue")
				if cont and cont:IsA("GuiButton") then pressed = _G.FS_PressButton(cont) or pressed end
				if not pressed then
					for _, b in ipairs(buttons:GetChildren()) do
						if b:IsA("GuiButton") and b ~= cont and b.Visible
							and b.Name ~= "Revive" and b.Name ~= "Spectate" then
							pressed = _G.FS_PressButton(b) or pressed
							if pressed then break end
						end
					end
				end
			end
			-- last resort: re-fire the DeathScreen client's Continue handler even
			-- if the button was somehow invisible/renamed
			if not pressed and buttons then
				local cont = buttons:FindFirstChild("Continue")
				if cont then pressed = _G.FS_PressButton(cont) or pressed end
			end
			task.wait(0.6)
			return true
		end
		-- VictoryFrame: the game dismisses it on UserInputService.InputBegan with
		-- gameProcessed == false (MouseButton1/Touch/Gamepad1) -> RoundEnd:Show().
		-- VIM clicks don't always reach that listener, so fire the connection we
		-- can see first; a real VIM click is the fallback.
		local UISvc = game:GetService("UserInputService")
		local vict = fsFrame("VictoryFrame")
		if vict and vict.Visible then
			local dismissed = false
			if getconnections then
				pcall(function()
					for _, conn in ipairs(getconnections(UISvc.InputBegan)) do
						-- only scripts (the game's), skip our own hub listeners
						if conn.Script and conn.Script ~= script then
							local ok = pcall(function()
								conn:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, false)
							end)
							if ok then dismissed = true end
						end
					end
				end)
			end
			if not dismissed then
				pcall(function()
					local VIM = game:GetService("VirtualInputManager")
					local cam = workspace.CurrentCamera
					local vp = cam and cam.ViewportSize or Vector2.new(960, 540)
					VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
					task.wait(0.05)
					VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
				end)
			end
			task.wait(0.6)
			return true
		end
		return false
	end
end

-- ===================== AUTO REPLAY WAVE LOOP =====================
-- Fires ONLY after a finished round (win or death): the trigger is the game's
-- own RoundEnd screen turning Visible (its "Again" button = replay). Never
-- from lobby idle. Queues the last selected map + difficulty via the game's
-- own WorldSelection channel, exactly like Auto Join does.
do
	local replayRunning = false
	local function roundEndVisible()
		local ok, v = pcall(function()
			local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
			local frames = pg and pg:FindFirstChild("Frames")
			local re = frames and frames:FindFirstChild("RoundEnd")
			return re ~= nil and re.Visible == true
		end)
		return ok and v or false
	end
	local function autoReplayLoop()
		if replayRunning then return end
		replayRunning = true
		while getFlag("AutoReplayOn") and isCurrentGen() do
			-- click through death/victory gates first — RoundEnd sits behind them
			pcall(function() _G.FS_ClickThroughEndGates() end)
			-- arm only when a round actually finished (win/death -> RoundEnd screen)
			local wasInRound = getFlag("FS_WasInRound")
			if not wasInRound then
				if roundEndVisible() then RS:SetAttribute("FS_WasInRound", true) end
				task.wait(1)
			else
				local lb = workspace:FindFirstChild("Lobby")
				-- RoundEnd reward screen still up? Its "Again" button IS the replay
				-- path (GameServiceClient:PlayAgain) — pressing it re-queues without
				-- walking back through world selection. Fall back to manual queueing.
				local pressedAgain = false
				pcall(function()
					local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
					local frames = pg and pg:FindFirstChild("Frames")
					local re = frames and frames:FindFirstChild("RoundEnd")
					local again = re and re:FindFirstChild("Buttons") and re.Buttons:FindFirstChild("Again")
					if again and again:IsA("GuiButton") and again.Visible and re.Visible then
						pressedAgain = _G.FS_PressButton(again) or false
						if not pressedAgain then
							pcall(function()
								local GS = require(RS.Shared.Services.GameService.GameServiceClient)
								GS:PlayAgain()
							end)
							pressedAgain = true
						end
					end
				end)
				if pressedAgain then
					RS:SetAttribute("FS_WasInRound", false)
					if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Replay", "Round ended -> pressed Again") end) end
					task.wait(5)
				elseif lb then
					-- round over: queue again (queueWorld is defined above in this scope)
					local map = getFlag("Lobby_World") or "Grasslands"
					local diff = getFlag("Lobby_Difficulty") or "Normal"
					queueWorld(WORLD_LABELS[map] or map, diff)
					pcall(function()
						local netQ = Networker.client.new("QueueService", {})
						netQ:fire("PartySizeSelected", 1)
					end)
					task.wait(0.3)
					pcall(function()
						local netQ = Networker.client.new("QueueService", {})
						netQ:fire("Created")
					end)
					RS:SetAttribute("FS_WasInRound", false)
					-- hold position inside the assigned queue circle like Auto Join
					local deadline = os.clock() + 30
					while os.clock() < deadline and getFlag("AutoReplayOn") do
						if not workspace:FindFirstChild("Lobby") then break end
						local h = getCharacterHRP()
						if h then
							local areas = lb:FindFirstChild("Areas")
							local qFolder = areas and areas:FindFirstChild("Queue")
							local best, bd = nil, math.huge
							if qFolder then
								for _, q in ipairs(qFolder:GetChildren()) do
									if q:IsA("Model") and q:FindFirstChild("Container") then
										local c = q.Container.Position
										local d = (Vector3.new(c.X, 0, c.Z) - Vector3.new(h.Position.X, 0, h.Position.Z)).Magnitude
										if d < bd then bd = d; best = q end
									end
								end
							end
							if best and bd < 80 then
								pcall(function() h.CFrame = CFrame.new(best.Container.Position + Vector3.new(0, 4, 0)) end)
							end
						end
						task.wait(0.3)
					end
				else
					RS:SetAttribute("FS_WasInRound", false) -- in a match (RoundEnd hidden)
					task.wait(2)
				end
			end
		end
		replayRunning = false
	end
	task.spawn(autoReplayLoop)
	_G.FS_StartAutoReplay = function(on)
		RS:SetAttribute("TPL_AutoReplayOn", on)
	end
end

-- ===================== AUTO RETURN LOBBY LOOP =====================
-- Fires ONLY after a finished round (win or death): the run ends behind the
-- death/victory gate screens — click through those first, then wait for the
-- game's own RoundEnd reward screen and press its "Lobby" button
-- (RoundEnd.Buttons.Lobby -> GameServiceClient:Continue()).
do
	local retRunning = false
	local function autoReturnLobbyLoop()
		if retRunning then return end
		retRunning = true
		local function roundEndVisible()
			local ok, v = pcall(function()
				local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
				local frames = pg and pg:FindFirstChild("Frames")
				local re = frames and frames:FindFirstChild("RoundEnd")
				return re ~= nil and re.Visible == true
			end)
			return ok and v or false
		end
		while getFlag("AutoReturnLobbyOn") and isCurrentGen() do
			local inMatch = workspace:FindFirstChild("Map") ~= nil and workspace:FindFirstChild("Lobby") == nil
			if not inMatch then
				task.wait(1)
			else
				-- death screen or victory splash up? click through them first —
				-- RoundEnd is unreachable until both are dismissed
				if pcall(function() _G.FS_ClickThroughEndGates() end) then
					task.wait(0.5)
				end
				-- look for the round-end screen
				local pressed = false
				pcall(function()
					local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
					local frames = pg and pg:FindFirstChild("Frames")
					local roundEnd = frames and frames:FindFirstChild("RoundEnd")
					local btn = roundEnd and roundEnd:FindFirstChild("Buttons")
						and roundEnd.Buttons:FindFirstChild("Lobby")
					-- win/death gate: the RoundEnd screen itself must be on screen
					if btn and btn:IsA("GuiButton") and btn.Visible
						and roundEnd.Visible and roundEndVisible() then
						-- fire the game's own handler first (safest path)
						local okPress = _G.FS_PressButton and _G.FS_PressButton(btn)
						-- fall back to the service call directly
						if not okPress then
							pcall(function()
								local GS = require(RS.Shared.Services.GameService.GameServiceClient)
								GS:Continue()
							end)
						end
						pressed = true
					end
				end)
				if pressed then
					RS:SetAttribute("TPL_AutoReturnLobbyOn", false) -- one-shot per round
					if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Return Lobby", "Round ended -> returning to lobby") end) end
					task.wait(5) -- let the teleport settle before re-checking
				else
					task.wait(0.5)
				end
			end
		end
		retRunning = false
	end
	task.spawn(autoReturnLobbyLoop)
	_G.FS_StartAutoReturnLobby = function(on)
		RS:SetAttribute("TPL_AutoReturnLobbyOn", on)
		if on then task.spawn(autoReturnLobbyLoop) end
	end
end

-- ===================== AUTO SMART CARDS =====================
-- Picks level-up cards by priority without touching the UI: fires the same
-- remote the Upgrade frame uses (GameServiceClient:UpgradeSelected(name, count))
-- as soon as IsChoosingUpgrade flips true.
-- Strategy:
--   * early game: grab Luck first (better rare rolls for the rest of the run)
--   * late game (>= min level): Luck is deprioritized
--   * weapons are ranked to match the hover auto-farm: ranged/AOE first,
--     close-range last
--   * passives fill whatever's left

do
	-- // WEAPON PRIORITY: long/AOE range first, close-range last (hover farm) //
	local WEAPON_PRIORITY = {
		-- S-tier: ranged AOE / high raw damage — perfect for hover farm
		"Inferno Sword", "Laserbeam", "Trident", "Meteor", "Ban Hammer",
		"Black Hole Cannon", "Void Scythe", "Firestaff", "Lightning Staff",
		-- A-tier: solid ranged or homing
		"Missile", "Tornado", "Bananarang", "Bow", "Revolver", "Sniper",
		"Poison Flask", "Ninja Star",
		-- B-tier: AOE zones that still reach from above
		"Aura", "Explosion", "Axe",
		-- C-tier: walkers / short reach — least useful while hovering
		"Frost Walker", "Flame Walker", "Flamethrower", "Spike Ball", "Sword",
		"Shotgun", "Daggers",
	}
	local WEAPON_RANK = {}
	for i, w in ipairs(WEAPON_PRIORITY) do WEAPON_RANK[w] = i end

	-- // PASSIVE PRIORITY //
	local function passiveScore(id, kind)
		-- kind: "early" (levels 1-9), "mid" (10-19), "late" (20+)
		if id:find("Luck") then
			-- early: top priority, late: dead last
			if kind == "early" then return 1000 end
			if kind == "mid" then return 55 end
			return -10
		end
		local tier = {
			["Multishot"] = 900,
			["Projectile Count Epic"] = 880, ["Projectile Count Legendary"] = 885,
			["Damage Legendary"] = 850, ["Damage Epic"] = 820, ["Damage Rare"] = 700, ["Damage Common"] = 500,
			["Attack Speed Legendary"] = 840, ["Attack Speed Epic"] = 810, ["Attack Speed Rare"] = 690, ["Attack Speed Common"] = 490,
			["Size Legendary"] = 780, ["Size Epic"] = 750, ["Size Rare"] = 620,
			["Piercing Rare"] = 760, ["Ricochet Rare"] = 755,
			["Bolt"] = 740, ["Blaze"] = 730, ["Freeze"] = 720,
			["XP Gain Legendary"] = 660, ["XP Gain Epic"] = 640, ["XP Gain Rare"] = 560,
			["Crit Chance Rare"] = 620, ["Crit Chance Common"] = 480,
			["Power Trio"] = 700,
			["Soul of Swiftness"] = 540,
			["Demon Slayer"] = 520,
			["Regen Epic"] = 500, ["Regen Rare"] = 420, ["Regen Common"] = 350,
			["Health Legendary"] = 460, ["Health Epic"] = 430, ["Health Rare"] = 360, ["Health Common"] = 300,
			["Armor Epic"] = 450, ["Armor Rare"] = 400,
			["Lifesteal Epic"] = 440, ["Lifesteal Rare"] = 380,
			["Movement Speed Legendary"] = 420, ["Movement Speed Epic"] = 400, ["Movement Speed Rare"] = 340, ["Movement Speed Common"] = 280,
			["Projectile Speed Epic"] = 380, ["Projectile Speed Rare"] = 330, ["Projectile Speed Common"] = 270,
			["Wind Blessing"] = 350, ["Perilous Fervor"] = 320, ["Thorns Rare"] = 250,
			["Stand Strong"] = 50, -- hover farm: we're never still on the ground
			["Giant's Strength"] = 100, -- bigger hitbox = worse while dodging
			["Extra Jump Legendary"] = 80,
		}
		return tier[id] or 200
	end

	local function levelKind(level)
		if level < 10 then return "early" end
		if level < 20 then return "mid" end
		return "late"
	end

	local smartRunning = false
	local function getRunLevel()
		-- player run level comes from PlayerRunData
		local ok, PRD = pcall(function() return require(RS.Shared.Modules.Core.PlayerRunData) end)
		if not ok then return 1 end
		local ok2, data = pcall(function() return PRD:get(Players.LocalPlayer) end)
		if ok2 and type(data) == "table" then
			return tonumber(data.level) or 1
		end
		return 1
	end

	local function pickBestCard(offers)
		-- offers: {[cardId] = {rarity, ...}, ...} — the shape showUpgrades receives
		if type(offers) ~= "table" then return nil end
		local level = getRunLevel()
		local kind = levelKind(level)
		local best, bestScore = nil, -math.huge
		for id in pairs(offers) do
			local s
			if WEAPON_RANK[id] then
				s = 2000 - WEAPON_RANK[id] -- always above passives unless mid-late weapon is C-tier
			else
				s = passiveScore(id, kind)
			end
			if s > bestScore then bestScore = s best = id end
		end
		return best
	end

	local function getUpgradeParts()
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local frames = pg and pg:FindFirstChild("Frames")
		local up = frames and frames:FindFirstChild("Upgrades")
		return up, up and up:FindFirstChild("Holder"), up and up:FindFirstChild("SpinHolder")
	end

	-- Skip Card Animation: ported from the OLD proven script — fake owning the
	-- FastUpgrade skill (hook DataService.client:get) and send the screen-center
	-- click the Upgrade frame listens for. Works without the skill owned.
	local VIM = game:GetService("VirtualInputManager")
	local function skipCardAnimation()
		pcall(function()
			local up, holder, spin = getUpgradeParts()
			if not (up and up.Visible) then return end
			spin = up:FindFirstChild("SpinHolder")
			if not (spin and spin.Visible) then return end
			if not getgenv()._fsFastHooked then
				getgenv()._fsFastHooked = true
				local okDS, DS = pcall(function() return require(RS.Packages.DataService) end)
				if okDS and DS and DS.client and DS.client.get then
					local orig = DS.client.get
					DS.client.get = function(self, path)
						if type(path) == "table" and path[1] == "stats" and path[2] == "skillTree" and path[3] == "FastUpgrade" then
							return true
						end
						return orig(self, path)
					end
				end
			end
			local cam = workspace.CurrentCamera
			local sz = cam and cam.ViewportSize or Vector2.new(960, 540)
			VIM:SendMouseButtonEvent(sz.X * 0.5, sz.Y * 0.5, 0, true, game, 0)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(sz.X * 0.5, sz.Y * 0.5, 0, false, game, 0)
		end)
	end

	-- Read the visible offered cards (name, rarity, frame) from the Holder —
	-- exactly like the old working Auto Pick loop.
	local function getOfferedCards()
		local up = getUpgradeParts()
		if not up or not up.Visible then return nil end
		local holder = up:FindFirstChild("Holder")
		if not holder then return nil end
		local cards = {}
		for i = 1, 12 do
			local sel = holder:FindFirstChild("Selection" .. i)
			if sel and sel.Visible then
				local nameLbl = sel:FindFirstChild("ItemTitle")
				local name = nameLbl and nameLbl.Text or ""
				if name ~= "" then
					cards[#cards + 1] = { frame = sel, name = name }
				end
			end
		end
		return #cards > 0 and cards or nil
	end

	local function smartCardLoop()
		if smartRunning then return end
		smartRunning = true
		-- Ported from the OLD working script: no choosing gate, no arming, no
		-- remotes — poll the visible offer set, VIM-click the best card, reset
		-- the signature after every pick. This is what actually works.
		local lastSig = nil
		while getFlag("AutoSmartCardsOn") and isCurrentGen() do
			local okE, err = pcall(function()
				local cards = getOfferedCards()
				if not cards then
					lastSig = nil
					return
				end
				if getFlag("SkipCardAnimOn") then pcall(skipCardAnimation) end
				local sigParts = {}
				for _, c in ipairs(cards) do sigParts[#sigParts + 1] = c.name end
				local sig = table.concat(sigParts, "|")
				if sig == lastSig then return end
				lastSig = sig
				local nameToIndex = {}
				for _, c in ipairs(cards) do nameToIndex[c.name] = tonumber(c.frame.Name:match("Selection(%d+)")) end
				local pick = pickBestCard(nameToIndex)
				if pick and nameToIndex[pick] then
					local card = cards[1] and cards[1].frame.Parent:FindFirstChild("Selection" .. nameToIndex[pick])
					if card and card.Parent then
						task.wait(0.08)
						-- the old script's click: synthetic mouse down+up at card center
						pcall(function()
							local ap, as = card.AbsolutePosition, card.AbsoluteSize
							local x, y = ap.X + as.X / 2, ap.Y + as.Y / 2
							VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
							task.wait(0.03)
							VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
						end)
						lastSig = nil
						if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Smart Cards", "level " .. getRunLevel() .. " -> picked " .. pick) end) end
						task.wait(0.5)
					end
				end
			end)
			if not okE then warn("[FS SmartCards] " .. tostring(err)) end
			task.wait(0.2)
		end
		smartRunning = false
	end
	task.spawn(smartCardLoop)
	_G.FS_StartAutoSmartCards = function(on)
		RS:SetAttribute("TPL_AutoSmartCardsOn", on)
		if on then task.spawn(smartCardLoop) end
	end
end

-- Skip Card Animation stays tied to Auto Smart Cards. Keep the flag mirrored
-- so the pick loop's existing getFlag("SkipCardAnimOn") check works.
RS:GetAttributeChangedSignal("TPL_AutoSmartCardsOn"):Connect(function()
	RS:SetAttribute("TPL_SkipCardAnimOn", RS:GetAttribute("TPL_AutoSmartCardsOn") and true or false)
end)
RS:SetAttribute("TPL_SkipCardAnimOn", RS:GetAttribute("TPL_AutoSmartCardsOn") and true or false)

-- ===================== LOBBY TAB UI =====================
do

	local secJoin = lobby:CreateSection({ name = "Auto Join" })

	local worldDD = secJoin:CreateDropdown({

		name = "Map",

		options = WORLDS,

		value = currentMap,

		callback = function(v)

			if type(v) == "string" and WORLD_LABELS[v] then

				currentMap = v

				RS:SetAttribute("TPL_Lobby_World", v)

			end

		end,

	})

	local diffDD = secJoin:CreateDropdown({

		name = "Difficulty",

		options = DIFFICULTIES,

		value = currentDiff,

		callback = function(v)

			if type(v) == "string" then

				currentDiff = v

				RS:SetAttribute("TPL_Lobby_Difficulty", v)

			end

		end,

	})

	secJoin:CreateToggle({

		name = "Auto Join Map",

		value = autoJoinOn,

		callback = function(v)

			RS:SetAttribute("TPL_AutoJoinOn", v)

			if _G.FS_StartAutoJoin then _G.FS_StartAutoJoin(v) end

		end,

	})

	secJoin:CreateToggle({

		name = "Auto Raid (Colosseum)",

		value = autoRaidOn,

		callback = function(v)

			RS:SetAttribute("TPL_AutoRaidQueueOn", v)

			if _G.FS_StartAutoRaid then _G.FS_StartAutoRaid(v) end

		end,

	})

end

-- ===================== INVENTORY: AUTO UPGRADE =====================
-- Upgrades items with the game's own InventoryService remote. The game's client
-- sends: networker("InventoryService"):fire("upgradeItem", itemName, itemType)
-- where itemType is "weapon" / "armor" / "gear" (from WeaponData/ArmorData/GearData).
-- An item is maxed when its level >= #ItemData[name].upgrades (verified against
-- InventoryFrame._applyUpgrade). Keys are spent server-side.

local ItemData = nil

pcall(function()

	local DataFolder = RS:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Data")

	ItemData = {}

	for _, mod in ipairs({ "WeaponData", "ArmorData", "GearData" }) do

		local ok, m = pcall(require, DataFolder:WaitForChild(mod))

		if ok and type(m) == "table" then

			for name, def in pairs(m) do

				if type(def) == "table" and type(def.upgrades) == "table" and #def.upgrades > 0 then

					ItemData[name] = { type = mod:sub(1, -5):lower(), maxLevel = #def.upgrades }

				end

			end

		end

	end

end)

local DSClient = nil

pcall(function()

	local dsMod = RS:WaitForChild("Packages"):WaitForChild("_Index"):FindFirstChild("leifstout_dataservice@0.3.2")

	if dsMod then

		local ds = dsMod:FindFirstChild("dataservice")

		if ds then

			-- this package version exposes the client singleton as the module
			-- itself (require(...).get), with no .client field - handle both

			local ok, m = pcall(require, ds:FindFirstChild("DataServiceClient") or ds)

			if ok and type(m) == "table" then

				DSClient = (type(m.get) == "function" and m) or m.client

			end

		end

	end

end)

-- fallback if the package folder name ever changes

if not DSClient then

	pcall(function()

		local idx = RS.Packages:FindFirstChild("_Index")

		if idx then

			for _, c in ipairs(idx:GetChildren()) do

				if c.Name:find("dataservice") then

					for _, d in ipairs(c:GetChildren()) do

						if d.Name:find("dataservice") then

							local target = d:IsA("ModuleScript") and d or d:FindFirstChild("DataServiceClient")

							if target then

								local ok, m = pcall(require, target)

								if ok and type(m) == "table" then

									DSClient = (type(m.get) == "function" and m) or m.client

								end

							end

						end

					end

				end

			end

		end

	end)

end

local function getInventoryCategory(cat)

	if not DSClient then return nil end

	local ok, res = pcall(function() return DSClient:get({ "inventory", cat }) end)

	if ok and type(res) == "table" then return res end

	return nil

end

-- build the list of items the player owns (maxed ones included, marked so the
-- picker can grey-label them; the loop skips maxed items on its own)

local function getUpgradableItems()

	local list = {}

	for _, cat in ipairs({ "weapons", "armors", "gears" }) do

		local inv = getInventoryCategory(cat)

		if inv then

			for name, save in pairs(inv) do

				local info = ItemData[name]

				if info and type(save) == "table" then

					table.insert(list, { name = name, type = info.type, level = save.level or 0, maxLevel = info.maxLevel })

				end

			end

		end

	end

	table.sort(list, function(a, b) return a.name < b.name end)

	return list

end

-- reuse the game's own service clients' networkers so server replies land on
-- their real handlers (creating one with an empty table turns every reply into
-- a console error)
local invNet, chestNet = nil, nil

local invNetCache, chestNetCache = {}, {}

local function getServiceNetworker(tag, cache)

	if cache[1] then return cache[1] end

	local found = nil

	pcall(function()

		for _, c in ipairs(RS.Shared.Services:GetChildren()) do

			local client = c:IsA("ModuleScript") and c or c:FindFirstChildOfClass("ModuleScript")

			if client and client.Name:find("Client") then

				local ok, m = pcall(require, client)

				if ok and type(m) == "table" and m._networker and m._networker.networkTag == tag then

					found = m._networker

				end

			end

		end

	end)

	cache[1] = found

	return found

end

local function fireUpgrade(itemName, itemType)

	if not invNet then invNet = getServiceNetworker("InventoryService", invNetCache) end

	if not invNet then return false end

	return pcall(function() invNet:fire("upgradeItem", itemName, itemType) end)

end

-- item selection is stored as one comma-joined attribute so any item name
-- (they may contain spaces) round-trips safely
local function setSelectedList(names)
	RS:SetAttribute("TPL_AutoUpgradeSelList", table.concat(names or {}, ","))
end

local function getSelectedItems()
	local raw = getFlag("AutoUpgradeSelList")
	if not raw or raw == "" then return nil end -- nil = Select All (everything)
	local set = {}
	for name in raw:gmatch("[^,]+") do set[name] = true end
	return set
end

-- ===================== AUTO UPGRADE LOOP =====================
do

	local upgradeRunning = false

	local function autoUpgradeLoop()

		if upgradeRunning then return end

		upgradeRunning = true

		while getFlag("AutoUpgradeOn") and isCurrentGen() do

			local didSomething = false

			local list = getUpgradableItems()

			for _, it in ipairs(list) do

				if not getFlag("AutoUpgradeOn") then break end

				local selectedSet = getSelectedItems()

				if (not selectedSet) or selectedSet[it.name] then

					-- maxed per the game's own rule (level > #upgrades): skip silently
					if it.level <= it.maxLevel then

						if fireUpgrade(it.name, it.type) then didSomething = true end

						task.wait(0.15)
					end
				end

			end

			-- wait for data to update (level/xp changes come back async)

			task.wait(didSomething and 0.5 or 1.5)

		end
		upgradeRunning = false

	end

	task.spawn(autoUpgradeLoop)

	_G.FS_StartAutoUpgrade = function(on)

		RS:SetAttribute("TPL_AutoUpgradeOn", on)

		if on then task.spawn(autoUpgradeLoop) end

	end

end

-- ===================== CHESTS: AUTO OPEN =====================
-- Opens chests with the game's own ChestService remote:
--   networker("ChestService"):fire("OpenMultipleChests", chestName, amount)
-- The in-game batch cap is the ChestOpen5/10/100 skill-tree unlock (verified in
-- ChestFrame: the amount picker only offers 100 when stats.skillTree.ChestOpen100
-- is true). Auto Open reads that flag: batches of 100 when unlocked, else the
-- largest batch the player has (10 / 5), else singles, opening as fast as the
-- game allows.

local CHEST_ORDER = { "EpicChest", "GoldenChest", "RareChest", "WoodenChest", "InfernoChest", "VoidChest", "RaidChest" }

local CHEST_NET = "ChestService"

local function getChestNet()

	if not chestNet then chestNet = getServiceNetworker(CHEST_NET, chestNetCache) end

	return chestNet

end

local function getSkillTree()

	if not DSClient then return {} end

	local ok, res = pcall(function() return DSClient:get({ "stats", "skillTree" }) end)

	if ok and type(res) == "table" then return res end

	return {}

end

local function getMaxBatch()

	local st = getSkillTree()

	if st.ChestOpen100 then return 100 end

	if st.ChestOpen10 then return 10 end

	if st.ChestOpen5 then return 5 end

	return 1

end

local function getChestCounts()

	local inv = getInventoryCategory("chests") or {}

	return inv

end

local function openChests(chestName, amount)

	local net = getChestNet()

	if not net then return false end

	return pcall(function() net:fire("OpenMultipleChests", chestName, amount) end)

end

-- ===================== AUTO OPEN CHESTS LOOP =====================
do

	local chestRunning = false

	local function autoOpenChestsLoop()

		if chestRunning then return end

		chestRunning = true

		while getFlag("AutoOpenChestsOn") and isCurrentGen() do

			local didSomething = false

			local counts = getChestCounts()

			local batch = getMaxBatch()

			for _, chestName in ipairs(CHEST_ORDER) do

				if not getFlag("AutoOpenChestsOn") then break end

				local n = counts[chestName] or 0

				while n > 0 and getFlag("AutoOpenChestsOn") do

					local amt = math.min(batch, n)

					if openChests(chestName, amt) then didSomething = true end

					n = n - amt

					task.wait(0.35)

				end

			end

			task.wait(didSomething and 0.5 or 1.5)

		end

		chestRunning = false

	end

	task.spawn(autoOpenChestsLoop)

	_G.FS_StartAutoChests = function(on)

		RS:SetAttribute("TPL_AutoOpenChestsOn", on)

		if on then task.spawn(autoOpenChestsLoop) end

	end

end

-- ===================== SKILL TREE: AUTO UPGRADE =====================
-- helper: which skills the user picked (nil = all)
local function getSelectedSkills()
	local raw = getFlag("AutoSkillSelList")
	if not raw or raw == "" then return nil end
	local set = {}
	for name in raw:gmatch("[^,]+") do set[name] = true end
	return set
end
-- Buys skill-tree nodes with the game's own SkillTree remote:
--   networker("SkillTree"):fire("purchaseSkill", skillId)
-- Node prerequisites, key cost and availability are checked client-side the same
-- way the game's SkillTree frame does (dependency owned, currency sufficient),
-- so we only fire purchases the game itself would accept.

local SkillTreeData = nil

pcall(function()

	local ok, m = pcall(require, RS.Shared.Modules.Data:WaitForChild("SkillTreeData"))

	if ok and type(m) == "table" then SkillTreeData = m end

end)

local skillNetCache = {}

local function getSkillNet()

	if not skillNetCache[1] then

		skillNetCache[1] = getServiceNetworker("SkillTree", skillNetCache)

	end

	return skillNetCache[1]

end

local function getSkillStats()

	if not DSClient then return nil, 0 end

	local ok, st = pcall(function() return DSClient:get({ "stats" }) end)

	if not ok or type(st) ~= "table" then return nil, 0 end

	return st.skillTree or {}, st.keys or 0

end

-- ids of nodes whose data exists, sorted for a stable dropdown

local function getSkillIds()

	local ids = {}

	if SkillTreeData then

		for id in pairs(SkillTreeData) do table.insert(ids, id) end

		table.sort(ids)

	end

	return ids

end

-- ===================== AUTO SKILL TREE LOOP =====================
do

	local skillRunning = false

	local function autoSkillLoop()

		if skillRunning then return end

		skillRunning = true

		while getFlag("AutoSkillTreeOn") and isCurrentGen() do

			local didSomething = false

			local owned, keys = getSkillStats()

			local targets = getSelectedSkills()

			local net = getSkillNet()

			if SkillTreeData and owned and net then

				for id, def in pairs(SkillTreeData) do

					if not getFlag("AutoSkillTreeOn") then break end

					-- target filter: empty/nil selection = buy every affordable node						local wanted = (not targets) or targets[id]

						-- non-purchasable (gamepass-only) and already-owned nodes are skipped;
						-- prerequisites are NOT checked here - the player may buy the parent
						-- first, so retrying is how a fresh account walks the whole tree
						if wanted and type(def) == "table" and not def.gamepass
							and not owned[id]
							and def.cost and type(def.cost) == "table" then

							local cur = def.cost.currency or "keys"

							local have = keys

							if cur ~= "keys" then

								local okC, bal = pcall(function() return DSClient:get({ "stats", cur }) end)

								have = (okC and type(bal) == "number") and bal or 0

							end

							-- fire whenever the player can afford it, even if the
							-- prerequisite is missing: the server just declines until the
							-- parent node is bought, and a later pass retries it
							if have >= (def.cost.amount or 0) then

								if pcall(function() net:fire("purchaseSkill", id) end) then

									didSomething = true

								end

								task.wait(0.25)

							end

						end

				end

			end

			task.wait(didSomething and 0.5 or 1.5)

			keys = nil -- loop re-reads each pass

		end

		skillRunning = false

	end

	task.spawn(autoSkillLoop)

	_G.FS_StartAutoSkill = function(on)

		RS:SetAttribute("TPL_AutoSkillTreeOn", on)

		if on then task.spawn(autoSkillLoop) end

	end

end

-- ===================== GRADING: AUTO PERFECT =====================
-- Grades items with the game's own pipeline:
--   InventoryFrame.gradeStartSignal:Fire(itemName)
--     -> InventoryService "startGrading" fetch (rolls the grade, consumes a
--        grade crystal)
--     -> SkillTestServiceClient:setGrade(...) + :Start(item)  (the lock minigame)
-- The minigame spawns a target arc and sweeps a line; a press inside
-- areaHalfWidth is a hit and inside areaPerfect is a PERFECT (combo +1). The
-- line angle lives in the UI: PlayerGui.Frames.MainInventory
-- .ArmorGradingSkillFrame.SkillTest.selectionLine.Rotation, and the target's
-- center angle in SkillTestServiceClient's private state - so instead of
-- touching internals, Auto Grade presses exactly when the line's rotation is
-- within a few degrees of the visible target arc (read from the UI arcs).
-- It stops re-grading an item once its grade reaches the chosen "Grade Until"
-- tier (F<D<C<B<A<S<SS<SSS<Omega).

local GradeData = nil

pcall(function()

	local ok, m = pcall(require, RS.Shared.Modules.Data:WaitForChild("GradeData"))

	if ok and type(m) == "table" and type(m.order) == "table" then GradeData = m end

end)

local InventoryFrameCtl = nil

pcall(function()

	-- timeout: this module only exists in the LOBBY place; in a match place
	-- waiting forever stalled the whole hub (farm/toggles never registered)

	local ok, m = pcall(require, RS.Shared.UI.Frames:WaitForChild("InventoryFrame", 5))

	if ok and type(m) == "table" and m.gradeStartSignal then InventoryFrameCtl = m end

end)

local function gradeIndexOf(g)

	if not (GradeData and type(g) == "string") then return 1 end

	local ok, idx = pcall(function() return GradeData.orderOf(g) end)

	if ok and type(idx) == "number" then return idx end

	return 1

end

local GRADE_NAMES = (GradeData and GradeData.order) or { "F", "D", "C", "B", "A", "S", "SS", "SSS", "Omega" }

local function getGradableItems()

	-- gradable: armors + gears (amulets and rings are gears in this game)
	local out = {}

	local seen = {}

	for _, cat in ipairs({ "armors", "gears" }) do

		local inv = getInventoryCategory(cat)

		if inv then

			for name, save in pairs(inv) do

				if type(save) == "table" and not seen[name] then

					seen[name] = true

					table.insert(out, { name = name, grade = save.grade or "F" })

				end

			end

		end

	end

	table.sort(out, function(a, b) return a.name < b.name end)

	return out

end

-- ===================== GRADING MINIGAME SOLVER =====================
-- Watches the selection line and presses at the perfect moment. The game reads
-- clicks from SkillTestServiceClient (a Remote-less client module), so we fire
-- the same press path the click handler does: the line-vs-area check happens
-- inside the game on every press, and pressing "perfectly" means clicking when
-- the line is centered on the target arc.

local skillTest = nil

local function getSkillTestParts()

	if skillTest and skillTest.Parent then return skillTest end

	pcall(function()

		skillTest = Players.LocalPlayer.PlayerGui:WaitForChild("Frames", 5)

			:WaitForChild("MainInventory", 5)

			:WaitForChild("ArmorGradingSkillFrame", 5)

			:WaitForChild("SkillTest", 5)

	end)

	if not skillTest then skillTest = nil end

	return skillTest

end

-- the currently shown target arc lives in SkillTest.SelectionArea / PerfectArea;
-- exactly one of Large/Medium/Small/Mini is visible per spawn and .Rotation is
-- the arc center (verified live: line sweeps past it and the game counts a hit)

local function getCurrentTargetArea()

	local st = getSkillTestParts()

	if not st then return nil end

	local sa = st:FindFirstChild("SelectionArea")

	if not sa then return nil end

	for _, name in ipairs({ "Large", "Medium", "Small", "Mini" }) do

		local area = sa:FindFirstChild(name)

		if area and area.Visible then return area end

	end

	return nil

end

-- ===================== AUTO GRADE LOOP =====================
do

	local gradeRunning = false

	-- The game's SkillTestServiceClient exposes lifecycle signals. We use them
	-- to know the TRUE state of a run (instead of guessing from frozen arcs,
	-- which broke runs mid-flight and made the server reject every new grade).

	local SkillTestCtl = nil

	pcall(function()

		-- lobby-only module: timeout so a match-place load never stalls here

		local ok, m = pcall(require, RS.Shared.Services:WaitForChild("SkillTestServiceClient", 5))

		if ok and type(m) == "table" and m.started then SkillTestCtl = m end

	end)

	local inRun = false

	local clicksSeen = 0

	if SkillTestCtl then

		pcall(function()

			SkillTestCtl.started:Connect(function()

				inRun = true

				clicksSeen = 0

			end)

			local function endRun() inRun = false end

			SkillTestCtl.luckRunEnded:Connect(endRun)

			SkillTestCtl.finished:Connect(endRun)

			-- each accepted lock press fires clicked("lock") - our heartbeat

			SkillTestCtl.clicked:Connect(function(kind)

				if kind == "lock" then clicksSeen = clicksSeen + 1 end

			end)

		end)

	end

	-- direct read of the game's live run state through debug.getupvalues: the
	-- exported functions close over the module's private state table, which
	-- holds the exact target center (areaRotation) and perfect half-width.
	-- This cannot be faked by a dead leftover overlay, and gives dead-center
	-- perfect timing even on the fast Mini arcs.

	local function getRunState()

		if not SkillTestCtl or not SkillTestCtl.Start then return nil end

		local ok, ups = pcall(debug.getupvalues, SkillTestCtl.Start)

		if not ok or type(ups) ~= "table" then return nil end

		for _, v in ipairs(ups) do

			if type(v) == "table" and v.phase ~= nil and v.areaRotation ~= nil then

				return v

			end

		end

		return nil

	end

	-- returns the current deviation (degrees) of the line from the target arc center

	local function getLineDeviation()

		local st = getSkillTestParts()

		if not st then return nil end

		local line = st:FindFirstChild("selectionLine")

		if not line or not line.Visible then return nil end

		local area = getCurrentTargetArea()

		if not area then return nil end

		local dev = (line.Rotation - area.Rotation) % 360

		if dev > 180 then dev = dev - 360 end

		return dev

	end

	-- one press: the game reads every press from UserInputService.InputBegan
	-- (keyboard / mouse / touch). A virtual mouse click at screen center is the
	-- most compatible way to reach that handler across executors.

	local function pressLock()

		local st = getSkillTestParts()

		if not st then return false end

		local ok = pcall(function()

			local vim = game:GetService("VirtualInputManager")

			local pos = st.AbsolutePosition

			local size = st.AbsoluteSize

			vim:SendMouseButtonEvent(pos.X + size.X / 2, pos.Y + size.Y / 2, 0, true, game, 0)

			task.wait()

			vim:SendMouseButtonEvent(pos.X + size.X / 2, pos.Y + size.Y / 2, 0, false, game, 0)

		end)

		return ok

	end

	-- the spam burst prompt is a BIG full-screen circle that says "SPAM
	-- CLICK" - it lives OUTSIDE the grading frame tree (it covers the whole
	-- screen while the grading menu is hidden), so scan the entire PlayerGui
	-- for a visible element whose text contains "spam"

	local spamScanCache, spamScanAt = nil, 0

	local function getSpamTarget()

		-- cache the scan for 0.15s: the driver polls ~30x/s and a PlayerGui
		-- tree scan is not free

		if os.clock() - spamScanAt < 0.15 then return spamScanCache end

		spamScanAt = os.clock()

		spamScanCache = nil

		local best, bestArea = nil, 0

		pcall(function()

			for _, d in ipairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do

				if d.Visible and (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then

					if string.find(string.lower(d.Text), "spam", 1, true) then

						-- ignore tiny stray labels ("SPAM" text alone is ~70px
						-- tall, so keep the floor low)

						if d.AbsoluteSize.X >= 60 and d.AbsoluteSize.Y >= 30 then

							local area = d.AbsoluteSize.X * d.AbsoluteSize.Y

							if area > bestArea then best, bestArea = d, area end

						end

					end

				end

			end

		end)

		spamScanCache = best

		return best

	end

	-- one press DURING THE SPAM PHASE: click the "SPAM CLICK" circle itself
	-- (falls back to the dead center of the screen - the game reads global
	-- InputBegan, so any click at all counts) and ALSO fire a key press, since
	-- the spam handler accepts InputBegan from any device

	local function pressSpam()

		local ok = pcall(function()

			local vim = game:GetService("VirtualInputManager")

			local x, y

			local target = getSpamTarget()

			if target then

				local pos, size = target.AbsolutePosition, target.AbsoluteSize

				x, y = pos.X + size.X / 2, pos.Y + size.Y / 2

			else

				-- no overlay found: click the center of the viewport

				local cam = workspace.CurrentCamera

				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)

				x, y = vp.X / 2, vp.Y / 2

			end

			-- mouse click AND key press every time: the spam handler reads
			-- InputBegan from any device, so firing both maximizes the odds a
			-- press lands no matter which input path this build listens on

			vim:SendMouseButtonEvent(x, y, 0, true, game, 0)

			task.wait()

			vim:SendMouseButtonEvent(x, y, 0, false, game, 0)

			vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)

			task.wait()

			vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

		end)

		return ok

	end

	-- (old luck-label reader removed: the cap now counts confirmed green-zone
	-- hits instead of parsing the multiplier text - see TARGET_HITS below)

	local function autoGradeLoop()

		if gradeRunning then return end

		gradeRunning = true

		while getFlag("AutoGradeOn") and isCurrentGen() do

			local stopIdx = tonumber(getFlag("AutoGradeStopTier")) or 6 -- S by default

			local targetItem = getFlag("AutoGradeItem")

			if not targetItem or targetItem == "" then

				task.wait(1)

			else

				local save = nil

				for _, cat in ipairs({ "armors", "gears" }) do

					local inv = getInventoryCategory(cat)

					if inv and inv[targetItem] and type(inv[targetItem]) == "table" then save = inv[targetItem] break end

				end

				local curIdx = save and gradeIndexOf(save.grade) or 1

				if curIdx >= stopIdx then

					-- reached the target tier: done

					RS:SetAttribute("TPL_AutoGradeOn", false)

					if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Grading", targetItem .. " reached " .. tostring(save.grade) .. " - stopped") end) end

					task.wait(0.5)

				elseif inRun then

					-- a run is already live (e.g. from a previous loop pass):
					-- finish driving it instead of starting a second one

					task.wait(0.1)

				else

			-- 1) make sure the inventory / grading menu is OPEN so the run is visible

			-- on screen (the game blocks grading while the menu is closed)

			pcall(function()

					local pg = Players.LocalPlayer.PlayerGui

					local frames = pg:FindFirstChild("Frames")

					local main = frames and frames:FindFirstChild("MainInventory")

					if main then main.Visible = true end

				end)

			-- 1b) start a grade run on the item (consumes a crystal)

			inRun = false

			pcall(function()

				if InventoryFrameCtl then InventoryFrameCtl.gradeStartSignal:Fire(targetItem) end

			end)

				-- wait for REAL confirmation the run began (max 10s): the module's
				-- started signal, a live state table, or a MOVING needle. A dead
				-- leftover overlay also shows a line, but its needle never moves -
				-- only movement (or a state) proves a live run.

				local waited = 0

				local prevRot = nil

				while waited < 10 and getFlag("AutoGradeOn") and not inRun do

					task.wait(0.1)

					waited = waited + 0.1

					if getRunState() and getRunState().phase == "lock" then

						inRun = true

						break

					end

					local st = getSkillTestParts()

					local line = st and st:FindFirstChild("selectionLine")

					if line and line.Visible then

						local rot = line.Rotation

						if prevRot then

							local delta = math.abs(((rot - prevRot + 180) % 360) - 180)

							if delta > 0.5 then inRun = true break end

						end

						prevRot = rot

					end

				end

				if not inRun then

					-- never started (server rejected: no crystals / session busy):

					-- back off and retry next pass; do NOT drive the dead visuals

					task.wait(2)

				end

-- 2) drive the whole minigame by the game's own internal state. The state
				-- table tells us the exact phase: "lock" = line + arc (time the green
				-- zone), "spam" = burst click, "transition"/"outro" = wait. The
				-- ClickCircle is NOT a start prompt (it belongs to the spam phase),
				-- so no UI guessing: press only what the state says.

				local deadline = os.clock() + 180

				local lastClicks = 0

				local lastClickChange = os.clock()

				local lockStreak = 0

				-- CAP SYSTEM (v2): count CONFIRMED green-zone hits instead of reading
				-- the luck label. Every accepted hit fires the game's clicked("lock")
				-- signal (tracked in clicksSeen), so the hit count is exact regardless
				-- of the player's luck upgrades or the pity system - everyone's luck
				-- grows differently per hit, but "12 hits then fail" behaves the same
				-- for everyone. 12 sits in the 10-15 band the user asked for

				local TARGET_HITS = 12

				local startClicks = clicksSeen

				local capped = false -- set once TARGET_HITS confirmed hits: burn the 3 hearts after

				local missCount = 0 -- deliberate misses used to fail the run at the cap

				local lastPressRot = -999

				while os.clock() < deadline and getFlag("AutoGradeOn") and inRun do

					local acted = false

					local state = getRunState()

					local phase = state and state.phase or nil

					-- cap check: confirmed hits this run >= target -> switch to miss
					-- mode (3 presses outside the green = 3 hearts = run failed, and
					-- the grade rolls with whatever luck 12 hits built up)

					if not capped and (clicksSeen - startClicks) >= TARGET_HITS then

						capped = true

						if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Grading", TARGET_HITS .. " hits - failing run now") end) end

					end

					-- SPAM OVERLAY HAS PRIORITY: the big "SPAM CLICK" circle appears
					-- right after the lock minigame, but the state table may still
					-- report another phase (or a phase name we don't know) while it's
					-- up. If we trust the phase first, we never click during the burst
					-- and the game burns a heart per burst - that killed runs ~5x.
					-- So: overlay visible = spam NOW, whatever the state claims

					if not capped and getSpamTarget() then

						pressSpam()

						acted = true

						task.wait(0.03)

					elseif phase == "lock" then

						-- lock: press only when the needle is inside the green
						-- (perfect) zone around the arc's exact center

						local st = getSkillTestParts()

						local line = st and st:FindFirstChild("selectionLine")

						if state and line and line.Visible then

						local dev = ((line.Rotation - state.areaRotation + 180) % 360) - 180

						local half = math.clamp(tonumber(state.areaPerfect) or 6, 2, 10)

						-- require the needle to have moved since the last press
						-- so we never double-fire on the same sweep position

						local moved = math.abs(((line.Rotation - lastPressRot + 180) % 360) - 180) > 1

						if capped then

							-- at 10x luck: miss on purpose. A press outside the target
							-- arc costs one heart; 3 misses = run failed, grade rolled
							-- with the luck we reached

							local missHalf = tonumber(state.areaHalfWidth) or (half * 3)

							if math.abs(dev) > missHalf then

								pressLock()

								missCount = missCount + 1

								acted = true

								task.wait(0.4) -- let the heart-loss feedback play out

								if missCount >= 3 then inRun = false break end -- lost the luck minigame; the spam minigame comes next

							else

								task.wait(0.01) -- wait for the needle to leave the zone

							end

						elseif math.abs(dev) <= half and moved then

								pressLock()

								lastPressRot = line.Rotation

								acted = true

								lockStreak = 0

								task.wait(0.05) -- brief pause while the next arc spawns

							elseif math.abs(dev) > half then

								lockStreak = 0

								task.wait(0.01) -- poll tight so fast sweeps can't slip by

							end

							end

				elseif phase == "spam" then

					-- state says spam but the overlay wasn't found (naming change?):
					-- still hammer - pressSpam falls back to screen center. At the
					-- 10x cap we hold instead (spam clicks can't miss, so they'd
					-- push luck past the cap)

					if not capped then

						pressSpam()

						acted = true

						task.wait(0.03)

					else

						task.wait(0.05)

					end

					elseif phase == "transition" or phase == "outro" then

						-- just wait these out quietly

						task.wait(0.05)

					end

					-- watchdog: if no press registered for a long time while the
					-- run is supposedly live, bail so the outer loop can restart

					if clicksSeen ~= lastClicks then

						lastClicks = clicksSeen

						lastClickChange = os.clock()

					end

					if not acted and os.clock() - lastClickChange > 25 then

						inRun = false

						break

					end

					if not acted then task.wait(0.02) end

				end

				-- 2a-2) POST-RUN SPAM MINIGAME (driven by the game's own state, from
				-- decompiled SkillTestServiceClient): the press handler only counts
				-- when phase == "spam" and not state.won, throttles presses at
				-- 0.05s, and sets state.won = true the moment the spam target is
				-- reached. So: press at the throttle rate while the state says
				-- spam && not won, and stop exactly when won flips - no more
				-- blind clicking after the minigame is already gone. Overlay
				-- detection remains only as a fallback when no state is visible

				do

					local spamWait = os.clock() + 25 -- hard ceiling

					local doneSince = nil

					while os.clock() < spamWait and getFlag("AutoGradeOn") do

						local st = getRunState()

						if st and st.phase == "spam" and not st.won then

							doneSince = nil

							pressSpam()

							task.wait(0.06) -- the game throttles presses at 0.05s; faster is wasted

						elseif st and st.won then

							-- game itself says the spam target was reached: minigame
							-- done, stop clicking after a short settle

							if not doneSince then doneSince = os.clock() end

							if os.clock() - doneSince > 0.8 then break end

							task.wait(0.05)

						else

							-- no live state: fall back to the visible overlay

							local target = getSpamTarget()

							if target then

								doneSince = nil

								pressSpam()

								task.wait(0.06)

							else

								if not doneSince then doneSince = os.clock() end

								if os.clock() - doneSince > 1.5 then break end

								task.wait(0.05)

							end

						end

					end

				end

				-- 2b) fail-safe: if the run is still live when we stop driving
				-- (watchdog bail), close its server session explicitly, or every
				-- future startGrading will be silently rejected (poisoned session).
				-- ONLY on a bail: after a NORMAL end the game can leave phase set
				-- while it rolls the grade, and firing revealGrade then races the
				-- Leave/Take decision with a second grade-resolution call

				do

					local state = getRunState()

					if state and state.phase ~= nil and inRun then

						pcall(function()

							local invCli = require(RS.Shared.Services.InventoryService.InventoryServiceClient)

							invCli._networker:fetch("revealGrade", targetItem, tonumber(state.luckPoints) or 0)

						end)

						inRun = false

						task.wait(0.5)

					end

				end

				-- 3) reward screen: read the ROLLED grade from the frame's
				-- NewTier label (decompiled ArmorGradingRewardFrame: the screen is
				-- MainInventory.ArmorGradingReward with OldVSNewTier.NewTier showing
				-- "<G> TIER"), then decide:
				--   rolled >= "Grade Until" target -> TAKE (decidedSignal true ->
				--   finishGrading applies it server-side; may need a 2nd click for
				--   the "Take Anyway?" confirm)
				--   rolled < target -> LEAVE (not good enough, keep grading)
				-- skip() only fast-forwards the animation and decides NOTHING

				pcall(function()

					local RF = require(RS.Shared.UI.Frames.ArmorGradingRewardFrame)

					-- wait for the reward screen to appear

					local rewardShown = false

					for _ = 1, 25 do

						if RF.isShowing and RF.isShowing() then rewardShown = true break end

						task.wait(0.2)

					end

					if rewardShown then

						-- read the rolled tier from the NewTier label

						local rolledIdx = nil

						pcall(function()

							local pg = Players.LocalPlayer.PlayerGui

							local main = pg:FindFirstChild("Frames") and pg.Frames:FindFirstChild("MainInventory")

							local reward = main and main:FindFirstChild("ArmorGradingReward")

							local cmp = reward and reward:FindFirstChild("OldVSNewTier")

							local newTier = cmp and cmp:FindFirstChild("NewTier")

							local lbl = newTier and (newTier:FindFirstChild("Grade") or newTier)

							local txt = nil

							if lbl and lbl:IsA("TextLabel") then txt = lbl.Text end

							if not txt and lbl then

								local inner = lbl:FindFirstChildOfClass("TextLabel")

								if inner then txt = inner.Text end

							end

							if type(txt) == "string" then

								local g = string.match(txt, "^(%S+)%s*TIER$")

								if g then rolledIdx = gradeIndexOf(g) end

							end

						end)

						local wantTake = true -- default: take (never silently discard)

						if rolledIdx then wantTake = (rolledIdx >= stopIdx) end

						-- fire the game's own MouseButton1Click handler on the real
						-- Take/Leave buttons (MainInventory.ArmorGradingReward.Take/.Leave
						-- per the decompiled show()); VirtualInputManager click as backup

						local function pressButton(which)

							local pg = Players.LocalPlayer.PlayerGui

							local frames = pg:FindFirstChild("Frames")

							local main = frames and frames:FindFirstChild("MainInventory")

							local reward = main and main:FindFirstChild("ArmorGradingReward")

							local btn = reward and reward:FindFirstChild(which)

						if btn and btn:IsA("GuiButton") and btn.Visible then

							-- fire the game's own handler EXACTLY ONCE per press. The old
							-- code fired getconnections AND sent a synthetic VIM click, so
							-- the decision handler ran twice per press. On Take the
							-- "Take Anyway?" confirm absorbed the 2nd call, but Leave has
							-- NO confirm - the double decidedSignal/finishGrading on a
							-- frame mid-teardown hard-crashed the client ("rolled B,
							-- leaving" -> crash)

							local fired = 0

							if getconnections then

								pcall(function()

									for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do

										local ok = pcall(function() conn:Fire() end)

										if ok then fired = fired + 1 end

									end

								end)

							end

							-- synthetic click ONLY as a fallback when no connection could
							-- be fired (naming change / handler moved)

							if fired == 0 then

								pcall(function()

									local vim = game:GetService("VirtualInputManager")

									local p, s = btn.AbsolutePosition, btn.AbsoluteSize

									vim:SendMouseButtonEvent(p.X + s.X / 2, p.Y + s.Y / 2, 0, true, game, 0)

									task.wait()

									vim:SendMouseButtonEvent(p.X + s.X / 2, p.Y + s.Y / 2, 0, false, game, 0)

								end)

							end

							return true

						end

						return false

					end

						-- the frame gates the buttons behind its reveal animation
						-- (u79.interactive): give it a moment before pressing

						task.wait(1.2)

						local which = wantTake and "Take" or "Leave"

						print("[FS Grade] decision:", which, "rolledIdx=", rolledIdx, "stopIdx=", stopIdx)

						pressButton(which)

						if wantTake then

							-- TAKE may need the "Take Anyway?" confirm: keep pressing
							-- (paced 0.8s) until the frame hides

							for _ = 1, 10 do

								if not (RF.isShowing and RF.isShowing()) then break end

								pressButton(which)

								task.wait(0.8)

							end

						else

							-- LEAVE: ONE press, never a re-fire. The game has no
							-- leave-confirm, the frame hides asynchronously, and every
							-- re-fired decision on the mid-teardown frame crashed the
							-- client ("rolled B -> leave" -> dead). Just wait out the
							-- hide animation instead of pressing again

							for _ = 1, 30 do

								if not (RF.isShowing and RF.isShowing()) then break end

								task.wait(0.2)

							end

							task.wait(1.5) -- let the game finish its teardown before the next run starts

						end

						print("[FS Grade] decision done:", which)

						if _G.FS_Notify then

							pcall(function()

								local rolledName = rolledIdx and GRADE_NAMES[rolledIdx] or "?"

								_G.FS_Notify("Auto Grading", "rolled " .. rolledName .. " -> " .. (wantTake and "TAKE" or "leave"))

							end)

						end

					end

				end)

				task.wait(1)

				end

			end

		end

		gradeRunning = false

	end

	task.spawn(autoGradeLoop)

	_G.FS_StartAutoGrade = function(on)

		RS:SetAttribute("TPL_AutoGradeOn", on)

		if on then task.spawn(autoGradeLoop) end

	end

end

-- ===================== LOBBY TAB: AUTO UPGRADE + CHESTS UI =====================
do

	-- the Nebula MultiDropdown pins a built-in "Select All" row at the top of
	-- its option list (it flips to "Deselect All" once everything is picked).
	-- The user wants the "Select All" state but not the "Deselect All"/"Select
	-- None" one: rename the row back to "Select All" whenever it flips, so the
	-- row stays visible and always says "Select All" (clicking it while
	-- everything is picked clears the list - the label is just fixed text)
	task.spawn(function()

		local hui = nil

		pcall(function() hui = gethui and gethui() end)

		while true do

			task.wait(0.5)

			pcall(function()

				local root = hui or game.CoreGui

				local nebula = root:FindFirstChild("NebulaUI")

				if nebula then

					for _, d in ipairs(nebula:GetDescendants()) do

						if d:IsA("TextButton") and (d.Text == "Select None" or d.Text == "Deselect All") then

							d.Text = "Select All"

						end

					end

				end

			end)

		end

	end)

	local secUpg = lobby:CreateSection({ name = "Auto Upgrade" })

	-- item picker: one multi-select dropdown (the "Select All" toggle inside the
	-- dropdown clears to "Select None" when everything is already picked)
	local function upgradeOptions()

		local opts = {}

		for _, it in ipairs(getUpgradableItems()) do

			table.insert(opts, it.name)

		end

		return opts

	end

	local selDD = secUpg:CreateDropdown({

		name = "Upgrade Items",

		multiSelect = true,

		options = upgradeOptions(),

		value = {},

		noreg = true,

		callback = function(list)

			-- picking every option means "everything" -> store empty (= all)
			local opts = upgradeOptions()

			local picked = {}

			for _, n in ipairs(list) do picked[n] = true end

			local all = #opts > 0

			for _, n in ipairs(opts) do

				if not picked[n] then all = false break end

			end

			if all then

				setSelectedList({})

			else
				setSelectedList(list)

			end

		end,

	})

	secUpg:CreateToggle({

		name = "Auto Upgrade Items",

		value = getFlag("AutoUpgradeOn"),

		callback = function(v)

			if _G.FS_StartAutoUpgrade then _G.FS_StartAutoUpgrade(v) end

		end,

	})

	-- ==================== AUTO SKILL TREE UI ====================
	local secSkill = lobby:CreateSection({ name = "Auto Skill Tree" })

	local skillIds = getSkillIds()

	local skillDD = secSkill:CreateDropdown({

		name = "Skills To Buy",

		multiSelect = true,

		options = skillIds,

		value = {},

		noreg = true,

		callback = function(list)

			local picked = {}

			for _, n in ipairs(list) do picked[n] = true end

			local all = #skillIds > 0

			for _, n in ipairs(skillIds) do

				if not picked[n] then all = false break end

			end

			if all then

				RS:SetAttribute("TPL_AutoSkillSelList", "")

			else

				RS:SetAttribute("TPL_AutoSkillSelList", table.concat(list, ","))

			end

		end,

	})

	secSkill:CreateToggle({

		name = "Auto Skill Tree Upgrade",

		value = getFlag("AutoSkillTreeOn"),

		callback = function(v)

			if _G.FS_StartAutoSkill then _G.FS_StartAutoSkill(v) end

		end,

	})

	-- ==================== AUTO GRADING UI ====================
	local secGrade = lobby:CreateSection({ name = "Auto Grading (Perfect)" })

	local gradables = getGradableItems()

	local gradeNames = {}

	for _, g in ipairs(GRADE_NAMES) do table.insert(gradeNames, g) end

	-- which tier to stop grading an item at (index -> name)

	local function stopTierName()

		local idx = math.clamp(tonumber(getFlag("AutoGradeStopTier")) or 6, 1, #gradeNames)

		return gradeNames[idx]

	end

	secGrade:CreateDropdown({

		name = "Item To Grade",

		search = true,

		options = (function()

			local opts = {}

			for _, it in ipairs(gradables) do table.insert(opts, it.name) end

			return opts

		end)(),

		value = getFlag("AutoGradeItem") or gradables[1] and gradables[1].name or nil,

		noreg = true,

		callback = function(v)

			if type(v) == "string" then RS:SetAttribute("TPL_AutoGradeItem", v) end

		end,

	})

	secGrade:CreateDropdown({

		name = "Grade Until",

		options = gradeNames,

		value = stopTierName(),

		noreg = true,

		callback = function(v)

			for i, g in ipairs(gradeNames) do

				if g == v then RS:SetAttribute("TPL_AutoGradeStopTier", i) break end

			end

		end,

	})

	secGrade:CreateToggle({

		name = "Auto Grade (Perfect)",

		value = getFlag("AutoGradeOn"),

		callback = function(v)

			if _G.FS_StartAutoGrade then _G.FS_StartAutoGrade(v) end

		end,

	})

	local secChest = lobby:CreateSection({ name = "Auto Open Chests" })

	secChest:CreateToggle({

		name = "Auto Open All Chests",

		value = getFlag("AutoOpenChestsOn"),

		callback = function(v)

			if _G.FS_StartAutoChests then _G.FS_StartAutoChests(v) end

		end,

	})

	local batchStat = secChest:CreateStat({ name = "Batch Size", value = tostring(getMaxBatch()) })

	task.spawn(function()

		while true do

			task.wait(3)

			pcall(function() batchStat.Set("x" .. tostring(getMaxBatch())) end)

		end

	end)

end

-- ===================== MAIN TAB: AUTO FARM =====================
-- Flight-based auto farm for the round (Volcano etc). The character hovers
-- ABOVE the enemy cluster so melee enemies can't reach it, while the game's own
-- weapons auto-attack whatever is in range (no attack driving here). Enemy
-- PROJECTILES are the only real threat in the air: they fly as models under
-- workspace.VFX (e.g. Fireball), so a velocity-based dodge sidesteps when a
-- shot's future path passes near the character. Orb collecting is a separate
-- toggle: the server grants XP on its own ~0.6s distance tick, so "Auto
-- Collect Orbs" flies a smooth swoop down INTO the orb cluster (movement, not
-- teleport - a teleport would be ignored server-side) and holds there until
-- the orbs vacuum in, then climbs back to the fight hover.

local RunServiceFarm = game:GetService("RunService")

if getFlag("Farm_Height") == nil then RS:SetAttribute("TPL_Farm_Height", 28) end
if getFlag("Farm_OrbDwell") == nil then RS:SetAttribute("TPL_Farm_OrbDwell", 2) end
-- hover/dodge flight responsiveness (the mover's lerp strength); higher = snappier
if getFlag("Farm_Speed") == nil then RS:SetAttribute("TPL_Farm_Speed", 7) end

local farmOn = false
local farmCollectOn = false
-- portal priority handoff: while Auto Enter Portal is walking/holding, the
-- farm loop must NOT write moverGoal — both loops otherwise fight over the
-- same flight target every frame. The portal is the end of the run: it wins.
local portalDriving = false

-- // SCENE READS //--

-- in a round = the match workspace exists (Lobby exists only in the lobby)
local function inRound()

	return workspace:FindFirstChild("Enemies") ~= nil and workspace:FindFirstChild("Lobby") == nil

end

-- nearest walkable floor under a point: raycast DOWN from just ABOVE the point,
-- skipping INVISIBLE boundary geometry (Grasslands shells the whole arena in a
-- giant transparent wall union whose top eats rays from above and reports a
-- fake floor at ~Y114 — every map with such a shell hovered on the shell, not
-- the floor). Walks through transparent/boundary hits until a real surface.
-- Fail-open: raycast error / no hit => assume ground at the point itself.
local function groundBelow(x, z, fromY)

	local hitY = nil

	pcall(function()

			-- match maps spawn HIGH (every world template's 'ground level' marker
			-- sits at Y~161.5, island top ~164): always cast from a start above
			-- the highest possible floor, not from fromY-8 (a Y52 start begins
			-- UNDER the map floor on every world => no hit => hover fell back to
			-- Y3+height and the farm flew away from spawn on tall maps)
			local origin = Vector3.new(x, math.max(fromY or 60, 340) + 20, z)

		local params = RaycastParams.new()

		params.FilterType = Enum.RaycastFilterType.Exclude

		-- FilterDescendantsInstances returns a COPY: table.insert on it never
		-- writes back, so the old boundary-walk re-hit the same invisible shell
		-- 6 times and returned nil. Rebuild the list locally and ASSIGN it.
		local exclude = { Players.LocalPlayer.Character }

		local last = nil

		for _ = 1, 12 do

			params.FilterDescendantsInstances = exclude

			local res = workspace:Raycast(origin, Vector3.new(0, -800, 0), params)

			if not res or not res.Instance then break end

			local inst = res.Instance

			local boundary = inst.Transparency >= 0.99 or inst.Name == "Wall" or inst.Name == "selectionLine"

			if not boundary then

				hitY = res.Position.Y

				break

			end

			if inst == last then break end -- filter write failed; don't spin

			last = inst

			exclude[#exclude + 1] = inst

		end

	end)

	return hitY

end

-- one enemy sample: position of the live melee threat (Humanoid alive, has HRP
-- or a Hitbox part). Enemy rigs are R6 models with a Humanoid + Hitbox part.
local function enemyPos(e)

	if not e:IsA("Model") then return nil end

	local hum = e:FindFirstChildOfClass("Humanoid")

	if hum and hum.Health <= 0 then return nil end

	local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Hitbox") or e:FindFirstChild("Torso")

	if hrp and hrp:IsA("BasePart") then return hrp.Position end

	local pp = e.PrimaryPart or e:FindFirstChildWhichIsA("BasePart", true)

	if pp then return pp.Position end

	return nil

end

-- cluster center + count of live enemies (dist-filtered MEDIAN per axis: a few
-- despawn ghosts parked tens of thousands of studs away must not drag the
-- hover point off the map)
local farmScanCache, farmScanAt = nil, 0

local function getFarmScan()

	if os.clock() - farmScanAt < 0.4 then return farmScanCache end

	farmScanAt = os.clock()

	farmScanCache = nil

	local enemies = workspace:FindFirstChild("Enemies")

	if not enemies then return nil end

	local xs, ys, zs = {}, {}, {}

	local n = 0

	local myPos = nil

	local char = Players.LocalPlayer.Character

	local myHrp = char and char:FindFirstChild("HumanoidRootPart")

	if myHrp then myPos = myHrp.Position end

	for _, e in ipairs(enemies:GetChildren()) do

		local p = enemyPos(e)

		if p and p.Y > -50 and p.Y < 300 then

			-- only enemies near the character define the hover point (the map
			-- floor is 1500x1500; far waves can spawn anywhere)

			if not myPos or (Vector3.new(p.X, 0, p.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude < 400 then

				n = n + 1

				table.insert(xs, p.X)
				table.insert(ys, p.Y)
				table.insert(zs, p.Z)
			end

		end

	end

	if n == 0 then return nil end

	table.sort(xs)
	table.sort(ys)
	table.sort(zs)

	local mid = math.ceil(n / 2)

	farmScanCache = { pos = Vector3.new(xs[mid], ys[mid], zs[mid]), count = n }

	return farmScanCache

end

-- // CHARACTER HELPERS //--

local function getCharParts()

	local char = Players.LocalPlayer.Character

	if not char then return nil end

	local hum = char:FindFirstChildOfClass("Humanoid")

	local hrp = char:FindFirstChild("HumanoidRootPart")

	if not hum or not hrp then return nil end

	return char, hum, hrp

end

-- the game death-parks by ANCHORING the HRP: a server-owned anchored assembly
-- silently rolls back client CFrame writes, so flight must unanchor first
local function ensureFlightReady(hrp)

	if hrp.Anchored then hrp.Anchored = false end

end

-- // DODGE: velocity-projectile sidestep //--
-- enemy shots are models under workspace.VFX moving with AssemblyLinearVelocity
-- (bananarangs move by CFrame - tracked via position delta). If a shot's
-- FUTURE path (next ~0.7s) passes within `radius` of the character, sidestep
-- perpendicular to the shot's travel direction.
local dodgeDir = 1 -- alternates so repeated shots don't push us off the map

local dodgeUntil = 0

local dodgeVec = Vector3.zero

local lastShotPos = {} -- [model] = last position, for CFrame-movers
local shotFirstSeen = {} -- [model] = first position we saw it at
local shotSeenAt = {} -- [model] = os.clock() of first sighting

local function projectileDodge(hrp, dt)

	local vfx = workspace:FindFirstChild("VFX")

	if not vfx then return Vector3.zero end

	local myPos = hrp.Position

	local now = os.clock()

	-- prune stale trackers

	for m in pairs(lastShotPos) do

		if not m.Parent then lastShotPos[m] = nil end

	end

	for m in pairs(shotFirstSeen) do

		if not m.Parent then shotFirstSeen[m] = nil shotSeenAt[m] = nil end

	end

	for _, m in ipairs(vfx:GetChildren()) do

		if m:IsA("Model") then

			-- only projectile-looking models: they fly; skip loot/XP/keys

			local nm = m.Name

			if nm ~= "xp" and nm ~= "keys" and nm ~= "InfernoKey" and nm ~= "Chest" then

				local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)

				if pp then

					local p, v = pp.Position, pp.AssemblyLinearVelocity

					-- OWN-SHOT FILTER: our own weapon projectiles spawn in the same
					-- workspace.VFX folder with the SAME names as enemy shots (no owner
					-- tag exists client-side). A shot FIRST SEEN right on top of the
					-- character is ours (enemy shots come from the swarm, far away);
					-- flag it once and skip that model for its whole life — otherwise
					-- every own shot triggered a +16-stud dodge and the farm surfed
					-- across the map
					if shotFirstSeen[m] == nil then
						shotFirstSeen[m] = ((p - myPos).Magnitude < 25) and true or false
						shotSeenAt[m] = now
					end
					if shotFirstSeen[m] == true then
						-- flagged as our own shot at first sighting: never dodge it
					else

					local speed = v.Magnitude

					if speed < 1 then

						-- CFrame-mover (bananarang): estimate velocity from the
						-- position delta

						local prev = lastShotPos[m]

						if prev then

							v = (p - prev) / math.max(dt, 1 / 60)

							speed = v.Magnitude

						end

						lastShotPos[m] = p

					end

					-- a projectile is a FAST thing heading roughly at us

					if speed > 25 then

						local toMe = myPos - p

						local dist = toMe.Magnitude

						if dist < 130 then

							local dir = v.Unit

							-- closest approach of its path to my position

							local t = math.clamp(toMe:Dot(dir), 0, 0.7 * speed)

							local closest = p + dir * t

							local miss = (myPos - closest).Magnitude

							if miss < 14 and now > dodgeUntil then

								-- sidestep perpendicular to the shot's travel,
								-- keeping some height

								local perp = Vector3.new(-dir.Z, 0, dir.X)

								if perp.Magnitude < 0.1 then perp = Vector3.new(1, 0, 0) else perp = perp.Unit end

								-- pick the side that goes TOWARD the shot's origin
								-- side (dodging "behind" the shot path)

								local side = ((p - myPos):Dot(perp) > 0) and 1 or -1

								dodgeDir = -dodgeDir

								dodgeVec = perp * side * 16 + Vector3.new(0, 6, 0)

								dodgeUntil = now + 0.45

								break

							end

						end

					end

					end -- speed<1 / if-true(pp block close)

				end


			end

		end

	end

	if now < dodgeUntil then return dodgeVec end

	return Vector3.zero

end

-- // MAIN FARM LOOP (OP v2) //--

local farmThread = nil

local OP_RANGED = { Fireball = true, ArrowShot = true, Bananarang = true }

-- enemies that shoot: keep them OFF the hover-center so their shots arc
-- wide, but their radius is still counted so the auto-attack reaches them
local function isRanged(e)
	if OP_RANGED[e.Name] then return true end
	return false
end

-- // SMOOTH MOVER: framerate-based flight (kills the micro-teleport stutter) //--
-- The old loop moved the character with one lerp step per 0.05s tick (20 Hz).
-- Now the scan loop only computes the goal; a Heartbeat connection glides the
-- character toward it every frame with dt-based exponential smoothing.
local orbitAngle = 0
local moverGoal = nil
local moverLook = nil
local moverConn = nil
local function ensureMover()
	if moverConn then return end
	local rs = game:GetService("RunService")
	moverConn = rs.Heartbeat:Connect(function(dt)
		pcall(function()
			if not farmOn and not farmCollectOn then return end
			if not moverGoal then return end
			local char = Players.LocalPlayer.Character
			local h = char and char:FindFirstChild("HumanoidRootPart")
			if not h then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health <= 0 then return end
			local cur = h.Position
			-- flight speed: exponential smoothing strength, user-set (Farm_Speed,
			-- default 7 = the original feel). Clamp hard: 1 crawls, 30 teleport-snaps
			local spd = math.clamp(tonumber(getFlag("Farm_Speed")) or 7, 1, 30)
			local alpha = 1 - math.exp(-dt * spd)
			local step = cur:Lerp(moverGoal, alpha)
			local lt = moverLook or step
			h.CFrame = CFrame.lookAt(step, Vector3.new(lt.X, step.Y, lt.Z))
			h.AssemblyLinearVelocity = Vector3.zero
		end)
	end)
end

-- orbit center: the arena floor part is the playable area (Map is a Folder,
-- GetBoundingBox doesn't exist on Folders and the pcall used to fail silently,
-- making the character orbit ITSELF). Floor is 1500x1500 centered on the map.
local function getMapCenter(fallback)
	local map = workspace:FindFirstChild("Map")
	if map then
		local floor = map:FindFirstChild("Floor")
		if floor and floor:IsA("BasePart") then
			return floor.Position
		end
		-- fallback: extent center over all BasePart descendants
		local minv, maxv = nil, nil
		pcall(function()
			for _, d in ipairs(map:GetDescendants()) do
				if d:IsA("BasePart") then
					local p = d.Position - d.Size / 2
					local q = d.Position + d.Size / 2
					minv = minv and minv:Min(p) or p
					maxv = maxv and maxv:Max(q) or q
				end
			end
		end)
		if minv and maxv then return (minv + maxv) / 2 end
	end
	return fallback
end
-- playable radius: half the Floor's XZ extent (orbit must stay INSIDE the map)
local function getMapRadius(fallback)
	local map = workspace:FindFirstChild("Map")
	if map then
		local floor = map:FindFirstChild("Floor")
		if floor and floor:IsA("BasePart") then
			return math.min(floor.Size.X, floor.Size.Z) * 0.5
		end
	end
	return fallback
end

local function farmLoop()

	while (farmOn or farmCollectOn) and isCurrentGen() do

		if not inRound() then

			task.wait(1)

		else

			local ok, err = pcall(function()

				local char, hum, hrp = getCharParts()

				if not char or not hum or not hrp then task.wait(0.5) return end

				if hum.Health <= 0 then

					-- dead: zero writes until respawn (verified death-loop regression)
					task.wait(1)
					return
				end

				-- Auto Enter Portal owns the mover right now (end of the run):
				-- touch nothing, not even flight setup, until it is done
				if portalDriving then task.wait(0.1) return end

				ensureFlightReady(hrp)

				local hoverH = tonumber(getFlag("Farm_Height")) or 28
				local orbDwell = 2 -- fixed: swoop dwell (setting removed)
				if RS:GetAttribute("TPL_FarmMode") == "🧪 Auto-Dodge — In Testing" then RS:SetAttribute("TPL_FarmMode", "Auto-Dodge") end
				local farmMode = getFlag("FarmMode") or "Orbit Center"
				local orbitR = tonumber(getFlag("Farm_OrbitRadius")) or 40
				local orbitH = tonumber(getFlag("Farm_OrbitHeight")) or hoverH
				local orbitSpd = tonumber(getFlag("Farm_OrbitSpeed")) or 20

				-- // FULL SCAN: enemies + ranged flags + danger zones + orbs in one walk //--
				local enemies = workspace:FindFirstChild("Enemies")
				local vfx = workspace:FindFirstChild("VFX")
				local myPos = hrp.Position
				local myXZ = Vector3.new(myPos.X, 0, myPos.Z)

				local meleeXs, meleeYs, meleeZs, meleeN = {}, {}, {}, 0
				local allXs, allYs, allZs, allN = {}, {}, {}, 0
				local orbXs, orbYs, orbZs, orbN = {}, {}, {}, 0
				local dangerUntil = 0

				if enemies and farmMode ~= "Orbit Center" then
					for _, e in ipairs(enemies:GetChildren()) do
						local p = enemyPos(e)
						if p and p.Y > -50 and p.Y < 300
							and (Vector3.new(p.X, 0, p.Z) - myXZ).Magnitude < 400 then
							allN = allN + 1
							table.insert(allXs, p.X); table.insert(allYs, p.Y); table.insert(allZs, p.Z)
							if not isRanged(e) then
								meleeN = meleeN + 1
								table.insert(meleeXs, p.X); table.insert(meleeYs, p.Y); table.insert(meleeZs, p.Z)
							end
						end
					end
				end

				-- // DANGER ZONES: ground telegraphs (DangerArea / SlashZone) — walk out early //--
				if vfx then
					for _, m in ipairs(vfx:GetChildren()) do
						local nm = m.Name
						if nm == "DangerArea" or nm == "SlashZone" then
							local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
							if pp then
								local dp = pp.Position
								-- roughly circular: radius from part size
								local rad = math.max(pp.Size.X, pp.Size.Z) * 0.5 + 4
								local dx, dz = myPos.X - dp.X, myPos.Z - dp.Z
								if dx * dx + dz * dz < rad * rad then
									-- walk to the nearest edge + margin
									local dist = math.sqrt(dx * dx + dz * dz)
									local ux, uz = (dist > 0.1) and dx / dist or 1, (dist > 0.1) and dz / dist or 0
									local push = Vector3.new(ux, 0, uz) * (rad - dist + 6)
									dangerUntil = os.clock() + 0.6
									dodgeVec = push
									dodgeUntil = dangerUntil
								end
							end
						elseif nm == "xp" or nm == "keys" or nm == "InfernoKey" then
							local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
							if pp then
								local p = pp.Position
								if (Vector3.new(p.X, 0, p.Z) - myXZ).Magnitude < 250 then
									orbN = orbN + 1
									table.insert(orbXs, p.X); table.insert(orbYs, p.Y); table.insert(orbZs, p.Z)
								end
							end
						end
					end
				end

				-- median of each group (ghost positions can't drag the point)
				local function med(xs, ys, zs, n)
					if n == 0 then return nil end
					table.sort(xs); table.sort(ys); table.sort(zs)
					local mid = math.ceil(n / 2)
					return Vector3.new(xs[mid], ys[mid], zs[mid])
				end

				local meleeC = med(meleeXs, meleeYs, meleeZs, meleeN)
				local allC = med(allXs, allYs, allZs, allN)
				local orbC = med(orbXs, orbYs, orbZs, orbN)

				-- hover over MELEE cluster when it exists (they can't reach up there,
				-- and ranged shots from the far side are less likely to arc at us)
				-- else fall back to the all-enemy cluster
				local fightC = meleeC or allC

				-- fallback ground = character's own altitude, NOT 3: on high-spawned
				-- maps a missed raycast used to drop the hover target to Y~31 while
				-- enemies sat at Y~165 => 'flying away from spawn'
				local myGroundGuess = myPos.Y - hoverH
				local target
				local lookT = fightC
				if farmMode == "Orbit Center" then
					-- orbit fly INSIDE the map, around the arena floor center
					orbitAngle = orbitAngle + math.rad(orbitSpd) * 0.1
					local c = getMapCenter(myPos)
					-- clamp the radius so the circle stays on the playable floor
					local maxR = (getMapRadius(300) or 300) - 30
					if orbitR > maxR then orbitR = maxR end
					local gy = groundBelow(c.X, c.Z, 150) or myGroundGuess
					-- void guard: shrink the radius until the orbit point has ground under it
					local effR = orbitR
					for _ = 1, 4 do
						local gx = c.X + math.cos(orbitAngle) * effR
						local gz = c.Z + math.sin(orbitAngle) * effR
						if groundBelow(gx, gz, 60) then break end
						effR = effR * 0.75
					end
					target = Vector3.new(c.X + math.cos(orbitAngle) * effR, gy + orbitH, c.Z + math.sin(orbitAngle) * effR)
					lookT = c
				elseif fightC and farmOn then
					local gy = groundBelow(fightC.X, fightC.Z, 60) or myGroundGuess
					target = Vector3.new(fightC.X, gy + hoverH, fightC.Z)
				elseif allC and farmOn then
					local gy = groundBelow(allC.X, allC.Z, 60) or myGroundGuess
					target = Vector3.new(allC.X, gy + hoverH, allC.Z)
				else
					-- no enemies (wave break): hover where we are
					local gy = groundBelow(myPos.X, myPos.Z, 60) or myGroundGuess
					target = Vector3.new(myPos.X, gy + hoverH, myPos.Z)
				end

				-- // ORB SWOOP: dip into the cluster, hold for the dwell, climb back //--
				local swooping = false
				-- orb collection works in EVERY mode: Orbit Center swoops down to
				-- the cluster too (it used to be hover-only and never collected)
				if farmCollectOn and orbC then
					local groundY = groundBelow(orbC.X, orbC.Z, 60) or myGroundGuess
					-- orb model pivot sits at pickup height +2 already (per the game's
					-- CollectableClient): dip just under the orb pivot, and never above
					-- the fight hover height (collect dips BELOW the hover, never rises)
					local gy = groundBelow(fightC and fightC.X or myPos.X, fightC and fightC.Z or myPos.Z, 60) or myGroundGuess
					local hoverCeiling = gy + hoverH - 5
					local wantY = math.max(orbC.Y - 2, groundY + 4)
					target = Vector3.new(orbC.X, math.min(wantY, hoverCeiling), orbC.Z)
					swooping = true
				end

				-- // MOVE: hand the goal to the Heartbeat mover (smooth, per-frame) //--

				-- Orbit Center = PURE orbit: never dodge anything (projectiles or
				-- danger zones), just fly the circle
				local dodge = Vector3.zero
				if farmMode ~= "Orbit Center" then
					dodge = projectileDodge(hrp, 0.05)
					if os.clock() < dangerUntil then dodge = dodge + dodgeVec end
				end

				local goal = target + dodge

				-- dodge bound: dodge offsets must stay NEAR the fight target — the
				-- mover otherwise surfs across the map when projectiles keep coming
				-- from one side (verified: +16 studs every 0.45s, never resets)
				do
					local off = goal - target
					local maxOff = 25
					if off.Magnitude > maxOff then goal = target + off.Unit * maxOff end
				end

				-- void guard: if the goal would be over empty space, pull back to my XZ
				local goalGround = groundBelow(goal.X, goal.Z, 60)
				if not goalGround then
					goal = Vector3.new(myPos.X, target.Y, myPos.Z) + dodge
				end

				ensureMover()
				moverGoal = goal
				moverLook = lookT

				task.wait(0.1)

			end)

			if not ok then warn("[FS Farm] " .. tostring(err)) end

		end

	end

end

_G.FS_StartAutoFarm = function(on)

	farmOn = on

	RS:SetAttribute("TPL_FarmOn", on)

	if on and not farmThread then

		farmThread = task.spawn(function()

			farmLoop()

			farmThread = nil

		end)

	end

end

_G.FS_StartAutoCollect = function(on)

	farmCollectOn = on
RS:SetAttribute("TPL_FarmCollectOn", on)

end

-- ===================== AUTO ENTER PORTAL (Final Swarm) =====================
-- At the end of a round the Final Swarm starts and a BossPortal rises with a
-- PortalPrompt (tag "portalPrompt") on it. Staying OUT of the portal grows the
-- loot multiplier; walking in and holding the prompt ends the run and banks it.
-- Auto Enter Portal parks the character at the portal and holds the prompt as
-- soon as the multiplier reaches the target.
-- How the game tracks it (verified in WaveDisplay / GameServiceClient):
--   * HUD.Top.FinalSwarmBar.ProgressBar.Bar.CurrentMult is a NumberValue the
--     HUD itself tweens every wave tick — reads as the live loot multiplier
--   * the portal prompt only becomes usable when the HUD enabled it
--   * ProximityPromptService:PromptButtonHoldBegan/Ended drive the custom HUD
--     hold bar, so the prompt can be triggered without being near-screen
do
	local function getPortalPrompt()
		local p = nil
		pcall(function()
			local map = workspace:FindFirstChild("Map")
			local bp = map and map:FindFirstChild("BossPortal")
			if bp then p = bp:FindFirstChild("PortalPrompt") end
		end)
		return p
	end

	-- live loot multiplier: 0 until the Final Swarm bar exists / fills
	local function getCurrentMult()
		local v = 0
		pcall(function()
			local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
			local hud = pg and pg:FindFirstChild("HUD")
			local top = hud and hud:FindFirstChild("Top")
			local bar = top and top:FindFirstChild("FinalSwarmBar")
			local prog = bar and bar:FindFirstChild("ProgressBar")
			local barPart = prog and prog:FindFirstChild("Bar")
			local cur = barPart and barPart:FindFirstChild("CurrentMult")
			v = cur and cur.Value or 0
		end)
		return tonumber(v) or 0
	end

	local function holdPortalPrompt(prompt)
		-- fire the game's own hold flow: began -> wait the hold duration -> ended
		pcall(function()
			local PPS = game:GetService("ProximityPromptService")
			PPS:TriggerPromptButtonHoldBegan(prompt)
			task.wait(math.max(prompt.HoldDuration or 0, 0) + 0.35)
			PPS:TriggerPromptButtonHoldEnded(prompt)
		end)
		-- belt and braces: some builds only accept the direct prompt signal
		pcall(function()
			prompt:InputHoldBegin()
			task.wait(math.max(prompt.HoldDuration or 0, 0) + 0.35)
			prompt:InputHoldEnd()
		end)
		-- last resort: real key hold at the prompt's screen position
		pcall(function()
			local VIM = game:GetService("VirtualInputManager")
			local cam = workspace.CurrentCamera
			local pp = prompt.Parent and (prompt.Parent.PrimaryPart or prompt.Parent:FindFirstChildWhichIsA("BasePart", true))
			if VIM and pp and cam then
				local sp, on = cam:WorldToViewportPoint(pp.Position)
				if on then
					VIM:SendKeyEvent(true, prompt.KeyboardKeyCode or Enum.KeyCode.E, false, game)
					task.wait(math.max(prompt.HoldDuration or 0, 0) + 0.35)
					VIM:SendKeyEvent(false, prompt.KeyboardKeyCode or Enum.KeyCode.E, false, game)
				end
			end
		end)
	end

	local function autoPortalLoop()
		if portalRunning then return end
		portalRunning = true
		while getFlag("AutoEnterPortalOn") and isCurrentGen() do
			local okE, err = pcall(function()
				if not inRound() then return end
				local prompt = getPortalPrompt()
				-- no portal yet, or the HUD hasn't armed it: nothing to do
				if not prompt or not prompt.Enabled or prompt.MaxActivationDistance <= 0 then return end
				local mult = getCurrentMult()
				local target = tonumber(getFlag("PortalTargetMult")) or 3
				-- not at the target multiplier yet: keep farming, keep banking later
				if mult < target then return end
				-- walk/park into the prompt's activation range first
				local hrp = getCharacterHRP()
				local holder = prompt.Parent
				local pp = holder and (holder.PrimaryPart or holder:FindFirstChildWhichIsA("BasePart", true))
				if not hrp or not pp then return end
				local anchor = pp.Position + Vector3.new(0, 2, 0)
				local deadline = os.clock() + 12
				while os.clock() < deadline and getFlag("AutoEnterPortalOn") and inRound() do
					-- inside activation range already?
					if (hrp.Position - anchor).Magnitude <= math.min(prompt.MaxActivationDistance, 14) then break end
					-- park through the flight mover when the farm drives it, else
					-- set the pivot directly (portal prompt reads 3D distance)
					if farmOn or farmCollectOn then
						-- priority handoff: block the farm loop from writing moverGoal
						-- for the whole walk, otherwise the two loops fight every frame
						portalDriving = true
						moverGoal = anchor
						moverLook = anchor
						ensureMover()
					else
						pcall(function() hrp.CFrame = CFrame.lookAt(anchor, anchor + Vector3.new(0, 0, 1)) end)
					end
					task.wait(0.1)
				end
				if not (getFlag("AutoEnterPortalOn") and inRound()) then portalDriving = false return end
				-- still at/above target? (the multiplier can only go up, but the
				-- toggle could have been flipped mid-walk)
				if getCurrentMult() < (tonumber(getFlag("PortalTargetMult")) or 3) then
					portalDriving = false
					return
				end
				holdPortalPrompt(prompt)
				-- run ends here either way: release the mover, turn the toggle off
				portalDriving = false
				RS:SetAttribute("TPL_AutoEnterPortalOn", false)
				if _G.FS_Notify then pcall(function() _G.FS_Notify("Auto Enter Portal", "mult " .. string.format("%.2f", getCurrentMult()) .. " -> entered the portal") end) end
				task.wait(3)
			end)
			if not okE then warn("[FS AutoPortal] " .. tostring(err)) end
			-- hand the mover back no matter how the tick ended (error, timeout,
			-- toggle off, or the portal fired) — the farm must never stay locked out
			portalDriving = false
			task.wait(0.5)
		end
		portalRunning = false
	end
	task.spawn(autoPortalLoop)
	_G.FS_StartAutoPortal = function(on)
		RS:SetAttribute("TPL_AutoEnterPortalOn", on)
		if on then task.spawn(autoPortalLoop) end
	end
end

local secFarm = tab:CreateSection({ name = "Auto Farm" })

secFarm:CreateToggle({

	name = "Auto Farm",

	value = getFlag("FarmOn"),

	callback = function(v)

		if _G.FS_StartAutoFarm then _G.FS_StartAutoFarm(v) end

	end,

})

-- mode-conditional settings: the dropdown shows/hides the elements that
-- belong to each mode (SetVisible comes from the UI lib)
local hoverElems, orbitElems = {}, {}

local farmModeDD = secFarm:CreateDropdown({

	name = "Farm Mode",

	desc = "Auto-Dodge hovers over enemies and dodges; Orbit just circles the map center",			options = { "🧪 Auto-Dodge — In Testing", "Orbit Center" },
		value = getFlag("FarmMode") or "Orbit Center",

	callback = function(v)
		if type(v) == "string" then
			-- the display label carries the "In Testing" badge; strip it so the
			-- saved flag stays the plain mode name every reader expects
			RS:SetAttribute("TPL_FarmMode", (v == "🧪 Auto-Dodge — In Testing") and "Auto-Dodge" or v)
			local orbit = (v == "Orbit Center")
			for _, el in ipairs(hoverElems) do pcall(function() el.SetVisible(not orbit) end) end
			for _, el in ipairs(orbitElems) do pcall(function() el.SetVisible(orbit) end) end
		end
	end,

})

local function regHover(el) table.insert(hoverElems, el) return el end
local function regOrbit(el) table.insert(orbitElems, el) return el end

regOrbit(secFarm:CreateSlider({

	name = "Orbit Speed",

	desc = "Orbit Center mode: degrees per second around the map center",

	range = { 5, 180 },

	increment = 5,

	value = getFlag("Farm_OrbitSpeed") or 20,

	callback = function(v) RS:SetAttribute("TPL_Farm_OrbitSpeed", v) end,

}))

regOrbit(secFarm:CreateSlider({

	name = "Orbit Radius",

	desc = "Orbit Center mode: distance from the map center (clamped to stay inside the map)",

	range = { 10, 400 },

	increment = 1,

	value = getFlag("Farm_OrbitRadius") or 40,

	callback = function(v) RS:SetAttribute("TPL_Farm_OrbitRadius", v) end,

}))

regOrbit(secFarm:CreateSlider({

	name = "Orbit Height",

	desc = "Orbit Center mode: height above the ground",

	range = { 10, 80 },

	increment = 1,

	value = getFlag("Farm_OrbitHeight") or 28,

	callback = function(v) RS:SetAttribute("TPL_Farm_OrbitHeight", v) end,

}))

regHover(secFarm:CreateSlider({

	name = "Hover Height",

	range = { 10, 80 },

	increment = 1,

	value = getFlag("Farm_Height"),

	callback = function(v) RS:SetAttribute("TPL_Farm_Height", v) end,

}))

regHover(secFarm:CreateSlider({

	name = "Hover Speed",

	desc = "Auto-Dodge mode: how fast the character glides between hover points and dodges (higher = snappier)",

	range = { 1, 30 },

	increment = 1,

	value = getFlag("Farm_Speed") or 7,

	callback = function(v) RS:SetAttribute("TPL_Farm_Speed", v) end,

}))

-- // FARM DEBUG OVERLAY: makes farm internals visible in-world //--
-- Cyan ball = hover goal the mover is gliding toward. Orange shells = VFX
-- models flagged as OUR OWN shots (skipped by the dodge). Red shells = live
-- threats that triggered the current dodge. Vertical beam = ground raycast
-- result under the goal (nil => void-guard active, shown magenta).

secFarm:CreateToggle({

	name = "Auto Collect Orbs",

	value = getFlag("FarmCollectOn"),

	callback = function(v)

		if _G.FS_StartAutoCollect then _G.FS_StartAutoCollect(v) end

	end,

})
	secFarm:CreateToggle({
		name = "Auto Smart Cards",
		desc = "Picks the best level-up card for the hover farm (skips the spin animation when it can)",
		value = getFlag("AutoSmartCardsOn"),
		callback = function(v)
			RS:SetAttribute("TPL_AutoSmartCardsOn", v)
			if _G.FS_StartAutoSmartCards then _G.FS_StartAutoSmartCards(v) end
		end,

	})
-- apply the initial visibility for the mode saved from the last run
do
	local orbit = ((getFlag("FarmMode") or "Orbit Center") == "Orbit Center")
	for _, el in ipairs(hoverElems) do pcall(function() el.SetVisible(not orbit) end) end
	for _, el in ipairs(orbitElems) do pcall(function() el.SetVisible(orbit) end) end
end

-- // ROUND END: second column — portal banking + what happens after the run //--
local secRoundEnd = tab:CreateSection({ name = "Round End", column = 2 })

secRoundEnd:CreateToggle({

	name = "Auto Enter Portal",

	desc = "When the loot multiplier reaches the target, walks to the Final Swarm portal and holds the prompt (ends the run)",

	value = getFlag("AutoEnterPortalOn"),

	callback = function(v)

		RS:SetAttribute("TPL_AutoEnterPortalOn", v)

		if _G.FS_StartAutoPortal then _G.FS_StartAutoPortal(v) end

	end,

})

secRoundEnd:CreateSlider({

	name = "Portal Target Multiplier",

	desc = "Auto Enter Portal enters the portal once the loot multiplier reaches this value",

	range = { 1, 20 },

	increment = 1,

	value = getFlag("PortalTargetMult") or 3,

	callback = function(v)

		if type(v) == "number" then RS:SetAttribute("TPL_PortalTargetMult", math.max(1, v)) end

	end,

})

secRoundEnd:CreateToggle({

	name = "Auto Replay",

	desc = "When the round ends, rejoin the same map + difficulty",

	value = getFlag("AutoReplayOn"),

	callback = function(v)
		RS:SetAttribute("TPL_AutoReplayOn", v)
		if _G.FS_StartAutoReplay then _G.FS_StartAutoReplay(v) end
	end,

})

secRoundEnd:CreateToggle({

	name = "Auto Return Lobby",

	desc = "When the round ends, press the game's own Lobby button (Continue)",

	value = getFlag("AutoReturnLobbyOn"),

	callback = function(v)
		RS:SetAttribute("TPL_AutoReturnLobbyOn", v)
		if _G.FS_StartAutoReturnLobby then _G.FS_StartAutoReturnLobby(v) end
	end,

})

local farmStat = secFarm:CreateStat({ name = "Status", value = "idle" })

task.spawn(function()

	while true do

		task.wait(2)

		pcall(function()

			local scan = getFarmScan()

			if not inRound() then

				farmStat.Set("lobby")

			elseif scan then

				farmStat.Set(scan.count .. " enemies")
			else
				farmStat.Set("no enemies")
			end

		end)

	end

end)

-- ===================== MISC =====================

-- Hide Name / Noclip / Walkspeed / Jumpheight / Fly

-- Uses TPL_ flags + Reg so Configs can save them

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

-- Hide Name — UI Template uses Head.PlayerInfo (ContainerFrame.PlayerUserName)

local function applyHideName(on)

    local char = Players.LocalPlayer.Character

    if char then

        local hum = char:FindFirstChildOfClass("Humanoid")

        if hum then

            hum.NameDisplayDistance = on and 0 or 100

            if on then hum.DisplayName = "" else hum.DisplayName = Players.LocalPlayer.DisplayName end

        end

        -- UI Template overhead: Head.PlayerInfo billboard + any other BillboardGui on char

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

        -- the game zeroes WalkSpeed/Jump on spawn and again between rounds;
        -- only accept the captured value when it is a sane number

        if type(h.WalkSpeed) == "number" and h.WalkSpeed > 0 then defaultWalkSpeed = h.WalkSpeed end

        if type(h.JumpPower) == "number" and h.JumpPower > 0 then defaultJumpPower = h.JumpPower end

        if type(h.JumpHeight) == "number" and h.JumpHeight > 0 then defaultJumpHeight = h.JumpHeight end

    end

end)

local currentWalkSpeed = getFlag("WalkSpeed") or defaultWalkSpeed

if type(currentWalkSpeed) ~= "number" or currentWalkSpeed <= 0 then currentWalkSpeed = defaultWalkSpeed end

local currentJump = getFlag("JumpHeight") or defaultJumpHeight

if type(currentJump) ~= "number" or currentJump <= 0 then currentJump = defaultJumpHeight end

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

            -- never enforce a poisoned zero: snap back to a sane default first

            if currentWalkSpeed <= 0 then currentWalkSpeed = defaultWalkSpeed end

            if currentJump <= 0 then currentJump = defaultJumpHeight end

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

    fsWhitelist(flyBG)
    flyBG.Parent = hrp

    flyBV = Instance.new("BodyVelocity")

    flyBV.velocity = Vector3.new(0,0,0)

    flyBV.maxForce = Vector3.new(9e9, 9e9, 9e9)

    fsWhitelist(flyBV)
    flyBG.Parent = hrp

    flyBV.Parent = hrp

    setNoclip(true)

    flyConn = RunService.Heartbeat:Connect(function()

        if not flyOn or not isCurrentGen() then stopFly() return end

        -- the AC reverts PlatformStand (silently now) — keep it asserted
        local humNow = getHumanoid()
        if humNow and not humNow.PlatformStand then humNow.PlatformStand = true end

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

-- re-apply on respawn + watch for PlayerInfo recreation (game re-creates billboard)

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

do

    local moveSec = misc:CreateSection({ name = "Movement" })

    moveSec:CreateSlider({

        name = "Walkspeed",

        desc = "Default 16 • Max 200",

        range = {8, 200},

        increment = 1,

        value = currentWalkSpeed,

        callback = function(v) applyWalkSpeed(v) end,

    })

    moveSec:CreateSlider({

        name = "Jumpheight",

        desc = "JumpHeight / JumpPower (auto)",

        range = {0, 200},

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

        range = {10, 250},

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

-- Auto-detect the game name: MarketPlaceServiceProductInfo needs the owner's
-- web API and is unreliable from executors, so resolve in priority order:
-- 1) real place name via the Roblox web API (game:HttpGet, works in-game)
-- 2) fall back to the in-experience name from ReplicatedStorage if present
-- 3) fall back to PlaceId / "Unknown Game"
do

    -- column 1: team + community

    local teamSec = credits:CreateSection({ name = "Team", column = 1 })

    teamSec:CreateLabel("Owner • sempai.real")

    creditsTeamGameLabel = teamSec:CreateLabel("Game: " .. GAME_NAME)

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

-- Named setups (toggles/sliders/dropdowns) saved to files + optional autoload
-- applied a few seconds after (re)start, so the farm resumes by itself after
-- a rejoin once the script is executed. Same file format as the old template,
-- so previously saved configs keep working.

do

	local CF_DIR = "UITemplate/configs"

	local AUTOLOAD_FILE = "UITemplate/autoload.txt"

	local Http = game:GetService("HttpService")

	local canIO = typeof(writefile) == "function" and typeof(readfile) == "function"

		and typeof(isfile) == "function" and typeof(makefolder) == "function"

	local function ensureDir()

		if not canIO then return false end

		local ok = pcall(function()

			makefolder("UITemplate")

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

	-- Auto Minimize on Start: when on, the NEXT script launch opens the window
	-- already minimized (bare title bar). Persisted to its own file because the
	-- window builds before any toggle exists to read.
	local STARTMIN_FILE = "UITemplate/startmin.txt"
	local function readStartMin()
		local ok, v = pcall(function()
			if not canIO or not isfile(STARTMIN_FILE) then return false end
			return readfile(STARTMIN_FILE) == "1"
		end)
		return ok and v or false
	end
	local function writeStartMin(on)
		pcall(function()
			if canIO then ensureDir() writefile(STARTMIN_FILE, on and "1" or "0") end
		end)
	end
	local minSec = cfgTab:CreateSection({ name = "Startup" })
	local minimizeT
	minimizeT = minSec:CreateToggle({
		name = "Auto Minimize on Start",
		desc = "Next launch of the script opens the window already minimized",
		value = readStartMin(),
		callback = function(v)
			writeStartMin(v)
			window:Notify({ title = "Configs", content = v and "Launches minimized from next start" or "Launches expanded" })
		end,
		noreg = true,
	})
	minimizeT.Set(readStartMin())

	-- Autoload

	-- ===================== THEMES =====================
	-- Same theme names as the old template: Ocean, Midnight, Aqua, Blood.
	-- Applied to the window live via the lib's SetTheme.
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

	local autoSec = cfgTab:CreateSection({ name = "Autoload" })
	local autoloadEnabled = false
	local autoT -- forward declaration: the callback below must close over the
	             -- real local, otherwise "autoT" inside the callback is a nil GLOBAL
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

	local cur = getAutoload()

	if cur and table.find(names, cur) then

		selected = cur

		pcall(function() listDD.Set(cur) end)

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

window:Notify({ title = "Final Swarm Hub", content = "Loaded! Press RightShift to toggle.", duration = 4 })

end, function(e)
	pcall(function()
		local tb = ""
		pcall(function() tb = debug.traceback("", 2) end)
		showErrorBox("load", tostring(e) .. (tb ~= "" and ("\n" .. tb) or ""))
	end)
end)
