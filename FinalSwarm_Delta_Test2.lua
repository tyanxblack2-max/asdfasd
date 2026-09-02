-- Test2: + require EnemyService
print("[Test2] start")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
RS:SetAttribute("LH_LoadGen", math.floor(os.clock()*100000))
print("[Test2] before require")
local ok, mod = pcall(function() return require(game.ReplicatedStorage.Shared.Services.EnemyService.EnemyServiceClient) end)
print("[Test2] require EnemyService ok=", ok, "mod=", type(mod))
if ok and mod then
    print("[Test2] BossAttack", type(mod.BossAttack))
end
local parent = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "Test2_UI"
sg.Parent = parent
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,200,0,50)
btn.Position = UDim2.new(0.5,-100,0.5,-25)
btn.Text = "Test2 OK"
btn.Parent = sg
btn.MouseButton1Click:Connect(function() print("[Test2] clicked") end)
print("[Test2] UI done")
