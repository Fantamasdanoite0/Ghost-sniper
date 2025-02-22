local cloneref = cloneref or function(...) return ... end

local TweenService = cloneref(game:GetService("TweenService"))
local Players = cloneref(game:GetService("Players"))
local player = Players.LocalPlayer
local HttpService = cloneref(game:GetService("HttpService"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))

local autoPurchaseEnabled = false
local isProcessingPrompt = false
local purchasedItems = {}
local isPromptClosed = false
local hidePlayersEnabled = false

local function playNotificationSound()
    local soundService = game:GetService("SoundService")
    local notificationSound = Instance.new("Sound")
    notificationSound.SoundId = "rbxassetid://8745692251"
    notificationSound.Volume = 0.5
    notificationSound.Parent = soundService
    notificationSound:Play()
end

local function createNotification(message)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = screenGui
    textLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
    textLabel.Position = UDim2.new(0.25, 0, 0.9, 0)
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = message
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0.8
    textLabel.TextTransparency = 1

    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tweenIn = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 0})
    local tweenOut = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 1})

    tweenIn:Play()
    tweenIn.Completed:Connect(function()
        task.wait(5)
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0.2, 0, 0.4, 0)
    frame.Position = UDim2.new(0.4, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(0.8, 0, 0.1, 0)
    title.Position = UDim2.new(0.1, 0, 0.05, 0)
    title.Text = "Auto Purchase"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BackgroundTransparency = 1

    local toggleButton = Instance.new("TextButton")
    toggleButton.Parent = frame
    toggleButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    toggleButton.Position = UDim2.new(0.1, 0, 0.2, 0)
    toggleButton.Text = "OFF"
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true

    local testWebhookButton = Instance.new("TextButton")
    testWebhookButton.Parent = frame
    testWebhookButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    testWebhookButton.Position = UDim2.new(0.1, 0, 0.4, 0)
    testWebhookButton.Text = "Test Webhook"
    testWebhookButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    testWebhookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    testWebhookButton.TextScaled = true

    local closePromptButton = Instance.new("TextButton")
    closePromptButton.Parent = frame
    closePromptButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    closePromptButton.Position = UDim2.new(0.1, 0, 0.6, 0)
    closePromptButton.Text = "Fechar Prompt: OFF"
    closePromptButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
    closePromptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closePromptButton.TextScaled = true

    local hidePlayersButton = Instance.new("TextButton")
    hidePlayersButton.Parent = frame
    hidePlayersButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    hidePlayersButton.Position = UDim2.new(0.1, 0, 0.8, 0)
    hidePlayersButton.Text = "Ocultar Jogadores: OFF"
    hidePlayersButton.BackgroundColor3 = Color3.fromRGB(255, 128, 0)
    hidePlayersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    hidePlayersButton.TextScaled = true

    toggleButton.MouseButton1Click:Connect(function()
        autoPurchaseEnabled = not autoPurchaseEnabled
        if autoPurchaseEnabled then
            toggleButton.Text = "ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            createNotification("Auto Purchase Ativado!")
        else
            toggleButton.Text = "OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            createNotification("Auto Purchase Desativado!")
        end
    end)

    testWebhookButton.MouseButton1Click:Connect(function()
        createNotification("Teste de Webhook removido.")
    end)

    closePromptButton.MouseButton1Click:Connect(function()
        isPromptClosed = not isPromptClosed
        closePromptButton.Text = isPromptClosed and "Fechar Prompt: ON" or "Fechar Prompt: OFF"
        createNotification(isPromptClosed and "Fechar Prompt Ativado!" or "Fechar Prompt Desativado!")
    end)

    hidePlayersButton.MouseButton1Click:Connect(function()
        hidePlayersEnabled = not hidePlayersEnabled
        hidePlayersButton.Text = hidePlayersEnabled and "Ocultar Jogadores: ON" or "Ocultar Jogadores: OFF"
        createNotification(hidePlayersEnabled and "Ocultar Jogadores Ativado!" or "Ocultar Jogadores Desativado!")
    end)
end

local function autoPurchaseUGCItem()
    getrenv()._set = clonefunction(setthreadidentity)
    local old
    old = hookmetamethod(game, "__index", function(a, b)
        task.spawn(function()
            _set(7)
            task.wait()
            if isProcessingPrompt then return end
            isProcessingPrompt = true

            local connection
            connection = MarketplaceService.PromptPurchaseRequestedV2:Connect(function(...)
                if not autoPurchaseEnabled then return end

                createNotification("Prompt Detected: Attempting to purchase the UGC item...")
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
                local imageUrl = info.IconImageAssetId and "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=" .. info.IconImageAssetId or nil

                createNotification("PurchaseAuthToken: " .. purchaseAuthToken)
                createNotification("IdempotencyKey: " .. idempotencyKey)
                createNotification("CollectibleItemId: " .. collectibleItemId)
                createNotification("CollectibleProductId: " .. collectibleProductId)
                createNotification("ProductId (should be 0): " .. productId)
                createNotification("Price: " .. price)
                playNotificationSound()

                local success, result = pcall(function()
                    return MarketplaceService:PerformPurchase(Enum.InfoType.Asset, productId, price,
                        tostring(game:GetService("HttpService"):GenerateGUID(false)), true, collectibleItemId,
                        collectibleProductId, idempotencyKey, tostring(purchaseAuthToken))
                end)

                if success then
                    createNotification("First Purchase Attempt")
                    for i, v in pairs(result) do
                        createNotification(i .. ": " .. v)
                    end
                    local endTime = tick()
                    local duration = endTime - startTime
                    createNotification("Bought Item! Took " .. tostring(duration) .. " seconds")

                    table.insert(purchasedItems, {
                        assetId = assetId,
                        price = price,
                        idempotencyKey = idempotencyKey,
                        imageUrl = imageUrl
                    })
                else
                    createNotification("Failed to Purchase Item: " .. result)
                end

                isProcessingPrompt = false
                connection:Disconnect()
            end)
        end)
        hookmetamethod(game, "__index", old)
        return old(a, b)
    end)
end

local function monitorGui()
    while true do
        task.wait(0.1)

        if isPromptClosed then
            for _, gui in pairs(game.CoreGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:lower():find("purchase") then
                    gui.Enabled = false
                    gui:Destroy()
                    createNotification("Prompt fechado automaticamente!")
                end
            end
        end
    end
end

local function hidePlayers()
    while true do
        if hidePlayersEnabled then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    player.Character:Destroy()
                end
            end
        end
        task.wait()
    end
end

createUI()

task.spawn(monitorGui)

task.spawn(hidePlayers)

while true do
    if autoPurchaseEnabled then
        autoPurchaseUGCItem()
    end
    task.wait()
end
