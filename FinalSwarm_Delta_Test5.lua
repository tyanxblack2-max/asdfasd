-- Test5: only UI fallback minimal, no HubIcon, no loops - check if 5-tab UI was culprit
print("[Test5] start")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local IS_DELTA = false
pcall(function() local ex = identifyexecutor and identifyexecutor() or "" if ex:lower():find("delta") then IS_DELTA = true end end)
print("[Test5] IS_DELTA", IS_DELTA)

local function getUIParent()
    return game.Players.LocalPlayer:FindFirstChild("PlayerGui")
end

-- mimic Clean's Rayfield skip
local Rayfield, window
if IS_DELTA then
    print("[Test5] skip Rayfield")
else
    print("[Test5] not delta")
end

-- minimal fallback UI (1 button, not 5 tabs)
local parent = getUIParent()
local sg = Instance.new("ScreenGui")
sg.Name = "Test5_UI"
sg.ResetOnSpawn = false
sg.Parent = parent
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,200,0,50)
btn.Position = UDim2.new(0.5,-100,0.5,-25)
btn.Text = "Test5 OK - 1 button"
btn.BackgroundColor3 = Color3.fromRGB(0,170,80)
btn.TextColor3 = Color3.new(1,1,1)
btn.Parent = sg
btn.MouseButton1Click:Connect(function() print("[Test5] clicked", tick()) end)
print("[Test5] UI done - check Rcoin")
