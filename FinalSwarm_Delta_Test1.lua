-- Test1: attributes + UI only, no require, no loops
print("[Test1] start")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
RS:SetAttribute("LH_LoadGen", math.floor(os.clock()*100000))
RS:SetAttribute("LH_AutoRaidOn", false)
print("[Test1] attributes set")

local parent = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "Test1_UI"
sg.Parent = parent
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,200,0,50)
btn.Position = UDim2.new(0.5,-100,0.5,-25)
btn.Text = "Test1 OK - click"
btn.Parent = sg
btn.MouseButton1Click:Connect(function() print("[Test1] clicked") end)
print("[Test1] UI done - check Rcoin")
