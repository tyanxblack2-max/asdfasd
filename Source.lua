--[[
    ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗
    ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗
    ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║
    ██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║
    ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║
    ██║  ╚███║╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝

    LIQUID HUB UI LIBRARY v2.3 — "Deep Water"
    A modern, fully-featured UI library built for Roblox script executors.

    Executor compatibility: Delta, Real Executor, Hydrogen, Fluxus, Codex,
    Arceus X, Wave, Solara, Swift, Vega X, Evon, etc.

    Features:
      • Window with draggable/resizable frame, minimizable, close, keybind
      • Unthemed sidebar tabs with dynamic icons
      • Toggle, Slider, Dropdown, MultiDropdown, Keybind, Textbox, Button,
        ColorPicker, Label, Section
      • Notifications system
      • Config system (save / load / autoload)
      • 4 built-in themes + full theme customization
      • Mobile-friendly (touch dragging), works with and without gethui()
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Nebula = {}
Nebula.__index = Nebula

-- Library version: ALWAYS shown in the title bar and footer, regardless of
-- what version string a loader passes in (loaders lag behind and the two
-- numbers used to disagree)
local LIB_VERSION = "v2.3"

-- // Protect against double-execution //--
local okHui, hui = pcall(function() return gethui and gethui() end)
if okHui and hui then
    local existing = hui:FindFirstChild("NebulaUI")
    if existing then existing:Destroy() end
end

-- // CONFIG //--
Nebula.Themes = {
    Ocean = {
        Background   = Color3.fromRGB(13, 13, 18),
        Secondary    = Color3.fromRGB(22, 22, 30),
        Tertiary     = Color3.fromRGB(30, 30, 40),
        Element      = Color3.fromRGB(38, 38, 50),
        ElementHover = Color3.fromRGB(48, 48, 62),
        ElementStroke= Color3.fromRGB(55, 55, 70),
        Text         = Color3.fromRGB(240, 240, 245),
        SubText      = Color3.fromRGB(140, 140, 155),
        Accent       = Color3.fromRGB(59, 234, 255),
        AccentDim    = Color3.fromRGB(7, 87, 224),
    },
    Midnight = {
        Background   = Color3.fromRGB(8, 8, 14),
        Secondary    = Color3.fromRGB(14, 14, 22),
        Tertiary     = Color3.fromRGB(20, 20, 32),
        Element      = Color3.fromRGB(28, 28, 44),
        ElementHover = Color3.fromRGB(38, 38, 58),
        ElementStroke= Color3.fromRGB(45, 45, 70),
        Text         = Color3.fromRGB(235, 235, 250),
        SubText      = Color3.fromRGB(130, 130, 160),
        Accent       = Color3.fromRGB(80, 140, 255),
        AccentDim    = Color3.fromRGB(45, 85, 165),
    },
    Aqua = {
        Background   = Color3.fromRGB(10, 14, 16),
        Secondary    = Color3.fromRGB(15, 22, 26),
        Tertiary     = Color3.fromRGB(20, 30, 36),
        Element      = Color3.fromRGB(26, 40, 48),
        ElementHover = Color3.fromRGB(34, 52, 62),
        ElementStroke= Color3.fromRGB(42, 62, 74),
        Text         = Color3.fromRGB(235, 245, 248),
        SubText      = Color3.fromRGB(125, 145, 155),
        Accent       = Color3.fromRGB(40, 210, 210),
        AccentDim    = Color3.fromRGB(25, 130, 135),
    },
    Blood = {
        Background   = Color3.fromRGB(16, 10, 10),
        Secondary    = Color3.fromRGB(24, 14, 14),
        Tertiary     = Color3.fromRGB(34, 20, 20),
        Element      = Color3.fromRGB(44, 26, 26),
        ElementHover = Color3.fromRGB(56, 34, 34),
        ElementStroke= Color3.fromRGB(70, 42, 42),
        Text         = Color3.fromRGB(250, 240, 240),
        SubText      = Color3.fromRGB(160, 130, 130),
        Accent       = Color3.fromRGB(235, 60, 60),
        AccentDim    = Color3.fromRGB(150, 35, 35),
    },
}

Nebula.Theme = "Ocean"
Nebula.Flags = {}
Nebula.Connections = {}

-- // UTILITIES //--
local function Theme(key)
    return Nebula.Themes[Nebula.Theme][key]
end

local function Create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    -- UIStroke defaults to Contextual mode, which strokes the TEXT of text widgets
    -- (unreadable outlines) instead of the border. Every stroke in this library is
    -- meant as a border, so default to Border mode unless explicitly overridden.
    if inst:IsA("UIStroke") and props.ApplyStrokeMode == nil then
        inst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, time, props, style, dir)
    local ti = TweenInfo.new(
        time or 0.18,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, ti, props)
    t:Play()
    return t
end

-- // MOBILE MODE //-- touch-only devices get bigger hit targets and a
-- floating bubble to show/hide the window
local Mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- scale helper: fixed sizes are multiplied on mobile so rows are easier to tap
local function sz(v)
    if not Mobile then return v end
    return math.floor(v * 1.3 + 0.5)
end

-- shallow copy that does not rely on Luau's table.clone (older executors)
local function copyTable(t)
    local c = {}
    for i, v in ipairs(t) do c[i] = v end
    return c
end

-- Safe parent: gethui() or CoreGui, with fallbacks
local function GetGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    if RunService:IsStudio() then return game:GetService("CoreGui") end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LocalPlayer.PlayerGui
end

-- // CHARACTER CONTROLS: freeze movement while typing in UI fields //--
local Controls
do
    local ok, pm = pcall(function()
        return require(LocalPlayer:WaitForChild("PlayerScripts", 5):WaitForChild("PlayerModule", 5))
    end)
    if ok and pm then
        local ok2, c = pcall(function() return pm:GetControls() end)
        if ok2 and c then Controls = c end
    end
end

local typingDepth = 0
local function SetTyping(on)
    typingDepth = math.max(0, typingDepth + (on and 1 or -1))
    if Controls then
        pcall(function()
            if typingDepth > 0 then Controls:Disable() else Controls:Enable() end
        end)
    end
end

-- // DROPDOWN OVERLAY MANAGER — only one open at a time //--
local CloseCurrentDropdown = nil

-- Shared "user is mid-interaction" flag: set while a slider is being dragged or
-- the window resize grip is held. The column balancer refuses to run during
-- these, because element positions shifting under the cursor feel broken.
local InteractionBusy = 0
local function BeginInteraction() InteractionBusy = InteractionBusy + 1 end
local function EndInteraction() InteractionBusy = math.max(0, InteractionBusy - 1) end

local function MakeDraggable(dragInput, dragTarget)
    local dragging, dragStart, startPos = false, nil, nil
    dragInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            -- overlays are placed in absolute coordinates now: close them on drag
            -- start so they don't get stranded away from the window
            if CloseCurrentDropdown then CloseCurrentDropdown() end
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart
        and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local abs = Camera.ViewportSize
            -- Main is center-anchored: clamp its CENTER so the whole window
            -- (incl. its stroke) stays on screen
            local halfW = dragTarget.AbsoluteSize.X / 2
            local halfH = dragTarget.AbsoluteSize.Y / 2
            local x = math.clamp(
                startPos.X.Scale * abs.X + startPos.X.Offset + delta.X,
                halfW + 2, abs.X - halfW - 2
            )
            local y = math.clamp(
                startPos.Y.Scale * abs.Y + startPos.Y.Offset + delta.Y,
                halfH + 2, abs.Y - halfH - 2
            )
            dragTarget.Position = UDim2.fromOffset(x, y)
        end
    end)
end

-- Ripple click effect: an expanding circle clipped to the button
local function Ripple(inst, color)
    -- clip the circle to the button: otherwise the expanding ripple spills
    -- past the button edges onto the section background
    inst.ClipsDescendants = true
    inst.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local circle = Create("Frame", {
                Name = "Ripple",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = color or Theme("Accent"),
                BackgroundTransparency = 0.8,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0, 0),
                ZIndex = inst.ZIndex + 5,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
            circle.Parent = inst
            local target = math.max(inst.AbsoluteSize.X, inst.AbsoluteSize.Y) * 2.2
            Tween(circle, 0.55, { Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1 })
            task.delay(0.55, function() circle:Destroy() end)
        end
    end)
end

-- // WINDOW //--
function Nebula:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Nebula)
    self.Tabs = {}
    self.Toggles = {}
    self.Keybinds = {}
    self.ConfigFolder = config.ConfigFolder or "LiquidHubConfig"
    self.TitleText = config.Title or "Liquid Hub"
    self.SubTitle = LIB_VERSION -- loaders may pass a stale SubTitle; always show the library's own
    self.GameName = config.GameName -- optional: shown dimmed in the title bar next to the version

    -- Auto-fit to small screens (phones)
    local viewport = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
    self.Width = math.floor(math.min(config.Width or 720, viewport.X - 30))
    self.Height = math.floor(math.min(config.Height or 440, viewport.Y - 30))

    local ScreenGui = Create("ScreenGui", {
        Name = "NebulaUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    ScreenGui.Parent = GetGuiParent()

    -- Plain Frame, NOT CanvasGroup: executors (Real among them) clip CanvasGroup
    -- children unreliably, which let content bleed past the window border. Frame
    -- clipping is reliable everywhere.
    local Main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme("Background"),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self.Width, self.Height),
        Active = true,
        -- NO ClipsDescendants here: the UIStroke border renders half outside the
        -- frame's bounds, so frame clipping would cut off the outer half of the
        -- border. Content itself is clipped by the Content frame instead.
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Name = "Stroke", Color = Theme("ElementStroke"), Thickness = 1.5, Transparency = 0 }),
    })
    Main.Parent = ScreenGui

    -- Show/hide the big panels without relying on clipping (see note above)
    local function setPanelsVisible(v)
        for _, name in ipairs({ "Sidebar", "Content", "Footer", "ResizeGrip" }) do
            local child = Main:FindFirstChild(name)
            if child then child.Visible = v end
        end
    end

    -- Keep the whole window on screen. Main is center-anchored, so growing it
    -- (restore-from-minimize, resize grip) extends it BOTH ways from the
    -- center — a title bar dragged near the top while minimized ends up
    -- half-off-screen after the expand, and since the drag handle is the title
    -- bar the window becomes undraggable. Re-clamp the center after every
    -- size change so the title bar always stays reachable.
    local function ClampToScreen()
        if not Main or not Main.Parent then return end
        local abs = Camera.ViewportSize
        local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
        if w <= 0 or h <= 0 then return end
        local center = Main.AbsolutePosition + Vector2.new(w / 2, h / 2)
        local x = math.clamp(center.X, w / 2 + 2, math.max(w / 2 + 2, abs.X - w / 2 - 2))
        local y = math.clamp(center.Y, h / 2 + 2, math.max(h / 2 + 2, abs.Y - h / 2 - 2))
        Main.Position = UDim2.fromOffset(x, y)
    end

    -- // POP-IN — quick expand from the title bar (WindUI-style) //--
    -- defined below, after TitleBar exists: the title bar's bottom filler must
    -- start hidden, because at 40px height the title bar IS the whole window
    -- and the square filler would cover Main's rounded bottom corners (same as
    -- the minimize case)
    local titleCornerFill

    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme("Secondary"),
        Size = UDim2.new(1, 0, 0, 40),
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("Frame", { -- fill bottom corners
            Name = "CornerFill",
            BackgroundColor3 = Theme("Secondary"),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 1),
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(1, 0, 0, 10),
        }),
    })
    TitleBar.Parent = Main
    titleCornerFill = TitleBar:FindFirstChild("CornerFill")
    if titleCornerFill then titleCornerFill.Visible = false end

    Main.Size = UDim2.fromOffset(self.Width, 40)
    setPanelsVisible(false)
    Tween(Main, 0.35, {
        Size = UDim2.fromOffset(self.Width, self.Height),
    })
    task.delay(0.36, function()
        if Main and Main.Parent then
            if titleCornerFill then titleCornerFill.Visible = true end
            setPanelsVisible(true)
        end
    end)

    local Title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(0, 300, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "💧  " .. self.TitleText .. "  <font color=\"#3beaff\">|</font>  " .. LIB_VERSION
            .. (self.GameName and ("  <font color=\"#8c8c9b\">•  " .. self.GameName .. "</font>") or ""),
        RichText = true,
        TextColor3 = Theme("Text"),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    Title.Parent = TitleBar

    -- Accent gradient across the title (like the preview)
    local titleGrad = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Theme("Accent")),
        }),
    })
    titleGrad.Parent = Title

    -- Window controls
    local function MakeControl(offset, symbol, callback, hoverColor)
        local btn = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Theme("Tertiary"),
            Position = UDim2.new(1, offset, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            Font = Enum.Font.GothamBold,
            Text = symbol,
            TextColor3 = Theme("SubText"),
            TextSize = 14,
            AutoButtonColor = false,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })
        btn.Parent = TitleBar
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.15, { BackgroundColor3 = hoverColor or Theme("ElementHover"), TextColor3 = Theme("Text") })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, { BackgroundColor3 = Theme("Tertiary"), TextColor3 = Theme("SubText") })
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local minimized = false
    -- titleCornerFill is declared above (pop-in block): the filler squares off
    -- the title bar's lower corners so it merges with the body BELOW it — but
    -- when minimized the title bar IS the whole window, and the square filler
    -- would paint over Main's rounded bottom corners
    MakeControl(-12, "X", function()
        Nebula:Destroy(self)
    end, Color3.fromRGB(255, 70, 70))

    MakeControl(-48, "—", function() -- minimize
        minimized = not minimized
        if minimized then
            -- close any open dropdown / color picker overlay first
            if CloseCurrentDropdown then CloseCurrentDropdown() end
            -- hide panels explicitly: Frame clipping handles the visuals, this
            -- just stops interactions with invisible content
            setPanelsVisible(false)
        end
        if titleCornerFill then titleCornerFill.Visible = not minimized end
        Tween(Main, 0.25, {
            Size = minimized and UDim2.fromOffset(self.Width, 40)
                or UDim2.fromOffset(self.Width, self.Height),
        })
        if not minimized then
            -- re-clamp after the expand: a title bar parked near the top while
            -- minimized must not let the restored window hang off the screen
            task.delay(0.26, function()
                if not minimized and Main and Main.Parent then
                    ClampToScreen()
                    setPanelsVisible(true)
                end
            end)
        end
    end)

    MakeDraggable(TitleBar, Main)

    self.MobileMode = Mobile

    -- // MOBILE MODE: floating show/hide bubble //--
    -- Touch-only devices have no reliable always-available key, so a
    -- draggable bubble (tap = toggle, drag = reposition) is the standard fix
    if Mobile then
        local bubble = Create("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme("Secondary"),
            Position = UDim2.new(1, -40, 0.5, 0),
            Size = UDim2.fromOffset(48, 48),
            Font = Enum.Font.GothamBold,
            Text = "\u{1F4A7}",
            TextColor3 = Theme("Accent"),
            TextSize = 22,
            AutoButtonColor = false,
            ZIndex = 500,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create("UIStroke", { Color = Theme("Accent"), Thickness = 1.5, Transparency = 0.4 }),
        })
        bubble.Parent = ScreenGui

        local pressStart, moved = nil, false
        bubble.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                pressStart = input.Position
                moved = false
            end
        end)
        local bubbleMove = UserInputService.InputChanged:Connect(function(input)
            if pressStart and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = input.Position - pressStart
                if math.abs(d.X) + math.abs(d.Y) > 8 then moved = true end
                if moved then
                    -- follow the finger, clamped to the screen (scale-based so it
                    -- survives resolution changes)
                    local abs = Camera.ViewportSize
                    bubble.Position = UDim2.new(
                        math.clamp(input.Position.X / abs.X, 0.05, 0.95), 0,
                        math.clamp(input.Position.Y / abs.Y, 0.05, 0.95), 0
                    )
                end
            end
        end)
        local bubbleEnd = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if pressStart and not moved then
                    Main.Visible = not Main.Visible
                end
                pressStart = nil
            end
        end)
        table.insert(Nebula.Connections, bubbleMove)
        table.insert(Nebula.Connections, bubbleEnd)
    end

    -- Sidebar (Chiyo-style: wide panel with icon + label rows).
    -- Runs all the way down to the window bottom: no awkward gap above the footer
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme("Secondary"),
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(0, 150, 1, -40),
    }, {
        -- Rounded to match the window corner: a square sidebar corner pokes
        -- past Main's rounded bottom-left corner (frame clipping is rectangular
        -- and never follows rounded corners)
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("Frame", { -- fill the top corners below the rounded title bar
            Name = "CornerFill",
            BackgroundColor3 = Theme("Secondary"),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 0, 10),
        }),
        Create("Frame", { -- square off the INTERIOR bottom-right corner: only the
            -- outer bottom-left corner should follow the window's rounding
            Name = "CornerFillBottom",
            BackgroundColor3 = Theme("Secondary"),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.new(0, 10, 0, 10),
        }),
    })
    -- Clip tab overflow HERE, at the sidebar bounds. TabHolder itself must stay
    -- unclipped (stroke fix); without a clip ancestor, tabs that don't fit a
    -- shrunken window draw straight past the window's bottom edge.
    Sidebar.ClipsDescendants = true
    Sidebar.Parent = Main

    local TabHolder = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        -- extra room around the tab rows so their border strokes never touch
        -- the holder edge (a stroke renders half outside the button and gets
        -- shaved off when it lands exactly on a clipping boundary)
        Position = UDim2.fromOffset(4, 6),
        Size = UDim2.new(1, -8, 1, -12),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        -- ScrollingFrames CLIP by default, which cut the outer half of the tab
        -- button strokes off. Tab rows never overflow this holder anyway, so
        -- clipping only ever did harm here. (When the WINDOW is short the tab
        -- list CAN overflow — but then the Sidebar clips it; see below.)
        ClipsDescendants = false,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })
    TabHolder.Parent = Sidebar

    -- Content area
    local Content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(150, 40),
        Size = UDim2.new(1, -150, 1, -62),
        ClipsDescendants = true,
    })
    Content.Parent = Main

    -- Footer: sits right of the sidebar (the sidebar now reaches the bottom edge)
    local Footer = Create("TextLabel", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 150, 1, -22),
        Size = UDim2.new(1, -150, 0, 22),
        Font = Enum.Font.Gotham,
        RichText = true,
        Text = "discord.gg/liquidhub  |  <b>Liquid Hub " .. LIB_VERSION .. "</b>",
        TextColor3 = Theme("SubText"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    Footer.Parent = Main

    -- // RESIZE GRIP — drag the bottom-right corner to resize the window //--
    -- The layout is scale/auto-size based, so panels reflow to any size; the
    -- grip just updates Main (and self.Width/Height so minimize keeps using
    -- the current dimensions).
    local MIN_W, MIN_H = 420, 260
    local grip = Create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 60, -- above page content and the scroll fade
    })
    grip.Parent = Main

    -- icon: double-headed diagonal arrow drawn from frames (more reliable than
    -- unicode arrows, which some fonts render as empty boxes)
    local function gripBar(w, h, x, y, rot)
        return Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h),
            Rotation = rot,
            BackgroundColor3 = Theme("SubText"),
            BorderSizePixel = 0,
            ZIndex = 61,
        }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end
    gripBar(14, 2, 9, 9, 45).Parent = grip -- main diagonal ↗↙
    gripBar(6, 2, 3.5, 3.5, -45).Parent = grip -- arrowhead top-left
    gripBar(6, 2, 14.5, 14.5, -45).Parent = grip -- arrowhead bottom-right

    grip.MouseEnter:Connect(function()
        for _, b in ipairs(grip:GetChildren()) do
            if b:IsA("Frame") then b.BackgroundColor3 = Theme("Accent") end
        end
    end)
    grip.MouseLeave:Connect(function()
        for _, b in ipairs(grip:GetChildren()) do
            if b:IsA("Frame") then b.BackgroundColor3 = Theme("SubText") end
        end
    end)

    local resizing, resizeStart, sizeAtStart = false, nil, nil
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            BeginInteraction() -- freeze column rebalancing while resizing
            resizeStart = input.Position
            sizeAtStart = Main.AbsoluteSize
            if CloseCurrentDropdown then CloseCurrentDropdown() end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    EndInteraction()
                end
            end)
        end
    end)
    local resizeConn = UserInputService.InputChanged:Connect(function(input)
        if not resizing or not resizeStart then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs = Camera.ViewportSize
        local delta = input.Position - resizeStart
        -- Main is center-anchored: growing extends both ways from the center.
        -- Clamp so the window never gets smaller than the layout tolerates or
        -- bigger than the screen.
        self.Width = math.clamp(math.floor(sizeAtStart.X + delta.X + 0.5), MIN_W, abs.X - 20)
        self.Height = math.clamp(math.floor(sizeAtStart.Y + delta.Y + 0.5), MIN_H, abs.Y - 20)
        Main.Size = UDim2.fromOffset(self.Width, self.Height)
        ClampToScreen() -- center-anchored growth extends both ways: keep it on screen
    end)
    table.insert(Nebula.Connections, resizeConn)

    -- // SCROLL FADE //-- soft gradient over the bottom edge of the content
    -- area, visible only while the current page has more content below the
    -- viewport (so users can tell there is something left to scroll)
    local ScrollFade = Create("Frame", {
        Name = "ScrollFade",
        BackgroundColor3 = Theme("Background"),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 26),
        ZIndex = 50,
        Visible = false,
    }, {
        Create("UIGradient", {
            Rotation = 90, -- top -> bottom
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), -- top: fully see-through
                NumberSequenceKeypoint.new(1, 0), -- bottom: solid Background
            }),
        }),
    })
    ScrollFade.Parent = Content

    local function updateScrollFade()
        local tab = self.CurrentTab
        if not tab or not tab.Page or not tab.Page.Visible then
            ScrollFade.Visible = false
            return
        end
        local page = tab.Page
        local viewH = page.AbsoluteWindowSize.Y
        local remaining = page.AbsoluteCanvasSize.Y - (page.CanvasPosition.Y + viewH)
        ScrollFade.Visible = remaining > 2
    end

    -- repaint on theme switch is handled automatically: SetTheme remaps every
    -- descendant color matching the old palette, ScrollFade included

    -- Tab container
    local TabContainer = Create("Folder", { Name = "TabContainer" })
    TabContainer.Parent = Content

    self.ScreenGui = ScreenGui
    self.Main = Main
    self.TabHolder = TabHolder
    self.TabContainer = TabContainer
    self.CurrentTab = nil
    table.insert(Nebula.Connections, ScreenGui.Destroying:Connect(function()
        for _, c in ipairs(Nebula.Connections) do c:Disconnect() end
    end))

    -- // INLINE LIST OPENER //-- Chiyo-style dropdown: the option list expands
    -- INSIDE the section card and pushes the content below it down, so it can
    -- never cross the window border (pages always clip their content).
    -- h = row-list height, or nil to collapse the list back.
    local function OpenInlineList(list, frame, stroke, arrow, h)
        if h then
            frame.Size = UDim2.new(1, 0, 0, sz(60) + h)
            list.Size = UDim2.new(1, 0, 0, h)
            list.Visible = true
            Tween(stroke, 0.15, { Color = Theme("Accent") })
            Tween(arrow, 0.15, { Rotation = 180 })
            -- if the expanded list runs past the bottom of the viewport, scroll
            -- the page down just enough to reveal it
            task.defer(function()
                pcall(function()
                    local page = list:FindFirstAncestorOfClass("ScrollingFrame")
                    if not page then return end
                    local bottom = list.AbsolutePosition.Y + list.AbsoluteSize.Y
                    local viewBottom = page.AbsolutePosition.Y + page.AbsoluteSize.Y
                    local overflow = bottom - viewBottom
                    if overflow > 0 then
                        local maxY = page.AbsoluteCanvasSize and page.AbsoluteCanvasSize.Y or 0
                        page.CanvasPosition = Vector2.new(0,
                            math.clamp(page.CanvasPosition.Y + overflow, 0, maxY))
                    end
                end)
            end)
        else
            frame.Size = UDim2.new(1, 0, 0, sz(56))
            list.Visible = false
            Tween(stroke, 0.12, { Color = Theme("ElementStroke") })
            Tween(arrow, 0.12, { Rotation = 0 })
        end
    end

    -- // TAB CREATION //--
    function self:CreateTab(name, icon)
        local tab = {}
        tab.Name = name
        tab.Sections = {}

        local btn = Create("TextButton", {
            BackgroundColor3 = Theme("Tertiary"),
            BackgroundTransparency = 1,
            -- slightly narrower than the holder: leaves a clear gap on the right
            -- so the selected tab's accent stroke has room to render in full
            Size = UDim2.new(1, -12, 0, sz(32)),
            Font = Enum.Font.GothamBold,
            Text = (icon or name:sub(1, 1)) .. "  " .. name:upper(),
            TextColor3 = Theme("SubText"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = #self.Tabs + 1,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
        })
        btn.Parent = self.TabHolder

        local stroke = Create("UIStroke", {
            Color = Theme("ElementStroke"),
            Thickness = 1,
            Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, -- Border, not Contextual: Contextual strokes the TEXT and makes it unreadable
        })
        stroke.Parent = btn

        local page = Create("ScrollingFrame", {
            Name = name,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme("Accent"),
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })
        page.Parent = self.TabContainer
        -- keep the fade honest while this page scrolls or its content grows
        page:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollFade)
        page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollFade)
        page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollFade)
        -- Page padding lives on a PLAIN frame, not on the ScrollingFrame itself:
        -- UIPadding on a ScrollingFrame is not honored for scale-based child
        -- layout (children are laid out against the raw canvas size), which let
        -- the right column run flush into the window edge and get its border
        -- clipped off by Content.
        local inner = Create("Frame", {
            Name = "PageInner",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, -- grows with the columns so the page's AutomaticCanvasSize tracks the real content height
        })
        inner.Parent = page
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }).Parent = inner

        local left = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        })
        left.Parent = inner

        local right = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 9, 0, 0),
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        })
        right.Parent = inner

        tab.LeftColumn = left
        tab.RightColumn = right
        tab.Button = btn
        tab.Page = page

        local function select()
            -- keep the selected tab visible: when the window is short the tab
            -- list overflows into a scroll range, and a selected tab can end up
            -- scrolled out of view (invisible — the sidebar clips the overflow)
            if self.CurrentTab then
                self.CurrentTab.Page.Visible = false
                Tween(self.CurrentTab.Button, 0.2, { BackgroundColor3 = Theme("Tertiary"), TextColor3 = Theme("SubText") })
                self.CurrentTab.Button.UIStroke.Transparency = 1
            end
            self.CurrentTab = tab
            page.Visible = true
            updateScrollFade()
            -- WindUI-style content slide on tab switch
            left.Position = UDim2.new(0, 0, 0, 12)
            right.Position = UDim2.new(0.5, 9, 0, 12)
            Tween(left, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
            Tween(right, 0.25, { Position = UDim2.new(0.5, 9, 0, 0) })
            Tween(btn, 0.18, { BackgroundColor3 = Theme("Element"), BackgroundTransparency = 0, TextColor3 = Theme("Accent") })
            stroke.Transparency = 0
            stroke.Color = Theme("Accent")
            task.defer(function()
                local holder = self.TabHolder
                if not holder or not btn.Parent then return end
                local viewH = holder.AbsoluteWindowSize.Y
                local top = btn.AbsolutePosition.Y - holder.AbsolutePosition.Y + holder.CanvasPosition.Y
                local bottom = top + btn.AbsoluteSize.Y
                if top < holder.CanvasPosition.Y then
                    holder.CanvasPosition = Vector2.new(0, math.max(0, top - 4))
                elseif bottom > holder.CanvasPosition.Y + viewH then
                    holder.CanvasPosition = Vector2.new(0, bottom - viewH + 4)
                end
            end)
        end

        btn.MouseButton1Click:Connect(select)
        btn.MouseEnter:Connect(function()
            if self.CurrentTab ~= tab then
                Tween(btn, 0.15, { BackgroundTransparency = 0.5, TextColor3 = Theme("Text") })
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.CurrentTab ~= tab then
                Tween(btn, 0.15, { BackgroundTransparency = 1, TextColor3 = Theme("SubText") })
            end
        end)

        if not self.CurrentTab then select() end

        -- // COLUMN BALANCING //-- sections created WITHOUT an explicit column
        -- are queued here; once a tab ends up with 3+ of them they get spread
        -- across both columns (tallest first, onto the lighter side) so the
        -- right half of the window is not left empty. Sections the developer
        -- pinned with column = 1/2 are never moved.
        tab.AutoSections = tab.AutoSections or {}
        local balanceScheduled = false
        local function balanceColumns()
            -- hard guard: an open dropdown overlay makes its card temporarily
            -- huge; balancing now would teleport it to the other column
            if CloseCurrentDropdown then return end
            -- same while a slider is being dragged or the window resized:
            -- elements shifting under the cursor mid-drag feels broken
            if InteractionBusy > 0 then return end
            local autos = tab.AutoSections
            if #autos < 3 then return end
            -- estimated height: real height once layout has run, otherwise a
            -- rough per-child estimate (elements are ~36px + card chrome)
            local function est(sec)
                local h = sec.Frame.AbsoluteSize.Y
                if h and h > 0 then return h end
                local n = 0
                for _, c in ipairs(sec.Frame:GetChildren()) do
                    if c:IsA("Frame") then n = n + #c:GetChildren() end
                end
                return n * 36 + 30
            end
            local items = {}
            for _, sec in ipairs(autos) do items[#items + 1] = sec end
            -- height order for PLACEMENT, but creation order for DISPLAY: each
            -- section keeps the position in the stack where it was created
            table.sort(items, function(a, b) return est(a) > est(b) end)
            local leftH, rightH = 0, 0
            for _, sec in ipairs(items) do
                local goLeft = leftH <= rightH
                local side = goLeft and tab.LeftColumn or tab.RightColumn
                if sec.Frame.Parent ~= side then sec.Frame.Parent = side end
                sec.Frame.LayoutOrder = sec.AutoIndex
                sec.Column = goLeft and 1 or 2
                if goLeft then leftH = leftH + est(sec) + 8 else rightH = rightH + est(sec) + 8 end
            end
        end
        local function scheduleBalance()
            -- NEVER reshuffle while a dropdown overlay is open: the expanded
            -- card is temporarily the tallest, so a rebalance here would
            -- teleport it to another column in the middle of the interaction
            if CloseCurrentDropdown then return end
            if balanceScheduled then return end
            balanceScheduled = true
            -- end of the current resumption: by then the script has finished
            -- creating sections/elements synchronously, so the counts are final
            task.defer(function()
                balanceScheduled = false
                -- re-check: an overlay may have opened between schedule and run
                if CloseCurrentDropdown then return end
                balanceColumns()
                -- belt and braces: heights settle over the next frames (fonts,
                -- automatic size) and the tab may not be the visible one yet —
                -- re-run shortly after, and again when the tab is first shown
                task.delay(0.15, balanceColumns)
                task.delay(0.5, balanceColumns)
                if not tab.BalanceOnSelect then
                    tab.BalanceOnSelect = true
                    local btn = tab.Button
                    if btn then
                        btn.MouseButton1Click:Connect(function()
                            task.defer(balanceColumns)
                            task.delay(0.1, balanceColumns)
                        end)
                    end
                end
            end)
        end

        -- // SECTION //--
        function tab:CreateSection(title, column)
            local side = (column == 2) and tab.RightColumn or tab.LeftColumn
            local section = {}
            section.Column = column or 1

            local frame = Create("Frame", {
                BackgroundColor3 = Theme("Secondary"),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = #side:GetChildren(),
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
                Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1, Transparency = 0.35 }),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            })
            frame.Parent = side
            section.Frame = frame

            -- auto-placed (no explicit column): queue for balancing
            if column == nil then
                table.insert(tab.AutoSections, section)
                section.AutoIndex = #tab.AutoSections
                scheduleBalance()
                -- elements are sometimes added AFTER the tab was built (async
                -- feature code): when this card's real height settles, re-run
                -- the balance so the split tracks actual content
                frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleBalance)
            end
            local holder = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, {
                Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
            })
            holder.Parent = frame

            if title then
                -- Chiyo-style header: small accent bar beside the title
                local headRow = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    LayoutOrder = 0,
                })
                headRow.Parent = holder

                local accentBar = Create("Frame", {
                    BackgroundColor3 = Theme("Accent"),
                    Size = UDim2.new(0, 3, 1, -4),
                    Position = UDim2.new(0, 0, 0, 2),
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                accentBar.Parent = headRow

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -10, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = title,
                    TextColor3 = Theme("Text"),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = headRow
            end

            local order = title and 1 or 0
            local function nextOrder()
                order = order + 1
                return order
            end

            -- // ELEMENT: LABEL //--
            function section:CreateLabel(text)
                local l = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = Theme("SubText"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, -- long labels must never bleed past the card border
                    LayoutOrder = nextOrder(),
                })
                l.Parent = holder
                return l
            end

            -- // ELEMENT: BUTTON //--
            function section:CreateButton(text, callback)
                local b = Create("TextButton", {
                    BackgroundColor3 = Theme("Element"),
                    Size = UDim2.new(1, 0, 0, sz(32)),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    AutoButtonColor = false,
                    LayoutOrder = nextOrder(),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                })
                b.Parent = holder
                b.MouseEnter:Connect(function() Tween(b, 0.15, { BackgroundColor3 = Theme("ElementHover") }) end)
                b.MouseLeave:Connect(function() Tween(b, 0.15, { BackgroundColor3 = Theme("Element") }) end)
                b.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
                Ripple(b)
                return b
            end

            -- // ELEMENT: TOGGLE //--
            function section:CreateToggle(text, default, callback, flag)
                flag = flag or text
                local state = default or false
                Nebula.Flags[flag] = state

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(32)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local btn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                })
                btn.Parent = frame

                -- The switch itself is a TextButton that sinks clicks (double-toggle fix:
                -- previously both this frame and the label button fired for one click)
                local toggle = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme("Tertiary"),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(sz(44), sz(22)),
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true, -- Back-easing knob overshoot must not poke past the pill edge
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    -- Thickness 2, not 1: the pill clips its own stroke, and a
                    -- 2px stroke leaves the full inner 1px visible after clipping
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 2 }),
                })
                toggle.Parent = frame
                toggle.ZIndex = btn.ZIndex + 1

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Theme("Text"),
                    Position = UDim2.new(0, sz(3), 0.5, 0),
                    Size = UDim2.fromOffset(sz(18), sz(18)),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                knob.Parent = toggle

                local function setState(v, noFire)
                    state = v
                    Nebula.Flags[flag] = v
                    -- ON: knob left edge at 44-3-18 = 23px (AnchorPoint is 0,0.5 — using scale 1,-3 put the knob 15px outside the pill)
                    Tween(knob, 0.18, {
                        Position = v and UDim2.new(0, sz(44) - sz(3) - sz(18), 0.5, 0) or UDim2.new(0, sz(3), 0.5, 0),
                        BackgroundColor3 = v and Color3.fromRGB(255, 255, 255) or Theme("Text"),
                    }, Enum.EasingStyle.Back)
                    Tween(toggle, 0.15, { BackgroundColor3 = v and Theme("Accent") or Theme("Tertiary") })
                    if not noFire and callback then callback(v) end
                end
                setState(state, true)

                -- ONE handler: the switch is a TextButton sitting above the label,
                -- so a click lands on exactly one of them — never both
                toggle.MouseButton1Click:Connect(function() setState(not state) end)
                btn.MouseButton1Click:Connect(function() setState(not state) end)
                toggle.MouseEnter:Connect(function()
                    if not state then Tween(toggle, 0.12, { BackgroundColor3 = Theme("ElementHover") }) end
                end)
                toggle.MouseLeave:Connect(function()
                    Tween(toggle, 0.12, { BackgroundColor3 = state and Theme("Accent") or Theme("Tertiary") })
                end)

                return {
                    Set = function(v) setState(v, true) end,
                    Get = function() return state end,
                }
            end

            -- // ELEMENT: SLIDER //-- (Chiyo style: "83 s/600 s" next to the label,
            -- bar on the row below; the value doubles as an exact-input TextBox)
            function section:CreateSlider(text, min, max, default, callback, flag, suffix)
                flag = flag or text
                min = min or 0
                max = max or 100
                local value = math.floor((default or min) + 0.5) -- round: kills float noise from config loads / adapter Sets
                Nebula.Flags[flag] = value

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(42)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                -- Chiyo value format: current + suffix + "/" + max + suffix
                -- round away float noise (34.000000001 -> 34): the Set() path
                -- and config loads pass fractional values that used to print
                -- as 34.000001525878906 in the value box
                local function round(v)
                    return math.floor(v + 0.5)
                end

                local function fmt(v)
                    return tostring(round(v)) .. (suffix or "") .. "/" .. tostring(round(max)) .. (suffix or "")
                end

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -sz(150), 0, sz(16)),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                -- Value is a TextBox: click it and type an exact number (confirm with
                -- Enter or click-away; invalid input reverts to the previous value)
                local valueBox = Create("TextBox", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, sz(150), 0, sz(16)),
                    Font = Enum.Font.GothamMedium,
                    Text = fmt(value),
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ClearTextOnFocus = false,
                })
                valueBox.Parent = frame

                -- Chiyo track: rounded bar with a 2px inset, ~56% taller than the
                -- fill (the accent fill "floats" in the middle of the dark track)
                local bar = Create("TextButton", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = Theme("Tertiary"),
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, sz(24)),
                    Text = "",
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                bar.Parent = frame

                local fill = Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Theme("Accent"),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new((value - min) / (max - min), -4, 0, sz(14)),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                fill.Parent = bar

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Theme("Text"),
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.fromOffset(sz(20), sz(20)),
                    ZIndex = 5,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                knob.Parent = bar

                local dragging = false
                local function setFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * rel + 0.5)
                    Nebula.Flags[flag] = value
                    if not valueBox:IsFocused() then
                        valueBox.Text = fmt(value)
                    end
                    -- live updates while dragging, exactly like Chiyo (no tween lag)
                    fill.Size = UDim2.new(rel, -4, 0, sz(14))
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    if callback then callback(value) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        BeginInteraction() -- freeze column rebalancing while dragging
                        setFromX(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        setFromX(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        if dragging then EndInteraction() end
                        dragging = false
                    end
                end)

                -- Commit a typed value: parse the number, clamp to [min, max],
                -- snap to the same integer stepping the drag uses, repaint, fire callback
                local function commitTyped()
                    local n = tonumber(valueBox.Text:match("-?%d+%.?%d*"))
                    if not n then
                        valueBox.Text = fmt(value)
                        return
                    end
                    value = math.clamp(math.floor(n + 0.5), min, max)
                    Nebula.Flags[flag] = value
                    local rel = (value - min) / (max - min)
                    valueBox.Text = fmt(value)
                    fill.Size = UDim2.new(rel, -4, 0, sz(14))
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    if callback then callback(value) end
                end

                valueBox.Focused:Connect(function()
                    SetTyping(true)
                    BeginInteraction() -- freeze column rebalancing while typing
                end)
                valueBox.FocusLost:Connect(function(enter)
                    SetTyping(false)
                    EndInteraction()
                    commitTyped()
                end)

                return {
                    Set = function(v)
                        v = math.floor(math.clamp(v, min, max) + 0.5) -- round away float noise
                        local rel = (v - min) / (max - min)
                        value = v
                        Nebula.Flags[flag] = v
                        valueBox.Text = fmt(v)
                        fill.Size = UDim2.new(rel, -4, 0, sz(14))
                        knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    end,
                    Get = function() return value end,
                }
            end

            -- // ELEMENT: DROPDOWN //-- (floating overlay: never pushes content down)
            function section:CreateDropdown(text, options, default, callback, flag)
                flag = flag or text
                options = options or {}
                local selected = default
                Nebula.Flags[flag] = selected

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(56)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local btn = Create("TextButton", {
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, sz(30)),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                btn.Parent = frame
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }).Parent = btn
                local stroke = btn.UIStroke

                local selectedLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -34, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = selected and tostring(selected) or "---",
                    TextColor3 = selected and Theme("Text") or Theme("SubText"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                selectedLbl.Parent = btn

                local arrow = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Font = Enum.Font.GothamBold,
                    Text = "v",
                    TextColor3 = Theme("SubText"),
                    TextSize = 13,
                })
                arrow.Parent = btn

                -- Chiyo-style inline list: opens inside the section card, right
                -- below the button, and pushes the rest of the content down with it
                local list = Create("Frame", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.fromOffset(0, sz(54)),
                    -- NO ClipsDescendants: it would clip this frame's own border
                    -- stroke in half. The inner ScrollingFrame does the scrolling,
                    -- so nothing can overflow anyway.
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = frame

                local scroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme("Accent"),
                    BorderSizePixel = 0,
                    ZIndex = 61,
                }, {
                    Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
                    Create("UIPadding", {
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                    }),
                })
                scroll.Parent = list

                local ROW, GAP, MAXH = sz(26), 3, 150
                local open = false
                local outsideConn = nil

                local function countRows()
                    local n = 0
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then n = n + 1 end
                    end
                    return n
                end

                local function setOpen(v)
                    if open == v then return end
                    open = v
                    if v then
                        if CloseCurrentDropdown and CloseCurrentDropdown ~= setOpen then
                            CloseCurrentDropdown()
                        end
                        CloseCurrentDropdown = setOpen
                        local h = math.min(countRows() * (ROW + GAP) + 8, MAXH)
                        OpenInlineList(list, frame, stroke, arrow, h)
                        outsideConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                                local p, lp, ls = input.Position, list.AbsolutePosition, list.AbsoluteSize
                                local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                                local inList = p.X >= lp.X and p.X <= lp.X + ls.X and p.Y >= lp.Y and p.Y <= lp.Y + ls.Y
                                local inBtn = p.X >= bp.X and p.X <= bp.X + bs.X and p.Y >= bp.Y and p.Y <= bp.Y + bs.Y
                                if not inList and not inBtn then setOpen(false) end
                            end
                        end)
                        table.insert(Nebula.Connections, outsideConn)
                    else
                        if CloseCurrentDropdown == setOpen then CloseCurrentDropdown = nil end
                        if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                        OpenInlineList(list, frame, stroke, arrow, nil)
                    end
                end

                local function rebuild()
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                    end
                    for i, opt in ipairs(options) do
                        local isSel = (opt == selected)
                        local ob = Create("TextButton", {
                            BackgroundColor3 = Theme("Element"),
                            Size = UDim2.new(1, 0, 0, ROW),
                            Font = Enum.Font.Gotham,
                            Text = isSel and ("\u{2022}  " .. tostring(opt)) or tostring(opt),
                            TextColor3 = isSel and Theme("Accent") or Theme("Text"),
                            TextSize = 12,
                            AutoButtonColor = false,
                            ZIndex = 62,
                            LayoutOrder = i,
                        }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                        ob.Parent = scroll
                        ob.MouseEnter:Connect(function()
                            Tween(ob, 0.1, { BackgroundColor3 = Theme("ElementHover") })
                        end)
                        ob.MouseLeave:Connect(function()
                            Tween(ob, 0.1, { BackgroundColor3 = Theme("Element") })
                        end)
                        ob.MouseButton1Click:Connect(function()
                            selected = opt
                            Nebula.Flags[flag] = opt
                            selectedLbl.Text = tostring(opt)
                            selectedLbl.TextColor3 = Theme("Text")
                            if callback then callback(opt) end
                            setOpen(false)
                        end)
                    end
                end
                rebuild()

                btn.MouseButton1Click:Connect(function() setOpen(not open) end)
                btn.MouseEnter:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("Accent") }) end
                end)
                btn.MouseLeave:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("ElementStroke") }) end
                end)

                return {
                    Set = function(v)
                        selected = v
                        Nebula.Flags[flag] = v
                        selectedLbl.Text = v and tostring(v) or "---"
                        selectedLbl.TextColor3 = v and Theme("Text") or Theme("SubText")
                    end,
                    Refresh = function(newOpts)
                        options = newOpts or options
                        rebuild()
                        if open then
                            OpenInlineList(list, frame, stroke, arrow,
                                math.min(countRows() * (ROW + GAP) + 8, MAXH))
                        end
                    end,
                    Get = function() return selected end,
                }
            end

            -- // ELEMENT: SEARCHABLE DROPDOWN //-- (floating overlay)
            function section:CreateSearchDropdown(text, options, default, callback, flag)
                flag = flag or text
                options = options or {}
                local selected = default
                Nebula.Flags[flag] = selected

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(56)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local btn = Create("TextButton", {
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, sz(30)),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                btn.Parent = frame
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }).Parent = btn
                local stroke = btn.UIStroke

                -- Current selection display (or "---"): sits in the same top row as
                -- the search field; the search box takes the row over while open
                local selectedLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -34, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = selected and tostring(selected) or "---",
                    TextColor3 = selected and Theme("Text") or Theme("SubText"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                selectedLbl.Parent = btn

                local searchBox = Create("TextBox", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -34, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    PlaceholderText = "Search...",
                    PlaceholderColor3 = Theme("SubText"),
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Visible = false,
                })
                searchBox.Parent = btn

                local arrow = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Font = Enum.Font.GothamBold,
                    Text = "v",
                    TextColor3 = Theme("SubText"),
                    TextSize = 13,
                })
                arrow.Parent = btn

                -- Chiyo-style inline list: opens inside the section card, right
                -- below the button, and pushes the rest of the content down with it
                local list = Create("Frame", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.fromOffset(0, sz(54)),
                    -- NO ClipsDescendants: it would clip this frame's own border
                    -- stroke in half. The inner ScrollingFrame does the scrolling,
                    -- so nothing can overflow anyway.
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = frame

                local scroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme("Accent"),
                    BorderSizePixel = 0,
                    ZIndex = 61,
                }, {
                    Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
                    Create("UIPadding", {
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                    }),
                })
                scroll.Parent = list

                local ROW, GAP, MAXH = sz(26), 3, 150
                local open = false
                local outsideConn = nil
                local setOpen -- forward declaration: rebuild() below closes over this

                local function countRows()
                    local n = 0
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then n = n + 1 end
                    end
                    return n
                end

                local function place()
                    OpenInlineList(list, frame, stroke, arrow,
                        math.min(countRows() * (ROW + GAP) + 8, MAXH))
                end

                local function rebuild(filter)
                    filter = (filter or ""):lower()
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                    end
                    local shown = 0
                    for i, opt in ipairs(options) do
                        if filter == "" or tostring(opt):lower():find(filter, 1, true) then
                            shown = shown + 1
                            local isSel = (opt == selected)
                            local ob = Create("TextButton", {
                                BackgroundColor3 = Theme("Element"),
                                Size = UDim2.new(1, 0, 0, ROW),
                                Font = Enum.Font.Gotham,
                                Text = isSel and ("\u{2022}  " .. tostring(opt)) or tostring(opt),
                                TextColor3 = isSel and Theme("Accent") or Theme("Text"),
                                TextSize = 12,
                                AutoButtonColor = false,
                                ZIndex = 62,
                                LayoutOrder = i,
                            }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                            ob.Parent = scroll
                            ob.MouseEnter:Connect(function()
                                Tween(ob, 0.1, { BackgroundColor3 = Theme("ElementHover") })
                            end)
                            ob.MouseLeave:Connect(function()
                                Tween(ob, 0.1, { BackgroundColor3 = Theme("Element") })
                            end)
                            ob.MouseButton1Click:Connect(function()
                                selected = opt
                                Nebula.Flags[flag] = opt
                                selectedLbl.Text = tostring(opt)
                                selectedLbl.TextColor3 = Theme("Text")
                                if callback then callback(opt) end
                                setOpen(false)
                            end)
                        end
                    end
                    if shown == 0 then
                        local empty = Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, ROW),
                            Font = Enum.Font.Gotham,
                            Text = "Nothing found",
                            TextColor3 = Theme("SubText"),
                            TextSize = 12,
                            ZIndex = 62,
                            LayoutOrder = 9999,
                        })
                        empty.Parent = scroll
                    end
                end

                setOpen = function(v)
                    if open == v then return end
                    open = v
                    if v then
                        if CloseCurrentDropdown and CloseCurrentDropdown ~= setOpen then
                            CloseCurrentDropdown()
                        end
                        CloseCurrentDropdown = setOpen
                        searchBox.Text = ""
                        selectedLbl.Visible = false -- top row becomes the search field
                        searchBox.Visible = true
                        rebuild("")
                        place()
                        outsideConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                                local p, lp, ls = input.Position, list.AbsolutePosition, list.AbsoluteSize
                                local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                                local inList = p.X >= lp.X and p.X <= lp.X + ls.X and p.Y >= lp.Y and p.Y <= lp.Y + ls.Y
                                local inBtn = p.X >= bp.X and p.X <= bp.X + bs.X and p.Y >= bp.Y and p.Y <= bp.Y + bs.Y
                                if not inList and not inBtn then setOpen(false) end
                            end
                        end)
                        table.insert(Nebula.Connections, outsideConn)
                        -- Only auto-focus on mouse devices: on touch, CaptureFocus pops
                        -- the on-screen keyboard which steals focus and instantly closes
                        -- the freshly opened list
                        if not UserInputService.TouchEnabled then
                            task.defer(function()
                                if open then pcall(function() searchBox:CaptureFocus() end) end
                            end)
                        end
                    else
                        if CloseCurrentDropdown == setOpen then CloseCurrentDropdown = nil end
                        if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                        searchBox.Text = ""
                        searchBox.Visible = false
                        selectedLbl.Visible = true -- back to the selection display
                        OpenInlineList(list, frame, stroke, arrow, nil)
                    end
                end

                btn.MouseButton1Click:Connect(function() setOpen(not open) end)
                btn.MouseEnter:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("Accent") }) end
                end)
                btn.MouseLeave:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("ElementStroke") }) end
                end)

                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if not open then return end
                    rebuild(searchBox.Text)
                    place()
                end)

                -- Freeze character while the search box is focused;
                -- tapping the field itself also opens the list (the TextBox sinks the
                -- click, so the button's own click handler never fires)
                searchBox.Focused:Connect(function()
                    SetTyping(true)
                    BeginInteraction() -- freeze column rebalancing while typing
                    if not open then setOpen(true) end
                end)
                -- FocusLost deliberately does NOT close the list: tapping any option or
                -- the on-screen keyboard appearing fired FocusLost and the dropdown
                -- closed itself instantly
                searchBox.FocusLost:Connect(function()
                    SetTyping(false)
                    EndInteraction() -- rebalancing allowed again
                end)

                return {
                    Set = function(v)
                        selected = v
                        Nebula.Flags[flag] = v
                        selectedLbl.Text = v and tostring(v) or "---"
                        selectedLbl.TextColor3 = v and Theme("Text") or Theme("SubText")
                    end,
                    Refresh = function(newOpts)
                        options = newOpts or options
                        rebuild("")
                        if open then place() end
                    end,
                    Get = function() return selected end,
                }
            end

            -- // ELEMENT: MULTI DROPDOWN //-- (floating overlay)
            function section:CreateMultiDropdown(text, options, defaults, callback, flag)
                flag = flag or text
                options = options or {}
                local selected = {}
                for _, v in ipairs(defaults or {}) do
                    table.insert(selected, v)
                end
                local function sync()
                    Nebula.Flags[flag] = copyTable(selected)
                    if callback then callback(copyTable(selected)) end
                end
                Nebula.Flags[flag] = copyTable(selected)

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(56)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local btn = Create("TextButton", {
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, sz(30)),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                btn.Parent = frame
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }).Parent = btn
                local stroke = btn.UIStroke

                local summaryLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -34, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                summaryLbl.Parent = btn

                local function updateSummary()
                    if #selected == 0 then
                        summaryLbl.Text = "Nothing selected"
                        summaryLbl.TextColor3 = Theme("SubText")
                    elseif #selected <= 2 then
                        local parts = {}
                        for i, v in ipairs(selected) do parts[i] = tostring(v) end
                        summaryLbl.Text = table.concat(parts, ", ")
                        summaryLbl.TextColor3 = Theme("Text")
                    else
                        summaryLbl.Text = #selected .. " selected"
                        summaryLbl.TextColor3 = Theme("Text")
                    end
                end
                updateSummary()

                local arrow = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Font = Enum.Font.GothamBold,
                    Text = "v",
                    TextColor3 = Theme("SubText"),
                    TextSize = 13,
                })
                arrow.Parent = btn

                -- Chiyo-style inline list: opens inside the section card, right
                -- below the button, and pushes the rest of the content down with it
                local list = Create("Frame", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.fromOffset(0, sz(54)),
                    -- NO ClipsDescendants: it would clip this frame's own border
                    -- stroke in half. The inner ScrollingFrame does the scrolling,
                    -- so nothing can overflow anyway.
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = frame

                local scroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme("Accent"),
                    BorderSizePixel = 0,
                    ZIndex = 61,
                }, {
                    Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
                    Create("UIPadding", {
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                    }),
                })
                scroll.Parent = list

                local ROW, GAP, MAXH = sz(26), 3, 150
                local open = false
                local outsideConn = nil

                local function countRows()
                    local n = 0
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then n = n + 1 end
                    end
                    return n
                end

                local function place()
                    OpenInlineList(list, frame, stroke, arrow,
                        math.min(countRows() * (ROW + GAP) + 8, MAXH))
                end

                local optButtons = {}
                local selectAllBtn = nil -- "Select All" row (toggles to "Deselect All")
                local function isSelected(opt)
                    for _, v in ipairs(selected) do
                        if v == opt then return true end
                    end
                    return false
                end

                local function refreshOptionButtons()
                    for opt, ob in pairs(optButtons) do
                        if isSelected(opt) then
                            ob.Text = "\u{2022}  " .. tostring(opt)
                            ob.TextColor3 = Theme("Accent")
                        else
                            ob.Text = tostring(opt)
                            ob.TextColor3 = Theme("Text")
                        end
                    end
                    -- the Select All row flips to Deselect All once everything is picked
                    if selectAllBtn then
                        local all = #selected >= #options and #options > 0
                        selectAllBtn.Text = all and "Deselect All" or "Select All"
                        selectAllBtn.TextColor3 = all and Theme("Accent") or Theme("Text")
                    end
                end

                local function rebuild()
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                    end
                    optButtons = {}

                    -- pinned "Select All" row: picks everything, or clears everything
                    -- when every option is already selected
                    selectAllBtn = Create("TextButton", {
                        BackgroundColor3 = Theme("Tertiary"),
                        Size = UDim2.new(1, 0, 0, ROW),
                        Font = Enum.Font.GothamBold,
                        Text = "Select All",
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        ZIndex = 62,
                        LayoutOrder = 0,
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
                    })
                    selectAllBtn.Parent = scroll
                    selectAllBtn.MouseEnter:Connect(function()
                        Tween(selectAllBtn, 0.1, { BackgroundColor3 = Theme("ElementHover") })
                    end)
                    selectAllBtn.MouseLeave:Connect(function()
                        Tween(selectAllBtn, 0.1, { BackgroundColor3 = Theme("Tertiary") })
                    end)
                    selectAllBtn.MouseButton1Click:Connect(function()
                        if #selected >= #options and #options > 0 then
                            selected = {}
                        else
                            selected = copyTable(options)
                        end
                        refreshOptionButtons()
                        updateSummary()
                        sync()
                    end)

                    for i, opt in ipairs(options) do
                        local ob = Create("TextButton", {
                            BackgroundColor3 = Theme("Element"),
                            Size = UDim2.new(1, 0, 0, ROW),
                            Font = Enum.Font.Gotham,
                            Text = tostring(opt),
                            TextColor3 = Theme("Text"),
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 62,
                            LayoutOrder = i,
                        }, {
                            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                            Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
                        })
                        ob.Parent = scroll
                        optButtons[opt] = ob
                        ob.MouseEnter:Connect(function()
                            Tween(ob, 0.1, { BackgroundColor3 = Theme("ElementHover") })
                        end)
                        ob.MouseLeave:Connect(function()
                            Tween(ob, 0.1, { BackgroundColor3 = Theme("Element") })
                        end)
                        ob.MouseButton1Click:Connect(function()
                            if isSelected(opt) then
                                for idx, v in ipairs(selected) do
                                    if v == opt then table.remove(selected, idx) break end
                                end
                            else
                                table.insert(selected, opt)
                            end
                            refreshOptionButtons()
                            updateSummary()
                            sync()
                        end)
                    end
                    refreshOptionButtons()
                end
                rebuild()

                local function setOpen(v)
                    if open == v then return end
                    open = v
                    if v then
                        if CloseCurrentDropdown and CloseCurrentDropdown ~= setOpen then
                            CloseCurrentDropdown()
                        end
                        CloseCurrentDropdown = setOpen
                        place()
                        outsideConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                                local p, lp, ls = input.Position, list.AbsolutePosition, list.AbsoluteSize
                                local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                                local inList = p.X >= lp.X and p.X <= lp.X + ls.X and p.Y >= lp.Y and p.Y <= lp.Y + ls.Y
                                local inBtn = p.X >= bp.X and p.X <= bp.X + bs.X and p.Y >= bp.Y and p.Y <= bp.Y + bs.Y
                                if not inList and not inBtn then setOpen(false) end
                            end
                        end)
                        table.insert(Nebula.Connections, outsideConn)
                    else
                        if CloseCurrentDropdown == setOpen then CloseCurrentDropdown = nil end
                        if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                        OpenInlineList(list, frame, stroke, arrow, nil)
                    end
                end

                btn.MouseButton1Click:Connect(function() setOpen(not open) end)
                btn.MouseEnter:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("Accent") }) end
                end)
                btn.MouseLeave:Connect(function()
                    if not open then Tween(stroke, 0.12, { Color = Theme("ElementStroke") }) end
                end)

                return {
                    Set = function(list2)
                        selected = {}
                        for _, v in ipairs(list2 or {}) do table.insert(selected, v) end
                        refreshOptionButtons()
                        updateSummary()
                        Nebula.Flags[flag] = copyTable(selected)
                    end,
                    Get = function() return copyTable(selected) end,
                }
            end

            -- // ELEMENT: TEXTBOX //--
            function section:CreateTextbox(text, placeholder, callback, flag)
                flag = flag or text
                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(56)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local box = Create("TextBox", {
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, sz(30)),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    PlaceholderText = placeholder or "",
                    PlaceholderColor3 = Theme("SubText"),
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
                })
                box.Parent = frame

                -- Freeze character movement while typing
                box.Focused:Connect(function()
                    SetTyping(true)
                    BeginInteraction() -- freeze column rebalancing while typing
                end)
                box.FocusLost:Connect(function(enter)
                    SetTyping(false)
                    EndInteraction()
                    Nebula.Flags[flag] = box.Text
                    if callback then callback(box.Text, enter) end
                end)
                return box
            end

            -- // ELEMENT: KEYBIND //--
            function section:CreateKeybind(text, default, callback, flag)
                flag = flag or text
                local key = default
                Nebula.Flags[flag] = key

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(32)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -80, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                lbl.Parent = frame

                local btn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(sz(70), sz(24)),
                    Font = Enum.Font.GothamBold,
                    Text = key and key.Name or "None",
                    TextColor3 = Theme("Accent"),
                    TextSize = 12,
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                })
                btn.Parent = frame

                local listening = false
                local pendingKey = nil -- staged candidate, not yet applied

                -- apply the staged key: save it, repaint the button (the callback is
                -- NOT fired here — it is the activation bind, not an on-change event)
                local function applyCandidate()
                    key = pendingKey
                    Nebula.Flags[flag] = key
                    btn.Text = key and key.Name or "None"
                    btn.TextColor3 = Theme("Accent")
                    pendingKey = nil
                end

                -- listening look: accent-filled button with "..." + accent hint on the
                -- label + glowing stroke, so it's impossible to miss that a rebind
                -- is being captured
                local bindStroke = Create("UIStroke", {
                    Color = Theme("Accent"),
                    Thickness = 2.5,
                    Transparency = 1,
                })
                bindStroke.Parent = btn

                local function setListening(on)
                    listening = on
                    SetTyping(on) -- freeze character while capturing a key
                    if on then
                        pendingKey = nil -- nothing staged yet: old bind stays active
                        btn.Text = "..."
                        btn.TextSize = 15
                        btn.TextColor3 = Theme("Background")
                        Tween(btn, 0.12, { BackgroundColor3 = Theme("Accent") })
                        Tween(bindStroke, 0.12, { Transparency = 0.2 })
                        lbl.Text = text .. " — press a key, then Enter / click"
                        lbl.TextColor3 = Theme("Accent")
                    else
                        btn.Text = key and key.Name or "None"
                        btn.TextSize = 12
                        btn.TextColor3 = Theme("Accent")
                        Nebula.Flags[flag] = key
                        Tween(btn, 0.12, { BackgroundColor3 = Theme("Element") })
                        Tween(bindStroke, 0.12, { Transparency = 1 })
                        lbl.Text = text
                        lbl.TextColor3 = Theme("Text")
                    end
                end

                local lastConfirm = 0
                btn.MouseButton1Click:Connect(function()
                    -- the click that confirms capture also lands here (press fires
                    -- InputBegan first, the click event fires on release) — don't re-enter
                    if os.clock() - lastConfirm < 0.15 then return end
                    setListening(not listening)
                end)

                local conn = UserInputService.InputBegan:Connect(function(input, gp)
                    if listening then
                        -- While capturing, accept EVERYTHING — movement keys (W, Space,
                        -- etc.) are flagged gameProcessed, so honoring gp here would make
                        -- them impossible to bind
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                setListening(false) -- Escape = cancel: the old bind stays
                            elseif input.KeyCode == Enum.KeyCode.Return
                            or input.KeyCode == Enum.KeyCode.KeypadEnter then
                                if pendingKey then applyCandidate() end -- Enter = apply
                                setListening(false)
                            else
                                -- STAGE ONLY: the button previews the key dimmed; the
                                -- old bind keeps working until Enter / click confirms
                                pendingKey = input.KeyCode
                                btn.Text = pendingKey.Name
                                btn.TextColor3 = Theme("SubText")
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.MouseButton2 then
                            -- any click = apply the staged key
                            if pendingKey then applyCandidate() end
                            lastConfirm = os.clock()
                            setListening(false)
                        end
                    elseif not gp then
                        -- Activation path: gameProcessed stays ignored here so clicking
                        -- UI never fires other elements' binds
                        if key and input.KeyCode == key then
                            if callback then callback() end
                        end
                    end
                end)
                table.insert(Nebula.Connections, conn)
                return btn
            end

            -- // ELEMENT: COLOR SWATCH //-- simple color display: a small swatch
            -- that applies a random pastel shade on click (the full picker was
            -- removed — it picked colors unreliably). Set() still accepts any Color3.
            function section:CreateColorPicker(text, default, callback, flag)
                flag = flag or text
                local color = default or Color3.fromRGB(255, 255, 255)
                Nebula.Flags[flag] = color

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, sz(32)),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local swatch = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = color,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(sz(28), sz(28)),
                    Text = "",
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                swatch.Parent = frame

                local function apply(c, silent)
                    color = c
                    Nebula.Flags[flag] = c
                    swatch.BackgroundColor3 = c
                    if not silent and callback then callback(c) end
                end

                swatch.MouseButton1Click:Connect(function()
                    -- cycle through pleasant preset shades on click
                    local presets = {
                        Color3.fromRGB(59, 234, 255), Color3.fromRGB(126, 87, 255),
                        Color3.fromRGB(255, 92, 122), Color3.fromRGB(66, 226, 137),
                        Color3.fromRGB(255, 184, 77), Color3.fromRGB(255, 255, 255),
                    }
                    local nextIdx = 1
                    for i, c in ipairs(presets) do
                        if c == color then nextIdx = (i % #presets) + 1 break end
                    end
                    apply(presets[nextIdx])
                end)

                apply(color, true) -- set visuals without firing the callback

                return {
                    Set = function(c)
                        apply(c)
                    end,
                    Get = function() return color end,
                }
            end

            table.insert(tab.Sections, section)
            return section
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    -- // NOTIFICATIONS //-- stacked bottom-right: each new toast slots below the
    -- previous ones instead of drawing on top of them, and the stack re-flows
    -- when a toast disappears
    local activeNotifs = {}

    local function repositionNotifs()
        local offset = 20
        for i = #activeNotifs, 1, -1 do
            local n = activeNotifs[i]
            local h = n.AbsoluteSize.Y
            if h > 0 then
                Tween(n, 0.25, { Position = UDim2.new(1, -20, 1, -(offset + h)) })
                offset = offset + h + 8
            end
        end
    end

    function self:Notify(title, message, duration)
        duration = duration or 4
        local notifGui = Create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Theme("Secondary"),
            Position = UDim2.new(1, -20, 1, -20),
            -- Height grows with the wrapped message: a fixed 80px clipped long
            -- texts off. Width stays fixed at 280.
            Size = UDim2.fromOffset(280, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 100,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create("UIStroke", { Color = Theme("Accent"), Thickness = 1, Transparency = 0.5 }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
            }),
        })
        notifGui.Parent = ScreenGui

        local t = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = Theme("Text"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 101,
        })
        t.Parent = notifGui

        local m = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 20),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = message,
            TextColor3 = Theme("SubText"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 101,
        })
        m.Parent = notifGui

        notifGui.Position = UDim2.new(1, 300, 1, -20)
        table.insert(activeNotifs, notifGui)
        -- Slide into its stack slot once the first layout pass has sized the
        -- auto-height frame; the AbsoluteSize hook catches late layout too
        notifGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if notifGui.Parent then repositionNotifs() end
        end)
        task.defer(function()
            if notifGui.Parent then repositionNotifs() end
        end)
        task.delay(duration, function()
            local idx = table.find(activeNotifs, notifGui)
            if idx then
                table.remove(activeNotifs, idx)
                -- re-flow the stack NOW, in parallel with the slide-out: the
                -- remaining toasts glide down while this one slides away instead
                -- of jerking down only after the slide-out finishes
                repositionNotifs()
            end
            if notifGui and notifGui.Parent then
                Tween(notifGui, 0.3, { Position = UDim2.new(1, 300, 1, -20) })
                task.wait(0.3)
                notifGui:Destroy()
            end
        end)
    end

    -- // SETTINGS / KEYBIND TOGGLE //--
    self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            -- overlays now live on the ScreenGui: close them so they don't linger
            -- on screen when the window itself is hidden
            if CloseCurrentDropdown then CloseCurrentDropdown() end
            Main.Visible = not Main.Visible
        end
    end)
    table.insert(Nebula.Connections, toggleConn)

    -- // THEME SWITCHING //--
    function self:SetTheme(name)
        if not Nebula.Themes[name] then return end
        local old = Nebula.Themes[Nebula.Theme]
        local new = Nebula.Themes[name]
        Nebula.Theme = name
        -- Remap EVERY descendant whose color matches the old palette -> new palette.
        -- Colors must be compared by VALUE: Color3 is a userdata and userdata table
        -- keys hash by identity, so the previous reverse-lookup map never matched
        -- anything and elements only repainted when their hover handlers re-read Theme().
        local function mapColor(c)
            for k, v in pairs(old) do
                if c == v then return new[k] end
            end
            return nil
        end
        for _, obj in ipairs(Main:GetDescendants()) do
            if obj:IsA("GuiObject") then
                local mapped = mapColor(obj.BackgroundColor3)
                if mapped then obj.BackgroundColor3 = mapped end
                if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
                    mapped = mapColor(obj.TextColor3)
                    if mapped then obj.TextColor3 = mapped end
                end
                if obj:IsA("TextBox") then
                    mapped = mapColor(obj.PlaceholderColor3)
                    if mapped then obj.PlaceholderColor3 = mapped end
                end
            elseif obj:IsA("UIStroke") then
                local mapped = mapColor(obj.Color)
                if mapped then obj.Color = mapped end
            elseif obj:IsA("ScrollingFrame") then
                local mapped = mapColor(obj.ScrollBarImageColor3)
                if mapped then obj.ScrollBarImageColor3 = mapped end
            end
        end
        Main.BackgroundColor3 = new.Background
        Title.TextColor3 = new.Text
        -- the title text fades into the accent: repaint that gradient too
        titleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, new.Accent),
        })
        self:Notify("Theme", "Switched to " .. name .. " theme", 2)
    end

    -- // CONFIG SAVE / LOAD //--
    function self:SaveConfig(name)
        name = name or "default"
        local ok, err = pcall(function()
            if not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
            local data = {}
            for k, v in pairs(Nebula.Flags) do
                data[k] = typeof(v) == "EnumItem" and v.Name or v
            end
            writefile(self.ConfigFolder .. "/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(data))
        end)
        self:Notify("Config", ok and ("Saved config: " .. name) or ("Error: " .. tostring(err)), 3)
    end

    function self:LoadConfig(name)
        name = name or "default"
        local path = self.ConfigFolder .. "/" .. name .. ".json"
        local ok, result = pcall(function()
            if not isfile(path) then return nil end
            return game:GetService("HttpService"):JSONDecode(readfile(path))
        end)
        if ok and result then
            for k, v in pairs(result) do
                if Nebula.Flags[k] ~= nil then
                    Nebula.Flags[k] = v
                end
            end
            self:Notify("Config", "Loaded config: " .. name, 3)
        else
            self:Notify("Config", "Config not found: " .. name, 3)
        end
    end

    Nebula.Windows = Nebula.Windows or {}
    table.insert(Nebula.Windows, self)

    self:Notify("Liquid Hub", "Welcome, " .. LocalPlayer.Name .. "!", 3)
    return self
end

-- // DESTROY //--
function Nebula:Destroy(window)
    for _, c in ipairs(Nebula.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Nebula.Connections = {}
    if window and window.ScreenGui then
        window.ScreenGui:Destroy()
    end
end

return Nebula
