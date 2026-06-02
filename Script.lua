-- Arsenal Aimbot Full GUI - GitHub Loadstring Ready
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local AIMBOT_ENABLED = true
local SILENT_AIM_ENABLED = true
local TRIGGERBOT_ENABLED = true
local TEAM_CHECK = true
local WALL_CHECK = true
local SMOOTHNESS = 0.17
local PREDICTION = 0.13
local TRIGGER_DELAY = 0.06

local lastShot = 0
local guiVisible = true

local function isVisible(targetPart)
    if not WALL_CHECK then return true end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {player.Character or {}, targetPart.Parent}
    params.IgnoreWater = true
    return Workspace:Raycast(origin, direction.Unit * (direction.Magnitude + 2), params) == nil
end

local function isValidTarget(targetPlayer)
    if targetPlayer == player then return false end
    if not targetPlayer.Character then return false end
    local hum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if TEAM_CHECK and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
        return false
    end
    return true
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, other in pairs(Players:GetPlayers()) do
        if isValidTarget(other) then
            local part = other.Character:FindFirstChild("Head") or other.Character:FindFirstChild("HumanoidRootPart")
            if part and isVisible(part) then
                local dist = (part.Position - camera.CFrame.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = other
                end
            end
        end
    end
    return closest
end

-- Camera Aimbot
RunService.RenderStepped:Connect(function()
    if not AIMBOT_ENABLED then return end
    local target = getClosestPlayer()
    if target and target.Character then
        local part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("UpperTorso")
        if part then
            local vel = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new()
            local targetPos = part.Position + vel * PREDICTION
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPos), SMOOTHNESS)
        end
    end
end)

-- Silent Aim
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if SILENT_AIM_ENABLED and getnamecallmethod() == "FireServer" and self.Name:lower():find("shoot") or self.Name:lower():find("fire") or self.Name:lower():find("bullet") then
        local target = getClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if part and isVisible(part) then
                local vel = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new()
                local targetPos = part.Position + vel * PREDICTION * 1.15
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then
                        args[i] = (targetPos - camera.CFrame.Position).Unit * arg.Magnitude
                    elseif typeof(arg) == "CFrame" then
                        args[i] = CFrame.lookAt(arg.Position, targetPos)
                    end
                end
            end
        end
    end
    return old(self, unpack(args))
end)
setreadonly(mt, true)

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if not TRIGGERBOT_ENABLED then return end
    if tick() - lastShot < TRIGGER_DELAY then return end
    if getClosestPlayer() then
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("bullet")) then
                    v:FireServer()
                    lastShot = tick()
                    break
                end
            end
        end
    end
end)

-- ==================== GUI ====================
task.wait(0.5) -- Important for loadstring

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundTransparency = 1
Title.Text = "⚔️ Arsenal Aimbot"
Title.TextColor3 = Color3.fromRGB(0, 255, 120)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 120, 0, 45)
CloseBtn.Position = UDim2.new(0.5, -60, 1, -55)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "CLOSE GUI"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local function createToggle(name, default, y, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 55)
    f.Position = UDim2.new(0, 10, 0, y)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    f.Parent = MainFrame
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    Instance.new("TextLabel", f).Text = "  "..name
    local label = f:FindFirstChildOfClass("TextLabel")
    label.Size = UDim2.new(0.65,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.3,0,0.75,0)
    btn.Position = UDim2.new(0.67,0,0.12,0)
    btn.BackgroundColor3 = default and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,70,70)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.new(0,0,0)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.BackgroundColor3 = default and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,70,70)
        btn.Text = default and "ON" or "OFF"
        callback(default)
    end)
end

createToggle("Camera Aimbot", AIMBOT_ENABLED, 70, function(v) AIMBOT_ENABLED = v end)
createToggle("Silent Aim", SILENT_AIM_ENABLED, 135, function(v) SILENT_AIM_ENABLED = v end)
createToggle("Auto Shoot", TRIGGERBOT_ENABLED, 200, function(v) TRIGGERBOT_ENABLED = v end)
createToggle("Team Check", TEAM_CHECK, 265, function(v) TEAM_CHECK = v end)
createToggle("Wall Check", WALL_CHECK, 330, function(v) WALL_CHECK = v end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end
end)

print("✅ Arsenal Aimbot GUI Loaded from GitHub!")
