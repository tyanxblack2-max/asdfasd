-- UltraLight Delta - only 1 button initially, rest on demand to avoid Rcoin
print("[UltraLight] start")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local IS_DELTA = false
pcall(function() local ex = identifyexecutor and identifyexecutor() or "" if ex:lower():find("delta") then IS_DELTA = true end end)
print("[UltraLight] IS_DELTA", IS_DELTA)

local parent = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "UltraLight_Hub"
sg.ResetOnSpawn = false
sg.Parent = parent

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 160, 0, 40)
openBtn.Position = UDim2.new(0, 10, 0, 10)
openBtn.Text = "Open Hub (Delta)"
openBtn.BackgroundColor3 = Color3.fromRGB(0,170,90)
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 14
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0,8)
print("[UltraLight] open button ready - check Rcoin now, click to load full UI")

local loaded = false
openBtn.MouseButton1Click:Connect(function()
    if loaded then return end
    loaded = true
    print("[UltraLight] loading full logic...")
    -- staggered creation demo (no HttpGet, just local staggered)
    local ok, err = pcall(function()
        openBtn.Text = "Loading..."
        task.wait(0.5)
        -- Simulate creating 5 toggles one by one with delay to avoid Rcoin
        for i=1,5 do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 200, 0, 30)
            b.Position = UDim2.new(0, 10, 0, 60 + i*35)
            b.Text = "Toggle "..i
            b.Parent = sg
            task.wait(0.1)
        end
        openBtn.Text = "Loaded"
        print("[UltraLight] full UI loaded staggered - check Rcoin")
    end)
    if not ok then warn("[UltraLight] load err", err) end
end)
