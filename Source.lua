--[[
    ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗
    ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗
    ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║
    ██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║
    ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║
    ██║  ╚███║╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝

    LIQUID HUB UI LIBRARY v2.0 — "Deep Water"
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
            dragTarget.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
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
    self.SubTitle = config.SubTitle or "v2.0"

    -- Auto-fit to small screens (phones)
    local viewport = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
    self.Width = math.floor(math.min(config.Width or 680, viewport.X - 30))
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
    MakeControl(-12, "—", function() -- minimize
        minimized = not minimized
        local target = minimized and UDim2.fromOffset(self.Width, 40) or UDim2.fromOffset(self.Width, self.Height)
        Tween(Main, 0.25, { Size = target })
    end)

    MakeControl(-48, "X", function()
        Nebula:Destroy(self)
    end, Color3.fromRGB(255, 70, 70))

    MakeDraggable(TitleBar, Main)

    -- Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme("Secondary"),
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(0, 60, 1, -40),
    })
    Sidebar.Parent = Main

    local TabHolder = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 8),
        Size = UDim2.new(1, -12, 1, -16),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })
    TabHolder.Parent = Sidebar

    -- Content area
    local Content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(60, 40),
        Size = UDim2.new(1, -60, 1, -40),
    })
    Content.Parent = Main

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
            Size = UDim2.fromOffset(46, 46),
            Font = Enum.Font.GothamBold,
            Text = icon or name:sub(1, 1),
            TextColor3 = Theme("SubText"),
            TextSize = 18,
            AutoButtonColor = false,
            LayoutOrder = #self.Tabs + 1,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })
        btn.Parent = self.TabHolder

        local stroke = Create("UIStroke", {
            Color = Theme("ElementStroke"),
            Thickness = 1,
            Transparency = 1,
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
            Tween(btn, 0.18, { BackgroundColor3 = Theme("Element"), TextColor3 = Theme("Accent") })
            stroke.Transparency = 0
            stroke.Color = Theme("Accent")
        end

        btn.MouseButton1Click:Connect(select)
        btn.MouseEnter:Connect(function()
            if self.CurrentTab ~= tab then
                Tween(btn, 0.15, { TextColor3 = Theme("Text") })
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.CurrentTab ~= tab then
                Tween(btn, 0.15, { TextColor3 = Theme("SubText") })
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

                local toggle = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme("Tertiary"),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(44, 22),
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                toggle.Parent = frame

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
                    Tween(knob, 0.18, {
                        Position = v and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                        BackgroundColor3 = v and Color3.fromRGB(255, 255, 255) or Theme("Text"),
                    }, Enum.EasingStyle.Back)
                    Tween(toggle, 0.15, { BackgroundColor3 = v and Theme("Accent") or Theme("Tertiary") })
                    if not noFire and callback then callback(v) end
                end
                setState(state, true)

                btn.MouseButton1Click:Connect(function() setState(not state) end)
                toggle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        setState(not state)
                    end
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
                    Size = UDim2.new(1, 0, 0, 44),
                    LayoutOrder = nextOrder(),
                })
                frame.Parent = holder

                local lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -70, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextColor3 = Theme("Text"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                lbl.Parent = frame

                local valueLbl = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, 70, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = tostring(value) .. (suffix or ""),
                    TextColor3 = Theme("Accent"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                valueLbl.Parent = frame

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
                    valueLbl.Text = tostring(value) .. (suffix or "")
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

                return {
                    Set = function(v)
                        v = math.clamp(v, min, max)
                        local rel = (v - min) / (max - min)
                        value = v
                        Nebula.Flags[flag] = v
                        valueLbl.Text = tostring(v) .. (suffix or "")
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
                local selected = default or options[1]
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
                    Text = selected or "Select...",
                    TextColor3 = Theme("Text"),
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
                        local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < Main.AbsoluteSize.Y - 6
                        list.Position = below
                            and UDim2.fromOffset(rel.X, rel.Y + btn.AbsoluteSize.Y + 6)
                            or UDim2.fromOffset(rel.X, math.max(6, rel.Y - h - 6))
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
                        selectedLbl.Text = tostring(v)
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
                local selected = default or options[1]
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
                    local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < Main.AbsoluteSize.Y - 6
                    list.Position = below
                        and UDim2.fromOffset(rel.X, rel.Y + btn.AbsoluteSize.Y + 6)
                        or UDim2.fromOffset(rel.X, math.max(6, rel.Y - h - 6))
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
                        task.defer(function()
                            if open then searchBox:CaptureFocus() end
                        end)
                    else
                        if CloseCurrentDropdown == setOpen then CloseCurrentDropdown = nil end
                        if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                        searchBox.Text = ""
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

                -- Freeze character while the search box is focused
                searchBox.Focused:Connect(function() SetTyping(true) end)
                searchBox.FocusLost:Connect(function()
                    SetTyping(false)
                    if open then setOpen(false) end
                end)

                return {
                    Set = function(v)
                        selected = v
                        Nebula.Flags[flag] = v
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
                    local below = rel.Y + btn.AbsoluteSize.Y + 6 + h < Main.AbsoluteSize.Y - 6
                    list.Position = below
                        and UDim2.fromOffset(rel.X, rel.Y + btn.AbsoluteSize.Y + 6)
                        or UDim2.fromOffset(rel.X, math.max(6, rel.Y - h - 6))
                    list.Size = UDim2.fromOffset(btn.AbsoluteSize.X, h)
                end

                local optButtons = {}
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
                end

                local function rebuild()
                    for _, c in ipairs(scroll:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                    end
                    optButtons = {}
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
                btn.MouseButton1Click:Connect(function()
                    listening = not listening
                    SetTyping(listening) -- freeze character while capturing a key
                    btn.Text = listening and "..." or (key and key.Name or "None")
                end)

                local conn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            btn.Text = key.Name
                            Nebula.Flags[flag] = key
                            listening = false
                            SetTyping(false)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            listening = false
                            SetTyping(false)
                            btn.Text = key and key.Name or "None"
                        end
                    elseif key and input.KeyCode == key then
                        if callback then callback() end
                    end
                end)
                table.insert(Nebula.Connections, conn)
                return btn
            end

            -- // ELEMENT: COLOR PICKER //--
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

                local pickerOpen = false
                local picker = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Theme("Secondary"),
                    Position = UDim2.new(1, 0, 1, 6),
                    Size = UDim2.fromOffset(180, 140),
                    Visible = false,
                    ZIndex = 50,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme("ElementStroke"), Thickness = 1 }),
                })
                picker.Parent = swatch

                local saturation = Create("TextButton", {
                    BackgroundColor3 = color,
                    Position = UDim2.fromOffset(10, 10),
                    Size = UDim2.new(1, -20, 0, 70),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 51,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Rotation = 0,  -- horizontal white→transparent
                    }),
                })
                saturation.Parent = picker

                local hueBar = Create("TextButton", {
                    Position = UDim2.fromOffset(10, 90),
                    Size = UDim2.new(1, -20, 0, 12),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 51,
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

                local function apply(c)
                    color = c
                    Nebula.Flags[flag] = c
                    swatch.BackgroundColor3 = c
                    saturation.BackgroundColor3 = c
                    if callback then callback(c) end
                end

                swatch.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    picker.Visible = pickerOpen
                end)

                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        local rel = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                        apply(Color3.fromHSV(rel, 1, 1))
                    end
                end)
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
        -- Remap EVERY descendant whose color matches the old palette -> new palette
        local oldMap = {}
        for k, v in pairs(old) do oldMap[v] = k end
        for _, obj in ipairs(Main:GetDescendants()) do
            if obj:IsA("GuiObject") then
                local key = oldMap[obj.BackgroundColor3]
                if key then obj.BackgroundColor3 = new[key] end
                if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
                    local tkey = oldMap[obj.TextColor3]
                    if tkey then obj.TextColor3 = new[tkey] end
                end
                if obj:IsA("TextBox") then
                    local pkey = oldMap[obj.PlaceholderColor3]
                    if pkey then obj.PlaceholderColor3 = new[pkey] end
                end
            elseif obj:IsA("UIStroke") then
                local skey = oldMap[obj.Color]
                if skey then obj.Color = new[skey] end
            elseif obj:IsA("ScrollingFrame") then
                local bkey = oldMap[obj.ScrollBarImageColor3]
                if bkey then obj.ScrollBarImageColor3 = new[bkey] end
            end
        end
        Main.BackgroundColor3 = new.Background
        Title.TextColor3 = new.Text
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
