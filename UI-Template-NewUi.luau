-- UI-Template-NewUi | Universal Hub Template
-- Based on Liquid Hub (Nebula UI lib v2.3) — replaces the old WindUI template
-- Use as base for new projects: change PROJECT_NAME / FOLDER / PREFIX at top as needed
-- Folder: UITemplate | Flags: TPL_ | Nebula (Liquid Hub)
-- All feature code (movement, fly, noclip, hide name, configs, credits) is
-- ported 1:1 from the old Template.luau; only the UI adapter layer changed.

-- AUTO Plugin fix for Delta / WindUI (1 loadstring, no external wrapper needed)

pcall(function()

    local set = setthreadidentity or set_thread_identity or setthreadcontext or set_identity

    if set then pcall(set, 8) pcall(set, 7) end

end)

local Players = game:GetService("Players")

local RS = game:GetService("ReplicatedStorage")

local function getFlag(n) return RS:GetAttribute("TPL_"..n) end

local function setFlag(n,v) RS:SetAttribute("TPL_"..n, v) end

-- Every load stamps a unique generation into the DataModel. Loops check it, so a
-- loop left running by an EARLIER execution of this script stops as soon as a new
-- copy loads. Without this, re-executing instead of reloading left two raid loops
-- writing the character's CFrame in the same frame, each with its own idea of
-- where to hover -- which looks exactly like the character being unable to decide
-- and shaking between two points. Seeded from the clock so a wipe cannot make a
-- new load collide with a stale stamp.

local LOAD_GEN = math.floor(os.clock() * 100000) % 1000000 + math.random(1, 999) * 1000000

RS:SetAttribute("TPL_LoadGen", LOAD_GEN)

local function isCurrentGen() return RS:GetAttribute("TPL_LoadGen") == LOAD_GEN end

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



-- ===================== LIBRARY LOAD (Nebula / Liquid Hub) =====================

-- Same sources the Liquid Hub loader uses (raw + jsDelivr mirror, cache-busting).

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

			warn("[UI-Template] Compile error: " .. tostring(cerr))

		end

	end

end

if not Liquid then

	warn("[UI-Template] Failed to load Liquid Hub library from all sources")

	return

end



local WindowRaw = Liquid:CreateWindow({

	Title     = "UI Template",

	SubTitle  = "1.0.0",

	ToggleKey = Enum.KeyCode.RightShift,

	Width     = 680,

	Height    = 440,

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

		local obj

		if o.multiSelect then

			-- old template passed a full list as value for multi
			obj = sect:CreateMultiDropdown(o.name, o.options or {}, initVal or {}, wrappedCb, o.name)

		elseif type(o.options) == "table" and #o.options > 20 then

			-- long lists get the searchable variant (mirrors the old SearchBarEnabled)
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

		local col = (o and o.column) or 1

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

window._tabIcons = { Main = "🎮", Misc = "🔧", Credits = "ℹ️", Configs = "💾" }

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





local tab = window:CreateTab({ name = "Main" })

local misc = window:CreateTab({ name = "Misc" })

local credits = window:CreateTab({ name = "Credits" })

local cfgTab = window:CreateTab({ name = "Configs" })





-- ===================== MAIN =====================

-- Add your UI Template features below. Example:

-- tab:CreateSection({ name = "Main" })

-- tab:CreateToggle({ name = "Auto Farm", value = false, callback = function(v) print("Auto Farm", v) end })

-- tab:CreateSlider({ name = "Farm Speed", range = {1, 100}, increment = 1, value = 30, callback = function(v) print(v) end })

do

    tab:CreateSection({ name = "Main" })

    local mainSec = tab:CreateSection({ name = "Status" })

    local stat = mainSec:CreateStat({ name = "Status", value = "Ready - add your logic here" })

    _G.TemplateStatus = stat -- keep a handle: stat.Set("...") (dot, not colon) updates the text

end



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

local GAME_NAME = "My Project"



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



	-- Autoload

	local autoSec = cfgTab:CreateSection({ name = "Autoload" })	local autoloadEnabled = false
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



window:Notify({ title = "UI Template", content = "Loaded! Press RightShift to toggle.", duration = 4 })

