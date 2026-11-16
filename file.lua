-- injury hub: Mecha Farm
-- Game: Вспышка инфекции меха (PlaceId: 120550559221143)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Clean up any previous instance before re-running
if _G.UnloadMechaFarm then
    pcall(_G.UnloadMechaFarm)
end
if getgenv and getgenv().__MechaFarmCleanup then
    pcall(getgenv().__MechaFarmCleanup)
end

local GUI_NAME = "InjuryHub_MechaFarm_GUI"
local parentGui = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
local existing = parentGui:FindFirstChild(GUI_NAME) or LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
if existing then
    existing:Destroy()
end

-- Network pipeline (ByteNetMax)
local GameNet = nil
pcall(function()
    GameNet = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("Game"))
end)

-- Connections tracker for clean unloading
local connections = {}
local function trackConn(c)
    if c then table.insert(connections, c) end
    return c
end

-- Typography (San Francisco / BuilderSans / Gotham)
local FontBold = pcall(function() return Enum.Font.BuilderSansBold end) and Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = pcall(function() return Enum.Font.BuilderSansMedium end) and Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

-- Main Card Frame (1.5x scaled via UIScale)
local mainCard = Instance.new("Frame")
mainCard.Name = "MainCard"
mainCard.Size = UDim2.fromOffset(280, 440)
mainCard.Position = UDim2.new(0.04, 0, 0.12, 0)
mainCard.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
mainCard.BorderSizePixel = 0
mainCard.ClipsDescendants = false
mainCard.Parent = screenGui

-- 1.5x Global Scale
local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.5
uiScale.Parent = mainCard

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 16)
cardCorner.Parent = mainCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(48, 48, 54)
cardStroke.Thickness = 1
cardStroke.Parent = mainCard

-- Header Title: injury hub
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Text = "injury hub"
titleLabel.Font = FontBold
titleLabel.TextSize = 17
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(16, 10)
titleLabel.Size = UDim2.new(1, -104, 0, 18)
titleLabel.Parent = mainCard

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Subtitle"
subLabel.Text = "MECHA INFECTION AUTO-FARM"
subLabel.Font = FontMedium
subLabel.TextSize = 9
subLabel.TextColor3 = Color3.fromRGB(142, 142, 147)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.BackgroundTransparency = 1
subLabel.Position = UDim2.fromOffset(16, 28)
subLabel.Size = UDim2.new(1, -104, 0, 12)
subLabel.Parent = mainCard

-- Forward declare unload & switchTab
local unload
local switchTab
local currentTab = "Farm"

-- Header Tab Container (Farm & Visuals) левее Unload
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.fromOffset(52, 24)
tabContainer.Position = UDim2.new(1, -98, 0, 10)
tabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
tabContainer.BorderSizePixel = 0
tabContainer.ZIndex = 5
tabContainer.Parent = mainCard

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 7)
tabCorner.Parent = tabContainer

-- Animated Selection Indicator (квадратный скругленный серый фон)
local tabIndicator = Instance.new("Frame")
tabIndicator.Name = "TabIndicator"
tabIndicator.Size = UDim2.fromOffset(24, 20)
tabIndicator.Position = UDim2.fromOffset(2, 2)
tabIndicator.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 6
tabIndicator.Parent = tabContainer

local tabIndicatorCorner = Instance.new("UICorner")
tabIndicatorCorner.CornerRadius = UDim.new(0, 6)
tabIndicatorCorner.Parent = tabIndicator

-- Farm Tab Button (Sword icon from icons.lua)
local farmTabBtn = Instance.new("TextButton")
farmTabBtn.Name = "FarmTabBtn"
farmTabBtn.Size = UDim2.fromOffset(24, 20)
farmTabBtn.Position = UDim2.fromOffset(2, 2)
farmTabBtn.BackgroundTransparency = 1
farmTabBtn.AutoButtonColor = false -- при наведении ничего не происходит
farmTabBtn.Text = ""
farmTabBtn.Active = true
farmTabBtn.ZIndex = 7
farmTabBtn.Parent = tabContainer

local farmTabIcon = Instance.new("ImageLabel")
farmTabIcon.Name = "Icon"
farmTabIcon.Size = UDim2.fromOffset(14, 14)
farmTabIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
farmTabIcon.BackgroundTransparency = 1
farmTabIcon.Image = "rbxassetid://124448418211665" -- sword icon
farmTabIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
farmTabIcon.ZIndex = 8
farmTabIcon.Parent = farmTabBtn

-- Visuals Tab Button (Eye icon from icons.lua)
local visualsTabBtn = Instance.new("TextButton")
visualsTabBtn.Name = "VisualsTabBtn"
visualsTabBtn.Size = UDim2.fromOffset(24, 20)
visualsTabBtn.Position = UDim2.fromOffset(26, 2)
visualsTabBtn.BackgroundTransparency = 1
visualsTabBtn.AutoButtonColor = false -- при наведении ничего не происходит
visualsTabBtn.Text = ""
visualsTabBtn.Active = true
visualsTabBtn.ZIndex = 7
visualsTabBtn.Parent = tabContainer

local visualsTabIcon = Instance.new("ImageLabel")
visualsTabIcon.Name = "Icon"
visualsTabIcon.Size = UDim2.fromOffset(14, 14)
visualsTabIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
visualsTabIcon.BackgroundTransparency = 1
visualsTabIcon.Image = "rbxassetid://100033680381365" -- eye icon
visualsTabIcon.ImageColor3 = Color3.fromRGB(142, 142, 147)
visualsTabIcon.ZIndex = 8
visualsTabIcon.Parent = visualsTabBtn

-- Unload Button (1 в 1 дизайн из farm.lua)
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Name = "UnloadBtn"
UnloadBtn.Size = UDim2.fromOffset(24, 24)
UnloadBtn.Position = UDim2.new(1, -40, 0, 10)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
UnloadBtn.BorderSizePixel = 0
UnloadBtn.AutoButtonColor = false
UnloadBtn.Text = ""
UnloadBtn.Active = true
UnloadBtn.ZIndex = 5
UnloadBtn.Parent = mainCard

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 7)
UnloadCorner.Parent = UnloadBtn

local UnloadIcon = Instance.new("ImageLabel")
UnloadIcon.Name = "Icon"
UnloadIcon.Size = UDim2.fromOffset(14, 14)
UnloadIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
UnloadIcon.BackgroundTransparency = 1
UnloadIcon.Image = "rbxassetid://84895399304975" -- log-out icon
UnloadIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
UnloadIcon.Parent = UnloadBtn

trackConn(UnloadBtn.MouseEnter:Connect(function()
    TweenService:Create(UnloadBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    }):Play()
    TweenService:Create(UnloadIcon, TweenInfo.new(0.15), {
        ImageColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end))

trackConn(UnloadBtn.MouseLeave:Connect(function()
    TweenService:Create(UnloadBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    }):Play()
    TweenService:Create(UnloadIcon, TweenInfo.new(0.15), {
        ImageColor3 = Color3.fromRGB(180, 180, 180)
    }):Play()
end))

trackConn(UnloadBtn.MouseButton1Click:Connect(function()
    if unload then unload() end
end))

-- Divider
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -32, 0, 1)
divider.Position = UDim2.fromOffset(16, 46)
divider.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
divider.BorderSizePixel = 0
divider.Parent = mainCard

-- Scrollable Container for Settings (Farm Tab)
local scrollContainer = Instance.new("ScrollingFrame")
scrollContainer.Name = "ScrollContainer"
scrollContainer.Size = UDim2.new(1, 0, 1, -96)
scrollContainer.Position = UDim2.fromOffset(0, 50)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 2
scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 66)
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollContainer.ClipsDescendants = true
scrollContainer.Parent = mainCard

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 16)
scrollPadding.PaddingRight = UDim.new(0, 16)
scrollPadding.PaddingTop = UDim.new(0, 6)
scrollPadding.PaddingBottom = UDim.new(0, 16)
scrollPadding.Parent = scrollContainer

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.Parent = scrollContainer

-- Visuals Tab Container
local visualsContainer = Instance.new("ScrollingFrame")
visualsContainer.Name = "VisualsContainer"
visualsContainer.Size = UDim2.new(1, 0, 1, -96)
visualsContainer.Position = UDim2.fromOffset(0, 50)
visualsContainer.BackgroundTransparency = 1
visualsContainer.BorderSizePixel = 0
visualsContainer.ScrollBarThickness = 2
visualsContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 66)
visualsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
visualsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
visualsContainer.ClipsDescendants = true
visualsContainer.Visible = false
visualsContainer.Parent = mainCard

local visualsPadding = Instance.new("UIPadding")
visualsPadding.PaddingLeft = UDim.new(0, 16)
visualsPadding.PaddingRight = UDim.new(0, 16)
visualsPadding.PaddingTop = UDim.new(0, 6)
visualsPadding.PaddingBottom = UDim.new(0, 16)
visualsPadding.Parent = visualsContainer

local visualsLayout = Instance.new("UIListLayout")
visualsLayout.SortOrder = Enum.SortOrder.LayoutOrder
visualsLayout.Padding = UDim.new(0, 8)
visualsLayout.Parent = visualsContainer

-- Header row in Visuals tab
local visHeaderRow = Instance.new("Frame")
visHeaderRow.Name = "Row_VisualsHeader"
visHeaderRow.Size = UDim2.new(1, 0, 0, 24)
visHeaderRow.BackgroundTransparency = 1
visHeaderRow.LayoutOrder = 1
visHeaderRow.Parent = visualsContainer

local visPlate = Instance.new("Frame")
visPlate.Size = UDim2.fromOffset(24, 24)
visPlate.Position = UDim2.new(0, 0, 0.5, -12)
visPlate.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
visPlate.BorderSizePixel = 0
visPlate.Parent = visHeaderRow

local visPlateCorner = Instance.new("UICorner")
visPlateCorner.CornerRadius = UDim.new(0, 7)
visPlateCorner.Parent = visPlate

local visPlateIcon = Instance.new("ImageLabel")
visPlateIcon.Size = UDim2.fromOffset(14, 14)
visPlateIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
visPlateIcon.BackgroundTransparency = 1
visPlateIcon.Image = "rbxassetid://100033680381365" -- eye icon
visPlateIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
visPlateIcon.Parent = visPlate

local visHeaderLabel = Instance.new("TextLabel")
visHeaderLabel.Text = "Visuals"
visHeaderLabel.Font = FontMedium
visHeaderLabel.TextSize = 13
visHeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
visHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
visHeaderLabel.BackgroundTransparency = 1
visHeaderLabel.Position = UDim2.new(0, 32, 0, 0)
visHeaderLabel.Size = UDim2.new(1, -32, 1, 0)
visHeaderLabel.Parent = visHeaderRow

-- Tab Switching Implementation with Quad Animation
local closeModeMenu
local closeTargetMenu
local closeFilterMenu
local saveConfig

switchTab = function(tabName, skipTween)
    if tabName == currentTab and not skipTween then return end
    currentTab = tabName

    local isFarm = (tabName == "Farm")
    local targetPos = isFarm and UDim2.fromOffset(2, 2) or UDim2.fromOffset(26, 2)
    local farmColor = isFarm and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(142, 142, 147)
    local visColor = isFarm and Color3.fromRGB(142, 142, 147) or Color3.fromRGB(255, 255, 255)

    if not isFarm then
        if closeModeMenu then closeModeMenu() end
        if closeTargetMenu then closeTargetMenu() end
        if closeFilterMenu then closeFilterMenu() end
    end

    if skipTween then
        tabIndicator.Position = targetPos
        farmTabIcon.ImageColor3 = farmColor
        visualsTabIcon.ImageColor3 = visColor
    else
        TweenService:Create(tabIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPos
        }):Play()
        TweenService:Create(farmTabIcon, TweenInfo.new(0.2), {
            ImageColor3 = farmColor
        }):Play()
        TweenService:Create(visualsTabIcon, TweenInfo.new(0.2), {
            ImageColor3 = visColor
        }):Play()
    end

    scrollContainer.Visible = isFarm
    visualsContainer.Visible = not isFarm
end

trackConn(farmTabBtn.MouseButton1Click:Connect(function()
    switchTab("Farm")
    if saveConfig then saveConfig() end
end))

trackConn(visualsTabBtn.MouseButton1Click:Connect(function()
    switchTab("Visuals")
    if saveConfig then saveConfig() end
end))

-- State variables
local AutoFarm = false
local BackOnSpawn = true -- Return to spawn if holding filtered item
local isRunning = true
local farm_target = nil
local targetFilter = { ["All Items"] = true }
local selectedFarmMode = "All Map" -- "All Map" or "Spawn Clusters"
local FARM_MODES = {"All Map", "Spawn Clusters"}
local RUN_SPEED = 34 -- studs/sec (оптимальная стабильная скорость без откатов античита)
local playerSpawnPos = nil -- Recorded spawn location (updates upon spawn/respawn)
local noSafePathCount = 0 -- Consecutive 'no safe path' failures counter

-- Noclip cache
local nc_cache = {}

local function set_farm_noclip(on)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if on then
        if not char then return end
        if hum then
            pcall(function()
                hum.PlatformStand = false
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                if hum:GetState() == Enum.HumanoidStateType.Climbing then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                if nc_cache[p] == nil then nc_cache[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    else
        if not char then return end
        if hum then
            pcall(function()
                hum.PlatformStand = false
                if not AutoFarm then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                else
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                    if hum:GetState() == Enum.HumanoidStateType.Climbing then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end)
        end
        for p, v in pairs(nc_cache) do
            if p and p.Parent then pcall(function() p.CanCollide = v end) end
        end
        table.clear(nc_cache)
    end
end

-- =========================================================================
-- Dynamic Obstacle Removal & Restoration System (1.8s Stuck -> Remove -> 1s Pass -> Restore)
-- =========================================================================
local obstacleCache = {} -- [instance] = { parent = origParent, removedAt = tick(), removalPos = Vector3, restoreAfter = nil }

local function temporarilyRemoveObstacle(instance, removalPos)
    if not instance or not instance.Parent or not instance:IsDescendantOf(workspace) then return false end

    -- Guard core elements from ever being removed
    if instance:IsA("Terrain") then return false end
    if instance:IsDescendantOf(workspace:FindFirstChild("ToolSpawnPoints")) then return false end
    if instance:IsDescendantOf(workspace:FindFirstChild("Characters")) then return false end
    local char = LocalPlayer.Character
    if char and instance:IsDescendantOf(char) then return false end
    if instance == workspace:FindFirstChild("Map") then return false end

    local target = instance
    -- If part belongs to a small prop/barrier/door/hatch model, remove the parent model
    if target.Parent and target.Parent:IsA("Model") and target.Parent ~= workspace and target.Parent.Name ~= "Map" and target.Parent.Name ~= "MapLayout" and target.Parent.Name ~= "Models" and target.Parent.Name ~= "Details" then
        target = target.Parent
    end

    if obstacleCache[target] then return true end

    local origParent = target.Parent
    obstacleCache[target] = {
        parent = origParent,
        removedAt = tick(),
        removalPos = removalPos,
        restoreAfter = nil
    }

    pcall(function()
        target.Parent = nil
    end)
    return true
end

local function findBlockingObstacle(curPos, moveDir)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local wallParams = RaycastParams.new()
    wallParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    if char then table.insert(filter, char) end
    wallParams.FilterDescendantsInstances = filter
    wallParams.RespectCanCollide = true

    local dir = (moveDir and moveDir.Magnitude > 0.01) and moveDir.Unit or hrp.CFrame.LookVector
    local rayDist = 4.5

    -- 1. Check forward raycasts at eye level, chest level, and foot level
    local rayOffsets = {Vector3.new(0, 0, 0), Vector3.new(0, 1.8, 0), Vector3.new(0, -1.2, 0)}
    for _, offset in ipairs(rayOffsets) do
        local hit = workspace:Raycast(curPos + offset, dir * rayDist, wallParams)
        if hit and hit.Instance and not hit.Instance:IsA("Terrain") then
            local inst = hit.Instance
            if not inst:IsDescendantOf(workspace:FindFirstChild("ToolSpawnPoints")) and not inst:IsDescendantOf(workspace:FindFirstChild("Characters")) then
                local n = inst.Name:lower()
                if n ~= "facility" and n ~= "floor" and n ~= "baseplate" and n ~= "map" then
                    return inst
                end
            end
        end
    end

    -- 2. Check touching parts in immediate bounding box (stuck inside / wedged against obstacle)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = filter
    local parts = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, 0, -1.2), Vector3.new(3.5, 4.5, 3.5), overlap)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and p.CanCollide and not p:IsA("Terrain") then
            local pName = p.Name:lower()
            if pName ~= "facility" and pName ~= "floor" and pName ~= "baseplate" and pName ~= "map" then
                return p
            end
        end
    end

    return nil
end

local function restoreAllObstacles()
    for inst, data in pairs(obstacleCache) do
        if inst and data.parent then
            pcall(function()
                inst.Parent = data.parent
            end)
        end
    end
    table.clear(obstacleCache)
end

local function checkObstaclesPassed(curPos)
    local now = tick()
    for inst, data in pairs(obstacleCache) do
        if not data.restoreAfter then
            -- Check if character has passed through (moved away by >= 5 studs from removal point)
            local dist = (curPos - data.removalPos).Magnitude
            if dist >= 5.0 then
                -- Passed! Schedule restoration in 1.0 second
                data.restoreAfter = now + 1.0
            elseif (now - data.removedAt) >= 6.0 then
                -- Fallback timeout (6 seconds)
                data.restoreAfter = now + 1.0
            end
        else
            -- Restore after 1.0 second delay
            if now >= data.restoreAfter then
                pcall(function()
                    if inst and data.parent then
                        inst.Parent = data.parent
                    end
                end)
                obstacleCache[inst] = nil
            end
        end
    end
end

-- Active Heartbeat listener for obstacle restoration and climbing neutralization
trackConn(RunService.Heartbeat:Connect(function()
    if next(obstacleCache) ~= nil then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            checkObstaclesPassed(hrp.Position)
        end
    end

    if AutoFarm and isRunning then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            end)
            if hum:GetState() == Enum.HumanoidStateType.Climbing then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end))

-- Helper: Check if player is currently Infected
local function isPlayerInfected()
    if LocalPlayer.Team and tostring(LocalPlayer.Team.Name):lower():find("infected") then
        return true
    end
    local char = LocalPlayer.Character
    if char and (char:GetAttribute("Infected") == true or tostring(char:GetAttribute("Team")):lower():find("infected")) then
        return true
    end
    return false
end

-- Helper: Check if item requires Infected status to pick up
local function isInfectedItem(itemName)
    if not itemName then return false end
    local lower = itemName:lower()
    return lower:find("infected") ~= nil or lower:find("corrupted") ~= nil
end

-- Priority list for sorting best drops in "All Items" (Ranked by exact in-game DPS, Damage, Health & Durability stats)
local ITEM_PRIORITIES = {
    -- Tier S+ (Top DPS & Max Health/Damage)
    ["Dragonslayer Sword"] = 100,  -- Damage 60 (Highest in game!), Hitbox 10x2x10, Legendary (TOP 1 PRIORITY)
    ["Okatana"] = 98,              -- DPS 32.1 (0.7s CD), Durability 100, Legendary
    ["Heavy Vest"] = 96,           -- +50 Max Health (+50% survivability buffer)
    ["Katana"] = 94,               -- DPS 32.1 (0.7s CD), Durability 70
    ["Infected Katana"] = 94,      -- DPS 32.1 (0.7s CD), Durability 70

    -- Tier S (Massive 60 Damage & Double Durability)
    ["Carrot Hammer"] = 92,        -- Damage 60, Durability 50, Legendary
    ["Hope Edge"] = 90,            -- Damage 27.5, Durability 100 (Double life), Uncommon
    ["Sledgehammer"] = 88,         -- Damage 60, Durability 25, Uncommon
    ["Heavy Hazmat Suit"] = 86,    -- Rare suit, Price 30
    ["Light Vest"] = 84,           -- +35 Max Health

    -- Tier A (Heavy Melee 45-35 Damage & Fast DPS)
    ["Crucible"] = 82,             -- Damage 35, Cooldown 2.5s, Hitbox 6x4x6, Uncommon
    ["Breaching Hammer"] = 80,     -- Damage 45, Cooldown 3.0s, Uncommon
    ["Carrot Greatsword"] = 78,    -- Damage 40, Cooldown 3.0s, Hitbox 5.5x4x5.5, Legendary
    ["Claymore"] = 76,             -- Damage 40, Cooldown 3.0s, Hitbox 5.5x4x5.5, Uncommon
    ["Battle Axe"] = 75,           -- Damage 40, Cooldown 3.0s, Hitbox 5x4x4.5, Uncommon
    ["Knife"] = 73,                -- DPS 28.0 (0.5s CD, 2nd highest DPS in game!), Durability 50

    -- Tier B (30-23 Damage Medium Melee)
    ["Carrot Scythe"] = 70,        -- Damage 30, Cooldown 2.5s, Hitbox 7x4x6.5, Legendary
    ["Fire Axe"] = 68,             -- Damage 30, Cooldown 2.5s, Durability 50
    ["Sword"] = 65,                -- Damage 25, Cooldown 1.8s, DPS 13.9, Durability 50
    ["Pipe"] = 60,                 -- Damage 23, Cooldown 1.5s, DPS 15.3, Durability 50

    -- Tier C (Lower DPS / Low Durability)
    ["Corrupted Sword"] = 55,      -- Damage 20, Cooldown 1.8s, DPS 11.1, Legendary
    ["Bat"] = 50,                  -- Damage 20, Cooldown 1.3s, DPS 15.4, Durability 25
    ["Crescendo"] = 45,            -- Damage 20, Cooldown 2.5s, DPS 8.0, Durability 100, Legendary
    ["Energy Sword"] = 40,         -- Damage 22, Cooldown 3.0s, DPS 7.3, Durability 50
    ["Stun Baton"] = 25,           -- Damage 15, Cooldown 2.5s, Durability 5 (breaks in 5 hits)
    ["Red Protogen Visor"] = 22,   -- Visor accessory

    -- Tier D (Utility & Consumables)
    ["Light Hazmat Suit"] = 20,
    ["Bloxy Cola"] = 15,
    ["Bloxiade"] = 15,
    ["Cheezeburger"] = 10,
    ["Sandwich"] = 8,
}

-- ПОЛНЫЙ список всех предметов в игре для ComboBox
local SELECTABLE_ITEMS = {
    "All Items",
    -- Tier S+ & S (Top Weapons & Armor)
    "Dragonslayer Sword",
    "Okatana",
    "Heavy Vest",
    "Katana",
    "Infected Katana",
    "Carrot Hammer",
    "Hope Edge",
    "Sledgehammer",
    "Light Vest",

    -- Tier A (Heavy & Fast Weapons)
    "Crucible",
    "Breaching Hammer",
    "Carrot Greatsword",
    "Claymore",
    "Battle Axe",
    "Knife",

    -- Tier B & C (Medium & Utility Weapons)
    "Carrot Scythe",
    "Fire Axe",
    "Sword",
    "Pipe",
    "Corrupted Sword",
    "Bat",
    "Crescendo",
    "Energy Sword",
    "Stun Baton",

    -- Suits & Gear
    "Red Protogen Visor",
    "Heavy Hazmat Suit",
    "Light Hazmat Suit",

    -- Consumables
    "Bloxy Cola",
    "Bloxiade",
    "Cheezeburger",
    "Sandwich",
}

-- Список предметов для Filter ComboBox (Не ресетаться если есть в инвентаре)
-- Автоматически синхронизирован со ВСЕМИ предметами из SELECTABLE_ITEMS
local FILTER_ITEMS = {}
for _, item in ipairs(SELECTABLE_ITEMS) do
    if item ~= "All Items" then
        table.insert(FILTER_ITEMS, item)
    end
end

-- Default protected filter
local protectedFilter = {
    ["Dragonslayer Sword"] = true,
    ["Okatana"] = true,
}

-- Helper: Get effective item priority (Protected filter items get massive +1000 priority bonus)
local function getEffectiveItemPriority(itemName)
    if not itemName then return 0 end
    local basePriority = ITEM_PRIORITIES[itemName] or 1
    local filterBonus = (protectedFilter[itemName] == true) and 1000 or 0
    return basePriority + filterBonus
end

-- Stats Footer
local statsBox = Instance.new("Frame")
statsBox.Name = "StatsBox"
statsBox.Size = UDim2.new(1, -32, 0, 38)
statsBox.Position = UDim2.new(0, 16, 1, -44)
statsBox.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
statsBox.BorderSizePixel = 0
statsBox.ZIndex = 4
statsBox.Parent = mainCard

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 10)
statsCorner.Parent = statsBox

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(6, 6)
statusDot.Position = UDim2.fromOffset(8, 8)
statusDot.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
statusDot.BorderSizePixel = 0
statusDot.Parent = statsBox

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

local statusText = Instance.new("TextLabel")
statusText.Text = "Idle"
statusText.Font = FontMedium
statusText.TextSize = 11
statusText.TextColor3 = Color3.fromRGB(200, 200, 204)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(20, 5)
statusText.Size = UDim2.new(1, -26, 0, 12)
statusText.Parent = statsBox

local subStatusText = Instance.new("TextLabel")
subStatusText.Text = "Target: All Items | Speed: 32 studs/s (Run)"
subStatusText.Font = FontMedium
subStatusText.TextSize = 10
subStatusText.TextColor3 = Color3.fromRGB(100, 210, 255)
subStatusText.TextXAlignment = Enum.TextXAlignment.Left
subStatusText.BackgroundTransparency = 1
subStatusText.Position = UDim2.fromOffset(8, 22)
subStatusText.Size = UDim2.new(1, -14, 0, 12)
subStatusText.Parent = statsBox

-- Helper: Get Player Character and RootPart
local function getChar()
    local char = LocalPlayer.Character
    return char, char and char:FindFirstChild("HumanoidRootPart")
end

-- Failed pickup cooldown cache to prevent freezing in endless pickup loop
local failedPickupCache = {}

-- Helper: Check if item is already in Backpack or equipped in Character (case-insensitive + whitespace-agnostic)
local function hasItemInInventory(itemName)
    if not itemName then return false end
    local cleanTarget = itemName:lower():gsub("%s+", "")

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        if bp:FindFirstChild(itemName) then return true end
        for _, item in ipairs(bp:GetChildren()) do
            local cleanName = item.Name:lower():gsub("%s+", "")
            if cleanName == cleanTarget or item.Name:lower() == itemName:lower() then
                return true
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChild(itemName) then return true end
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Accessory") then
                local cleanName = item.Name:lower():gsub("%s+", "")
                if cleanName == cleanTarget or item.Name:lower() == itemName:lower() then
                    return true
                end
            end
        end
    end
    return false
end

-- Helper: Check if item was already collected (in inventory or spawn part has been consumed/destroyed)
local function isItemAlreadyCollected(targetPart, itemName)
    if itemName and hasItemInInventory(itemName) then
        return true
    end
    if not targetPart or not targetPart.Parent or not targetPart:IsDescendantOf(workspace) then
        return true
    end
    -- Check CollectionService tag: when an item is collected/consumed, the game removes "ToolPickUp" tag
    if not CollectionService:HasTag(targetPart, "ToolPickUp") then
        return true
    end
    -- Check Item attribute: when collected, attribute is nil or changed
    local curAttr = targetPart:GetAttribute("Item")
    if curAttr == nil or (itemName and curAttr ~= itemName) then
        return true
    end
    -- Check if visual model inside SpawnPoint was removed
    if targetPart.Name == "SpawnPoint" and not targetPart:FindFirstChildOfClass("Model") and not targetPart:FindFirstChild("Model") then
        return true
    end
    return false
end

-- Helper: Check if player holds ANY item from the protected filter list
local function isHoldingAnyProtectedItem()
    for itemName, isProtected in pairs(protectedFilter) do
        if isProtected and hasItemInInventory(itemName) then
            return true, itemName
        end
    end
    return false, nil
end

-- Helper: Count active protected items
local function countProtected()
    local c = 0
    for _, item in ipairs(FILTER_ITEMS) do
        if protectedFilter[item] then c = c + 1 end
    end
    return c
end

-- Helper: check if target is All Items
local function isAllItemsTarget()
    return targetFilter["All Items"] == true
end

-- Helper: count specific targets selected
local function countSelectedTargets()
    if targetFilter["All Items"] then return 0 end
    local count = 0
    for _, item in ipairs(SELECTABLE_ITEMS) do
        if item ~= "All Items" and targetFilter[item] then
            count = count + 1
        end
    end
    return count
end

-- Helper: get display summary of selected targets
local function getTargetSummary()
    if targetFilter["All Items"] then
        return "All Items"
    end
    local selectedList = {}
    for _, item in ipairs(SELECTABLE_ITEMS) do
        if item ~= "All Items" and targetFilter[item] then
            table.insert(selectedList, item)
        end
    end
    if #selectedList == 0 then
        targetFilter["All Items"] = true
        return "All Items"
    elseif #selectedList == 1 then
        return selectedList[1]
    elseif #selectedList == 2 then
        return selectedList[1] .. ", " .. selectedList[2]
    else
        return #selectedList .. " Items Selected"
    end
end

-- Helper: check if itemName is wanted by target filter
local function isItemWanted(itemName)
    if not itemName then return false end
    if targetFilter["All Items"] then
        return true
    end
    return targetFilter[itemName] == true
end

-- ==========================================
-- Persistent Configuration System (JSON)
-- ==========================================
local CONFIG_FILE = "mecha_farm_config.json"
local loadedConfig = nil

saveConfig = function()
    if not writefile then return end
    local cardPos = nil
    if mainCard then
        cardPos = {
            mainCard.Position.X.Scale,
            mainCard.Position.X.Offset,
            mainCard.Position.Y.Scale,
            mainCard.Position.Y.Offset
        }
    end
    local cfg = {
        AutoFarm = (AutoFarm == true),
        BackOnSpawn = (BackOnSpawn == true),
        selectedFarmMode = selectedFarmMode,
        targetFilter = targetFilter,
        protectedFilter = protectedFilter,
        cardPos = cardPos,
        currentTab = currentTab,
    }
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not raw or #raw == 0 then return end
    local decodeOk, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if not decodeOk or type(cfg) ~= "table" then return end
    loadedConfig = cfg

    if type(cfg.AutoFarm) == "boolean" then
        AutoFarm = cfg.AutoFarm
    end
    if type(cfg.BackOnSpawn) == "boolean" then
        BackOnSpawn = cfg.BackOnSpawn
    end
    if type(cfg.selectedFarmMode) == "string" and table.find(FARM_MODES, cfg.selectedFarmMode) then
        selectedFarmMode = cfg.selectedFarmMode
    end
    if type(cfg.targetFilter) == "table" then
        table.clear(targetFilter)
        for k, v in pairs(cfg.targetFilter) do
            if v == true then
                targetFilter[k] = true
            end
        end
        if countSelectedTargets() == 0 and not targetFilter["All Items"] then
            targetFilter["All Items"] = true
        end
    end
    if type(cfg.protectedFilter) == "table" then
        table.clear(protectedFilter)
        for k, v in pairs(cfg.protectedFilter) do
            if v == true then
                protectedFilter[k] = true
            end
        end
    end
    if cfg.cardPos and type(cfg.cardPos) == "table" and #cfg.cardPos >= 4 and mainCard then
        mainCard.Position = UDim2.new(cfg.cardPos[1], cfg.cardPos[2], cfg.cardPos[3], cfg.cardPos[4])
    end
    if type(cfg.currentTab) == "string" and (cfg.currentTab == "Farm" or cfg.currentTab == "Visuals") then
        if cfg.currentTab ~= currentTab and switchTab then
            switchTab(cfg.currentTab, true)
        end
    end
end

-- Load saved configuration immediately
loadConfig()
subStatusText.Text = "Mode: " .. selectedFarmMode .. " | Target: " .. getTargetSummary()

-- Synchronize position and ragdoll parts to prevent rubberbanding
local function syncPos(cf)
    local char, hrp = getChar()
    if not hrp then return end
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Climbing then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end

    local rc = char and char:FindFirstChild("RagdollColliders")
    if rc then
        for _, p in ipairs(rc:GetChildren()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.CFrame = cf
                p.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end

local isFlying = false
local jumpLoopThread = nil

-- Trigger the place's custom jump (JumpCooldown script listener)
local function triggerCustomJump()
    local char, hrp = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        if hum:GetState() == Enum.HumanoidStateType.Climbing then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        else
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        if firesignal then
            firesignal(UserInputService.JumpRequest)
        else
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- Start flight: enables noclip and launches infinite custom jump loop
local function startFlight()
    isFlying = true
    set_farm_noclip(true)

    local char, hrp = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            if hum:GetState() == Enum.HumanoidStateType.Climbing then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    if not jumpLoopThread then
        jumpLoopThread = task.spawn(function()
            while isFlying and AutoFarm and isRunning do
                triggerCustomJump()
                task.wait(0.2)
            end
            jumpLoopThread = nil
        end)
    end
end

-- Stop flight smoothly without sudden physics snaps
local function stopFlight()
    isFlying = false
    jumpLoopThread = nil

    local char, hrp = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            if not AutoFarm then
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            else
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                if hum:GetState() == Enum.HumanoidStateType.Climbing then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    set_farm_noclip(false)
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- Find solid floor point below any position
local function findFloorBelow(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    local char = LocalPlayer.Character
    if char then table.insert(filter, char) end
    params.FilterDescendantsInstances = filter
    params.RespectCanCollide = true

    local ray = workspace:Raycast(pos + Vector3.new(0, 2.0, 0), Vector3.new(0, -60, 0), params)
    return ray and ray.Position or pos
end

-- Track and remember player spawn location on room floor
local function updatePlayerSpawnPos(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local floor = findFloorBelow(hrp.Position)
        playerSpawnPos = floor or hrp.Position
    end
end

-- Capture initial spawn position if character already exists
if LocalPlayer.Character then
    updatePlayerSpawnPos(LocalPlayer.Character)
end

-- Update spawn position on every respawn / round start
trackConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
    noSafePathCount = 0
    task.defer(function()
        local hrp = newChar:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            task.wait(0.3)
            updatePlayerSpawnPos(newChar)
        end
    end)
end))

-- Generate reachable, walkable room floor candidates around any item (on floor, table, crate, or container)
local function findWalkableFloorCandidates(targetPart, preferNearPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    local char = LocalPlayer.Character
    if char then table.insert(filter, char) end
    params.FilterDescendantsInstances = filter
    params.RespectCanCollide = true

    local targetPos = targetPart.Position
    local floorDirect = findFloorBelow(targetPos)

    local candidateRadii = {3.5, 5.5, 7.5}
    local candidateAngles = {0, 45, 90, 135, 180, 225, 270, 315}
    local candidates = {}

    -- Direct floor below item (if within 1.5 studs of item, e.g. item lying directly on floor)
    if (targetPos.Y - floorDirect.Y) <= 1.5 then
        table.insert(candidates, {
            pos = floorDirect,
            distToPlayer = preferNearPos and (floorDirect - preferNearPos).Magnitude or 0,
            distToItem = (floorDirect - targetPos).Magnitude
        })
    end

    -- Radial floor candidates around item
    for _, r in ipairs(candidateRadii) do
        for _, deg in ipairs(candidateAngles) do
            local rad = math.rad(deg)
            local offset = Vector3.new(math.cos(rad) * r, 0, math.sin(rad) * r)
            local testHigh = targetPos + offset + Vector3.new(0, 0.5, 0)

            -- 1. Horizontal ray from above item outwards (must not hit walls)
            local horizRay = workspace:Raycast(targetPos + Vector3.new(0, 0.3, 0), offset, params)
            if not horizRay then
                -- 2. Vertical ray down to floor
                local downRay = workspace:Raycast(testHigh, Vector3.new(0, -60, 0), params)
                if downRay and downRay.Position then
                    local floorPt = downRay.Position
                    local distToItem = (floorPt - targetPos).Magnitude

                    -- Within valid interaction range (<= 13 studs)
                    if distToItem <= 13.0 then
                        -- 3. Verify vertical headroom (at least 4.5 studs clear air above floor)
                        local vertRay = workspace:Raycast(floorPt + Vector3.new(0, 0.5, 0), Vector3.new(0, 4.0, 0), params)
                        if not vertRay then
                            -- 4. Ground-level clearance ray towards item base
                            local groundTarget = floorPt + Vector3.new(0, 2.0, 0)
                            local groundOrigin = Vector3.new(targetPos.X, floorPt.Y + 2.0, targetPos.Z)
                            local groundRay = workspace:Raycast(groundTarget, groundOrigin - groundTarget, params)
                            if not groundRay or groundRay.Distance >= (r - 2.5) then
                                local distToPlayer = preferNearPos and (floorPt - preferNearPos).Magnitude or r
                                table.insert(candidates, {
                                    pos = floorPt,
                                    distToPlayer = distToPlayer,
                                    distToItem = distToItem
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    -- Sort candidates by distance to player (closest entrance side first)
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return a.distToPlayer < b.distToPlayer
        end)
    else
        table.insert(candidates, {
            pos = floorDirect,
            distToPlayer = preferNearPos and (floorDirect - preferNearPos).Magnitude or 0,
            distToItem = (floorDirect - targetPos).Magnitude
        })
    end

    return candidates
end

-- Helper: Find the highest priority spawn currently available on the map (ONLY from protectedFilter!)
local function getHighestAvailableSpawn()
    local char, hrp = getChar()
    if not char or not hrp then return nil end
    local myPos = hrp.Position
    local playerIsInfected = isPlayerInfected()
    local taggedParts = CollectionService:GetTagged("ToolPickUp")

    local bestCand = nil
    local bestPriority = -1

    for _, part in ipairs(taggedParts) do
        if part and part.Parent and part:IsA("BasePart") then
            local itmName = part:GetAttribute("Item")
            if itmName and not hasItemInInventory(itmName) then
                local itemIsInfected = isInfectedItem(itmName)
                if not itemIsInfected or playerIsInfected then
                    -- STRICT FILTER CHECK: Preemptive switching ONLY applies to items chosen in No-Reset Filter!
                    if (protectedFilter[itmName] == true) and isItemWanted(itmName) then
                        local p = getEffectiveItemPriority(itmName)
                        local d = (myPos - part.Position).Magnitude
                        if p > bestPriority or (p == bestPriority and bestCand and d < bestCand.dist) then
                            bestPriority = p
                            bestCand = {part = part, name = itmName, priority = p, dist = d}
                        end
                    end
                end
            end
        end
    end
    return bestCand
end

-- Forward declaration of AntiCheat rollback pause handler
local handleRubberband

-- Smooth flight interpolation at RUN_SPEED with strict obstacle detection (NEVER through walls)
local function flyTo(targetPos, currentTargetPriority, currentTargetPart, targetItemName)
    local char, hrp = getChar()
    if not char or not hrp then return false, false end

    startFlight()

    local wallParams = RaycastParams.new()
    wallParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    local curChar = LocalPlayer.Character
    if curChar then table.insert(filter, curChar) end
    wallParams.FilterDescendantsInstances = filter
    wallParams.RespectCanCollide = true

    local lastPlacedPos = nil
    local lastPriorityCheck = tick()
    local lastProgressPos = hrp.Position
    local lastProgressTime = tick()

    while AutoFarm and isRunning do
        local dt = RunService.Heartbeat:Wait()
        if not AutoFarm or not isRunning then
            stopFlight()
            return false, false
        end

        char, hrp = getChar()
        if not char or not hrp then return false, false end

        -- Neutralize Climbing on every frame
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            end)
            if hum:GetState() == Enum.HumanoidStateType.Climbing then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end

        -- If target item is already collected, return immediately
        if targetItemName and isItemAlreadyCollected(currentTargetPart, targetItemName) then
            stopFlight()
            return true, false
        end

        local curPos = hrp.Position

        -- AntiCheat Rollback detection: server teleports player backwards
        if lastPlacedPos and (curPos - lastPlacedPos).Magnitude > 4.2 then
            if handleRubberband then handleRubberband() end
            return false, false
        end

        -- Preemptive priority switch: abruptly retarget ONLY if a higher priority FILTERED item appeared
        if currentTargetPriority and tick() - lastPriorityCheck > 0.18 then
            lastPriorityCheck = tick()
            local bestCand = getHighestAvailableSpawn()
            if bestCand and (protectedFilter[bestCand.name] == true) and bestCand.part ~= currentTargetPart and bestCand.priority > currentTargetPriority then
                statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                statusText.Text = "Switching to: " .. bestCand.name .. "!"
                subStatusText.Text = "Higher priority spawn (" .. bestCand.name .. ")"
                stopFlight()
                return false, true
            end
        end

        local toTarget = targetPos - curPos
        local dist = toTarget.Magnitude

        if dist <= 1.2 then
            return true, false
        end

        -- 1.8-second Stuck Obstacle Removal System
        local moved = (curPos - lastProgressPos).Magnitude
        if moved > 0.6 then
            lastProgressPos = curPos
            lastProgressTime = tick()
        else
            local stuckDuration = tick() - lastProgressTime
            if stuckDuration >= 1.8 then
                local obs = findBlockingObstacle(curPos, toTarget)
                if obs then
                    temporarilyRemoveObstacle(obs, curPos)
                    lastProgressTime = tick() - 0.8
                else
                    if stuckDuration >= 2.5 then
                        stopFlight()
                        return false, false
                    end
                end
            end
        end

        local step = math.min(RUN_SPEED * dt, dist)
        local stepVec = toTarget.Unit * step

        -- Obstacle guard at chest height: verify step does not hit any solid wall
        local wallHit = workspace:Raycast(curPos, stepVec.Unit * (step + 1.2), wallParams)
        if wallHit and wallHit.Instance and not wallHit.Instance:IsDescendantOf(workspace:FindFirstChild("ToolSpawnPoints")) then
            local obs = wallHit.Instance
            local stuckDuration = tick() - lastProgressTime
            if stuckDuration >= 1.8 then
                temporarilyRemoveObstacle(obs, curPos)
                lastProgressTime = tick() - 0.8
            else
                task.wait(0.04)
                continue
            end
        end

        local nextPos = curPos + stepVec
        local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
        local nextCF
        if flatDir.Magnitude > 0.01 then
            nextCF = CFrame.lookAt(nextPos, nextPos + flatDir)
        else
            nextCF = CFrame.new(nextPos) * (hrp.CFrame - hrp.Position)
        end

        syncPos(nextCF)
        lastPlacedPos = nextPos
    end

    stopFlight()
    return false, false
end

-- Follow path waypoints with ON-THE-FLY item interception (collects as soon as within 13 studs)
local function followPathWithInterception(waypoints, targetPart, itemName, currentTargetPriority)
    local char, hrp = getChar()
    if not char or not hrp then return false, false, false end
    if not waypoints or #waypoints < 2 then return true, false, false end

    startFlight()

    local wallParams = RaycastParams.new()
    wallParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    local curChar = LocalPlayer.Character
    if curChar then table.insert(filter, curChar) end
    wallParams.FilterDescendantsInstances = filter
    wallParams.RespectCanCollide = true

    local wpIndex = 2
    local totalWps = #waypoints
    local lastPlacedPos = nil
    local lastPriorityCheck = tick()
    local lastProgressPos = hrp.Position
    local lastProgressTime = tick()

    while AutoFarm and isRunning and wpIndex <= totalWps do
        local dt = RunService.Heartbeat:Wait()
        if not AutoFarm or not isRunning then
            stopFlight()
            return false, false, false
        end

        char, hrp = getChar()
        if not char or not hrp then return false, false, false end

        -- 1. CRITICAL: Check if item was already collected on EVERY single frame!
        if itemName and isItemAlreadyCollected(targetPart, itemName) then
            stopFlight()
            return true, true, false -- Collected on the fly!
        end

        -- 2. Neutralize Climbing state on every frame
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            end)
            if hum:GetState() == Enum.HumanoidStateType.Climbing then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end

        local curPos = hrp.Position

        -- AntiCheat Rollback detection: server teleports player backwards
        if lastPlacedPos and (curPos - lastPlacedPos).Magnitude > 4.2 then
            if handleRubberband then handleRubberband() end
            return false, false, false
        end

        -- Preemptive priority switch: abruptly retarget ONLY if higher priority FILTERED item appeared
        if currentTargetPriority and tick() - lastPriorityCheck > 0.18 then
            lastPriorityCheck = tick()
            local bestCand = getHighestAvailableSpawn()
            if bestCand and (protectedFilter[bestCand.name] == true) and bestCand.part ~= targetPart and bestCand.priority > currentTargetPriority then
                statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                statusText.Text = "Switching to: " .. bestCand.name .. "!"
                subStatusText.Text = "Higher priority spawn (" .. bestCand.name .. ")"
                stopFlight()
                return false, false, true -- okPath = false, collectedOnFly = false, wasPreempted = true
            end
        end

        -- ON-THE-FLY INTERCEPTION: if character is within pickup range (<= 13 studs) on approach
        if targetPart and targetPart.Parent and itemName then
            local distToItem = (curPos - targetPart.Position).Magnitude
            if distToItem <= 13.0 then
                local cam = workspace.CurrentCamera
                if cam then
                    cam.CFrame = CFrame.lookAt(curPos + Vector3.new(0, 2.0, 0), targetPart.Position)
                end
                hrp.CFrame = CFrame.lookAt(curPos, Vector3.new(targetPart.Position.X, curPos.Y, targetPart.Position.Z))

                if GameNet and GameNet.packets and GameNet.packets.PickUpTool then
                    pcall(function()
                        GameNet.packets.PickUpTool.send(targetPart)
                    end)
                end

                if isItemAlreadyCollected(targetPart, itemName) then
                    stopFlight()
                    return true, true, false -- Collected on the fly!
                end
            end
        end

        local targetWp = waypoints[wpIndex].Position + Vector3.new(0, 2.5, 0)
        local toTarget = targetWp - curPos
        local dist = toTarget.Magnitude

        if dist <= 2.2 then
            wpIndex = wpIndex + 1
            lastProgressPos = curPos
            lastProgressTime = tick()
            if wpIndex > totalWps then
                break
            end
            targetWp = waypoints[wpIndex].Position + Vector3.new(0, 2.5, 0)
            toTarget = targetWp - curPos
            dist = toTarget.Magnitude
        end

        -- 1.8-second Stuck Obstacle Removal System
        local moved = (curPos - lastProgressPos).Magnitude
        if moved > 0.6 then
            lastProgressPos = curPos
            lastProgressTime = tick()
        else
            local stuckDuration = tick() - lastProgressTime
            if stuckDuration >= 1.8 then
                local obs = findBlockingObstacle(curPos, toTarget)
                if obs then
                    temporarilyRemoveObstacle(obs, curPos)
                    lastProgressTime = tick() - 0.8
                else
                    -- Advance stuck waypoint or break
                    wpIndex = wpIndex + 1
                    lastProgressTime = tick()
                    if wpIndex > totalWps then
                        break
                    end
                end
            end
        end

        local step = math.min(RUN_SPEED * dt, dist)
        local stepVec = toTarget.Unit * step

        -- Obstacle guard at chest height: verify step does not hit any solid wall
        local wallHit = workspace:Raycast(curPos, stepVec.Unit * (step + 1.2), wallParams)
        if wallHit and wallHit.Instance and not wallHit.Instance:IsDescendantOf(workspace:FindFirstChild("ToolSpawnPoints")) then
            local obs = wallHit.Instance
            local stuckDuration = tick() - lastProgressTime
            if stuckDuration >= 1.8 then
                temporarilyRemoveObstacle(obs, curPos)
                lastProgressTime = tick() - 0.8
            else
                task.wait(0.04)
                continue
            end
        end

        local nextPos = curPos + stepVec
        local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
        local nextCF
        if flatDir.Magnitude > 0.01 then
            nextCF = CFrame.lookAt(nextPos, nextPos + flatDir)
        else
            nextCF = CFrame.new(nextPos) * (hrp.CFrame - hrp.Position)
        end

        syncPos(nextCF)
        lastPlacedPos = nextPos
    end

    return true, false, false -- Arrived at final floor point beside item
end

-- Check if there is an open, unobstructed overhead air route above partition walls (NEVER through walls!)
local function tryOverheadFly(destFloor, currentTargetPriority, targetPart)
    local char, hrp = getChar()
    if not char or not hrp then return false, false end

    local wallParams = RaycastParams.new()
    wallParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {workspace:FindFirstChild("ToolSpawnPoints"), workspace:FindFirstChild("Characters")}
    local curChar = LocalPlayer.Character
    if curChar then table.insert(filter, curChar) end
    wallParams.FilterDescendantsInstances = filter
    wallParams.RespectCanCollide = true

    local curPos = hrp.Position

    -- 1. Check vertical ceiling above current position
    local upCheckCur = workspace:Raycast(curPos, Vector3.new(0, 45, 0), wallParams)
    local maxCurY = upCheckCur and (upCheckCur.Position.Y - 2.5) or (curPos.Y + 30)

    -- 2. Check vertical ceiling above destination
    local upCheckDest = workspace:Raycast(destFloor, Vector3.new(0, 45, 0), wallParams)
    local maxDestY = upCheckDest and (upCheckDest.Position.Y - 2.5) or (destFloor.Y + 30)

    -- Safe clearance altitude: above partition walls (at least 7 studs above floor), under any ceiling
    local minFlightY = math.max(curPos.Y, destFloor.Y) + 7.0
    local maxAllowedY = math.min(maxCurY, maxDestY)

    if maxAllowedY < minFlightY then
        -- Ceilings are too low (enclosed bunker with full-height walls to ceiling)
        return false, false
    end

    local flightAltitude = math.min(minFlightY + 3.0, maxAllowedY)
    local highStart = Vector3.new(curPos.X, flightAltitude, curPos.Z)
    local highDest = Vector3.new(destFloor.X, flightAltitude, destFloor.Z)

    -- 3. Check horizontal line-of-sight at flight altitude between start and dest
    local horizCheck = workspace:Raycast(highStart, highDest - highStart, wallParams)
    if horizCheck then
        -- Wall or obstacle blocks the overhead path at this altitude
        return false, false
    end

    -- 4. Overhead path is 100% CLEAR in open air! Fly safely without touching any wall:
    statusText.Text = "Flying overhead..."

    -- Step A: Ascend vertically in current room
    local ok1, pre1 = flyTo(highStart, currentTargetPriority, targetPart)
    if pre1 then stopFlight() return false, true end
    if not ok1 or not AutoFarm or not isRunning then stopFlight() return false, false end

    -- Step B: Glide horizontally across open air above walls
    local ok2, pre2 = flyTo(highDest, currentTargetPriority, targetPart)
    if pre2 then stopFlight() return false, true end
    if not ok2 or not AutoFarm or not isRunning then stopFlight() return false, false end

    -- Step C: Descend vertically into target room
    local ok3, pre3 = flyTo(destFloor + Vector3.new(0, 2.5, 0), currentTargetPriority, targetPart)
    if pre3 then stopFlight() return false, true end
    if not ok3 or not AutoFarm or not isRunning then stopFlight() return false, false end

    return true, false
end

-- Loot item: multi-candidate pathfinding, on-the-fly collection, camera lock, and clean ground navigation
local function lootItem(targetPart)
    if not targetPart or not targetPart.Parent then return false, false end
    if not AutoFarm or not isRunning then return false, false end

    local itemName = targetPart:GetAttribute("Item") or "Weapon"
    local currentTargetPriority = getEffectiveItemPriority(itemName)

    statusDot.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    statusText.Text = "Approaching " .. itemName .. "..."

    local char, hrp = getChar()
    if not char or not hrp then return false, false end

    -- 1. Ensure character starts from ground level
    if hrp.Position.Y > 29.5 then
        local floorBelow = findFloorBelow(hrp.Position)
        if floorBelow and (hrp.Position.Y - floorBelow.Y) > 2.0 then
            flyTo(floorBelow + Vector3.new(0, 2.5, 0), currentTargetPriority, targetPart)
            stopFlight()
        end
    end

    -- 2. Current player ground position for NavMesh start
    local startNavPt = findFloorBelow(hrp.Position) + Vector3.new(0, 0.5, 0)

    -- 3. Find walkable floor candidates around item (handles floor, table, crate, container)
    local candidates = findWalkableFloorCandidates(targetPart, hrp.Position)
    local chosenFloor = candidates[1].pos
    local pathWaypoints = nil

    -- 4. Multi-candidate, multi-radius NavMesh pathfinding: guaranteed to find the open side
    local testRadii = {1.0, 0.5, 0.2}
    for _, cand in ipairs(candidates) do
        local targetNavPt = cand.pos + Vector3.new(0, 0.5, 0)
        for _, radius in ipairs(testRadii) do
            local path = PathfindingService:CreatePath({
                AgentRadius = radius,
                AgentHeight = 4.5,
                AgentCanJump = true,
                AgentMaxSlope = 60,
                WaypointSpacing = 2.5
            })

            local computeOk = pcall(function()
                path:ComputeAsync(startNavPt, targetNavPt)
            end)

            if computeOk and path.Status == Enum.PathStatus.Success then
                local wps = path:GetWaypoints()
                if wps and #wps >= 2 then
                    pathWaypoints = wps
                    chosenFloor = cand.pos
                    break
                end
            end
        end
        if pathWaypoints then break end
    end

    -- 5. Execute path with on-the-fly collection
    if pathWaypoints then
        local okPath, collectedOnFly, wasPreempted = followPathWithInterception(pathWaypoints, targetPart, itemName, currentTargetPriority)
        if wasPreempted then
            stopFlight()
            return false, true
        end
        if collectedOnFly or isItemAlreadyCollected(targetPart, itemName) then
            statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            statusText.Text = "Collected " .. itemName
            subStatusText.Text = "Collected: " .. itemName .. " ✓"
            noSafePathCount = 0
            stopFlight()
            return true, false
        end
        if not okPath or not AutoFarm or not isRunning then
            stopFlight()
            return false, false
        end
    else
        -- No ground path found around walls. Try safe overhead air flight above partition walls:
        local okOverhead, wasPreempted = tryOverheadFly(chosenFloor, currentTargetPriority, targetPart)
        if wasPreempted then
            stopFlight()
            return false, true
        end
        if not okOverhead then
            -- Item in hermetically sealed room: skip cleanly without touching walls!
            noSafePathCount = noSafePathCount + 1
            statusText.Text = "No safe path (" .. noSafePathCount .. "/3) -> skipping"
            stopFlight()

            local isHoldingProtected, _ = isHoldingAnyProtectedItem()
            if not isHoldingProtected and noSafePathCount >= 3 then
                statusDot.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
                statusText.Text = "3x No Safe Path -> Resetting..."
                subStatusText.Text = "Resetting character (no protected items)..."
                noSafePathCount = 0
                justRespawned = true
                local c, h = getChar()
                local hm = c and c:FindFirstChildOfClass("Humanoid")
                if hm then
                    pcall(function() hm.Health = 0 end)
                end
                task.wait(2.0)
            end
            return false, false
        end
    end

    -- 6. Arrived at floor spot beside item (within 4-8 studs)! Perform final pickup with camera alignment
    if isItemAlreadyCollected(targetPart, itemName) then
        statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        statusText.Text = "Collected " .. itemName
        subStatusText.Text = "Collected: " .. itemName .. " ✓"
        noSafePathCount = 0
        stopFlight()
        return true, false
    end

    statusText.Text = "Picking up " .. itemName .. "..."
    char, hrp = getChar()
    local cam = workspace.CurrentCamera

    if hrp and targetPart and targetPart.Parent then
        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z))
    end
    if cam and hrp and targetPart and targetPart.Parent then
        cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 2.0, 0), targetPart.Position)
    end

    for attempt = 1, 6 do
        if not AutoFarm or not isRunning then break end
        if isItemAlreadyCollected(targetPart, itemName) then break end

        -- Also check if a much higher priority FILTERED item appeared right now
        local best = getHighestAvailableSpawn()
        if best and (protectedFilter[best.name] == true) and best.part ~= targetPart and best.priority > currentTargetPriority then
            statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            statusText.Text = "Switching to: " .. best.name .. "!"
            subStatusText.Text = "Higher priority spawn (" .. best.name .. ")"
            stopFlight()
            return false, true
        end

        if GameNet and GameNet.packets and GameNet.packets.PickUpTool and targetPart and targetPart.Parent then
            pcall(function()
                GameNet.packets.PickUpTool.send(targetPart)
            end)
        end
        task.wait(0.06)
    end

    -- 7. If still not collected and item is on high container roof (> 3 studs above chosen floor):
    -- Ascend vertically beside container to clear lip, grab, and descend back down
    if not isItemAlreadyCollected(targetPart, itemName) and targetPart and targetPart.Parent and targetPart:IsDescendantOf(workspace) and (targetPart.Position.Y - chosenFloor.Y) > 3.0 then
        local targetHigh = Vector3.new(chosenFloor.X, targetPart.Position.Y + 1.5, chosenFloor.Z)
        local okFly, preFly = flyTo(targetHigh, currentTargetPriority, targetPart)
        if preFly then stopFlight() return false, true end

        if cam and hrp and targetPart and targetPart.Parent then
            cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 2.0, 0), targetPart.Position)
        end

        for attempt = 1, 6 do
            if not AutoFarm or not isRunning then break end
            if isItemAlreadyCollected(targetPart, itemName) then break end

            local best = getHighestAvailableSpawn()
            if best and (protectedFilter[best.name] == true) and best.part ~= targetPart and best.priority > currentTargetPriority then
                statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                statusText.Text = "Switching to: " .. best.name .. "!"
                subStatusText.Text = "Higher priority spawn (" .. best.name .. ")"
                stopFlight()
                return false, true
            end

            if GameNet and GameNet.packets and GameNet.packets.PickUpTool and targetPart and targetPart.Parent then
                pcall(function()
                    GameNet.packets.PickUpTool.send(targetPart)
                end)
            end
            task.wait(0.06)
        end

        -- Descend back to ground floor
        flyTo(chosenFloor + Vector3.new(0, 2.5, 0), currentTargetPriority, targetPart)
        stopFlight()
    else
        stopFlight()
    end

    local isPicked = isItemAlreadyCollected(targetPart, itemName)
    if isPicked then
        noSafePathCount = 0
        statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        statusText.Text = "Collected " .. itemName
        subStatusText.Text = "Collected: " .. itemName .. " ✓"
        return true, false
    end

    -- If we arrived and attempted 6 times, but item was still not picked, add cooldown so we don't freeze on it
    if targetPart then
        failedPickupCache[targetPart] = tick()
    end
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
    statusText.Text = "Pickup timeout (" .. itemName .. ")"
    subStatusText.Text = "Skipping unpickable spawn"
    return false, false
end

-- Helper: Safe navigation to a target floor coordinate
local function safeNavigateTo(destFloorPos, currentTargetPriority, currentTargetPart)
    local char, hrp = getChar()
    if not char or not hrp then return false, false end
    if (hrp.Position - destFloorPos).Magnitude < 10 then return true, false end

    if hrp.Position.Y > 29.5 then
        local floorBelow = findFloorBelow(hrp.Position)
        if floorBelow and (hrp.Position.Y - floorBelow.Y) > 2.0 then
            flyTo(floorBelow + Vector3.new(0, 2.5, 0), currentTargetPriority, currentTargetPart)
            stopFlight()
        end
    end

    local startNavPt = findFloorBelow(hrp.Position) + Vector3.new(0, 0.5, 0)
    local targetNavPt = destFloorPos + Vector3.new(0, 0.5, 0)
    local pathWaypoints = nil

    local testRadii = {1.0, 0.5, 0.2}
    for _, radius in ipairs(testRadii) do
        local path = PathfindingService:CreatePath({
            AgentRadius = radius,
            AgentHeight = 4.5,
            AgentCanJump = true,
            AgentMaxSlope = 60,
            WaypointSpacing = 2.5
        })
        local computeOk = pcall(function()
            path:ComputeAsync(startNavPt, targetNavPt)
        end)
        if computeOk and path.Status == Enum.PathStatus.Success then
            local wps = path:GetWaypoints()
            if wps and #wps >= 2 then
                pathWaypoints = wps
                break
            end
        end
    end

    -- If direct target failed, scan 8 radial floor candidates around destFloorPos
    if not pathWaypoints then
        local angles = {0, 45, 90, 135, 180, 225, 270, 315}
        local dists = {4.0, 8.0}
        for _, d in ipairs(dists) do
            for _, deg in ipairs(angles) do
                local rad = math.rad(deg)
                local offset = Vector3.new(math.cos(rad) * d, 0, math.sin(rad) * d)
                local candidatePos = findFloorBelow(destFloorPos + offset)
                if candidatePos then
                    for _, radius in ipairs(testRadii) do
                        local path = PathfindingService:CreatePath({
                            AgentRadius = radius,
                            AgentHeight = 4.5,
                            AgentCanJump = true,
                            AgentMaxSlope = 60,
                            WaypointSpacing = 2.5
                        })
                        local computeOk = pcall(function()
                            path:ComputeAsync(startNavPt, candidatePos + Vector3.new(0, 0.5, 0))
                        end)
                        if computeOk and path.Status == Enum.PathStatus.Success then
                            local wps = path:GetWaypoints()
                            if wps and #wps >= 2 then
                                pathWaypoints = wps
                                break
                            end
                        end
                    end
                end
                if pathWaypoints then break end
            end
            if pathWaypoints then break end
        end
    end

    if pathWaypoints then
        local okPath, _, wasPreempted = followPathWithInterception(pathWaypoints, currentTargetPart, nil, currentTargetPriority)
        stopFlight()
        return okPath, wasPreempted
    else
        local okOverhead, wasPreempted = tryOverheadFly(destFloorPos, currentTargetPriority, currentTargetPart)
        stopFlight()
        return okOverhead, wasPreempted
    end
end

-- Helper: Safely return to player's spawn point using ground Pathfinding & obstacle checks
local function safeReturnToSpawn()
    if isPlayerInfected() then return false end
    if not playerSpawnPos then return false end
    local destFloor = findFloorBelow(playerSpawnPos) or playerSpawnPos
    return safeNavigateTo(destFloor)
end

-- Helper: Group all static spawn parts into clusters (Hotspots)
local cachedClusters = nil
local function getSpawnClusters()
    if cachedClusters and #cachedClusters > 0 then
        return cachedClusters
    end

    local toolSpawns = workspace:FindFirstChild("ToolSpawnPoints")
    if not toolSpawns then return {} end

    local spawnParts = {}
    for _, desc in ipairs(toolSpawns:GetDescendants()) do
        if desc:IsA("BasePart") then
            table.insert(spawnParts, desc)
        end
    end

    local clusters = {}
    local RADIUS = 65

    for _, part in ipairs(spawnParts) do
        local pt = part.Position
        local matched = false
        for _, cl in ipairs(clusters) do
            local center = cl.sum / cl.count
            if (pt - center).Magnitude <= RADIUS then
                cl.sum = cl.sum + pt
                cl.count = cl.count + 1
                table.insert(cl.parts, part)
                matched = true
                break
            end
        end
        if not matched then
            table.insert(clusters, {
                sum = pt,
                count = 1,
                parts = {part}
            })
        end
    end

    table.sort(clusters, function(a, b) return a.count > b.count end)

    for _, cl in ipairs(clusters) do
        cl.center = cl.sum / cl.count
        local candidates = findWalkableFloorCandidates(cl.parts[1])
        cl.floorPos = candidates and candidates[1] and candidates[1].pos or findFloorBelow(cl.center)
    end

    cachedClusters = clusters
    return clusters
end

-- Helper: Move character to a spawn cluster's floor
local function moveToCluster(cl)
    if not cl then return false end
    local char, hrp = getChar()
    if not char or not hrp then return false end

    local targetFloor = cl.floorPos or findFloorBelow(cl.center)
    if not targetFloor then return false end

    if (hrp.Position - targetFloor).Magnitude < 14 then
        return true
    end

    statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    statusText.Text = "Moving to Cluster (" .. cl.count .. " spawns)"
    subStatusText.Text = "Cluster Hotspot: " .. math.round((hrp.Position - targetFloor).Magnitude) .. " studs"

    return safeNavigateTo(targetFloor)
end

-- Main Auto Farm loop
local farmThread = nil
local justRespawned = true

local function runFarmLoop()
    while AutoFarm and isRunning do
        local char, hrp = getChar()
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hrp or not hum or hum.Health <= 0 then
            farm_target = nil
            stopFlight()
            statusDot.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
            statusText.Text = "Waiting for respawn..."
            justRespawned = true
            task.wait(0.5)
            continue
        end

        -- Post-Reset/Respawn behavior: if Spawn Clusters mode, immediately run to main cluster!
        if justRespawned and selectedFarmMode == "Spawn Clusters" then
            justRespawned = false
            local clusters = getSpawnClusters()
            if #clusters > 0 then
                statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                statusText.Text = "Respawned -> Running to Cluster"
                moveToCluster(clusters[1])
            end
        end
        justRespawned = false

        -- Ensure starting on ground floor if standing on container
        if hrp.Position.Y > 29.5 then
            local floorBelow = findFloorBelow(hrp.Position)
            if floorBelow and (hrp.Position.Y - floorBelow.Y) > 2.0 then
                flyTo(floorBelow + Vector3.new(0, 2.5, 0))
                stopFlight()
            end
        end

        local playerIsInfected = isPlayerInfected()

        -- Back on Spawn: if player holds ANY item from the protected filter, safely return to spawn!
        -- EXCEPTION: If player is Infected, NEVER return to spawn!
        local isHoldingProtected, protectedName = isHoldingAnyProtectedItem()
        if BackOnSpawn and not playerIsInfected and isHoldingProtected and playerSpawnPos then
            local destFloor = findFloorBelow(playerSpawnPos) or playerSpawnPos
            local distToSpawn = (hrp.Position - destFloor).Magnitude
            if distToSpawn > 10 then
                farm_target = nil
                statusDot.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                statusText.Text = "Back on Spawn (" .. tostring(protectedName) .. ")"
                subStatusText.Text = "Returning to spawn: " .. math.round(distToSpawn) .. " studs"

                safeReturnToSpawn()
                task.wait(0.3)
                continue
            else
                stopFlight()
                statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                statusText.Text = "Safe at Spawn (" .. tostring(protectedName) .. ")"
                subStatusText.Text = "Holding " .. tostring(protectedName) .. " safely at spawn"
                task.wait(1.0)
                continue
            end
        end

        local taggedParts = CollectionService:GetTagged("ToolPickUp")
        local candidateSpawns = {}
        local totalValidSpawns = 0

        for _, part in ipairs(taggedParts) do
            if part and part.Parent and part:IsA("BasePart") then
                local itemName = part:GetAttribute("Item")
                if itemName then
                    local itemIsInfected = isInfectedItem(itemName)
                    local canPickUp = not itemIsInfected or playerIsInfected

                    if canPickUp then
                        totalValidSpawns = totalValidSpawns + 1
                        local isCoolingDown = failedPickupCache[part] and (tick() - failedPickupCache[part]) < 5
                        if not isCoolingDown and not hasItemInInventory(itemName) then
                            if isItemWanted(itemName) then
                                local priority = getEffectiveItemPriority(itemName)
                                table.insert(candidateSpawns, {
                                    part = part,
                                    name = itemName,
                                    priority = priority,
                                    dist = (hrp.Position - part.Position).Magnitude
                                })
                            end
                        end
                    end
                end
            end
        end

        if not AutoFarm or not isRunning then break end

        if #candidateSpawns > 0 then
            table.sort(candidateSpawns, function(a, b)
                if a.priority ~= b.priority then
                    return a.priority > b.priority
                end
                return a.dist < b.dist
            end)

            local picked = false
            for _, cand in ipairs(candidateSpawns) do
                if not AutoFarm or not isRunning then break end
                farm_target = cand.part
                local wasPicked, wasPreempted = lootItem(cand.part)
                if wasPicked then
                    picked = true
                    task.wait(0.1)
                    break
                elseif wasPreempted then
                    farm_target = nil
                    picked = true
                    task.wait(0.05)
                    break
                end
                task.wait(0.05)
            end

            if not picked then
                task.wait(0.3)
            end
        else
            stopFlight()

            local clusters = getSpawnClusters()
            local mainCluster = #clusters > 0 and clusters[1] or nil

            if totalValidSpawns == 0 then
                statusDot.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
                if selectedFarmMode == "Spawn Clusters" and mainCluster then
                    statusText.Text = "Waiting at Cluster..."
                    subStatusText.Text = "Cluster 1 (" .. mainCluster.count .. " spawns) | Spawns: 0"
                    moveToCluster(mainCluster)
                else
                    statusText.Text = "Waiting for spawns..."
                    subStatusText.Text = playerIsInfected and "Infected mode active" or "Human mode active"
                end
                task.wait(1.0)
            else
                local isHoldingProtected, protectedName = isHoldingAnyProtectedItem()
                if isHoldingProtected or playerIsInfected then
                    statusDot.BackgroundColor3 = Color3.fromRGB(255, 214, 72)
                    if playerIsInfected then
                        statusText.Text = "Infected: Active"
                        subStatusText.Text = "Spawns: " .. totalValidSpawns .. " (all duplicate/unwanted)"
                    else
                        statusText.Text = "Protected: Holding " .. tostring(protectedName)
                        subStatusText.Text = "Spawns: " .. totalValidSpawns .. " (all duplicate/unwanted)"
                    end
                    if selectedFarmMode == "Spawn Clusters" and mainCluster then
                        moveToCluster(mainCluster)
                    end
                    task.wait(1.5)
                else
                    statusDot.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
                    statusText.Text = "All Duplicates -> Resetting..."
                    subStatusText.Text = "Resetting character..."
                    justRespawned = true
                    pcall(function()
                        hum.Health = 0
                    end)
                    task.wait(2.0)
                end
            end
        end
    end
    farmThread = nil
    stopFlight()
end

-- 1. Create iOS Toggle: Auto Farm
local farmToggleRow = Instance.new("Frame")
farmToggleRow.Name = "Row_AutoFarm"
farmToggleRow.Size = UDim2.new(1, 0, 0, 28)
farmToggleRow.BackgroundTransparency = 1
farmToggleRow.LayoutOrder = 1
farmToggleRow.Parent = scrollContainer

local farmPlate = Instance.new("Frame")
farmPlate.Size = UDim2.fromOffset(24, 24)
farmPlate.Position = UDim2.new(0, 0, 0.5, -12)
farmPlate.BackgroundColor3 = AutoFarm and Color3.fromRGB(34, 34, 38) or Color3.fromRGB(22, 22, 22)
farmPlate.BorderSizePixel = 0
farmPlate.Parent = farmToggleRow

local farmPlateCorner = Instance.new("UICorner")
farmPlateCorner.CornerRadius = UDim.new(0, 7)
farmPlateCorner.Parent = farmPlate

local farmIcon = Instance.new("ImageLabel")
farmIcon.Size = UDim2.fromOffset(14, 14)
farmIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
farmIcon.BackgroundTransparency = 1
farmIcon.Image = "rbxassetid://130551565616516" -- zap icon
farmIcon.ImageColor3 = AutoFarm and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
farmIcon.Parent = farmPlate

local farmLabel = Instance.new("TextLabel")
farmLabel.Text = "Auto Farm (Loot)"
farmLabel.Font = FontMedium
farmLabel.TextSize = 13
farmLabel.TextColor3 = Color3.fromRGB(245, 245, 247)
farmLabel.TextXAlignment = Enum.TextXAlignment.Left
farmLabel.BackgroundTransparency = 1
farmLabel.Position = UDim2.fromOffset(32, 0)
farmLabel.Size = UDim2.new(1, -80, 1, 0)
farmLabel.Parent = farmToggleRow

local farmSwitchTrack = Instance.new("Frame")
farmSwitchTrack.Size = UDim2.fromOffset(42, 24)
farmSwitchTrack.Position = UDim2.new(1, -42, 0.5, -12)
farmSwitchTrack.BackgroundColor3 = AutoFarm and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(54, 54, 58)
farmSwitchTrack.BorderSizePixel = 0
farmSwitchTrack.Parent = farmToggleRow

local farmSwitchCorner = Instance.new("UICorner")
farmSwitchCorner.CornerRadius = UDim.new(1, 0)
farmSwitchCorner.Parent = farmSwitchTrack

local farmSwitchKnob = Instance.new("Frame")
farmSwitchKnob.Size = UDim2.fromOffset(20, 20)
farmSwitchKnob.Position = AutoFarm and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
farmSwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
farmSwitchKnob.BorderSizePixel = 0
farmSwitchKnob.Parent = farmSwitchTrack

local farmKnobCorner = Instance.new("UICorner")
farmKnobCorner.CornerRadius = UDim.new(1, 0)
farmKnobCorner.Parent = farmSwitchKnob

local farmSwitchBtn = Instance.new("TextButton")
farmSwitchBtn.Size = UDim2.fromScale(1, 1)
farmSwitchBtn.BackgroundTransparency = 1
farmSwitchBtn.Text = ""
farmSwitchBtn.Parent = farmSwitchTrack

local function setFarmState(state)
    AutoFarm = state
    saveConfig()
    local targetColor = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(54, 54, 58)
    local targetPos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    local targetPlate = state and Color3.fromRGB(34, 34, 38) or Color3.fromRGB(22, 22, 22)
    local targetIcon = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

    TweenService:Create(farmSwitchTrack, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
    TweenService:Create(farmSwitchKnob, TweenInfo.new(0.2), { Position = targetPos }):Play()
    TweenService:Create(farmPlate, TweenInfo.new(0.2), { BackgroundColor3 = targetPlate }):Play()
    TweenService:Create(farmIcon, TweenInfo.new(0.2), { ImageColor3 = targetIcon }):Play()

    if not state then
        farm_target = nil
        stopFlight()
        restoreAllObstacles()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            end)
        end
        statusDot.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
        statusText.Text = "Idle"
    else
        statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        statusText.Text = "Scanning loot..."
        if not farmThread or coroutine.status(farmThread) == "dead" then
            farmThread = task.spawn(runFarmLoop)
        end
    end
end

trackConn(farmSwitchBtn.MouseButton1Click:Connect(function()
    setFarmState(not AutoFarm)
end))

if AutoFarm then
    setFarmState(true)
end

-- AntiCheat Rollback Handler: pauses function for 3 seconds and turns it back on
local isRollbackActive = false
handleRubberband = function()
    if isRollbackActive then return end
    isRollbackActive = true

    stopFlight()

    -- Temporarily reflect OFF state in toggle visual
    TweenService:Create(farmSwitchTrack, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(54, 54, 58) }):Play()
    TweenService:Create(farmSwitchKnob, TweenInfo.new(0.2), { Position = UDim2.new(0, 2, 0.5, -10) }):Play()
    TweenService:Create(farmPlate, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(22, 22, 22) }):Play()
    TweenService:Create(farmIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(180, 180, 180) }):Play()

    statusDot.BackgroundColor3 = Color3.fromRGB(255, 69, 58) -- Red
    statusText.Text = "Rollback! AutoFarm OFF (3s)"

    for sec = 3, 1, -1 do
        subStatusText.Text = "AntiCheat cooldown: re-enabling in " .. sec .. "s..."
        task.wait(1.0)
        if not isRunning or not AutoFarm then
            isRollbackActive = false
            return
        end
    end

    if isRunning and AutoFarm then
        TweenService:Create(farmSwitchTrack, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(52, 199, 89) }):Play()
        TweenService:Create(farmSwitchKnob, TweenInfo.new(0.2), { Position = UDim2.new(1, -22, 0.5, -10) }):Play()
        TweenService:Create(farmPlate, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(34, 34, 38) }):Play()
        TweenService:Create(farmIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()

        statusDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        statusText.Text = "AutoFarm ON (Stabilized)"
        subStatusText.Text = "Physics settled. Resuming farm ✓"
        task.wait(0.2)
    end

    isRollbackActive = false
end

-- 2. Create iOS Toggle: Back on Spawn (Filter Items)
local backSpawnRow = Instance.new("Frame")
backSpawnRow.Name = "Row_BackOnSpawn"
backSpawnRow.Size = UDim2.new(1, 0, 0, 28)
backSpawnRow.BackgroundTransparency = 1
backSpawnRow.LayoutOrder = 2
backSpawnRow.Parent = scrollContainer

local backPlate = Instance.new("Frame")
backPlate.Size = UDim2.fromOffset(24, 24)
backPlate.Position = UDim2.new(0, 0, 0.5, -12)
backPlate.BackgroundColor3 = BackOnSpawn and Color3.fromRGB(34, 34, 38) or Color3.fromRGB(22, 22, 22)
backPlate.BorderSizePixel = 0
backPlate.Parent = backSpawnRow

local backPlateCorner = Instance.new("UICorner")
backPlateCorner.CornerRadius = UDim.new(0, 7)
backPlateCorner.Parent = backPlate

local backIcon = Instance.new("ImageLabel")
backIcon.Size = UDim2.fromOffset(14, 14)
backIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
backIcon.BackgroundTransparency = 1
backIcon.Image = "rbxassetid://122180020814574" -- shield / return icon
backIcon.ImageColor3 = BackOnSpawn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
backIcon.Parent = backPlate

local backLabel = Instance.new("TextLabel")
backLabel.Text = "Back on Spawn (Filter)"
backLabel.Font = FontMedium
backLabel.TextSize = 13
backLabel.TextColor3 = Color3.fromRGB(245, 245, 247)
backLabel.TextXAlignment = Enum.TextXAlignment.Left
backLabel.BackgroundTransparency = 1
backLabel.Position = UDim2.fromOffset(32, 0)
backLabel.Size = UDim2.new(1, -80, 1, 0)
backLabel.Parent = backSpawnRow

local backSwitchTrack = Instance.new("Frame")
backSwitchTrack.Size = UDim2.fromOffset(42, 24)
backSwitchTrack.Position = UDim2.new(1, -42, 0.5, -12)
backSwitchTrack.BackgroundColor3 = BackOnSpawn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(54, 54, 58)
backSwitchTrack.BorderSizePixel = 0
backSwitchTrack.Parent = backSpawnRow

local backSwitchCorner = Instance.new("UICorner")
backSwitchCorner.CornerRadius = UDim.new(1, 0)
backSwitchCorner.Parent = backSwitchTrack

local backSwitchKnob = Instance.new("Frame")
backSwitchKnob.Size = UDim2.fromOffset(20, 20)
backSwitchKnob.Position = BackOnSpawn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
backSwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
backSwitchKnob.BorderSizePixel = 0
backSwitchKnob.Parent = backSwitchTrack

local backKnobCorner = Instance.new("UICorner")
backKnobCorner.CornerRadius = UDim.new(1, 0)
backKnobCorner.Parent = backSwitchKnob

local backSwitchBtn = Instance.new("TextButton")
backSwitchBtn.Size = UDim2.fromScale(1, 1)
backSwitchBtn.BackgroundTransparency = 1
backSwitchBtn.Text = ""
backSwitchBtn.Parent = backSwitchTrack

local function setBackOnSpawnState(state)
    BackOnSpawn = state
    saveConfig()
    local targetColor = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(54, 54, 58)
    local targetPos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    local targetPlate = state and Color3.fromRGB(34, 34, 38) or Color3.fromRGB(22, 22, 22)
    local targetIcon = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

    TweenService:Create(backSwitchTrack, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
    TweenService:Create(backSwitchKnob, TweenInfo.new(0.2), { Position = targetPos }):Play()
    TweenService:Create(backPlate, TweenInfo.new(0.2), { BackgroundColor3 = targetPlate }):Play()
    TweenService:Create(backIcon, TweenInfo.new(0.2), { ImageColor3 = targetIcon }):Play()

    subStatusText.Text = "Back on Spawn: " .. (state and "ENABLED ✓" or "DISABLED")
end

trackConn(backSwitchBtn.MouseButton1Click:Connect(function()
    setBackOnSpawnState(not BackOnSpawn)
end))

-- Forward declarations of menu toggle functions
local toggleModeMenu
local toggleTargetMenu
local toggleFilterMenu

-- 3. iOS ComboBox: Farm Mode Selector ("All Map" vs "Spawn Clusters")
local modeHeaderRow = Instance.new("Frame")
modeHeaderRow.Name = "Row_ModeCombo"
modeHeaderRow.Size = UDim2.new(1, 0, 0, 24)
modeHeaderRow.BackgroundTransparency = 1
modeHeaderRow.LayoutOrder = 3
modeHeaderRow.Parent = scrollContainer

local modePlate = Instance.new("Frame")
modePlate.Size = UDim2.fromOffset(24, 24)
modePlate.Position = UDim2.new(0, 0, 0.5, -12)
modePlate.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
modePlate.BorderSizePixel = 0
modePlate.Parent = modeHeaderRow

local modePlateCorner = Instance.new("UICorner")
modePlateCorner.CornerRadius = UDim.new(0, 7)
modePlateCorner.Parent = modePlate

local modeIcon = Instance.new("ImageLabel")
modeIcon.Size = UDim2.fromOffset(14, 14)
modeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
modeIcon.BackgroundTransparency = 1
modeIcon.Image = "rbxassetid://108157549473765"
modeIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
modeIcon.Parent = modePlate

local modeLabel = Instance.new("TextLabel")
modeLabel.Text = "Farm Mode"
modeLabel.Font = FontMedium
modeLabel.TextSize = 13
modeLabel.TextColor3 = Color3.fromRGB(245, 245, 247)
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.BackgroundTransparency = 1
modeLabel.Position = UDim2.fromOffset(32, 0)
modeLabel.Size = UDim2.new(1, -40, 1, 0)
modeLabel.Parent = modeHeaderRow

-- Mode Dropdown Selector Button (iOS Pill style)
local modeSelectorBtn = Instance.new("TextButton")
modeSelectorBtn.Name = "ModeSelector"
modeSelectorBtn.Size = UDim2.new(1, 0, 0, 32)
modeSelectorBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
modeSelectorBtn.BorderSizePixel = 0
modeSelectorBtn.AutoButtonColor = false
modeSelectorBtn.Text = ""
modeSelectorBtn.LayoutOrder = 4
modeSelectorBtn.Parent = scrollContainer

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 8)
modeCorner.Parent = modeSelectorBtn

local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(48, 48, 54)
modeStroke.Thickness = 1
modeStroke.Parent = modeSelectorBtn

local modeBtnText = Instance.new("TextLabel")
modeBtnText.Name = "CurrentText"
modeBtnText.Text = selectedFarmMode
modeBtnText.Font = FontMedium
modeBtnText.TextSize = 12
modeBtnText.TextColor3 = Color3.fromRGB(245, 245, 247)
modeBtnText.TextXAlignment = Enum.TextXAlignment.Left
modeBtnText.BackgroundTransparency = 1
modeBtnText.Position = UDim2.fromOffset(12, 0)
modeBtnText.Size = UDim2.new(1, -36, 1, 0)
modeBtnText.Parent = modeSelectorBtn

local modeArrow = Instance.new("TextLabel")
modeArrow.Text = "▼"
modeArrow.Font = FontBold
modeArrow.TextSize = 10
modeArrow.TextColor3 = Color3.fromRGB(142, 142, 147)
modeArrow.BackgroundTransparency = 1
modeArrow.Position = UDim2.new(1, -24, 0, 0)
modeArrow.Size = UDim2.fromOffset(16, 32)
modeArrow.Parent = modeSelectorBtn

-- Mode Dropdown List Popover
local modeMenu = Instance.new("ScrollingFrame")
modeMenu.Name = "ModeMenu"
modeMenu.Size = UDim2.new(1, 0, 0, 0)
modeMenu.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
modeMenu.BorderSizePixel = 0
modeMenu.ScrollBarThickness = 3
modeMenu.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
modeMenu.ClipsDescendants = true
modeMenu.Visible = false
modeMenu.LayoutOrder = 5
modeMenu.Parent = scrollContainer

local modeMenuCorner = Instance.new("UICorner")
modeMenuCorner.CornerRadius = UDim.new(0, 8)
modeMenuCorner.Parent = modeMenu

local modeMenuStroke = Instance.new("UIStroke")
modeMenuStroke.Color = Color3.fromRGB(60, 60, 68)
modeMenuStroke.Thickness = 1
modeMenuStroke.Parent = modeMenu

local modeMenuLayout = Instance.new("UIListLayout")
modeMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
modeMenuLayout.Padding = UDim.new(0, 2)
modeMenuLayout.Parent = modeMenu

local modeMenuPadding = Instance.new("UIPadding")
modeMenuPadding.PaddingLeft = UDim.new(0, 4)
modeMenuPadding.PaddingRight = UDim.new(0, 4)
modeMenuPadding.PaddingTop = UDim.new(0, 4)
modeMenuPadding.PaddingBottom = UDim.new(0, 4)
modeMenuPadding.Parent = modeMenu

local isModeOpen = false

closeModeMenu = function()
    if not isModeOpen then return end
    isModeOpen = false
    modeArrow.Text = "▼"
    local tw = TweenService:Create(modeMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(1, 0, 0, 0)
    })
    tw:Play()
    tw.Completed:Once(function()
        if not isModeOpen then modeMenu.Visible = false end
    end)
end

toggleModeMenu = function()
    if isModeOpen then
        closeModeMenu()
    else
        if closeTargetMenu then closeTargetMenu() end
        if closeFilterMenu then closeFilterMenu() end
        isModeOpen = true
        modeMenu.Visible = true
        modeArrow.Text = "▲"
        TweenService:Create(modeMenu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, #FARM_MODES * 28 + 8)
        }):Play()
    end
end

trackConn(modeSelectorBtn.MouseButton1Click:Connect(toggleModeMenu))

-- Populate Mode Dropdown items
modeMenu.CanvasSize = UDim2.new(0, 0, 0, #FARM_MODES * 28 + 8)
for _, mode in ipairs(FARM_MODES) do
    local isCur = (mode == selectedFarmMode)

    local mBtn = Instance.new("TextButton")
    mBtn.Name = "Mode_" .. mode
    mBtn.Size = UDim2.new(1, 0, 0, 26)
    mBtn.BackgroundColor3 = isCur and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)
    mBtn.BorderSizePixel = 0
    mBtn.AutoButtonColor = false
    mBtn.Text = ""
    mBtn.Parent = modeMenu

    local mBtnCorner = Instance.new("UICorner")
    mBtnCorner.CornerRadius = UDim.new(0, 6)
    mBtnCorner.Parent = mBtn

    local mLabel = Instance.new("TextLabel")
    mLabel.Name = "ModeNameLabel"
    mLabel.Text = mode
    mLabel.Font = FontMedium
    mLabel.TextSize = 11
    mLabel.TextColor3 = isCur and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
    mLabel.TextXAlignment = Enum.TextXAlignment.Left
    mLabel.BackgroundTransparency = 1
    mLabel.Position = UDim2.fromOffset(10, 0)
    mLabel.Size = UDim2.new(1, -34, 1, 0)
    mLabel.Parent = mBtn

    local mCheckmark = Instance.new("TextLabel")
    mCheckmark.Name = "CheckmarkLabel"
    mCheckmark.Text = isCur and "✓" or ""
    mCheckmark.Font = FontBold
    mCheckmark.TextSize = 12
    mCheckmark.TextColor3 = Color3.fromRGB(52, 199, 89)
    mCheckmark.BackgroundTransparency = 1
    mCheckmark.Position = UDim2.new(1, -22, 0, 0)
    mCheckmark.Size = UDim2.fromOffset(16, 26)
    mCheckmark.Parent = mBtn

    trackConn(mBtn.MouseButton1Click:Connect(function()
        selectedFarmMode = mode
        modeBtnText.Text = mode
        saveConfig()
        toggleModeMenu()

        for _, btn in ipairs(modeMenu:GetChildren()) do
            if btn:IsA("TextButton") then
                local bName = btn.Name:gsub("Mode_", "")
                local cur = (bName == selectedFarmMode)
                btn.BackgroundColor3 = cur and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)

                local lbl = btn:FindFirstChild("ModeNameLabel")
                if lbl then
                    lbl.TextColor3 = cur and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
                end

                local chk = btn:FindFirstChild("CheckmarkLabel")
                if chk then
                    chk.Text = cur and "✓" or ""
                end
            end
        end

        subStatusText.Text = "Mode: " .. selectedFarmMode .. " | Target: " .. getTargetSummary()
    end))
end

-- 3. iOS ComboBox: Target Item Selector (Multi-Select with 'All Items' master toggle)
local comboHeaderRow = Instance.new("Frame")
comboHeaderRow.Name = "Row_TargetCombo"
comboHeaderRow.Size = UDim2.new(1, 0, 0, 24)
comboHeaderRow.BackgroundTransparency = 1
comboHeaderRow.LayoutOrder = 6
comboHeaderRow.Parent = scrollContainer

local comboPlate = Instance.new("Frame")
comboPlate.Size = UDim2.fromOffset(24, 24)
comboPlate.Position = UDim2.new(0, 0, 0.5, -12)
comboPlate.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
comboPlate.BorderSizePixel = 0
comboPlate.Parent = comboHeaderRow

local comboPlateCorner = Instance.new("UICorner")
comboPlateCorner.CornerRadius = UDim.new(0, 7)
comboPlateCorner.Parent = comboPlate

local comboIcon = Instance.new("ImageLabel")
comboIcon.Size = UDim2.fromOffset(14, 14)
comboIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
comboIcon.BackgroundTransparency = 1
comboIcon.Image = "rbxassetid://108157549473765" -- target icon
comboIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
comboIcon.Parent = comboPlate

local comboLabel = Instance.new("TextLabel")
comboLabel.Text = "Target Item"
comboLabel.Font = FontMedium
comboLabel.TextSize = 13
comboLabel.TextColor3 = Color3.fromRGB(245, 245, 247)
comboLabel.TextXAlignment = Enum.TextXAlignment.Left
comboLabel.BackgroundTransparency = 1
comboLabel.Position = UDim2.fromOffset(32, 0)
comboLabel.Size = UDim2.new(1, -40, 1, 0)
comboLabel.Parent = comboHeaderRow

-- Target Dropdown Selector Button (iOS Pill style)
local comboSelectorBtn = Instance.new("TextButton")
comboSelectorBtn.Name = "ComboSelector"
comboSelectorBtn.Size = UDim2.new(1, 0, 0, 32)
comboSelectorBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
comboSelectorBtn.BorderSizePixel = 0
comboSelectorBtn.AutoButtonColor = false
comboSelectorBtn.Text = ""
comboSelectorBtn.LayoutOrder = 7
comboSelectorBtn.Parent = scrollContainer

local comboCorner = Instance.new("UICorner")
comboCorner.CornerRadius = UDim.new(0, 8)
comboCorner.Parent = comboSelectorBtn

local comboStroke = Instance.new("UIStroke")
comboStroke.Color = Color3.fromRGB(48, 48, 54)
comboStroke.Thickness = 1
comboStroke.Parent = comboSelectorBtn

local comboBtnText = Instance.new("TextLabel")
comboBtnText.Name = "CurrentText"
comboBtnText.Text = getTargetSummary()
comboBtnText.Font = FontMedium
comboBtnText.TextSize = 12
comboBtnText.TextColor3 = Color3.fromRGB(245, 245, 247)
comboBtnText.TextXAlignment = Enum.TextXAlignment.Left
comboBtnText.BackgroundTransparency = 1
comboBtnText.Position = UDim2.fromOffset(12, 0)
comboBtnText.Size = UDim2.new(1, -36, 1, 0)
comboBtnText.Parent = comboSelectorBtn

local comboArrow = Instance.new("TextLabel")
comboArrow.Text = "▼"
comboArrow.Font = FontBold
comboArrow.TextSize = 10
comboArrow.TextColor3 = Color3.fromRGB(142, 142, 147)
comboArrow.BackgroundTransparency = 1
comboArrow.Position = UDim2.new(1, -24, 0, 0)
comboArrow.Size = UDim2.fromOffset(16, 32)
comboArrow.Parent = comboSelectorBtn

-- Target Dropdown List Popover (Multi-Select)
local comboMenu = Instance.new("ScrollingFrame")
comboMenu.Name = "ComboMenu"
comboMenu.Size = UDim2.new(1, 0, 0, 0)
comboMenu.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
comboMenu.BorderSizePixel = 0
comboMenu.ScrollBarThickness = 3
comboMenu.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
comboMenu.ClipsDescendants = true
comboMenu.Visible = false
comboMenu.LayoutOrder = 8
comboMenu.Parent = scrollContainer

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = comboMenu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(60, 60, 68)
menuStroke.Thickness = 1
menuStroke.Parent = comboMenu

local menuLayout = Instance.new("UIListLayout")
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 2)
menuLayout.Parent = comboMenu

local menuPadding = Instance.new("UIPadding")
menuPadding.PaddingLeft = UDim.new(0, 4)
menuPadding.PaddingRight = UDim.new(0, 4)
menuPadding.PaddingTop = UDim.new(0, 4)
menuPadding.PaddingBottom = UDim.new(0, 4)
menuPadding.Parent = comboMenu

local isTargetOpen = false

closeTargetMenu = function()
    if not isTargetOpen then return end
    isTargetOpen = false
    comboArrow.Text = "▼"
    local tw = TweenService:Create(comboMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(1, 0, 0, 0)
    })
    tw:Play()
    tw.Completed:Once(function()
        if not isTargetOpen then
            comboMenu.Visible = false
        end
    end)
end

toggleTargetMenu = function()
    if isTargetOpen then
        closeTargetMenu()
    else
        if closeModeMenu then closeModeMenu() end
        if closeFilterMenu then closeFilterMenu() end
        isTargetOpen = true
        comboMenu.Visible = true
        comboArrow.Text = "▲"
        TweenService:Create(comboMenu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 145)
        }):Play()
    end
end

trackConn(comboSelectorBtn.MouseButton1Click:Connect(toggleTargetMenu))

-- Populate Target Dropdown items (Multi-Select with 'All Items' master toggle)
comboMenu.CanvasSize = UDim2.new(0, 0, 0, #SELECTABLE_ITEMS * 28 + 8)

local function updateTargetMenuVisuals()
    local summary = getTargetSummary()
    comboBtnText.Text = summary
    subStatusText.Text = "Mode: " .. selectedFarmMode .. " | Target: " .. summary

    for _, btn in ipairs(comboMenu:GetChildren()) do
        if btn:IsA("TextButton") then
            local bName = btn.Name:gsub("Item_", "")
            local isChecked = (targetFilter[bName] == true)
            btn.BackgroundColor3 = isChecked and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)

            local lbl = btn:FindFirstChild("ItemNameLabel")
            if lbl then
                lbl.TextColor3 = isChecked and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
            end

            local chk = btn:FindFirstChild("CheckmarkLabel")
            if chk then
                chk.Text = isChecked and "✓" or ""
            end
        end
    end
end

for _, item in ipairs(SELECTABLE_ITEMS) do
    local isCur = (targetFilter[item] == true)

    local itemBtn = Instance.new("TextButton")
    itemBtn.Name = "Item_" .. item
    itemBtn.Size = UDim2.new(1, 0, 0, 26)
    itemBtn.BackgroundColor3 = isCur and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)
    itemBtn.BorderSizePixel = 0
    itemBtn.AutoButtonColor = false
    itemBtn.Text = ""
    itemBtn.Parent = comboMenu

    local itemBtnCorner = Instance.new("UICorner")
    itemBtnCorner.CornerRadius = UDim.new(0, 6)
    itemBtnCorner.Parent = itemBtn

    local itemLabel = Instance.new("TextLabel")
    itemLabel.Name = "ItemNameLabel"
    itemLabel.Text = item
    itemLabel.Font = FontMedium
    itemLabel.TextSize = 11
    itemLabel.TextColor3 = isCur and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    itemLabel.BackgroundTransparency = 1
    itemLabel.Position = UDim2.fromOffset(10, 0)
    itemLabel.Size = UDim2.new(1, -34, 1, 0)
    itemLabel.Parent = itemBtn

    local checkmark = Instance.new("TextLabel")
    checkmark.Name = "CheckmarkLabel"
    checkmark.Text = isCur and "✓" or ""
    checkmark.Font = FontBold
    checkmark.TextSize = 12
    checkmark.TextColor3 = Color3.fromRGB(52, 199, 89)
    checkmark.BackgroundTransparency = 1
    checkmark.Position = UDim2.new(1, -22, 0, 0)
    checkmark.Size = UDim2.fromOffset(16, 26)
    checkmark.Parent = itemBtn

    trackConn(itemBtn.MouseButton1Click:Connect(function()
        if item == "All Items" then
            table.clear(targetFilter)
            targetFilter["All Items"] = true
        else
            targetFilter["All Items"] = nil
            if targetFilter[item] then
                targetFilter[item] = nil
            else
                targetFilter[item] = true
            end

            if countSelectedTargets() == 0 then
                targetFilter["All Items"] = true
            end
        end

        farm_target = nil
        saveConfig()
        updateTargetMenuVisuals()
    end))
end

-- 4. iOS ComboBox: No-Reset Filter (Multi-Select Dropdown)
local filterHeaderRow = Instance.new("Frame")
filterHeaderRow.Name = "Row_FilterHeader"
filterHeaderRow.Size = UDim2.new(1, 0, 0, 24)
filterHeaderRow.BackgroundTransparency = 1
filterHeaderRow.LayoutOrder = 9
filterHeaderRow.Parent = scrollContainer

local filterPlate = Instance.new("Frame")
filterPlate.Size = UDim2.fromOffset(24, 24)
filterPlate.Position = UDim2.new(0, 0, 0.5, -12)
filterPlate.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
filterPlate.BorderSizePixel = 0
filterPlate.Parent = filterHeaderRow

local filterPlateCorner = Instance.new("UICorner")
filterPlateCorner.CornerRadius = UDim.new(0, 7)
filterPlateCorner.Parent = filterPlate

local filterIcon = Instance.new("ImageLabel")
filterIcon.Size = UDim2.fromOffset(14, 14)
filterIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
filterIcon.BackgroundTransparency = 1
filterIcon.Image = "rbxassetid://122180020814574" -- shield icon
filterIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
filterIcon.Parent = filterPlate

local filterTitle = Instance.new("TextLabel")
filterTitle.Text = "No-Reset Filter (Keep Items)"
filterTitle.Font = FontMedium
filterTitle.TextSize = 13
filterTitle.TextColor3 = Color3.fromRGB(245, 245, 247)
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.BackgroundTransparency = 1
filterTitle.Position = UDim2.fromOffset(32, 0)
filterTitle.Size = UDim2.new(1, -40, 1, 0)
filterTitle.Parent = filterHeaderRow

-- Filter Selector Button (iOS Pill style)
local filterSelectorBtn = Instance.new("TextButton")
filterSelectorBtn.Name = "FilterSelector"
filterSelectorBtn.Size = UDim2.new(1, 0, 0, 32)
filterSelectorBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
filterSelectorBtn.BorderSizePixel = 0
filterSelectorBtn.AutoButtonColor = false
filterSelectorBtn.Text = ""
filterSelectorBtn.LayoutOrder = 10
filterSelectorBtn.Parent = scrollContainer

local filterCorner = Instance.new("UICorner")
filterCorner.CornerRadius = UDim.new(0, 8)
filterCorner.Parent = filterSelectorBtn

local filterStroke = Instance.new("UIStroke")
filterStroke.Color = Color3.fromRGB(48, 48, 54)
filterStroke.Thickness = 1
filterStroke.Parent = filterSelectorBtn

local filterBtnText = Instance.new("TextLabel")
filterBtnText.Name = "CurrentText"
filterBtnText.Text = countProtected() .. " Items Protected"
filterBtnText.Font = FontMedium
filterBtnText.TextSize = 12
filterBtnText.TextColor3 = Color3.fromRGB(245, 245, 247)
filterBtnText.TextXAlignment = Enum.TextXAlignment.Left
filterBtnText.BackgroundTransparency = 1
filterBtnText.Position = UDim2.fromOffset(12, 0)
filterBtnText.Size = UDim2.new(1, -36, 1, 0)
filterBtnText.Parent = filterSelectorBtn

local filterArrow = Instance.new("TextLabel")
filterArrow.Text = "▼"
filterArrow.Font = FontBold
filterArrow.TextSize = 10
filterArrow.TextColor3 = Color3.fromRGB(142, 142, 147)
filterArrow.BackgroundTransparency = 1
filterArrow.Position = UDim2.new(1, -24, 0, 0)
filterArrow.Size = UDim2.fromOffset(16, 32)
filterArrow.Parent = filterSelectorBtn

-- Filter Dropdown List Popover (Multi-Select)
local filterMenu = Instance.new("ScrollingFrame")
filterMenu.Name = "FilterMenu"
filterMenu.Size = UDim2.new(1, 0, 0, 0)
filterMenu.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
filterMenu.BorderSizePixel = 0
filterMenu.ScrollBarThickness = 3
filterMenu.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
filterMenu.ClipsDescendants = true
filterMenu.Visible = false
filterMenu.LayoutOrder = 11
filterMenu.Parent = scrollContainer

local filterMenuCorner = Instance.new("UICorner")
filterMenuCorner.CornerRadius = UDim.new(0, 8)
filterMenuCorner.Parent = filterMenu

local filterMenuStroke = Instance.new("UIStroke")
filterMenuStroke.Color = Color3.fromRGB(60, 60, 68)
filterMenuStroke.Thickness = 1
filterMenuStroke.Parent = filterMenu

local fMenuLayout = Instance.new("UIListLayout")
fMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
fMenuLayout.Padding = UDim.new(0, 2)
fMenuLayout.Parent = filterMenu

local fMenuPadding = Instance.new("UIPadding")
fMenuPadding.PaddingLeft = UDim.new(0, 4)
fMenuPadding.PaddingRight = UDim.new(0, 4)
fMenuPadding.PaddingTop = UDim.new(0, 4)
fMenuPadding.PaddingBottom = UDim.new(0, 4)
fMenuPadding.Parent = filterMenu

local isFilterOpen = false

closeFilterMenu = function()
    if not isFilterOpen then return end
    isFilterOpen = false
    filterArrow.Text = "▼"
    local tw = TweenService:Create(filterMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(1, 0, 0, 0)
    })
    tw:Play()
    tw.Completed:Once(function()
        if not isFilterOpen then
            filterMenu.Visible = false
        end
    end)
end

toggleFilterMenu = function()
    if isFilterOpen then
        closeFilterMenu()
    else
        if closeModeMenu then closeModeMenu() end
        if closeTargetMenu then closeTargetMenu() end
        isFilterOpen = true
        filterMenu.Visible = true
        filterArrow.Text = "▲"
        TweenService:Create(filterMenu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 145)
        }):Play()
    end
end

trackConn(filterSelectorBtn.MouseButton1Click:Connect(toggleFilterMenu))

-- Populate Filter Dropdown items
filterMenu.CanvasSize = UDim2.new(0, 0, 0, #FILTER_ITEMS * 28 + 8)
for _, fItem in ipairs(FILTER_ITEMS) do
    local isChecked = (protectedFilter[fItem] == true)

    local fRowBtn = Instance.new("TextButton")
    fRowBtn.Name = "FilterItem_" .. fItem
    fRowBtn.Size = UDim2.new(1, 0, 0, 26)
    fRowBtn.BackgroundColor3 = isChecked and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)
    fRowBtn.BorderSizePixel = 0
    fRowBtn.AutoButtonColor = false
    fRowBtn.Text = ""
    fRowBtn.Parent = filterMenu

    local fBtnCorner = Instance.new("UICorner")
    fBtnCorner.CornerRadius = UDim.new(0, 6)
    fBtnCorner.Parent = fRowBtn

    local fItemLabel = Instance.new("TextLabel")
    fItemLabel.Name = "ItemNameLabel"
    fItemLabel.Text = fItem
    fItemLabel.Font = FontMedium
    fItemLabel.TextSize = 11
    fItemLabel.TextColor3 = isChecked and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
    fItemLabel.TextXAlignment = Enum.TextXAlignment.Left
    fItemLabel.BackgroundTransparency = 1
    fItemLabel.Position = UDim2.fromOffset(10, 0)
    fItemLabel.Size = UDim2.new(1, -34, 1, 0)
    fItemLabel.Parent = fRowBtn

    local fCheckmark = Instance.new("TextLabel")
    fCheckmark.Name = "CheckmarkLabel"
    fCheckmark.Text = isChecked and "✓" or ""
    fCheckmark.Font = FontBold
    fCheckmark.TextSize = 12
    fCheckmark.TextColor3 = Color3.fromRGB(52, 199, 89)
    fCheckmark.BackgroundTransparency = 1
    fCheckmark.Position = UDim2.new(1, -22, 0, 0)
    fCheckmark.Size = UDim2.fromOffset(16, 26)
    fCheckmark.Parent = fRowBtn

    trackConn(fRowBtn.MouseButton1Click:Connect(function()
        local newState = not (protectedFilter[fItem] == true)
        protectedFilter[fItem] = newState

        fRowBtn.BackgroundColor3 = newState and Color3.fromRGB(44, 44, 50) or Color3.fromRGB(28, 28, 32)
        fItemLabel.TextColor3 = newState and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(230, 230, 235)
        fCheckmark.Text = newState and "✓" or ""

        local totalCount = countProtected()
        if totalCount == 0 then
            filterBtnText.Text = "None Protected"
        elseif totalCount == #FILTER_ITEMS then
            filterBtnText.Text = "All Protected (" .. totalCount .. ")"
        else
            filterBtnText.Text = totalCount .. " Items Protected"
        end
        saveConfig()
    end))
end

-- Complete Unload Implementation
unload = function()
    setFarmState(false)
    isRunning = false
    stopFlight()
    restoreAllObstacles()

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        end)
    end

    -- Disconnect events
    for _, c in ipairs(connections) do
        if typeof(c) == "RBXScriptConnection" then
            pcall(function() c:Disconnect() end)
        end
    end
    table.clear(connections)

    -- Destroy UI
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end

    -- Clear globals
    _G.UnloadMechaFarm = nil
    if getgenv then
        getgenv().__MechaFarmCleanup = nil
    end
end

_G.UnloadMechaFarm = unload
if getgenv then
    getgenv().__MechaFarmCleanup = unload
end

-- Draggable Card
local dragging, dragStart, startPos
trackConn(mainCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainCard.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                saveConfig()
            end
        end)
    end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainCard.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

-- Right Ctrl Keybind Toggle Visibility
trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        mainCard.Visible = not mainCard.Visible
    end
end))
