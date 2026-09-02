-- WindLib: a self-contained UI library written from scratch.
-- Visual reference: WindUI (dark rounded panels, sidebar tabs, traffic dots).
-- Usage:
--   local Lib = loadstring(read("windlib.luau"))()
--   local Window = Lib:CreateWindow({ Title = "My Hub", SubTitle = "v1.0" })
--   local Tab = Window:Tab("Main")
--   Tab:Toggle({ Title = "Auto Farm", Default = false, Callback = function(v) end })

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Lib = {}
Lib.__index = Lib

local DEFAULT_THEME = {
	Background = Color3.fromRGB(13, 14, 17),
	Panel = Color3.fromRGB(20, 22, 27),
	Element = Color3.fromRGB(28, 30, 36),
	ElementHover = Color3.fromRGB(38, 41, 49),
	Stroke = Color3.fromRGB(45, 48, 58),
	Text = Color3.fromRGB(235, 237, 240),
	TextDim = Color3.fromRGB(140, 145, 155),
	Accent = Color3.fromRGB(0, 120, 255),
	Good = Color3.fromRGB(70, 200, 120),
	Bad = Color3.fromRGB(235, 80, 80),
	Warning = Color3.fromRGB(255, 189, 46),
}

local function resolveParent()
	local ok, hui = pcall(function()
		return (gethui and gethui()) or nil
	end)
	if ok and hui then
		return hui
	end
	local core = game:GetService("CoreGui")
	local probe = Instance.new("Folder")
	local writable = pcall(function()
		probe.Parent = core
	end)
	if writable then
		probe:Destroy()
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = instance
	return c
end

local function stroke(instance, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or DEFAULT_THEME.Stroke
	s.Thickness = thickness or 1
	s.Parent = instance
	return s
end

local function tween(instance, time, props)
	local t = TweenService:Create(instance, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function Lib:CreateWindow(config)
	config = config or {}
	local theme = {}
	for k, v in pairs(DEFAULT_THEME) do
		theme[k] = v
	end
	if config.Theme then
		for k, v in pairs(config.Theme) do
			theme[k] = v
		end
	end

	local size = config.Size or UDim2.fromOffset(680, 440)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

	local old = resolveParent():FindFirstChild(config.Name or "WindLibWindow")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = config.Name or "WindLibWindow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	gui.Parent = resolveParent()

	local window = {}
	local destroyed = false

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = size
	root.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
	root.BackgroundColor3 = theme.Background
	root.BorderSizePixel = 0
	root.Active = true
	root.Parent = gui
	corner(root, 12)
	stroke(root, theme.Stroke, 1)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.Parent = root
	corner(header, 12)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(58, 4)
	title.Size = UDim2.new(1, -80, 0, 20)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = theme.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = config.Title or "Window"
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(58, 24)
	subtitle.Size = UDim2.new(1, -80, 0, 14)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 11
	subtitle.TextColor3 = theme.TextDim
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = config.SubTitle or ""
	subtitle.Parent = header

	local dotColors = {
		{Color3.fromRGB(255, 95, 86), "close"},
		{Color3.fromRGB(255, 189, 46), "minimize"},
		{Color3.fromRGB(39, 201, 63), "reload"},
	}
	local dots = {}
	for i, pair in ipairs(dotColors) do
		local d = Instance.new("TextButton")
		d.Size = UDim2.fromOffset(12, 12)
		d.Position = UDim2.fromOffset(16 + (i - 1) * 18, 16)
		d.BackgroundColor3 = pair[1]
		d.Text = ""
		d.AutoButtonColor = false
		d.BorderSizePixel = 0
		d.Parent = header
		corner(d, 6)
		dots[pair[2]] = d
	end

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Position = UDim2.fromOffset(0, 44)
	sidebar.Size = UDim2.new(0, 180, 1, -44)
	sidebar.BackgroundColor3 = theme.Panel
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 2
	sidebar.ScrollBarImageColor3 = theme.Stroke
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.Parent = root

	local sidebarLayout = Instance.new("UIListLayout", sidebar)
	sidebarLayout.Padding = UDim.new(0, 6)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local sidebarPad = Instance.new("UIPadding", sidebar)
	sidebarPad.PaddingTop = UDim.new(0, 12)
	sidebarPad.PaddingLeft = UDim.new(0, 10)
	sidebarPad.PaddingRight = UDim.new(0, 10)

	local content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(180, 44)
	content.Size = UDim2.new(1, -180, 1, -44)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 2
	content.ScrollBarImageColor3 = theme.Stroke
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ClipsDescendants = true
	content.Parent = root
	local contentLayout = Instance.new("UIListLayout", content)
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local contentPad = Instance.new("UIPadding", content)
	contentPad.PaddingTop = UDim.new(0, 14)
	contentPad.PaddingLeft = UDim.new(0, 18)
	contentPad.PaddingRight = UDim.new(0, 18)
	contentPad.PaddingBottom = UDim.new(0, 14)

	local pages, tabButtons = {}, {}
	local minimized = false

	local function setMinimized(state)
		minimized = state
		sidebar.Visible = not state
		content.Visible = not state
		root.Size = state and UDim2.fromOffset(size.X.Offset, 44) or size
	end

	local selectedTabName = nil
	local function selectTabImpl(name)
		selectedTabName = name
		for n, page in pairs(pages) do
			page.Visible = (n == name)
			tabButtons[n].BackgroundColor3 = (n == name) and theme.Element or theme.Panel
			tabButtons[n].TextColor3 = (n == name) and theme.Text or theme.TextDim
		end
	end

	dots.minimize.Activated:Connect(function()
		setMinimized(not minimized)
	end)
	dots.close.Activated:Connect(function()
		destroyed = true
		gui:Destroy()
	end)
	dots.reload.Activated:Connect(function()
		for _, page in pairs(pages) do
			page.Visible = false
		end
		if selectedTabName then
			selectTabImpl(selectedTabName)
		end
	end)

	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = root.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if destroyed or processed then
			return
		end
		if input.KeyCode == toggleKey then
			gui.Enabled = not gui.Enabled
		end
	end)

	function window:SelectTab(name)
		window.SelectedTab = name
		for n, page in pairs(pages) do
			page.Visible = (n == name)
			tabButtons[n].BackgroundColor3 = (n == name) and theme.Element or theme.Panel
			tabButtons[n].TextColor3 = (n == name) and theme.Text or theme.TextDim
		end
	end

	function window:Tab(name, order)
		local page = Instance.new("Frame")
		page.Name = name
		page.BackgroundTransparency = 1
		page.Size = UDim2.new(1, 0, 0, 0)
		page.AutomaticSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = content

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 36)
		btn.BackgroundColor3 = theme.Panel
		btn.TextColor3 = theme.TextDim
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 14
		btn.Text = name
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.LayoutOrder = order or (#pages + 1)
		btn.Parent = sidebar
		corner(btn, 8)
		local bpad = Instance.new("UIPadding", btn)
		bpad.PaddingLeft = UDim.new(0, 14)

		pages[name] = page
		tabButtons[name] = btn
		btn.Activated:Connect(function()
			window:SelectTab(name)
		end)

		local tab = {}

		function tab:Section(text)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1, 0, 0, 20)
			l.Font = Enum.Font.GothamBold
			l.TextSize = 11
			l.TextColor3 = theme.TextDim
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Text = string.upper(text)
			l.LayoutOrder = #page:GetChildren() + 1
			l.Parent = page
			return l
		end

		function tab:Row(height)
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, height or 40)
			row.BackgroundColor3 = theme.Element
			row.BorderSizePixel = 0
			row.LayoutOrder = #page:GetChildren() + 1
			row.Parent = page
			corner(row, 8)
			local hover = Instance.new("TextButton")
			hover.BackgroundTransparency = 1
			hover.Size = UDim2.fromScale(1, 1)
			hover.Text = ""
			hover.ZIndex = 0
			hover.Parent = row
			return row
		end

		function tab:Label(config2)
			local row = tab:Row(36)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromOffset(14, 0)
			t.Size = UDim2.new(1, -28, 1, 0)
			t.Font = Enum.Font.GothamMedium
			t.TextSize = 14
			t.TextColor3 = theme.Text
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Text = config2.Title or ""
			t.Parent = row
			return {
				Set = function(_, text)
					t.Text = text
				end,
			}
		end

		function tab:Paragraph(config2)
			local row = tab:Row(64)
			local titleL = Instance.new("TextLabel")
			titleL.BackgroundTransparency = 1
			titleL.Position = UDim2.fromOffset(14, 8)
			titleL.Size = UDim2.new(1, -28, 0, 16)
			titleL.Font = Enum.Font.GothamBold
			titleL.TextSize = 13
			titleL.TextColor3 = theme.Text
			titleL.TextXAlignment = Enum.TextXAlignment.Left
			titleL.Text = config2.Title or ""
			titleL.Parent = row
			local body = Instance.new("TextLabel")
			body.BackgroundTransparency = 1
			body.Position = UDim2.fromOffset(14, 26)
			body.Size = UDim2.new(1, -28, 1, -34)
			body.Font = Enum.Font.Gotham
			body.TextSize = 12
			body.TextColor3 = theme.TextDim
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
			body.TextWrapped = true
			body.Text = config2.Content or ""
			body.Parent = row
			return {
				Set = function(_, text)
					body.Text = text
				end,
			}
		end

		function tab:Button(config2)
			local row = tab:Row(38)
			local b = Instance.new("TextButton")
			b.BackgroundTransparency = 1
			b.Size = UDim2.fromScale(1, 1)
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 14
			b.TextColor3 = theme.Text
			b.Text = config2.Title or "Button"
			b.Parent = row
			b.MouseEnter:Connect(function()
				row.BackgroundColor3 = theme.ElementHover
			end)
			b.MouseLeave:Connect(function()
				row.BackgroundColor3 = theme.Element
			end)
			b.Activated:Connect(function()
				if config2.Callback then
					config2.Callback()
				end
			end)
			return b
		end

		function tab:Toggle(config2)
			local row = tab:Row(config2.Desc and 52 or 40)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromOffset(14, 0)
			t.Size = UDim2.new(0.6, 0, config2.Desc and 0.55 or 1, 0)
			t.Font = Enum.Font.GothamMedium
			t.TextSize = 14
			t.TextColor3 = theme.Text
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Text = config2.Title or "Toggle"
			t.Parent = row
			if config2.Desc then
				local s = Instance.new("TextLabel")
				s.BackgroundTransparency = 1
				s.Position = UDim2.fromOffset(14, 20)
				s.Size = UDim2.new(1, -100, 0.45, 0)
				s.Font = Enum.Font.Gotham
				s.TextSize = 11
				s.TextColor3 = theme.TextDim
				s.TextXAlignment = Enum.TextXAlignment.Left
				s.TextWrapped = true
				s.Text = config2.Desc
				s.Parent = row
			end
			local state = config2.Default == true
			local holder = Instance.new("TextButton")
			holder.Size = UDim2.fromOffset(44, 24)
			holder.AnchorPoint = Vector2.new(1, 0.5)
			holder.Position = UDim2.new(1, -14, 0.5, 0)
			holder.BackgroundColor3 = state and theme.Accent or theme.Stroke
			holder.Text = ""
			holder.AutoButtonColor = false
			holder.BorderSizePixel = 0
			holder.Parent = row
			corner(holder, 12)
			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(18, 18)
			knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BorderSizePixel = 0
			knob.Parent = holder
			corner(knob, 9)
			local api = {}
			function api:Set(v)
				state = v
				holder.BackgroundColor3 = state and theme.Accent or theme.Stroke
				knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
			end
			holder.Activated:Connect(function()
				api:Set(not state)
				if config2.Callback then
					config2.Callback(state)
				end
			end)
			return api
		end

		function tab:Slider(config2)
			local minV = config2.Min or 0
			local maxV = config2.Max or 100
			local step = config2.Step or 1
			local current = config2.Default or minV
			local row = tab:Row(56)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(14, 8)
			name.Size = UDim2.new(0.6, 0, 0, 16)
			name.Font = Enum.Font.GothamMedium
			name.TextSize = 13
			name.TextColor3 = theme.Text
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Text = config2.Title or "Slider"
			name.Parent = row
			local value = Instance.new("TextLabel")
			value.AnchorPoint = Vector2.new(1, 0)
			value.Position = UDim2.new(1, -14, 0, 8)
			value.Size = UDim2.fromOffset(80, 16)
			value.Font = Enum.Font.GothamBold
			value.TextSize = 13
			value.TextColor3 = theme.Accent
			value.TextXAlignment = Enum.TextXAlignment.Right
			value.Text = tostring(current)
			value.Parent = row
			local bar = Instance.new("Frame")
			bar.Position = UDim2.fromOffset(14, 36)
			bar.Size = UDim2.new(1, -28, 0, 6)
			bar.BackgroundColor3 = theme.Stroke
			bar.BorderSizePixel = 0
			bar.Parent = row
			corner(bar, 3)
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((current - minV) / (maxV - minV), 0, 1, 0)
			fill.BackgroundColor3 = theme.Accent
			fill.BorderSizePixel = 0
			fill.Parent = bar
			corner(fill, 3)
			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(14, 14)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.new((current - minV) / (maxV - minV), 0, 0.5, 0)
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BorderSizePixel = 0
			knob.Parent = bar
			corner(knob, 7)
			local function apply(rel)
				rel = math.clamp(rel, 0, 1)
				local raw = minV + (maxV - minV) * rel
				local v = math.floor(raw / step + 0.5) * step
				v = math.clamp(v, minV, maxV)
				current = v
				fill.Size = UDim2.new(rel, 0, 1, 0)
				knob.Position = UDim2.new(rel, 0, 0.5, 0)
				value.Text = tostring(v)
				if config2.Callback then
					config2.Callback(v)
				end
			end
			local sliding = false
			bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = true
					apply((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
					apply((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = false
				end
			end)
			return {
				Set = function(_, v)
					apply((v - minV) / (maxV - minV))
				end,
				Get = function()
					return current
				end,
			}
		end

		function tab:Dropdown(config2)
			local options = config2.Options or {}
			local current = config2.Default
			local row = tab:Row(44)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(14, 0)
			name.Size = UDim2.new(0.5, 0, 1, 0)
			name.Font = Enum.Font.GothamMedium
			name.TextSize = 14
			name.TextColor3 = theme.Text
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Text = config2.Title or "Dropdown"
			name.Parent = row
			local picker = Instance.new("TextButton")
			picker.AnchorPoint = Vector2.new(1, 0.5)
			picker.Position = UDim2.new(1, -14, 0.5, 0)
			picker.Size = UDim2.fromOffset(140, 28)
			picker.BackgroundColor3 = theme.Panel
			picker.Font = Enum.Font.Gotham
			picker.TextSize = 13
			picker.TextColor3 = theme.Text
			picker.Text = tostring(current or "Select...")
			picker.Parent = row
			corner(picker, 6)
			stroke(picker, theme.Stroke, 1)
			local list = Instance.new("Frame")
			list.AnchorPoint = Vector2.new(1, 0)
			list.Position = UDim2.new(1, -14, 1, 6)
			list.Size = UDim2.fromOffset(140, 0)
			list.BackgroundColor3 = theme.Panel
			list.BorderSizePixel = 0
			list.ClipsDescendants = true
			list.ZIndex = 5
			list.Parent = row
			corner(list, 6)
			stroke(list, theme.Stroke, 1)
			local listLayout = Instance.new("UIListLayout", list)
			listLayout.Padding = UDim.new(0, 2)
			local open = false
			local function rebuild()
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end
				for _, opt in ipairs(options) do
					local ob = Instance.new("TextButton")
					ob.Size = UDim2.new(1, -4, 0, 26)
					ob.BackgroundColor3 = (opt == current) and theme.Element or theme.Background
					ob.Font = Enum.Font.Gotham
					ob.TextSize = 12
					ob.TextColor3 = (opt == current) and theme.Accent or theme.Text
					ob.Text = tostring(opt)
					ob.ZIndex = 6
					ob.Parent = list
					corner(ob, 4)
					ob.Activated:Connect(function()
						current = opt
						picker.Text = tostring(opt)
						open = false
						list.Size = UDim2.fromOffset(140, 0)
						if config2.Callback then
							config2.Callback(opt)
						end
						task.defer(rebuild)
					end)
				end
			end
			rebuild()
			picker.Activated:Connect(function()
				open = not open
				local h = math.min(#options, 6) * 28 + 8
				list.Size = open and UDim2.fromOffset(140, h) or UDim2.fromOffset(140, 0)
			end)
			return {
				Set = function(_, opts)
					options = opts
					rebuild()
				end,
				Get = function()
					return current
				end,
			}
		end

		function tab:Input(config2)
			local row = tab:Row(44)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(14, 0)
			name.Size = UDim2.new(0.5, 0, 1, 0)
			name.Font = Enum.Font.GothamMedium
			name.TextSize = 14
			name.TextColor3 = theme.Text
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Text = config2.Title or "Input"
			name.Parent = row
			local box = Instance.new("TextBox")
			box.AnchorPoint = Vector2.new(1, 0.5)
			box.Position = UDim2.new(1, -14, 0.5, 0)
			box.Size = UDim2.fromOffset(180, 28)
			box.BackgroundColor3 = theme.Panel
			box.Font = Enum.Font.Gotham
			box.TextSize = 13
			box.TextColor3 = theme.Text
			box.PlaceholderText = config2.Placeholder or "Type here..."
			box.PlaceholderColor3 = theme.TextDim
			box.Text = config2.Default or ""
			box.ClearTextOnFocus = false
			box.Parent = row
			corner(box, 6)
			stroke(box, theme.Stroke, 1)
			box.FocusLost:Connect(function(enterPressed)
				if enterPressed and config2.Callback then
					config2.Callback(box.Text)
				end
			end)
			return {
				Set = function(_, text)
					box.Text = text
				end,
				Get = function()
					return box.Text
				end,
			}
		end

		function tab:Keybind(config2)
			local row = tab:Row(40)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(14, 0)
			name.Size = UDim2.new(0.5, 0, 1, 0)
			name.Font = Enum.Font.GothamMedium
			name.TextSize = 14
			name.TextColor3 = theme.Text
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Text = config2.Title or "Keybind"
			name.Parent = row
			local current = config2.Default
			local picker = Instance.new("TextButton")
			picker.AnchorPoint = Vector2.new(1, 0.5)
			picker.Position = UDim2.new(1, -14, 0.5, 0)
			picker.Size = UDim2.fromOffset(100, 26)
			picker.BackgroundColor3 = theme.Panel
			picker.Font = Enum.Font.GothamBold
			picker.TextSize = 12
			picker.TextColor3 = theme.Text
			picker.Text = current and current.Name or "Bind"
			picker.Parent = row
			corner(picker, 6)
			stroke(picker, theme.Stroke, 1)
			local waiting = false
			picker.Activated:Connect(function()
				waiting = true
				picker.Text = "..."
			end)
			local bindConn = UserInputService.InputBegan:Connect(function(input, processed)
				if not waiting or processed then
					return
				end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					current = input.KeyCode
					picker.Text = current.Name
					waiting = false
					if config2.Callback then
						config2.Callback(current)
					end
				end
			end)
			local fireConn = UserInputService.InputBegan:Connect(function(input, processed)
				if waiting or processed then
					return
				end
				if input.KeyCode == current and config2.Callback then
					config2.Callback(current)
				end
			end)
			return {
				Set = function(_, key)
					current = key
					picker.Text = key and key.Name or "Bind"
				end,
			}
		end

		return tab
	end

	local toastHolder = Instance.new("Frame")
	toastHolder.AnchorPoint = Vector2.new(1, 0)
	toastHolder.Position = UDim2.new(1, -16, 0, 16)
	toastHolder.Size = UDim2.new(0, 280, 0, 500)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui
	local toastLayout = Instance.new("UIListLayout", toastHolder)
	toastLayout.Padding = UDim.new(0, 8)
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder

	function window:Notify(config2)
		local t = Instance.new("Frame")
		t.Size = UDim2.new(1, 0, 0, 52)
		t.BackgroundColor3 = theme.Panel
		t.BorderSizePixel = 0
		t.Parent = toastHolder
		corner(t, 8)
		stroke(t, config2.Color or theme.Accent, 1)
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Position = UDim2.fromOffset(12, 6)
		tl.Size = UDim2.new(1, -24, 0, 16)
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 13
		tl.TextColor3 = theme.Text
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.Text = config2.Title or "Notification"
		tl.Parent = t
		local tc = Instance.new("TextLabel")
		tc.BackgroundTransparency = 1
		tc.Position = UDim2.fromOffset(12, 24)
		tc.Size = UDim2.new(1, -24, 1, -30)
		tc.Font = Enum.Font.Gotham
		tc.TextSize = 12
		tc.TextColor3 = theme.TextDim
		tc.TextXAlignment = Enum.TextXAlignment.Left
		tc.TextWrapped = true
		tc.Text = config2.Content or ""
		tc.Parent = t
		task.delay(config2.Duration or 3, function()
			tween(t, 0.3, {BackgroundTransparency = 1})
			tween(tl, 0.3, {TextTransparency = 1})
			tween(tc, 0.3, {TextTransparency = 1})
			task.wait(0.35)
			t:Destroy()
		end)
	end

	function window:SetTheme(overrides)
		for k, v in pairs(overrides or {}) do
			theme[k] = v
		end
		root.BackgroundColor3 = theme.Background
		header.BackgroundColor3 = theme.Panel
		sidebar.BackgroundColor3 = theme.Panel
		title.TextColor3 = theme.Text
		subtitle.TextColor3 = theme.TextDim
	end

	function window:Destroy()
		destroyed = true
		gui:Destroy()
	end

	window.GUI = gui
	window.Theme = theme

	if config.DefaultTab then
		window:SelectTab(config.DefaultTab)
	end

	window:Notify({
		Title = config.Title or "WindLib",
		Content = "Loaded. Press " .. toggleKey.Name .. " to toggle.",
		Duration = 3,
	})

	return window
end

return Lib