-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL = "https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID = "989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true
getgenv().UNLOCK_TIMEOUT = 5

if not getgenv().UnlockedRoomsCache then getgenv().UnlockedRoomsCache = {} end
if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================
-- CACHE
-- ============================
local Vector3_new, CFrame_new = Vector3.new, CFrame.new
local task_wait, task_spawn, task_defer = task.wait, task.spawn, task.defer
local string_format, pairs, ipairs = string.format, pairs, ipairs
local table_insert, table_sort = table.insert, table.sort
local pcall, tick, math_huge = pcall, tick, math.huge

-- ============================
-- SERVICES
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
        hrp.CFrame = CFrame_new(pos.X, pos.Y + 2.5, pos.Z)
    end
end

-- ============================
-- AUTO JOIN MINIGAME
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
local breakablesContainer = thingsContainer:WaitForChild("Breakables")
local generatedBackrooms = thingsContainer:WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active"):WaitForChild("Backrooms"):WaitForChild("GeneratedBackrooms")

local spawnRoomFolder = generatedBackrooms:WaitForChild("SpawnRoom", 30)
if spawnRoomFolder then
    local deepDoor = spawnRoomFolder:FindFirstChild("DeepDoor")
    if deepDoor and deepDoor:FindFirstChild("Interact") then
        for i = 1, 5 do
            safeTeleport(deepDoor.Interact.Position)
            task_wait(0.3)
        end
        task_wait(2)
        local roomUID = spawnRoomFolder:GetAttribute("RoomUID")
        if roomUID then
            pcall(function()
                ReplicatedStorage.Network.Instancing_FireCustomFromClient:FireServer("Backrooms", "AbstractRoom_FireServer", roomUID, "EnterDeepBackrooms")
            end)
        end
    end
end

-- ============================
-- DISCORD WEBHOOK
-- ============================
local MENTION_STRING = "<@" .. getgenv().DiscordUserID .. ">"
local requestFunction = syn and syn.request or http_request or request

local function sendToDiscord(title, description, color, mention)
    if not requestFunction then return end
    pcall(function()
        requestFunction({
            Url = getgenv().WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = mention and MENTION_STRING or "",
                embeds = {{title = title, description = description, color = color}}
            })
        })
    end)
end

-- ============================
-- INVENTORY CHECK
-- ============================
local SaveModule = pcall(function() return require(ClientFolder:WaitForChild("Save")) end)
local previousPetCounts = {}
local firstCheck = true

local function checkInventoryForHugeTitanic()
    if not SaveModule then return end
    local ok, data = pcall(function() return SaveModule.Get() end)
    if not ok or not data or not data.Inventory or not data.Inventory.Pet then return end
    local current = {}
    for _, pet in pairs(data.Inventory.Pet) do
        if pet.id then current[pet.id] = (current[pet.id] or 0) + (pet._am or 1) end
    end
    if firstCheck then previousPetCounts = current firstCheck = false return end
    for name, count in pairs(current) do
        local prev = previousPetCounts[name] or 0
        if count > prev and (name:find("Huge") or name:find("Titanic")) then
            sendToDiscord(name:find("Titanic") and "TITANIC!" or "HUGE!", string_format("**%s** +%d", name, count - prev), name:find("Titanic") and 16711680 or 65280, true)
        end
    end
    previousPetCounts = current
end

if not spawnRoomFolder then return end
local origin = spawnRoomFolder:FindFirstChildWhichIsA("BasePart", true)
if not origin then return end
local originPos = origin.Position

-- ============================
-- GUI
-- ============================
if game.CoreGui:FindFirstChild("ScanGUI") then game.CoreGui.ScanGUI:Destroy() end
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ScanGUI"

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 300, 0, 180)
label.Position = UDim2.new(0, 10, 0, 150)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.Font = Enum.Font.Code
label.TextSize = 10
label.TextWrapped = true
label.Text = "Status: San sang..."

local mainFarmEnabled = false
local toggleFarmBtn = Instance.new("TextButton", sg)
toggleFarmBtn.Size = UDim2.new(0, 300, 0, 30)
toggleFarmBtn.Position = UDim2.new(0, 10, 0, 100)
toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
toggleFarmBtn.TextColor3 = Color3.new(1,1,1)
toggleFarmBtn.Font = Enum.Font.GothamBold
toggleFarmBtn.TextSize = 13
toggleFarmBtn.Text = "FARM: OFF"

-- ============================
-- ROOM FUNCTIONS
-- ============================
local bossRooms = {}
local currentBossIndex = 1
local totalBosses = 0
local damageRemote = ReplicatedStorage:WaitForChild("Network", 15):WaitForChild("Breakables_PlayerDealDamage")

local function isChestOnCooldown(room)
    if not room then return false end
    local bz = room:FindFirstChild("BREAK_ZONE", true)
    if not bz then return false end
    local timer = bz:FindFirstChild("ChestTimer")
    return timer and timer.Enabled
end

local function isLocked(room)
    return room and room:GetAttribute("LockedRoom") == true
end

local function unlockRoom(room)
    if not room then return end
    local uid = room:GetAttribute("RoomUID")
    if not uid then return end
    pcall(function()
        ReplicatedStorage.Network.Instancing_FireCustomFromClient:FireServer("Backrooms", "AbstractRoom_FireServer", uid, "UnlockDoors")
    end)
end

local function getCorners(room, bz)
    local positions = {}
    if bz then
        local p = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
        if p then positions[1] = p.Position end
    end
    if room then
        local sp = room:FindFirstChild("MiniChestSpawnPoints")
        if sp then
            for _, v in ipairs(sp:GetChildren()) do
                local p = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                if p then table_insert(positions, p.Position) end
            end
        end
    end
    return positions
end

local function detectSpawnedRoom(bossPos)
    for _, r in ipairs(generatedBackrooms:GetChildren()) do
        if r.Name == "GameMastersStage" then
            local bz = r:FindFirstChild("BREAK_ZONE", true)
            if bz then
                local p = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
                if p and (p.Position - bossPos).Magnitude < 150 then return r, bz end
            end
        end
    end
    return nil
end

-- ============================
-- SCAN BOSS LIÊN TỤC
-- ============================
local function scanBosses()
    local found = {}
    for _, obj in ipairs(breakablesContainer:GetChildren()) do
        if obj:IsA("Model") and obj:GetAttribute("BreakableID") == "Daydream Mimic Boss2" then
            local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if p then table_insert(found, {bossModel = obj, pos = p.Position, room = nil, unlockStatus = "Chua mo"}) end
        end
    end
    
    if #found > 0 then
        table_sort(found, function(a, b) return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude end)
    end
    
    return found
end

-- ============================
-- FARM ROOM
-- ============================
local farmingThisRoom = false

local function farmRoom(entry, room, idx)
    if not mainFarmEnabled then return end
    
    if isChestOnCooldown(room) then
        label.Text = string_format("Room %d/%d: Dang hoi -> Chuyen...\nTong boss hien co: %d", idx, totalBosses, totalBosses)
        task_defer(function() processNextBoss(idx % totalBosses + 1) end)
        return
    end
    
    if getgenv().NOTIFY_TARGET_ROOM then
        sendToDiscord("Dang farm room", string_format("Room %d/%d", idx, totalBosses), 65280, false)
    end
    
    safeTeleport(entry.pos)
    farmingThisRoom = true
    
    -- Đợi boss bị phá
    local conn
    conn = breakablesContainer.ChildAdded:Connect(function()
        if not mainFarmEnabled or not farmingThisRoom then return end
        if isChestOnCooldown(room) then
            conn:Disconnect()
            farmingThisRoom = false
            task_defer(function() processNextBoss(idx % totalBosses + 1) end)
        end
    end)
    
    -- Fallback 60s
    task_defer(function()
        task_wait(60)
        if conn and conn.Connected then
            conn:Disconnect()
            farmingThisRoom = false
            task_defer(function() processNextBoss(idx % totalBosses + 1) end)
        end
    end)
end

-- ============================
-- PROCESS NEXT BOSS
-- ============================
local function processNextBoss(idx)
    if not mainFarmEnabled then return end
    
    -- Quét lại boss mỗi lần chuyển room
    bossRooms = scanBosses()
    totalBosses = #bossRooms
    
    if totalBosses == 0 then
        label.Text = string_format("Dang tim boss...\nTong boss: 0")
        task_defer(function() processNextBoss(1) end)
        return
    end
    
    if idx > totalBosses then idx = 1 end
    
    local entry = bossRooms[idx]
    if not entry then
        task_defer(function() processNextBoss(1) end)
        return
    end
    
    label.Text = string_format(">> Teleport den Boss %d/%d\nTong boss hien co: %d", idx, totalBosses, totalBosses)
    
    safeTeleport(entry.pos)
    task_defer(function()
        task_wait(2)
        if not mainFarmEnabled then return end
        
        local actualRoom = detectSpawnedRoom(entry.pos)
        entry.room = actualRoom
        
        if not actualRoom then
            label.Text = string_format("Room %d/%d: Chua spawn map...\nTong boss: %d", idx, totalBosses, totalBosses)
            task_defer(function() processNextBoss(idx % totalBosses + 1) end)
            return
        end
        
        local roomUID = actualRoom:GetAttribute("RoomUID") or tostring(entry.pos)
        
        -- Unlock
        if not getgenv().UnlockedRoomsCache[roomUID] and isLocked(actualRoom) then
            label.Text = string_format("Room %d/%d: Dang mo khoa...\nTong boss: %d", idx, totalBosses, totalBosses)
            
            local function tryUnlock(attempt)
                if not mainFarmEnabled then return end
                if attempt > getgenv().UNLOCK_TIMEOUT * 2 or not isLocked(actualRoom) then
                    getgenv().UnlockedRoomsCache[roomUID] = true
                    entry.unlockStatus = "Da mo"
                    label.Text = string_format("Room %d/%d: Bat dau farm!\nTong boss: %d", idx, totalBosses, totalBosses)
                    farmRoom(entry, actualRoom, idx)
                    return
                end
                unlockRoom(actualRoom)
                task_wait(0.5)
                tryUnlock(attempt + 1)
            end
            tryUnlock(1)
        else
            getgenv().UnlockedRoomsCache[roomUID] = true
            entry.unlockStatus = "Da mo"
            label.Text = string_format("Room %d/%d: Bat dau farm!\nTong boss: %d", idx, totalBosses, totalBosses)
            farmRoom(entry, actualRoom, idx)
        end
    end)
end

-- ============================
-- TICK SYSTEM (1 LOOP DUY NHẤT)
-- ============================
local tickCount = 0

task_spawn(function()
    while task_wait(1) do
        tickCount = tickCount + 1
        
        -- Mỗi 3s: Check inventory
        if tickCount % 3 == 0 then
            pcall(checkInventoryForHugeTitanic)
        end
        
        -- Mỗi 15s: Dọn rác
        if tickCount % 15 == 0 then
            collectgarbage("collect")
        end
        
        -- Mỗi 30s: Chống crash
        if tickCount % 30 == 0 and gcinfo() > 300000 then
            for _ = 1, 3 do
                collectgarbage("collect")
            end
        end
    end
end)

-- ============================
-- FARM BUTTON
-- ============================
toggleFarmBtn.MouseButton1Click:Connect(function()
    mainFarmEnabled = not mainFarmEnabled
    
    if mainFarmEnabled then
        toggleFarmBtn.Text = "FARM: ON"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        
        bossRooms = scanBosses()
        totalBosses = #bossRooms
        
        if totalBosses > 0 then
            label.Text = string_format("Bat dau farm %d boss!", totalBosses)
            task_defer(function() processNextBoss(1) end)
        else
            label.Text = "Khong tim thay boss! Dang quet..."
            task_defer(function() processNextBoss(1) end)
        end
    else
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        farmingThisRoom = false
        label.Text = "Da tat farm."
    end
end)
