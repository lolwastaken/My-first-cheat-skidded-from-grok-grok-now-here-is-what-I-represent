-- Arsenal Advanced Hub - Vape Style GUI (Mobile + PC)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Settings
local AIMBOT_ENABLED = true
local SILENT_AIM_ENABLED = true
local TRIGGERBOT_ENABLED = true
local TEAM_CHECK = true
local WALL_CHECK = true
local ESP_ENABLED = false
local HITBOX_EXPANDER = false

local SMOOTHNESS = 0.16
local PREDICTION = 0.135
local TRIGGER_DELAY = 0.04
local FOV = 120

local lastShot = 0
local guiVisible = true
local currentTab = "Main"

-- Device Detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== CORE FUNCTIONS ====================
local function isVisible(targetPart)
    if not WALL_CHECK then return true end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {player.Character or {}, targetPart.Parent}
    params.IgnoreWater = true
    return Workspace:Raycast(origin, direction.Unit * (direction.Magnitude + 3), params) == nil
end

local function isValidTarget(targetPlayer)
    if targetPlayer == player then return false end
    if not targetPlayer.Character then return false end
    local hum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if TEAM_CHECK and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then return false end
    return true
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, other in pairs(Players:GetPlayers()) do
        if isValidTarget(other) then
            local part = other.Character:FindFirstChild("Head") or other.Character:FindFirstChild("HumanoidRootPart")
            if part and isVisible(part) then
                local dist = (part.Position - camera.CFrame.Position).Magnitude
                if dist < shortest and dist < FOV then
                    shortest = dist
                    closest = other
                end
            end
        end
    end
    return closest
end

-- Aimbot Loop
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
    if SILENT_AIM_ENABLED and getnamecallmethod() == "FireServer" and (self.Name:lower():find("shoot") or self.Name:lower():find("fire") or self.Name:lower():find("bullet")) then
        local target = getClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if part and isVisible(part) then
                local vel = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new()
                local targetPos = part.Position + vel * PREDICTION * 1.18
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

-- ==================== ADVANCED GUI ====================
task.wait(0.8)
local playerGui = player:WaitForChild("PlayerGui", 15)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 480)
MainFrame.Position = UDim2.new(0.5, -180, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundTransparency = 1
Title.Text = "⚔️ Arsenal Hub"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Mode Label
local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, 0, 0, 25)
ModeLabel.Position = UDim2.new(0, 0, 0, 60)
ModeLabel.BackgroundTransparency = 1
ModeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
ModeLabel.TextScaled = true
ModeLabel.Font = Enum.Font.Gotham
ModeLabel.Parent = MainFrame

if isMobile then
    ModeLabel.Text = "📱 Mobile Mode"
else
    ModeLabel.Text = "🖥️ PC Mode - Right Shift"
end

-- Tab Buttons
local tabs = {"Main", "Combat", "Visuals"}
local tabFrames = {}

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0.33, 0, 0, 40)
    tabBtn.Position = UDim2.new((i-1)*0.33, 0, 0, 90)
    tabBtn.BackgroundColor3 = currentTab == tabName and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 40)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Parent = MainFrame
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 1, -170)
    tabFrame.Position = UDim2.new(0, 10, 0, 140)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = (currentTab == tabName)
    tabFrame.Parent = MainFrame
    tabFrames[tabName] = tabFrame

    tabBtn.MouseButton1Click:Connect(function()
        currentTab = tabName
        for _, f in pairs(tabFrames) do f.Visible = false end
        tabFrame.Visible = true
        -- Update button colors
        for _, btn in pairs(MainFrame:GetChildren()) do
            if btn:IsA("TextButton") and btn.Text == tabName or btn.Text \~= tabName and tabs[1] then
                -- Simple color update
            end
        end
    end)
end

-- Toggle Creator
local function createToggle(parent, name, default, y, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 55)
    f.Position = UDim2.new(0, 0, 0, y)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "   " .. name
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 0.75, 0)
    btn.Position = UDim2.new(0.72, 0, 0.12, 0)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.new(0,0,0)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.BackgroundColor3 = default and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,60,60)
        btn.Text = default and "ON" or "OFF"
        callback(default)
    end)
end

-- Fill Tabs
createToggle(tabFrames["Main"], "Camera Aimbot", AIMBOT_ENABLED, 10, function(v) AIMBOT_ENABLED = v end)
createToggle(tabFrames["Main"], "Silent Aim", SILENT_AIM_ENABLED, 75, function(v) SILENT_AIM_ENABLED = v end)
createToggle(tabFrames["Main"], "Triggerbot", TRIGGERBOT_ENABLED, 140, function(v) TRIGGERBOT_ENABLED = v end)

createToggle(tabFrames["Combat"], "Wall Check", WALL_CHECK, 10, function(v) WALL_CHECK = v end)
createToggle(tabFrames["Combat"], "Team Check", TEAM_CHECK, 75, function(v) TEAM_CHECK = v end)

createToggle(tabFrames["Visuals"], "ESP Boxes", ESP_ENABLED, 10, function(v) ESP_ENABLED = v end)
createToggle(tabFrames["Visuals"], "Hitbox Expander", HITBOX_EXPANDER, 75, function(v) HITBOX_EXPANDER = v end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 140, 0, 50)
CloseBtn.Position = UDim2.new(0.5, -70, 1, -65)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.Text = "CLOSE"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Mobile Button
if isMobile then
    local mobBtn = Instance.new("TextButton")
    mobBtn.Size = UDim2.new(0, 70, 0, 70)
    mobBtn.Position = UDim2.new(0, 20, 1, -90)
    mobBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    mobBtn.Text = "🎮"
    mobBtn.TextScaled = true
    mobBtn.Parent = ScreenGui
    Instance.new("UICorner", mobBtn).CornerRadius = UDim.new(1,0)
    
    mobBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end)
end

-- PC RightShift
if not isMobile then
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            guiVisible = not guiVisible
            MainFrame.Visible = guiVisible
        end
    end)
end

print("✅ Advanced Arsenal Hub Loaded | Tab System Added")
