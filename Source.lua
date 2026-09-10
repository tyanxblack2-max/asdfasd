--[[
    ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗
    ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗
    ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║
    ██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║
    ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║
    ██║  ╚███║╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝

    LIQUID HUB UI LIBRARY v2.1 — "Deep Water"
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

local function MakeDraggable(dragInput, dragTarget)
    local dragging, dragStart, startPos = false, nil, nil
    dragInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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

local function Ripple(inst, color)
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
    self.SubTitle = config.SubTitle or "v2.1"

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

    local Main = Create("CanvasGroup", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme("Background"),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self.Width, self.Height),
        Active = true,
        ClipsDescendants = true, -- minimize pop-in: sidebar/footer must never spill outside the 40px title bar
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Name = "Stroke", Color = Theme("ElementStroke"), Thickness = 1.5, Transparency = 0 }),
    })
    Main.Parent = ScreenGui

    -- // POP-IN — quick fade + expand from the title bar (WindUI-style) //--
    Main.Size = UDim2.fromOffset(self.Width, 40)
    Main.GroupTransparency = 1
    Tween(Main, 0.35, {
        Size = UDim2.fromOffset(self.Width, self.Height),
        GroupTransparency = 0,
    })

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

    local Title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(0, 300, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "💧  " .. self.TitleText .. "  <font color=\"#3beaff\">|</font>  " .. self.SubTitle,
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
    MakeControl(-12, "X", function()
        Nebula:Destroy(self)
    end, Color3.fromRGB(255, 70, 70))

    MakeControl(-48, "—", function() -- minimize
        minimized = not minimized
        if minimized then
            -- close any open dropdown / color picker overlay first
            if CloseCurrentDropdown then CloseCurrentDropdown() end
            -- Some executors clip CanvasGroup children unreliably: at 40px height the
            -- sidebar/content would bleed OUTSIDE the title bar as visual artifacts,
            -- so hide them explicitly instead of relying on ClipsDescendants
            for _, name in ipairs({ "Sidebar", "Content", "Footer" }) do
                local child = Main:FindFirstChild(name)
                if child then child.Visible = false end
            end
        end
        Tween(Main, 0.25, {
            Size = minimized and UDim2.fromOffset(self.Width, 40)
                or UDim2.fromOffset(self.Width, self.Height),
        })
        if not minimized then
            -- restore panels only once the expand tween has finished
            task.delay(0.26, function()
                if not minimized and Main and Main.Parent then
                    for _, name in ipairs({ "Sidebar", "Content", "Footer" }) do
                        local child = Main:FindFirstChild(name)
                        if child then child.Visible = true end
                    end
                end
            end)
        end
    end)

    MakeDraggable(TitleBar, Main)

    -- Sidebar (Chiyo-style: wide panel with icon + label rows)
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme("Secondary"),
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(0, 150, 1, -62),
    })
    Sidebar.Parent = Main

    local TabHolder = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
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
    })
    Content.Parent = Main

    -- Footer: discord link, like the preview
    local Footer = Create("TextLabel", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -22),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.Gotham,
        RichText = true,
        Text = "discord.gg/liquidhub  |  <b>Liquid Hub v2.1</b>",
        TextColor3 = Theme("SubText"),
        TextSize = 12,
    })
    Footer.Parent = Main

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

    -- // TAB CREATION //--
    function self:CreateTab(name, icon)
        local tab = {}
        tab.Name = name
        tab.Sections = {}

        local btn = Create("TextButton", {
            BackgroundColor3 = Theme("Tertiary"),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 32),
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
        -- Page padding: keeps sections off the window edges
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }).Parent = page

        local left = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        })
        left.Parent = page

        local right = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 9, 0, 0),
            Size = UDim2.new(0.5, -9, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        })
        right.Parent = page

        tab.LeftColumn = left
        tab.RightColumn = right
        tab.Button = btn
        tab.Page = page

        local function select()
            if self.CurrentTab then
                self.CurrentTab.Page.Visible = false
                Tween(self.CurrentTab.Button, 0.2, { BackgroundColor3 = Theme("Tertiary"), TextColor3 = Theme("SubText") })
                self.CurrentTab.Button.UIStroke.Transparency = 1
            end
            self.CurrentTab = tab
            page.Visible = true
            -- WindUI-style content slide on tab switch
            left.Position = UDim2.new(0, 0, 0, 12)
            right.Position = UDim2.new(0.5, 9, 0, 12)
            Tween(left, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
            Tween(right, 0.25, { Position = UDim2.new(0.5, 9, 0, 0) })
            Tween(btn, 0.18, { BackgroundColor3 = Theme("Element"), BackgroundTransparency = 0, TextColor3 = Theme("Accent") })
            stroke.Transparency = 0
            stroke.Color = Theme("Accent")
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
                    LayoutOrder = nextOrder(),
                })
                l.Parent = holder
                return l
            end

            -- // ELEMENT: BUTTON //--
            function section:CreateButton(text, callback)
                local b = Create("TextButton", {
                    BackgroundColor3 = Theme("Element"),
                    Size = UDim2.new(1, 0, 0, 32),
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
                    Size = UDim2.new(1, 0, 0, 32),
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
                    Size = UDim2.fromOffset(44, 22),
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true, -- Back-easing knob overshoot must not poke past the pill edge
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                toggle.Parent = frame
                toggle.ZIndex = btn.ZIndex + 1

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Theme("Text"),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.fromOffset(18, 18),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                knob.Parent = toggle

                local function setState(v, noFire)
                    state = v
                    Nebula.Flags[flag] = v
                    -- ON: knob left edge at 44-3-18 = 23px (AnchorPoint is 0,0.5 — using scale 1,-3 put the knob 15px outside the pill)
                    Tween(knob, 0.18, {
                        Position = v and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
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

            -- // ELEMENT: SLIDER //--
            function section:CreateSlider(text, min, max, default, callback, flag, suffix)
                flag = flag or text
                min = min or 0
                max = max or 100
                local value = default or min
                Nebula.Flags[flag] = value

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 56),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -90, 0, 16),
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
                    Size = UDim2.new(0, 90, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = tostring(value) .. (suffix or ""),
                    TextColor3 = Theme("Accent"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ClearTextOnFocus = false,
                })
                valueBox.Parent = frame

                local bar = Create("TextButton", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = Theme("Tertiary"),
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 8),
                    Text = "",
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                bar.Parent = frame

                local fill = Create("Frame", {
                    BackgroundColor3 = Theme("Accent"),
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                fill.Parent = bar

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Theme("Text"),
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
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
                        valueBox.Text = tostring(value) .. (suffix or "")
                    end
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    if callback then callback(value) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
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
                        dragging = false
                    end
                end)

                -- Commit a typed value: parse the number, clamp to [min, max],
                -- snap to the same integer stepping the drag uses, repaint, fire callback
                local function commitTyped()
                    local n = tonumber(valueBox.Text:match("-?%d+%.?%d*"))
                    if not n then
                        valueBox.Text = tostring(value) .. (suffix or "")
                        return
                    end
                    value = math.clamp(math.floor(n + 0.5), min, max)
                    Nebula.Flags[flag] = value
                    local rel = (value - min) / (max - min)
                    valueBox.Text = tostring(value) .. (suffix or "")
                    Tween(fill, 0.15, { Size = UDim2.new(rel, 0, 1, 0) })
                    Tween(knob, 0.15, { Position = UDim2.new(rel, 0, 0.5, 0) })
                    if callback then callback(value) end
                end

                valueBox.Focused:Connect(function() SetTyping(true) end)
                valueBox.FocusLost:Connect(function(enter)
                    SetTyping(false)
                    commitTyped()
                end)

                return {
                    Set = function(v)
                        v = math.clamp(v, min, max)
                        local rel = (v - min) / (max - min)
                        value = v
                        Nebula.Flags[flag] = v
                        valueBox.Text = tostring(v) .. (suffix or "")
                        Tween(fill, 0.15, { Size = UDim2.new(rel, 0, 1, 0) })
                        Tween(knob, 0.15, { Position = UDim2.new(rel, 0, 0.5, 0) })
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
                    Size = UDim2.new(1, 0, 0, 56),
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
                    Size = UDim2.new(1, 0, 0, 30),
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

                -- Floating list: lives on the window itself, above all content
                local list = Create("CanvasGroup", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    ZIndex = 60,
                    GroupTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = Main

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

                local ROW, GAP, MAXH = 26, 3, 150
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
                        local rel = btn.AbsolutePosition - Main.AbsolutePosition
                        local winW, winH = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
                        -- clamp fully inside the window so the list stroke never crosses its edge
                        local x = math.clamp(rel.X, 6, math.max(6, winW - btn.AbsoluteSize.X - 6))
                        local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < winH - 6
                        local y = below and (rel.Y + btn.AbsoluteSize.Y + 6) or (rel.Y - h - 6)
                        y = math.clamp(y, 6, math.max(6, winH - h - 6))
                        list.Position = UDim2.fromOffset(x, y)
                        list.Size = UDim2.fromOffset(btn.AbsoluteSize.X, h)
                        list.Visible = true
                        Tween(list, 0.15, { GroupTransparency = 0 })
                        Tween(stroke, 0.15, { Color = Theme("Accent") })
                        Tween(arrow, 0.15, { Rotation = 180 })
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
                        Tween(list, 0.12, { GroupTransparency = 1 })
                        Tween(stroke, 0.12, { Color = Theme("ElementStroke") })
                        Tween(arrow, 0.12, { Rotation = 0 })
                        task.delay(0.13, function()
                            if not open and list and list.Parent then list.Visible = false end
                        end)
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
                            list.Size = UDim2.fromOffset(btn.AbsoluteSize.X,
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
                    Size = UDim2.new(1, 0, 0, 56),
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
                    Size = UDim2.new(1, 0, 0, 30),
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

                -- Floating list lives on the window, above all content
                local list = Create("CanvasGroup", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    ZIndex = 60,
                    GroupTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = Main

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

                local ROW, GAP, MAXH = 26, 3, 150
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
                    local h = math.min(countRows() * (ROW + GAP) + 8, MAXH)
                    local rel = btn.AbsolutePosition - Main.AbsolutePosition
                    local winW, winH = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
                    -- clamp fully inside the window so the list stroke never crosses its edge
                    local x = math.clamp(rel.X, 6, math.max(6, winW - btn.AbsoluteSize.X - 6))
                    local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < winH - 6
                    local y = below and (rel.Y + btn.AbsoluteSize.Y + 6) or (rel.Y - h - 6)
                    y = math.clamp(y, 6, math.max(6, winH - h - 6))
                    list.Position = UDim2.fromOffset(x, y)
                    list.Size = UDim2.fromOffset(btn.AbsoluteSize.X, h)
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
                        list.Visible = true
                        Tween(list, 0.15, { GroupTransparency = 0 })
                        Tween(stroke, 0.15, { Color = Theme("Accent") })
                        Tween(arrow, 0.15, { Rotation = 180 })
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
                        Tween(list, 0.12, { GroupTransparency = 1 })
                        Tween(stroke, 0.12, { Color = Theme("ElementStroke") })
                        Tween(arrow, 0.12, { Rotation = 0 })
                        task.delay(0.13, function()
                            if not open and list and list.Parent then list.Visible = false end
                        end)
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
                    if not open then setOpen(true) end
                end)
                -- FocusLost deliberately does NOT close the list: tapping any option or
                -- the on-screen keyboard appearing fired FocusLost and the dropdown
                -- closed itself instantly
                searchBox.FocusLost:Connect(function()
                    SetTyping(false)
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
                    Nebula.Flags[flag] = table.clone(selected)
                    if callback then callback(table.clone(selected)) end
                end
                Nebula.Flags[flag] = table.clone(selected)

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 56),
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
                    Size = UDim2.new(1, 0, 0, 30),
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

                -- Floating list lives on the window, above all content
                local list = Create("CanvasGroup", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    ZIndex = 60,
                    GroupTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                list.Parent = Main

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

                local ROW, GAP, MAXH = 26, 3, 150
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
                    local h = math.min(countRows() * (ROW + GAP) + 8, MAXH)
                    local rel = btn.AbsolutePosition - Main.AbsolutePosition
                    local winW, winH = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
                    -- clamp fully inside the window so the list stroke never crosses its edge
                    local x = math.clamp(rel.X, 6, math.max(6, winW - btn.AbsoluteSize.X - 6))
                    local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < winH - 6
                    local y = below and (rel.Y + btn.AbsoluteSize.Y + 6) or (rel.Y - h - 6)
                    y = math.clamp(y, 6, math.max(6, winH - h - 6))
                    list.Position = UDim2.fromOffset(x, y)
                    list.Size = UDim2.fromOffset(btn.AbsoluteSize.X, h)
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
                            selected = table.clone(options)
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
                        list.Visible = true
                        Tween(list, 0.15, { GroupTransparency = 0 })
                        Tween(stroke, 0.15, { Color = Theme("Accent") })
                        Tween(arrow, 0.15, { Rotation = 180 })
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
                        Tween(list, 0.12, { GroupTransparency = 1 })
                        Tween(stroke, 0.12, { Color = Theme("ElementStroke") })
                        Tween(arrow, 0.12, { Rotation = 0 })
                        task.delay(0.13, function()
                            if not open and list and list.Parent then list.Visible = false end
                        end)
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
                        Nebula.Flags[flag] = table.clone(selected)
                    end,
                    Get = function() return table.clone(selected) end,
                }
            end

            -- // ELEMENT: TEXTBOX //--
            function section:CreateTextbox(text, placeholder, callback, flag)
                flag = flag or text
                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 56),
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
                    Size = UDim2.new(1, 0, 0, 30),
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
                box.Focused:Connect(function() SetTyping(true) end)
                box.FocusLost:Connect(function(enter)
                    SetTyping(false)
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
                    Size = UDim2.new(1, 0, 0, 32),
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
                })
                lbl.Parent = frame

                local btn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(70, 24),
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
                local preKey = nil

                -- listening look: accent-filled button + hint on the label, so it's
                -- obvious a rebind is being captured
                local bindStroke = Create("UIStroke", {
                    Color = Theme("Accent"),
                    Thickness = 1.5,
                    Transparency = 1,
                })
                bindStroke.Parent = btn

                local function setListening(on)
                    listening = on
                    SetTyping(on) -- freeze character while capturing a key
                    if on then
                        preKey = key
                        btn.Text = "..."
                        btn.TextColor3 = Theme("Background")
                        Tween(btn, 0.12, { BackgroundColor3 = Theme("Accent") })
                        Tween(bindStroke, 0.12, { Transparency = 0 })
                        lbl.Text = text .. "  (press a key, then Enter / click)"
                    else
                        btn.Text = key and key.Name or "None"
                        btn.TextColor3 = Theme("Accent")
                        Nebula.Flags[flag] = key
                        Tween(btn, 0.12, { BackgroundColor3 = Theme("Element") })
                        Tween(bindStroke, 0.12, { Transparency = 1 })
                        lbl.Text = text
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
                                key = preKey -- Escape = cancel, keep the old bind
                                setListening(false)
                            elseif input.KeyCode == Enum.KeyCode.Return
                            or input.KeyCode == Enum.KeyCode.KeypadEnter then
                                setListening(false) -- Enter = confirm
                            else
                                key = input.KeyCode
                                btn.Text = key.Name -- shown immediately, confirmed on Enter/click
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.MouseButton2 then
                            -- any click = confirm the pending key
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

            -- // ELEMENT: COLOR PICKER //-- (floating overlay, exact HEX input)
            function section:CreateColorPicker(text, default, callback, flag)
                flag = flag or text
                local color = default or Color3.fromRGB(255, 255, 255)
                Nebula.Flags[flag] = color

                local frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
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
                    Size = UDim2.fromOffset(28, 28),
                    Text = "",
                    AutoButtonColor = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                swatch.Parent = frame

                -- Floating panel on the window itself (like dropdowns), above all content
                local pickerOpen = false
                local outsideConn = nil
                local closePicker
                local picker = Create("CanvasGroup", {
                    BackgroundColor3 = Theme("Secondary"),
                    Visible = false,
                    ZIndex = 60,
                    GroupTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                picker.Parent = Main

                -- Saturation/value pad: hue base + white gradient (L→R) + black shade (top→bottom)
                local svPad = Create("TextButton", {
                    BackgroundColor3 = color,
                    Position = UDim2.fromOffset(10, 10),
                    Size = UDim2.new(1, -20, 0, 100),
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true,
                    ZIndex = 61,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Rotation = 0,
                    }),
                })
                svPad.Parent = picker

                local shade = Create("Frame", {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.fromScale(1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 62,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1), -- top: full value
                            NumberSequenceKeypoint.new(1, 0), -- bottom: black
                        }),
                        Rotation = 90,
                    }),
                })
                shade.Parent = svPad

                local padCursor = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.fromOffset(10, 10),
                    BorderSizePixel = 0,
                    ZIndex = 63,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.4 }),
                })
                padCursor.Parent = svPad

                -- Horizontal hue bar (draggable, with cursor)
                local hueBar = Create("TextButton", {
                    Position = UDim2.fromOffset(10, 118),
                    Size = UDim2.new(1, -20, 0, 12),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 61,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                        }),
                    }),
                })
                hueBar.Parent = picker

                local hueCursor = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.fromOffset(4, 16),
                    BorderSizePixel = 0,
                    ZIndex = 62,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.4 }),
                })
                hueCursor.Parent = hueBar

                -- Exact color entry: HEX box (e.g. #3BEAFF)
                local hexRow = Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 140),
                    Size = UDim2.new(1, -20, 0, 24),
                    ZIndex = 61,
                })
                hexRow.Parent = picker

                local hexLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(34, 24),
                    Font = Enum.Font.GothamBold,
                    Text = "HEX",
                    TextColor3 = Theme("SubText"),
                    TextSize = 11,
                    ZIndex = 61,
                })
                hexLbl.Parent = hexRow

                local hexBox = Create("TextBox", {
                    BackgroundColor3 = Theme("Element"),
                    Position = UDim2.fromOffset(38, 0),
                    Size = UDim2.new(1, -38, 1, 0),
                    Font = Enum.Font.Code,
                    Text = "",
                    PlaceholderText = "#RRGGBB",
                    PlaceholderColor3 = Theme("SubText"),
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    ClearTextOnFocus = false,
                    ZIndex = 61,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
                })
                hexBox.Parent = hexRow

                local hue, sat, val = Color3.toHSV(color)

                local function parseHex(str)
                    str = tostring(str):gsub("#", ""):gsub("%s", "")
                    if #str ~= 6 then return nil end
                    local n = tonumber(str, 16)
                    if not n then return nil end
                    return Color3.fromRGB(
                        math.floor(n / 65536) % 256,
                        math.floor(n / 256) % 256,
                        n % 256)
                end

                local function apply(c, silent)
                    color = c
                    hue, sat, val = Color3.toHSV(c)
                    Nebula.Flags[flag] = c
                    swatch.BackgroundColor3 = c
                    svPad.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    padCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                    hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                    if not hexBox:IsFocused() then
                        hexBox.Text = string.format("#%02X%02X%02X",
                            math.floor(c.R * 255 + 0.5),
                            math.floor(c.G * 255 + 0.5),
                            math.floor(c.B * 255 + 0.5))
                    end
                    if not silent and callback then callback(c) end
                end

                local function setSV(x, y)
                    sat = math.clamp((x - svPad.AbsolutePosition.X) / math.max(svPad.AbsoluteSize.X, 1), 0, 1)
                    val = 1 - math.clamp((y - svPad.AbsolutePosition.Y) / math.max(svPad.AbsoluteSize.Y, 1), 0, 1)
                    apply(Color3.fromHSV(hue, sat, val))
                end

                local function setHue(x)
                    hue = math.clamp((x - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
                    apply(Color3.fromHSV(hue, sat, val))
                end

                local function setOpen(v)
                    if pickerOpen == v then return end
                    pickerOpen = v
                    if v then
                        if CloseCurrentDropdown and CloseCurrentDropdown ~= closePicker then
                            CloseCurrentDropdown()
                        end
                        CloseCurrentDropdown = closePicker
                        -- place near the swatch, clamped inside the window
                        local w, h = 200, 174
                        local rel = swatch.AbsolutePosition - Main.AbsolutePosition
                        local x = math.clamp(rel.X + swatch.AbsoluteSize.X - w, 6, math.max(6, Main.AbsoluteSize.X - w - 6))
                        local below = rel.Y + swatch.AbsoluteSize.Y + 6 + h < Main.AbsoluteSize.Y - 6
                        local y = below and (rel.Y + swatch.AbsoluteSize.Y + 6) or math.max(6, rel.Y - h - 6)
                        -- keep fully inside the window: the stroke must never cross its edge
                        y = math.clamp(y, 6, math.max(6, Main.AbsoluteSize.Y - h - 6))
                        picker.Position = UDim2.fromOffset(x, y)
                        picker.Size = UDim2.fromOffset(w, h)
                        picker.Visible = true
                        Tween(picker, 0.15, { GroupTransparency = 0 })
                        outsideConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                                local p, lp, ls = input.Position, picker.AbsolutePosition, picker.AbsoluteSize
                                local bp, bs = swatch.AbsolutePosition, swatch.AbsoluteSize
                                local inPicker = p.X >= lp.X and p.X <= lp.X + ls.X and p.Y >= lp.Y and p.Y <= lp.Y + ls.Y
                                local inSwatch = p.X >= bp.X and p.X <= bp.X + bs.X and p.Y >= bp.Y and p.Y <= bp.Y + bs.Y
                                if not inPicker and not inSwatch then setOpen(false) end
                            end
                        end)
                        table.insert(Nebula.Connections, outsideConn)
                    else
                        if CloseCurrentDropdown == closePicker then CloseCurrentDropdown = nil end
                        if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                        Tween(picker, 0.12, { GroupTransparency = 1 })
                        task.delay(0.13, function()
                            if not pickerOpen and picker and picker.Parent then picker.Visible = false end
                        end)
                    end
                end
                closePicker = function() setOpen(false) end

                local svPadDragging, hueDragging = false, false
                svPad.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svPadDragging = true
                        setSV(input.Position.X, input.Position.Y)
                    end
                end)
                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        setHue(input.Position.X)
                    end
                end)
                local moveConn = UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        if svPadDragging then
                            setSV(input.Position.X, input.Position.Y)
                        elseif hueDragging then
                            setHue(input.Position.X)
                        end
                    end
                end)
                local endConn = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svPadDragging = false
                        hueDragging = false
                    end
                end)
                table.insert(Nebula.Connections, moveConn)
                table.insert(Nebula.Connections, endConn)

                swatch.MouseButton1Click:Connect(function() setOpen(not pickerOpen) end)

                hexBox.Focused:Connect(function() SetTyping(true) end)
                hexBox.FocusLost:Connect(function(enter)
                    SetTyping(false)
                    local c = parseHex(hexBox.Text)
                    if c then
                        apply(c) -- exact color from HEX
                    else
                        apply(color, true) -- invalid input: revert the text
                    end
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

    -- // NOTIFICATIONS //--
    function self:Notify(title, message, duration)
        duration = duration or 4
        local notifGui = Create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Theme("Secondary"),
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.fromOffset(280, 80),
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
            Size = UDim2.new(1, 0, 1, -20),
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
        Tween(notifGui, 0.3, { Position = UDim2.new(1, -20, 1, -20) }, Enum.EasingStyle.Back)
        task.delay(duration, function()
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
