-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL = "https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID = "989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true
getgenv().UNLOCK_TIMEOUT = 5

if not getgenv().UnlockedRoomsCache then
    getgenv().UnlockedRoomsCache = {}
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================
-- OPTIMIZATION: CACHE GLOBAL FUNCTIONS
-- ============================
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local math_floor = math.floor
local task_wait = task.wait
local task_spawn = task.spawn
local task_defer = task.defer
local string_format = string.format
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local tostring = tostring
local pcall = pcall
local tick = tick
local math_huge = math.huge

-- ============================
-- KHAI BÁO BIẾN HỆ THỐNG CƠ BẢN
-- ============================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local vim = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local libraryFolder = ReplicatedStorage:WaitForChild("Library", 30)
if not libraryFolder then return end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

local function safeTeleport(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame_new(Vector3_new(pos.X, pos.Y + 2.5, pos.Z))
        hrp.Anchored = true
        task_wait(0.15)
        hrp.Anchored = false
    end
end

-- ============================
-- AUTO JOIN MINIGAME EVENT (LUÔN CHẠY KHI EXE)
-- ============================
local ClientFolder = libraryFolder:WaitForChild("Client", 15)
local InstancingCmds = require(ClientFolder:WaitForChild("InstancingCmds"))
local FFlags = require(ClientFolder:WaitForChild("FFlags"))

local joinTarget = FFlags.Get(FFlags.Keys.SideJoinEventTarget)
if joinTarget then
    InstancingCmds.Enter(joinTarget, nil, true, "You are joining the minigame!")
end

task_wait(10)

local thingsContainer = workspace:WaitForChild("__THINGS")
local activeContainer = thingsContainer:WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
local backroomsFolder = activeContainer:WaitForChild("Backrooms")
local generatedBackrooms = backroomsFolder:WaitForChild("GeneratedBackrooms")

local spawnRoomFolder = generatedBackrooms:WaitForChild("SpawnRoom", 30)
if spawnRoomFolder then
    local deepDoor = spawnRoomFolder:WaitForChild("DeepDoor", 15)
    if deepDoor and deepDoor:FindFirstChild("Interact") then
        local interactPart = deepDoor.Interact
        
        for i = 1, 5 do
            safeTeleport(interactPart.Position)
            task_wait(0.3)
        end
        
        task_wait(2)
        
        local roomUID = spawnRoomFolder:GetAttribute("RoomUID")
        if roomUID then
            pcall(function()
                ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient"):FireServer(
                    "Backrooms", "AbstractRoom_FireServer", roomUID, "EnterDeepBackrooms"
                )
            end)
        else
            safeTeleport(interactPart.Position)
        end
    end
end

-- ============================
-- HAM GUI DISCORD WEBHOOK
-- ============================
local MENTION_STRING = "<@" .. getgenv().DiscordUserID .. ">"
local requestFunction = syn and syn.request or http_request or request

local function sendToDiscord(title, description, color, mention)
    if not requestFunction then return end
    local data = {
        ["content"] = mention and MENTION_STRING or "",
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    pcall(function()
        requestFunction({
            Url = getgenv().WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- ============================
-- CHECK INVENTORY HUGE/TITANIC
-- ============================
local SaveModule
do
    local ok, mod = pcall(function()
        return require(ClientFolder:WaitForChild("Save"))
    end)
    if ok then SaveModule = mod end
end
local previousPetCounts = {}
local firstInventoryCheck = true
local function checkInventoryForHugeTitanic()
    if not SaveModule then return end
    local ok, data = pcall(function() return SaveModule.Get() end)
    if not ok or not data or not data.Inventory or not data.Inventory.Pet then return end
    local currentCounts = {}
    for _, petData in pairs(data.Inventory.Pet) do
        if petData.id then
            local name = petData.id
            local amount = petData._am or 1
            currentCounts[name] = (currentCounts[name] or 0) + amount
        end
    end
    if firstInventoryCheck then
        previousPetCounts = currentCounts
        firstInventoryCheck = false
        return
    end
    for name, count in pairs(currentCounts) do
        local isTitanic = name:find("Titanic") ~= nil
        local isHuge = (not isTitanic) and name:find("Huge") ~= nil
        if isHuge or isTitanic then
            local prevCount = previousPetCounts[name] or 0
            if count > prevCount then
                local gained = count - prevCount
                local title = isTitanic and "TITANIC PET MOI!" or "HUGE PET MOI!"
                local color = isTitanic and 16711680 or 65280
                sendToDiscord(
                    title,
                    string_format("Tai khoan **%s** vua nhan duoc **%s** (x%d)!\nTong hien co: **%d**",
                        player.Name, name, gained, count),
                    color, true
                )
            end
        end
    end
    previousPetCounts = currentCounts
end

if getgenv().NOTIFY_HUGE_TITANIC then
    task_spawn(function()
        while true do
            pcall(checkInventoryForHugeTitanic)
            task_wait(3)
        end
    end)
end

if not spawnRoomFolder then return end
local origin = spawnRoomFolder:FindFirstChildWhichIsA("BasePart", true)
if not origin then return end

local originPos = origin.Position

-- ============================
-- INITIALIZE GUI
-- ============================
if game.CoreGui:FindFirstChild("ScanGUI") then game.CoreGui.ScanGUI:Destroy() end
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ScanGUI"
sg.ResetOnSpawn = false

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 280, 0, 160)
label.Position = UDim2.new(0, 10, 0, 180)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.Font = Enum.Font.Code
label.TextSize = 11
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Text = "Status: Dang cho lenh tu Nut FARM..."
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

-- 1. NÚT FARM (NẰM TRÊN CÙNG - Y = 100)
local mainFarmEnabled = false
local toggleFarmBtn = Instance.new("TextButton", sg)
toggleFarmBtn.Size = UDim2.new(0, 280, 0, 30) 
toggleFarmBtn.Position = UDim2.new(0, 10, 0, 100)
toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
toggleFarmBtn.TextColor3 = Color3.new(1, 1, 1)
toggleFarmBtn.Font = Enum.Font.GothamBold
toggleFarmBtn.TextSize = 13
toggleFarmBtn.Text = "FARM: OFF"
Instance.new("UICorner", toggleFarmBtn).CornerRadius = UDim.new(0, 6)

-- 2. NÚT SCREEN CLICK (NẰM Ở GIỮA - Y = 140)
local screenClickEnabled = true
local toggleClickBtn = Instance.new("TextButton", sg)
toggleClickBtn.Size = UDim2.new(0, 280, 0, 30)
toggleClickBtn.Position = UDim2.new(0, 10, 0, 140)
toggleClickBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
toggleClickBtn.TextColor3 = Color3.new(1, 1, 1)
toggleClickBtn.Font = Enum.Font.GothamBold
toggleClickBtn.TextSize = 13
toggleClickBtn.Text = "SCREEN CLICK: ON"
Instance.new("UICorner", toggleClickBtn).CornerRadius = UDim.new(0, 6)

toggleClickBtn.MouseButton1Click:Connect(function()
    screenClickEnabled = not screenClickEnabled
    if screenClickEnabled then
        toggleClickBtn.Text = "SCREEN CLICK: ON"
        toggleClickBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    else
        toggleClickBtn.Text = "SCREEN CLICK: OFF"
        toggleClickBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    end
end)

-- ============================
-- CÁC HÀM HỆ THỐNG PHÒNG GỐC
-- ============================
local bossRooms = {}
local breakablesContainer = thingsContainer:WaitForChild("Breakables")

local function isChestOnCooldown(room)
    if not room then return false, nil end
    local bz = room:FindFirstChild("BREAK_ZONE", true)
    if not bz then return false, nil end
    local timer = bz:FindFirstChild("ChestTimer")
    if not timer then return false, bz end
    return timer.Enabled, bz
end

local function isLocked(room)
    if not room then return false end
    return room:GetAttribute("LockedRoom") == true
end

local function unlockRoom(room)
    if not room then return end
    local roomUID = room:GetAttribute("RoomUID")
    if not roomUID then return end
    pcall(function()
        ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient"):FireServer(
            "Backrooms", "AbstractRoom_FireServer", roomUID, "UnlockDoors"
        )
    end)
end

local function getCorners(r, breakZone)
    local positions = {}
    if breakZone then
        local mainPart = breakZone:IsA("BasePart") and breakZone or breakZone:FindFirstChildWhichIsA("BasePart", true)
        if mainPart then
            table_insert(positions, mainPart.Position)
        end
    end
    if r then
        local spawnPoints = r:FindFirstChild("MiniChestSpawnPoints")
        if spawnPoints then
            local points = spawnPoints:GetChildren()
            for i = 1, #points do
                local v = points[i]
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    table_insert(positions, part.Position)
                end
            end
        end
    end
    return positions
end

local function detectSpawnedRoom(bossPos)
    local children = generatedBackrooms:GetChildren()
    for i = 1, #children do
        local r = children[i]
        if r.Name == "GameMastersStage" then
            local bz = r:FindFirstChild("BREAK_ZONE", true)
            if bz then
                local part = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - bossPos).Magnitude < 150 then
                    return r, bz
                end
            end
        end
    end
    return nil, nil
end

local function updateStatusUI(currentAction)
    local str = string_format("Status: %s\n", currentAction)
    str = str .. "-----------------------------\n"
    for i, entry in ipairs(bossRooms) do
        local cooldown = isChestOnCooldown(entry.room)
        local statusText = entry.unlockStatus
        if entry.room and statusText ~= "Dang khoa" then
            statusText = cooldown and "Dang Hoi" or "San Sang"
        end
        str = str .. string_format("room%d: (%.0f, %.0f): %s\n", i, entry.pos.X, entry.pos.Z, statusText)
    end
    label.Text = str
end

local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
local damageRemote = networkFolder:WaitForChild("Breakables_PlayerDealDamage")

local function isBreakableInstance(inst)
    if inst:IsA("BasePart") or inst:IsA("Model") then
        return inst:GetAttribute("BreakableUID") ~= nil
    end
    return false
end

task_spawn(function()
    while true do
        if screenClickEnabled then
            local vp = camera.ViewportSize
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
        end
        task_wait(1)
    end
end)

local farmingThisRoom = true

-- ============================
-- CORE LOGIC RUNNER (CHỈ CHẠY KHI FARM ON)
-- ============================
local function startScanAndFarmLoop()
    bossRooms = {}
    label.Text = "Status: [ON] Dang quet tim kiem boss..."
    
    local currentHrp = getHRP()
    if currentHrp then currentHrp.Anchored = true end
    
    task_wait(1)
    local bossesCount = 0

    for _, breakable in ipairs(breakablesContainer:GetChildren()) do
        if breakable:IsA("Model") and breakable:GetAttribute("BreakableID") == "Daydream Mimic Boss2" then
            bossesCount = bossesCount + 1
            local part = breakable:IsA("BasePart") and breakable or breakable:FindFirstChildWhichIsA("BasePart", true)
            if part then
                table_insert(bossRooms, {
                    bossModel = breakable, 
                    pos = part.Position, 
                    unlocked = false,
                    unlockStatus = "Cho quet room",
                    room = nil 
                })
            end
        end
    end

    if #bossRooms == 0 then
        currentHrp = getHRP()
        if currentHrp then currentHrp.Anchored = false end
        label.Text = "Status: [ON] Khong tim thay Daydream Mimic Boss2 nao!"
        mainFarmEnabled = false
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        return
    end

    table_sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)

    currentHrp = getHRP()
    if currentHrp then currentHrp.Anchored = false end

    local idx = 1
    while mainFarmEnabled do
        local numRooms = #bossRooms
        local entry = bossRooms[idx]

        if not entry then
            idx = 1
            task_wait(0.5)
            continue
        end

        updateStatusUI(string_format("Teleport den toa do Boss %d/%d", idx, numRooms))

        for i = 1, 3 do
            if not mainFarmEnabled then break end
            safeTeleport(entry.pos)
            task_wait(0.5)
        end
        if not mainFarmEnabled then break end

        local actualRoom, bz = detectSpawnedRoom(entry.pos)
        entry.room = actualRoom 

        if not actualRoom then
            updateStatusUI(string_format("Room %d/%d: Game chua spawn map, chuyen...", idx, numRooms))
            idx = idx % numRooms + 1
            task_wait(1)
            continue
        end

        local roomUID = actualRoom:GetAttribute("RoomUID") or tostring(entry.pos)

        if getgenv().UnlockedRoomsCache[roomUID] or not isLocked(actualRoom) then
            entry.unlockStatus = "Da mo"
            entry.unlocked = true
        else
            updateStatusUI(string_format("Room %d/%d: MO KHOA (timeout 5s)...", idx, numRooms))
            local unlockStart = tick()
            
            while isLocked(actualRoom) and mainFarmEnabled do
                unlockRoom(actualRoom)
                task_wait(1)
                
                if tick() - unlockStart > getgenv().UNLOCK_TIMEOUT then
                    updateStatusUI(string_format("Room %d/%d: Qua 5s chua mo duoc -> Bo qua, farm luon!", idx, numRooms))
                    getgenv().UnlockedRoomsCache[roomUID] = true
                    entry.unlockStatus = "Da mo (skip)"
                    entry.unlocked = true
                    break
                end
            end
            
            if not isLocked(actualRoom) and entry.unlockStatus ~= "Da mo (skip)" then
                getgenv().UnlockedRoomsCache[roomUID] = true
                entry.unlockStatus = "Da mo"
                entry.unlocked = true
            end
            
            if not mainFarmEnabled then break end
        end

        local onCooldown, bzFresh = isChestOnCooldown(actualRoom)
        bz = bzFresh or bz

        if onCooldown then
            updateStatusUI(string_format("Room %d/%d: DANG HOI -> chuyen tiep", idx, numRooms))
            idx = idx % numRooms + 1 
            task_wait(0.5)
            continue
        end

        updateStatusUI(string_format("Room %d/%d: TELE va DANH chest", idx, numRooms))

        for i = 1, 3 do
            if not mainFarmEnabled then break end
            safeTeleport(entry.pos)
            task_wait(0.5)
        end
        if not mainFarmEnabled then break end

        if getgenv().NOTIFY_TARGET_ROOM then
            sendToDiscord(
                "Dang farm GameMastersStage",
                string_format("Room %d/%d\nVi tri: (%.0f, %.0f, %.0f)",
                    idx, numRooms, entry.pos.X, entry.pos.Y, entry.pos.Z),
                    65280, false
            )
        end

        local _, bzFinal = isChestOnCooldown(actualRoom)
        bz = bzFinal or bz
        local corners = getCorners(actualRoom, bz)
        
        local center = corners[1] or entry.pos
        local miniSpots = {corners[2], corners[3], corners[4], corners[5]}

        local pendingChests = {}
        local processing = false

        local function nearestSpotIndex(pos)
            local bestIdx, bestDist = nil, math_huge
            for i = 1, 4 do
                local spot = miniSpots[i]
                if spot then
                    local d = (spot - pos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestIdx = i
                    end
                end
            end
            return bestIdx, bestDist
        end

        local listenerConn = breakablesContainer.ChildAdded:Connect(function(inst)
            task_defer(function()
                if not isBreakableInstance(inst) then return end
                local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
                if not part then return end
                local idx2, dist = nearestSpotIndex(part.Position)
                if idx2 and dist <= 15 then
                    table_insert(pendingChests, {pos = miniSpots[idx2], inst = inst})
                end
            end)
        end)

        farmingThisRoom = true

        task_spawn(function()
            while farmingThisRoom and mainFarmEnabled do
                if #pendingChests > 0 and not processing then
                    processing = true
                    local chestEntry = table_remove(pendingChests, 1)

                    safeTeleport(chestEntry.pos)
                    updateStatusUI(string_format("Room %d/%d: Danh Mini Chest", idx, numRooms))

                    while chestEntry.inst and chestEntry.inst.Parent and mainFarmEnabled do
                        task_wait(0.2)
                    end

                    processing = false
                else
                    task_wait(0.1)
                end
            end
        end)

        while mainFarmEnabled do
            local cooldown = isChestOnCooldown(actualRoom)
            if cooldown then
                updateStatusUI(string_format("Room %d/%d: Da pha! Chuyen room...", idx, numRooms))
                break
            end

            if #pendingChests == 0 and not processing then
                safeTeleport(center)
                updateStatusUI(string_format("Room %d/%d: Dang danh Boss", idx, numRooms))
            end
            task_wait(0.5)
        end

        farmingThisRoom = false
        listenerConn:Disconnect()

        if not mainFarmEnabled then break end
        idx = idx % numRooms + 1
        task_wait(0.5)
    end
end

-- LẮNG NGHE SỰ KIỆN CLICK NÚT FARM
toggleFarmBtn.MouseButton1Click:Connect(function()
    mainFarmEnabled = not mainFarmEnabled
    if mainFarmEnabled then
        toggleFarmBtn.Text = "FARM: ON"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        task_spawn(startScanAndFarmLoop)
    else
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        farmingThisRoom = false
        label.Text = "Status: Da tat Farm. Dang dung lai..."
    end
end)
