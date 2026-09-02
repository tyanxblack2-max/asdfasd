-- Minimal Delta test - only UI, no game logic
print("[Delta Minimal] start")
local ok, parent
ok, parent = pcall(function()
    if gethui then
        local h = gethui()
        if cloneref then h = cloneref(h) end
        return h
    end
    return nil
end)
if not ok or not parent then
    parent = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    print("[Delta Minimal] fallback to PlayerGui", parent and parent.Name or "nil")
else
    print("[Delta Minimal] using gethui", parent.Name)
end

local sg = Instance.new("ScreenGui")
sg.Name = "DeltaMinimalTest"
sg.ResetOnSpawn = false
sg.Parent = parent
print("[Delta Minimal] gui created", sg.Name)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.5, -25)
btn.Text = "Test Delta UI - CLICK ME"
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
btn.TextColor3 = Color3.new(1,1,1)
btn.TextSize = 16
btn.Font = Enum.Font.GothamBold
btn.Parent = sg
Instance.new("UICorner", btn)

btn.MouseButton1Click:Connect(function()
    print("[Delta Minimal] clicked", tick())
    game.StarterGui:SetCore("SendNotification", {Title="Delta", Text="UI works!"})
end)
print("[Delta Minimal] button ready - click it, check if Rcoin errors appear")
