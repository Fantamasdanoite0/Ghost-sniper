local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "Ghost Product Purchaser",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false
})

local products = {}
local loopEnabled = false
local purchaseDelay = 0.01

local function SafePurchase(productId)
    pcall(function()
        MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, productId, true)
        
        local remotes = {"PurchaseProduct", "BuyItem", "AttemptPurchase"}
        for _, name in ipairs(remotes) do
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild(name)
            if remote then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(productId)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(productId)
                end
            end
        end
    end)
end

local function LoadProducts()
    local productList = {}
    local success, pages = pcall(function()
        return MarketplaceService:GetDeveloperProductsAsync()
    end)

    if success and pages then
        repeat
            local items = pages:GetCurrentPage()
            for _, product in ipairs(items) do
                table.insert(productList, {
                    id = product.ProductId,
                    name = product.Name,
                    price = product.PriceInRobux
                })
            end
        until pages.IsFinished or not pages:AdvanceToNextPage()
    end
    
    return #productList > 0 and productList or {{id=0, name="No products found", price=0}}
end

local function PurchaseAll()
    for _, product in ipairs(products) do
        if product.id ~= 0 then
            task.spawn(SafePurchase, product.id)
        end
    end
end

local function CreateUI()
    products = LoadProducts()
    
    local MainTab = Window:MakeTab({
        Name = "Main",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    local SettingsTab = Window:MakeTab({
        Name = "Settings",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    MainTab:AddToggle({
        Name = "Auto Buy All",
        Default = false,
        Callback = function(state)
            loopEnabled = state
            while loopEnabled do
                PurchaseAll()
                task.wait(purchaseDelay)
            end
        end    
    })
    
    MainTab:AddButton({
        Name = "Buy All Now",
        Callback = function()
            PurchaseAll()
        end
    })
    
    local productSection = MainTab:AddSection({
        Name = "Products List"
    })
    
    for _, product in ipairs(products) do
        productSection:AddButton({
            Name = product.name.." ("..product.price.." R$)",
            Callback = function()
                SafePurchase(product.id)
            end
        })
    end
    
    MainTab:AddButton({
        Name = "Refresh Products",
        Callback = CreateUI
    })
    
    SettingsTab:AddSlider({
        Name = "Purchase Delay",
        Min = 0.01,
        Max = 1,
        Default = 0.01,
        Color = Color3.fromRGB(255,255,255),
        Increment = 0.01,
        ValueName = "seconds",
        Callback = function(Value)
            purchaseDelay = Value
        end    
    })
    
    SettingsTab:AddToggle({
        Name = "Experimental Mode",
        Default = false,
        Callback = function(Value)
            if Value then
                purchaseDelay = 0
            else
                purchaseDelay = 0.01
            end
        end    
    })
end

CreateUI()
OrionLib:Init()
