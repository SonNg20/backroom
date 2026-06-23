-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL ="https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID ="989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true 

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
local math_huge = math.huge
local task_wait = task.wait
local task_spawn = task.spawn
local task_defer = task.defer
local string_format = string.format
local string_find = string.find
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local tostring = tostring
local pcall = pcall
local tick = tick

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
if not libraryFolder then
    print("Khong tim thay thu vien Library trong thoi gian cho!")
    return
end

-- ✅ CẢI TIẾN: Cache HRP thay vì tạo mới mỗi lần
local cachedHRP = nil
local lastHRPCheck = 0

local function getHRP()
    local currentTime = tick()
    
    if cachedHRP and cachedHRP.Parent and (currentTime - lastHRPCheck) < 0.5 then
        return cachedHRP
    end
    
    local char = player.Character or player.CharacterAdded:Wait()
    cachedHRP = char:WaitForChild("HumanoidRootPart", 10)
    lastHRPCheck = currentTime
    
    return cachedHRP
end

-- ✅ CẢI TIẾN: Optimized safeTeleport
local function safeTeleport(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame_new(pos.X, pos.Y + 2.5, pos.Z)
        hrp.Anchored = true
        task_wait(0.15)
        hrp.Anchored = false
    end
end

-- ============================
-- AUTO JOIN MINIGAME EVENT
-- ============================
local ClientFolder = libraryFolder:WaitForChild("Client", 15)
local InstancingCmds = require(ClientFolder:WaitForChild("InstancingCmds"))
local FFlags = require(ClientFolder:WaitForChild("FFlags"))

local joinTarget = FFlags.Get(FFlags.Keys.SideJoinEventTarget)
if joinTarget then
    InstancingCmds.Enter(joinTarget, nil, true, "You are joining the minigame!")
end

task_wait(10)

-- ✅ CẢI TIẾN: Cache các folder tại khởi động
local thingsContainer = workspace:WaitForChild("__THINGS")
local activeContainer = thingsContainer:WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
local backroomsFolder = activeContainer:WaitForChild("Backrooms")
local generatedBackrooms = backroomsFolder:WaitForChild("GeneratedBackrooms")

print("Dang tim kiem cong vao Deep Backrooms...")
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
            print("Da kich hoat Deep Backrooms qua Network Event!")
        else
            print("Khong tim thay RoomUID, dang thu va cham truc tiep...")
            safeTeleport(interactPart.Position)
        end
    end
end

-- ============================
-- HAM GUI DISCORD WEBHOOK (ASYNC)
-- ============================
local MENTION_STRING = "<@" .. getgenv().DiscordUserID .. ">"
local requestFunction = syn and syn.request or http_request or request

-- ✅ CẢI TIẾN: Async Discord call
local function sendToDiscordAsync(title, description, color, mention)
    if not requestFunction then return end
    
    task_spawn(function()
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
local lastInventoryCheck = 0
local INVENTORY_CHECK_INTERVAL = 3

local function checkInventoryForHugeTitanic()
    if not SaveModule then return end
    
    local currentTime = tick()
    if (currentTime - lastInventoryCheck) < INVENTORY_CHECK_INTERVAL then
        return
    end
    lastInventoryCheck = currentTime
    
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
        local isTitanic = string_find(name, "Titanic") ~= nil
        local isHuge = (not isTitanic) and string_find(name, "Huge") ~= nil
        if isHuge or isTitanic then
            local prevCount = previousPetCounts[name] or 0
            if count > prevCount then
                local gained = count - prevCount
                local title = isTitanic and "TITANIC PET MOI!" or "HUGE PET MOI!"
                local color = isTitanic and 16711680 or 65280
                sendToDiscordAsync(
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

-- NÚT FARM
local mainFarmEnabled = false
local toggleFarmBtn = Instance.new("TextButton", sg)
toggleFarmBtn.Name = "FarmBtn"
toggleFarmBtn.Size = UDim2.new(0, 100, 0, 40)
toggleFarmBtn.Position = UDim2.new(0, 10, 0, 100)
toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
toggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFarmBtn.Font = Enum.Font.Code
toggleFarmBtn.TextSize = 12
toggleFarmBtn.Text = "FARM: OFF"
Instance.new("UICorner", toggleFarmBtn).CornerRadius = UDim.new(0, 6)

-- ✅ CẢI TIẾN: Debounce click
local lastFarmToggleTime = 0
local FARM_TOGGLE_DEBOUNCE = 0.5

local function updateStatusUI(text)
    label.Text = "Status: [ON] " .. text
end

-- ✅ CẢI TIẾN: Cache các biến loop
local farmingThisRoom = false
local currentHrp = nil

-- ============================
-- ✅ FIX: DETECT MECHANISM TỪ FILE GỐC
-- ============================

local function detectSpawnedRoom(bossPos)
    -- ✅ FIX: Dùng generatedBackrooms thay vì active
    local children = generatedBackrooms:GetChildren()
    
    for i = 1, #children do
        local r = children[i]
        
        -- ✅ FIX: Tìm "GameMastersStage" chính xác
        if r.Name == "GameMastersStage" then
            -- ✅ FIX: Tìm BREAK_ZONE (không phải BossZone/MainPart)
            local bz = r:FindFirstChild("BREAK_ZONE", true)
            
            if bz then
                local part = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
                
                -- ✅ FIX: Threshold 150 studs (không phải 50)
                if part and (part.Position - bossPos).Magnitude < 150 then
                    return r, bz
                end
            end
        end
    end
    
    return nil, nil
end

-- ============================
-- HỘ TRỢ FUNCTIONS
-- ============================

local function isLocked(room)
    local door = room:FindFirstChild("Door")
    return door and door:FindFirstChild("LockedStatus") ~= nil
end

local function unlockRoom(room)
    if not isLocked(room) then return end
    local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
    local unlockRemote = networkFolder:FindFirstChild("Backrooms_UnlockDoor")
    if unlockRemote then
        pcall(function()
            unlockRemote:FireServer(room)
        end)
    end
end

local function isChestOnCooldown(room)
    local bzConfig = room:FindFirstChild("BossZone_Config")
    if bzConfig and bzConfig:GetAttribute("IsReady") == false then
        local bz = room:FindFirstChild("BossZone") or room:FindFirstChild("BossZone_Dummy")
        return true, bz
    end
    local door = room:FindFirstChild("Door")
    if door and door:FindFirstChild("LockedStatus") then
        return false, nil
    end
    return false, nil
end

local function getCorners(room, bz)
    local positions = {}
    local mainPart = room:FindFirstChild("MainPart")
    if mainPart then
        table_insert(positions, mainPart.Position)
    end
    local spawnPoints = room:FindFirstChild("MiniChestSpawnPoints")
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
    return positions
end

local function isBreakableInstance(inst)
    if inst:IsA("BasePart") or inst:IsA("Model") then
        return inst:GetAttribute("BreakableUID") ~= nil
    end
    return false
end

local breakablesContainer = nil
local function getBreakablesContainer()
    if not breakablesContainer or not breakablesContainer.Parent then
        local things = workspace:FindFirstChild("__THINGS")
        if things then
            breakablesContainer = things:FindFirstChild("Breakables")
        end
    end
    return breakablesContainer
end

local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
local damageRemote = networkFolder:WaitForChild("Breakables_PlayerDealDamage")

-- ============================
-- MAIN FARMING LOGIC
-- ============================

local function startScanAndFarmLoop()
    breakablesContainer = getBreakablesContainer()
    
    if not breakablesContainer then
        print("❌ Khong tim thay Breakables container")
        return
    end
    
    print("\n" .. string.rep("=", 70))
    print("STARTING FARM LOOP")
    print(string.rep("=", 70) .. "\n")
    
    task_wait(0.5)
    
    local bossRooms = {}
    local bossesCount = 0

    local breakablesChildren = breakablesContainer:GetChildren()
    for _, breakable in ipairs(breakablesChildren) do
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

    if bossesCount >= 3 then
        print("3 or more bosses detected:", bossesCount)
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
    local mainLoopTimeout = 0
    
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

        -- ✅ FIX: Tele 2 lần thay vì chuyển room
        if not actualRoom then
            updateStatusUI(string_format("Room %d/%d: Game chua spawn, tele lai (1/2)...", idx, numRooms))
            
            safeTeleport(entry.pos)
            task_wait(0.5)
            
            safeTeleport(entry.pos)
            task_wait(0.5)
            
            actualRoom, bz = detectSpawnedRoom(entry.pos)
            entry.room = actualRoom
            
            if not actualRoom then
                updateStatusUI(string_format("Room %d/%d: Tele 2 lan khong spawn, chuyen...", idx, numRooms))
                idx = idx % numRooms + 1
                task_wait(0.5)
                continue
            end
        end

        local roomUID = actualRoom:GetAttribute("RoomUID") or tostring(entry.pos)

        if getgenv().UnlockedRoomsCache[roomUID] or not isLocked(actualRoom) then
            entry.unlockStatus = "Da mo"
            entry.unlocked = true
        else
            updateStatusUI(string_format("Room %d/%d: MO KHOA LAN DAU...", idx, numRooms))
            local unlockStart = tick()
            local fail = false
            
            while isLocked(actualRoom) and mainFarmEnabled do
                unlockRoom(actualRoom)
                task_wait(1)
                if tick() - unlockStart > 30 then
                    fail = true
                    break
                end
            end
            
            if not mainFarmEnabled then break end
            
            if fail then
                entry.unlockStatus = "Dang khoa"
                entry.unlocked = false
                updateStatusUI(string_format("Room %d/%d: Mo khoa that bai, bo qua!", idx, numRooms))
                idx = idx % numRooms + 1
                task_wait(0.5)
                continue
            else
                getgenv().UnlockedRoomsCache[roomUID] = true
                entry.unlockStatus = "Da mo"
                entry.unlocked = true
            end
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
            sendToDiscordAsync(
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
            if not farmingThisRoom then return end
            
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
        
        local chestProcessTask = task_spawn(function()
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

        mainLoopTimeout = tick()
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
            
            if tick() - mainLoopTimeout > 600 then
                updateStatusUI(string_format("Room %d/%d: Timeout, chuyen room", idx, numRooms))
                break
            end
        end

        farmingThisRoom = false
        if listenerConn and listenerConn.Connected then
            listenerConn:Disconnect()
        end
        
        for i = 1, #pendingChests do
            pendingChests[i] = nil
        end

        if not mainFarmEnabled then break end
        idx = idx % numRooms + 1
        task_wait(0.5)
        
        collectgarbage("collect")
    end
end

-- LẮNG NGHE SỰ KIỆN CLICK NÚT FARM
toggleFarmBtn.MouseButton1Click:Connect(function()
    local currentTime = tick()
    if (currentTime - lastFarmToggleTime) < FARM_TOGGLE_DEBOUNCE then
        return
    end
    lastFarmToggleTime = currentTime
    
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

print("✅ Script loaded! Click FARM button to start.")
