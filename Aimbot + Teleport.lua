local settings = {
  
    smoothness = 0.15,
    max_range = 500,
    prediction = true,
    prediction_amount = 0.4,
    ignore_team = true,
    prioritize_head = true,
    fov_circle = true,
    
    teleport_delay = 0.1,
    distance_behind = 3,
    teleport_enabled = true
}

local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local rs = game:GetService("RunService")
local target = nil
local last_tp = 0

local function createFOVCircle()
    if not settings.fov_circle then return end
    
    local circle = Drawing.new("Circle")
    circle.Visible = true
    circle.Thickness = 1
    circle.Color = Color3.fromRGB(255, 255, 255)
    circle.Transparency = 0.1
    circle.Filled = false
    circle.Radius = 12
    circle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    
    return circle
end

local fov_circle = createFOVCircle()

local function getBestTarget()
    local closest = nil
    local closest_angle = math.huge
    local local_pos = camera.CFrame.Position
    
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v ~= plr and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local sameTeam = false
            if v.Team and plr.Team then
                sameTeam = v.Team == plr.Team
            end
            
            if not settings.ignore_team or not sameTeam then
                local target_part = settings.prioritize_head and v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("HumanoidRootPart")
                if target_part then
                    local target_pos = target_part.Position
                    if settings.prediction and target_part.Velocity.Magnitude > 0 then
                        target_pos = target_pos + (target_part.Velocity * settings.prediction_amount)
                    end
                    
                    local distance = (target_pos - local_pos).Magnitude
                    if distance <= settings.max_range then
                        local direction = (target_pos - local_pos).Unit
                        local look_vector = camera.CFrame.LookVector
                        local angle = math.deg(math.acos(direction:Dot(look_vector)))
                        
                        if angle < closest_angle then
                            closest_angle = angle
                            closest = v
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

local function teleportBehind()
    if not settings.teleport_enabled then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    
    if tick() - last_tp >= settings.teleport_delay then
        local targetCF = target.Character.HumanoidRootPart.CFrame
        local behindPos = targetCF * CFrame.new(0, 0, settings.distance_behind)
        plr.Character.HumanoidRootPart.CFrame = behindPos
        last_tp = tick()
    end
end

local function smoothAim()
    if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") or target.Character.Humanoid.Health <= 0 then
        target = getBestTarget()
        if not target then return end
    end
    
    local target_part = settings.prioritize_head and target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
    if not target_part then return end
    
    local target_pos = target_part.Position
    if settings.prediction and target_part.Velocity.Magnitude > 0 then
        target_pos = target_pos + (target_part.Velocity * settings.prediction_amount)
    end
    
    local current_cf = camera.CFrame
    local target_cf = CFrame.new(current_cf.Position, target_pos)
    camera.CFrame = current_cf:Lerp(target_cf, settings.smoothness)
end

local function updateFOV()
    if fov_circle then
        fov_circle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    end
end

rs.Heartbeat:Connect(function()
    smoothAim()
    teleportBehind()
    updateFOV()
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIMBOT & TELEPORT ENABLED",
    Text = "Auto-aim and teleport features activated",
    Duration = 5
})

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    if fov_circle then
        fov_circle:Remove()
        fov_circle = createFOVCircle()
    end
end)
