-- Arsenal Full Pack with Wall Check for Delta Executor
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
local WALL_CHECK = true        -- New: Wall visibility check
local SMOOTHNESS = 0.17
local TARGET_PART = "Head"
local PREDICTION = 0.13
local TRIGGER_DELAY = 0.06

local lastShot = 0

local function isVisible(targetPart)
    if not WALL_CHECK then return true end
    if not targetPart then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character or {}, targetPart.Parent}  -- Ignore self and target
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction * (distance + 1), raycastParams)
    
    return result == nil  -- No obstacle hit = visible
end

local function isValidTarget(targetPlayer)
    if targetPlayer == player then return false end
    if not targetPlayer.Character then return false end
    
    local hum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    -- Team Check
    if TEAM_CHECK and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
        return false
    end
    
    return true
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, other in pairs(Players:GetPlayers()) do
        if isValidTarget(other) then
            local part = other.Character:FindFirstChild(TARGET_PART) or other.Character:FindFirstChild("HumanoidRootPart")
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
        local targetPart = target.Character:FindFirstChild(TARGET_PART) or target.Character:FindFirstChild("UpperTorso")
        if targetPart then
            local targetPos = targetPart.Position
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if root then
                targetPos = targetPos + (root.Velocity * PREDICTION)
            end
            local current = camera.CFrame
            local targetCFrame = CFrame.lookAt(current.Position, targetPos)
            camera.CFrame = current:Lerp(targetCFrame, SMOOTHNESS)
        end
    end
end)

-- Silent Aim
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if SILENT_AIM_ENABLED and method == "FireServer" and (self.Name:lower():find("fire") or self.Name:lower():find("shoot") or self.Name:lower():find("bullet")) then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(TARGET_PART) or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart and isVisible(targetPart) then
                local targetPos = targetPart.Position
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    targetPos = targetPos + (root.Velocity * PREDICTION * 1.15)
                end
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
    return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if not TRIGGERBOT_ENABLED then return end
    if tick() - lastShot < TRIGGER_DELAY then return end
    
    local target = getClosestPlayer()
    if target then
        local character = player.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and (remote.Name:lower():find("shoot") or remote.Name:lower():find("fire") or remote.Name:lower():find("bullet")) then
                        remote:FireServer()
                        lastShot = tick()
                        break
                    end
                end
            end
        end
    end
end)

-- Toggles
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        AIMBOT_ENABLED = not AIMBOT_ENABLED
        print("Camera Aimbot: " .. (AIMBOT_ENABLED and "ON" or "OFF"))
    elseif input.KeyCode == Enum.KeyCode.End then
        SILENT_AIM_ENABLED = not SILENT_AIM_ENABLED
        print("Silent Aim: " .. (SILENT_AIM_ENABLED and "ON" or "OFF"))
    elseif input.KeyCode == Enum.KeyCode.Home then
        TRIGGERBOT_ENABLED = not TRIGGERBOT_ENABLED
        print("Triggerbot: " .. (TRIGGERBOT_ENABLED and "ON" or "OFF"))
    elseif input.KeyCode == Enum.KeyCode.Delete then
        TEAM_CHECK = not TEAM_CHECK
        print("Team Check: " .. (TEAM_CHECK and "ON" or "OFF"))
    elseif input.KeyCode == Enum.KeyCode.PageUp then
        WALL_CHECK = not WALL_CHECK
        print("Wall Check: " .. (WALL_CHECK and "ON (only visible targets)" or "OFF (aim through walls)"))
    end
end)

print("✅ Arsenal Full Pack with Wall Check Loaded for Delta!")
print("INSERT=Camera | END=Silent | HOME=Trigger | DELETE=Team | PAGE UP=Wall Check")
print("Wall check makes it much safer and more legit-looking!")
