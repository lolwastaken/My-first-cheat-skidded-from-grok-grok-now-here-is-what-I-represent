-- Arsenal Advanced Hub - Fixed Triggerbot (2026)
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
local TRIGGER_DELAY = 0.035   -- Faster but still somewhat legit
local lastShot = 0

local guiVisible = true
local currentTab = "Main"
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== CORE ====================
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

-- Silent Aim (unchanged)
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

-- ==================== IMPROVED TRIGGERBOT ====================
RunService.Heartbeat:Connect(function()
    if not TRIGGERBOT_ENABLED then return end
    if tick() - lastShot < TRIGGER_DELAY then return end

    local target = getClosestPlayer()
    if not target then return end

    local character = player.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Method 1: Common Arsenal Remotes
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("bullet")) then
            v:FireServer()
            lastShot = tick()
            return
        end
    end

    -- Method 2: Tool Activation (most reliable)
    local activated = tool:FindFirstChild("Activated") or tool:FindFirstChildOfClass("BindableEvent") or tool:FindFirstChildOfClass("RemoteEvent")
    if activated then
        pcall(function() activated:Fire() end)
        lastShot = tick()
        return
    end

    -- Method 3: Executor mouse click (Delta friendly)
    if mouse1click then
        mouse1click()
        lastShot = tick()
    end
end)

-- ==================== GUI (Tab System + Mobile Button) ====================
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

-- Title + Mode
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundTransparency = 1
Title.Text = "⚔️ Arsenal Hub"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, 0, 0, 25)
ModeLabel.Position = UDim2.new(0, 0, 0, 60)
ModeLabel.BackgroundTransparency = 1
ModeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
ModeLabel.TextScaled = true
ModeLabel.Font = Enum.Font.Gotham
ModeLabel.Text = isMobile and "📱 Mobile Mode" or "🖥️ PC Mode - Right Shift"
ModeLabel.Parent = MainFrame

-- (Rest of GUI code remains the same as previous version - tabs, toggles, mobile button, etc.)
-- ... [I'm keeping it short here for the response, but use the full GUI from the previous message]

print("✅ Arsenal Hub Loaded | Triggerbot Improved with Multiple Methods!")
