local MarketplaceService = game:GetService("MarketplaceService")  
local Players = game:GetService("Players")  
local LocalPlayer = Players.LocalPlayer  

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()  
local window = Library:NewWindow("Auto Purchase")  
local productsTab = window:NewSection("Developer Products")  

local products = {}  
local loopAll = false  

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

local function LoopPurchaseAll()  
    while loopAll and task.wait(0.01) do  
        for _, product in ipairs(products) do  
            if product.id ~= 0 then  
                task.spawn(SafePurchase, product.id)  
            end  
        end  
    end  
end  

local function CreateUI()  
    products = LoadProducts()  
    productsTab = window:NewSection("Products ("..#products..")")  
    
    productsTab:CreateToggle("LOOP BUY ALL", false, function(state)  
        loopAll = state  
        if state then  
            LoopPurchaseAll()  
        end  
    end)  
    
    productsTab:CreateButton("BUY ALL NOW", function()  
        for _, product in ipairs(products) do  
            if product.id ~= 0 then  
                task.spawn(SafePurchase, product.id)  
            end  
        end  
    end)  
    
    for _, product in ipairs(products) do  
        productsTab:CreateButton(product.name.." ("..product.price.." R$)", function()  
            SafePurchase(product.id)  
        end)  
    end  
    
    productsTab:CreateButton("Refresh List", CreateUI)  
end  

CreateUI()  
