local function Notify(message, duration)
    spawn(function()
        local existingNotification = game.CoreGui:FindFirstChild("Notification")
        if existingNotification then
            existingNotification:Destroy()
        end

        local notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "Notification"
        notificationGui.Parent = game.CoreGui

        local notificationLabel = Instance.new("TextLabel")
        notificationLabel.Text = message
        notificationLabel.Size = UDim2.new(0, 200, 0, 50)
        notificationLabel.Position = UDim2.new(0.5, -100, 1, -50)
        notificationLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notificationLabel.TextColor3 = Color3.new(1, 1, 1)
        notificationLabel.BackgroundTransparency = 0.5
        notificationLabel.Parent = notificationGui

        Instance.new("UICorner", notificationLabel).CornerRadius = UDim.new(0, 6)

        local tweenIn = game:GetService("TweenService"):Create(
            notificationLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -100, 0.9, -25)}
        )
        tweenIn:Play()

        wait(duration)

        local tweenOut = game:GetService("TweenService"):Create(
            notificationLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -100, 1, -50)}
        )
        tweenOut:Play()

        tweenOut.Completed:Wait()
        notificationGui:Destroy()
    end)
end

local function Sound(soundId, volume)
    if not tonumber(soundId) then
        warn("Invalid soundId: " .. soundId)
        return
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = game.CoreGui
    sound.Volume = volume
    sound:Play()
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
local Window = Library:NewWindow("Just A ghost 🌙")
local ScriptTab = Window:NewSection("Script")

local isPromptClosed = false
local hidePlayersEnabled = false
local autoProximityEnabled = false
local isProcessingPrompt = false
local loopActive = false
local playerVisibility = {}

local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local function sendNotification(title, text, duration, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
        Icon = icon
    })
end

local function playNotificationSound()
    local soundService = game:GetService("SoundService")
    local notificationSound = Instance.new("Sound")

    notificationSound.SoundId = "rbxassetid://8745692251"
    notificationSound.Volume = 0.5
    notificationSound.Parent = soundService

    notificationSound:Play()
end

local function autoPurchaseUGCItem()
    getrenv()._set = clonefunction(setthreadidentity)
    local old
    old = hookmetamethod(game, "__index", function(a, b)
        task.spawn(function()
            _set(7)
            task.wait()
            getgenv().promptpurchaserequestedv2 = MarketplaceService.PromptPurchaseRequestedV2:Connect(function(...)
                Notify("Prompt Detected: Attempting to purchase the UGC item...", 5)
                local startTime = tick()
                local t = {...}
                local assetId = t[2]
                local idempotencyKey = t[5]
                local purchaseAuthToken = t[6]
                local info = MarketplaceService:GetProductInfo(assetId)
                local productId = info.ProductId
                local price = info.PriceInRobux
                local collectibleItemId = info.CollectibleItemId
                local collectibleProductId = info.CollectibleProductId

                Notify("PurchaseAuthToken: " .. purchaseAuthToken, 5)
                Notify("IdempotencyKey: " .. idempotencyKey, 5)
                Notify("CollectibleItemId: " .. collectibleItemId, 5)
                Notify("CollectibleProductId: " .. collectibleProductId, 5)
                Notify("ProductId (should be 0): " .. productId, 5)
                Notify("Price: " .. price, 5)
                playNotificationSound()
                local success, result = pcall(function()
                    return MarketplaceService:PerformPurchase(Enum.InfoType.Asset, productId, price,
                        tostring(game:GetService("HttpService"):GenerateGUID(false)), true, collectibleItemId,
                        collectibleProductId, idempotencyKey, tostring(purchaseAuthToken))
                end)

                if success then
                    Notify("First Purchase Attempt", 5)
                    for i, v in pairs(result) do
                        Notify(i .. ": " .. v, 5)
                    end
                    local endTime = tick()
                    local duration = endTime - startTime
                    Notify("Bought Item! Took " .. tostring(duration) .. " seconds", 5)
                else
                    Notify("Failed to Purchase Item: " .. result, 5)
                end
            end)
        end)
        hookmetamethod(game, "__index", old)
        return old(a, b)
    end)
end

local function togglePlayerVisibility(state)
    hidePlayersEnabled = state
    if state then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        playerVisibility[part] = part.Transparency
                        part.Transparency = 1
                    end
                end
            end
        end
        print("[Auto Buy] Hider Players: ON")
        Notify("Hider Players: ON", 3)
    else
        for part, transparency in pairs(playerVisibility) do
            if part and part.Parent then
                part.Transparency = transparency
            end
        end
        playerVisibility = {}
        print("[Auto Buy] Hider Players: OFF")
        Notify("Hider Players: OFF", 3)
    end
end

local function autoCloseError(value)
    loopActive = value
    spawn(function()
        while loopActive do
            local pp = game.CoreGui.PurchasePrompt.ProductPurchaseContainer.Animator:FindFirstChild("Prompt")
            if pp and pp.AlertContents and pp.AlertContents.Footer and pp.AlertContents.Footer.Buttons and not pp.AlertContents.Footer.Buttons:FindFirstChild("2") then
                if pp.AlertContents.Footer.Buttons:FindFirstChild("1") then
                    local b1 = pp.AlertContents.Footer.Buttons[1].AbsolutePosition
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(b1.X + 55, b1.Y + 65.5, 0, true, game, 1)
                    wait()
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(b1.X + 55, b1.Y + 65.5, 0, false, game, 1)
                end
            end
            wait()
        end
    end)
    print("[Auto Close Error] " .. (loopActive and "ON" or "OFF"))
    Notify("Auto Close Error: " .. (loopActive and "ON" or "OFF"), 3)
end

local function proxi()
    autoProximityEnabled = not autoProximityEnabled
    if autoProximityEnabled then
        print("[Auto Buy] firepp: ON")
        Notify("firepp: ON", 3)
        spawn(function()
            while autoProximityEnabled do
                for _, pro in ipairs(workspace:GetDescendants()) do
                    if pro:IsA("ProximityPrompt") then
                        fireproximityprompt(pro)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        print("[Auto Buy] firepp: OFF")
        Notify("firepp: OFF", 3)
    end
end

local function antiAFK()
    local iku = coroutine.create(function()
        local VirtualUser = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    coroutine.resume(iku)
    print("[Anti AFK] Ativado!")
    Notify("Anti AFK Ativado!", 3)
end

ScriptTab:CreateToggle("Auto Buy", function(state)
    isPromptClosed = state
    print("[Auto Buy] Cancel Prompt: " .. (state and "ON" or "OFF"))
    Notify("Auto Buy: " .. (state and "ON" or "OFF"), 3)
end)

ScriptTab:CreateToggle("Auto Close Error", function(state)
    autoCloseError(state)
end)

ScriptTab:CreateButton("Auto Cancel Prompt", function()
    loopActive = not loopActive
    if loopActive then
        print("[Auto Close Prompt] Loop Ativado!")
        Notify("Auto Close Prompt: ON", 3)
        spawn(monitorGui)
    else
        print("[Auto Close Prompt] Loop Desativado!")
        Notify("Auto Close Prompt: OFF", 3)
    end
end)

ScriptTab:CreateButton("firepp", function()
    proxi()
end)

ScriptTab:CreateButton("Hide Players", function()
    hidePlayersEnabled = not hidePlayersEnabled
    togglePlayerVisibility(hidePlayersEnabled)
end)

antiAFK()

autoPurchaseUGCItem()
