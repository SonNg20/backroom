-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL = "https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID = "989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true
getgenv().UNLOCK_TIMEOUT = 5 -- Thời gian timeout unlock (giây)

if not getgenv().UnlockedRoomsCache then
    getgenv().UnlockedRoomsCache = {}
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================
-- CACHE GLOBALS
-- ============================
local Vector3_new, CFrame_new = Vector3.new, CFrame.new
local task_wait, task_spawn, task_defer = task.wait, task.spawn, task.defer
local string_format, pairs, ipairs = string.format, pairs, ipairs
local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort
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

-- ============================
-- LIBRARY INIT
-- ============================
local libraryFolder = ReplicatedStorage:WaitForChild("Library", 30)
if not libraryFolder then return print("❌ Khong tim thay Library") end

local ClientFolder = libraryFolder:WaitForChild("Client", 15)
local InstancingCmds = require(ClientFolder:WaitForChild("InstancingCmds"))
local FFlags = require(ClientFolder:WaitForChild("FFlags"))
local SaveModule = pcall(function() return require(ClientFolder:WaitForChild("Save")) end)

-- ============================
-- HELPER FUNCTIONS
-- ============================
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

local function safeTeleport(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame_new(pos.X, pos.Y + 2.5, pos.Z)
        hrp.Anchored = true
        task_wait(0.15)
        hrp.Anchored = false
    end
end

local function getPart(obj)
    return obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function isBreakable(obj)
    return obj:GetAttribute("BreakableUID") ~= nil
end

-- ============================
-- AUTO JOIN MINIGAME
-- ============================
local joinTarget = FFlags.Get(FFlags.Keys.SideJoinEventTarget)
if joinTarget then
    InstancingCmds.Enter(joinTarget, nil, true, "You are joining the minigame!")
end

task_wait(10)

-- ============================
-- ENTER DEEP BACKROOMS
-- ============================
local thingsContainer = workspace:WaitForChild("__THINGS")
local activeContainer = thingsContainer:WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
local backroomsFolder = activeContainer:WaitForChild("Backrooms")
local generatedBackrooms = backroomsFolder:WaitForChild("GeneratedBackrooms")
local breakablesContainer = thingsContainer:WaitForChild("Breakables")

print("🔍 Dang tim Deep Backrooms...")
local spawnRoomFolder = generatedBackrooms:WaitForChild("SpawnRoom", 30)

if spawnRoomFolder then
    local deepDoor = spawnRoomFolder:FindFirstChild("DeepDoor")
    if deepDoor and deepDoor:FindFirstChild("Interact") then
        local interactPart = deepDoor.Interact
        
        for _ = 1, 5 do
            safeTeleport(interactPart.Position)
            task_wait(0.3)
        end
        
        task_wait(2)
        
        local roomUID = spawnRoomFolder:GetAttribute("RoomUID")
        if roomUID then
            pcall(function()
                ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient")
                    :FireServer("Backrooms", "AbstractRoom_FireServer", roomUID, "EnterDeepBackrooms")
            end)
            print("✅ Da vao Deep Backrooms!")
        else
            safeTeleport(interactPart.Position)
        end
    end
end

if not spawnRoomFolder then return end

local origin = spawnRoomFolder:FindFirstChildWhichIsA("BasePart", true)
if not origin then return end
local originPos = origin.Position

-- ============================
-- DISCORD WEBHOOK
-- ============================
local MENTION_STRING = "<@" .. getgenv().DiscordUserID .. ">"
local requestFunction = syn and syn.request or http_request or request

local function sendToDiscord(title, description, color, mention)
    if not requestFunction then return end
    
    local data = {
        content = mention and MENTION_STRING or "",
        embeds = {{
            title = title,
            description = description,
            color = color,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
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
-- INVENTORY MONITOR
-- ============================
local previousPetCounts = {}
local firstInventoryCheck = true

local function checkInventoryForHugeTitanic()
    if not SaveModule then return end
    
    local ok, data = pcall(function() return SaveModule.Get() end)
    if not ok or not data or not data.Inventory or not data.Inventory.Pet then return end
    
    local currentCounts = {}
    for _, petData in pairs(data.Inventory.Pet) do
        if petData.id then
            currentCounts[petData.id] = (currentCounts[petData.id] or 0) + (petData._am or 1)
        end
    end
    
    if firstInventoryCheck then
        previousPetCounts = currentCounts
        firstInventoryCheck = false
        return
    end
    
    for name, count in pairs(currentCounts) do
        local isTitanic = name:find("Titanic")
        local isHuge = not isTitanic and name:find("Huge")
        
        if isHuge or isTitanic then
            local prevCount = previousPetCounts[name] or 0
            if count > prevCount then
                local gained = count - prevCount
                sendToDiscord(
                    isTitanic and "💎 TITANIC PET MOI!" or "🔥 HUGE PET MOI!",
                    string_format("**%s** vua nhan **%s** (x%d)\nTong: **%d**",
                        player.Name, name, gained, count),
                    isTitanic and 16711680 or 65280,
                    true
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

-- ============================
-- GUI SETUP
-- ============================
if game.CoreGui:FindFirstChild("ScanGUI") then
    game.CoreGui.ScanGUI:Destroy()
end

local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ScanGUI"
sg.ResetOnSpawn = false

-- Status Label
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
label.Text = "Status: San sang..."
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

-- Helper tạo button
local function createButton(name, positionY, color, text)
    local btn = Instance.new("TextButton", sg)
    btn.Size = UDim2.new(0, 280, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, positionY)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- Farm Button
local mainFarmEnabled = false
local toggleFarmBtn = createButton("Farm", 100, Color3.fromRGB(150, 30, 30), "FARM: OFF")

-- Screen Click Button
local screenClickEnabled = true
local toggleClickBtn = createButton("Click", 140, Color3.fromRGB(0, 150, 80), "CLICK: ON")

toggleClickBtn.MouseButton1Click:Connect(function()
    screenClickEnabled = not screenClickEnabled
    if screenClickEnabled then
        toggleClickBtn.Text = "CLICK: ON"
        toggleClickBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    else
        toggleClickBtn.Text = "CLICK: OFF"
        toggleClickBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    end
end)

-- ============================
-- ROOM SYSTEM FUNCTIONS
-- ============================
local bossRooms = {}
local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
local damageRemote = networkFolder:WaitForChild("Breakables_PlayerDealDamage")

local function isChestOnCooldown(room)
    if not room then return false, nil end
    local bz = room:FindFirstChild("BREAK_ZONE", true)
    if not bz then return false, nil end
    local timer = bz:FindFirstChild("ChestTimer")
    return timer and timer.Enabled, bz
end

local function isLocked(room)
    return room and room:GetAttribute("LockedRoom") == true
end

local function unlockRoom(room)
    if not room then return end
    local roomUID = room:GetAttribute("RoomUID")
    if not roomUID then return end
    pcall(function()
        ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient")
            :FireServer("Backrooms", "AbstractRoom_FireServer", roomUID, "UnlockDoors")
    end)
end

-- Hàm tryUnlockRoom: thử unlock trong timeout giây, nếu quá thì bỏ qua coi như đã mở
local function tryUnlockRoom(room, roomUID, idx, numRooms)
    if not isLocked(room) then
        return true -- Đã mở sẵn
    end
    
    updateStatusUI(string_format("🔓 Room %d/%d: Dang mo khoa (%ds timeout)...", idx, numRooms, getgenv().UNLOCK_TIMEOUT))
    
    local unlockStart = tick()
    local unlockAttempts = 0
    
    while isLocked(room) and mainFarmEnabled do
        unlockRoom(room)
        unlockAttempts = unlockAttempts + 1
        task_wait(0.5)
        
        local elapsed = tick() - unlockStart
        
        -- Kiểm tra timeout
        if elapsed >= getgenv().UNLOCK_TIMEOUT then
            updateStatusUI(string_format("⚠️ Room %d/%d: Qua %ds van chua mo duoc -> Bo qua, coi nhu da mo!", 
                idx, numRooms, getgenv().UNLOCK_TIMEOUT))
            
            -- Vẫn cache để lần sau không thử unlock nữa
            getgenv().UnlockedRoomsCache[roomUID] = true
            
            task_wait(1)
            return true -- Coi như đã mở, tiến hành farm
        end
    end
    
    if not mainFarmEnabled then return false end
    
    -- Unlock thành công
    getgenv().UnlockedRoomsCache[roomUID] = true
    updateStatusUI(string_format("✅ Room %d/%d: Da mo khoa sau %d lan thu!", idx, numRooms, unlockAttempts))
    
    return true
end

local function getCorners(room, breakZone)
    local positions = {}
    
    if breakZone then
        local mainPart = getPart(breakZone)
        if mainPart then
            positions[1] = mainPart.Position
        end
    end
    
    if room then
        local spawnPoints = room:FindFirstChild("MiniChestSpawnPoints")
        if spawnPoints then
            for _, point in ipairs(spawnPoints:GetChildren()) do
                local part = getPart(point)
                if part then
                    table_insert(positions, part.Position)
                end
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
                local part = getPart(bz)
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
        
        if entry.room and statusText ~= "Dang khoa" and statusText ~= "⚠️ Bo qua (timeout)" then
            statusText = cooldown and "⏳ Dang Hoi" or "✅ San Sang"
        end
        
        str = str .. string_format("Room %d: (%.0f, %.0f) %s\n",
            i, entry.pos.X, entry.pos.Z, statusText)
    end
    
    label.Text = str
end

-- ============================
-- AUTO CLICK + FARM BREAKABLES
-- ============================
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

task_spawn(function()
    while true do
        if mainFarmEnabled and farmingThisRoom then
            local hrp = getHRP()
            if hrp then
                local bestInst, bestDist = nil, math_huge
                
                for _, obj in ipairs(breakablesContainer:GetChildren()) do
                    if isBreakable(obj) then
                        local part = getPart(obj)
                        if part then
                            local dist = (part.Position - hrp.Position).Magnitude
                            if dist <= 15 and dist < bestDist then
                                bestDist = dist
                                bestInst = obj
                            end
                        end
                    end
                end
                
                if bestInst then
                    pcall(function()
                        damageRemote:FireServer(tostring(bestInst:GetAttribute("BreakableUID")))
                    end)
                end
            end
        end
        task_wait(0.1)
    end
end)

-- ============================
-- MAIN FARM LOOP
-- ============================
local function startScanAndFarmLoop()
    bossRooms = {}
    label.Text = "Status: [ON] Dang quet tim boss..."
    
    local hrp = getHRP()
    if hrp then hrp.Anchored = true end
    task_wait(1)
    
    -- Scan bosses
    local bossesCount = 0
    for _, breakable in ipairs(breakablesContainer:GetChildren()) do
        if breakable:IsA("Model") and breakable:GetAttribute("BreakableID") == "Daydream Mimic Boss2" then
            bossesCount = bossesCount + 1
            local part = getPart(breakable)
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
        hrp = getHRP()
        if hrp then hrp.Anchored = false end
        label.Text = "❌ Khong tim thay boss nao!"
        mainFarmEnabled = false
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        return
    end
    
    -- Sort theo khoảng cách
    table_sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)
    
    hrp = getHRP()
    if hrp then hrp.Anchored = false end
    
    -- Loop qua từng room
    local idx = 1
    local numRooms = #bossRooms
    
    while mainFarmEnabled do
        local entry = bossRooms[idx]
        
        if not entry then
            idx = 1
            task_wait(0.5)
            continue
        end
        
        updateStatusUI(string_format("📍 Teleport den Boss %d/%d", idx, numRooms))
        
        -- Teleport đến boss (3 lần)
        for _ = 1, 3 do
            if not mainFarmEnabled then break end
            safeTeleport(entry.pos)
            task_wait(0.5)
        end
        
        if not mainFarmEnabled then break end
        
        -- Detect room
        local actualRoom, bz = detectSpawnedRoom(entry.pos)
        entry.room = actualRoom
        
        if not actualRoom then
            updateStatusUI(string_format("⏳ Room %d/%d: Chua spawn map...", idx, numRooms))
            idx = idx % numRooms + 1
            task_wait(1)
            continue
        end
        
        local roomUID = actualRoom:GetAttribute("RoomUID") or tostring(entry.pos)
        
        -- === LOGIC UNLOCK ROOM MỚI (5s timeout) ===
        if not getgenv().UnlockedRoomsCache[roomUID] then
            local unlocked = tryUnlockRoom(actualRoom, roomUID, idx, numRooms)
            
            if not unlocked then
                -- mainFarmEnabled = false, thoát
                break
            end
            
            entry.unlockStatus = "Da mo"
            entry.unlocked = true
        else
            entry.unlockStatus = "Da mo (cached)"
            entry.unlocked = true
        end
        -- ===========================================
        
        -- Check cooldown
        local onCooldown, bzFresh = isChestOnCooldown(actualRoom)
        bz = bzFresh or bz
        
        if onCooldown then
            updateStatusUI(string_format("⏳ Room %d/%d: DANG HOI -> Chuyen room...", idx, numRooms))
            idx = idx % numRooms + 1
            task_wait(0.5)
            continue
        end
        
        -- Bắt đầu farm
        updateStatusUI(string_format("⚔️ Room %d/%d: Bat dau farm!", idx, numRooms))
        
        -- Teleport lại lần nữa
        for _ = 1, 3 do
            if not mainFarmEnabled then break end
            safeTeleport(entry.pos)
            task_wait(0.5)
        end
        
        if not mainFarmEnabled then break end
        
        -- Notify Discord
        if getgenv().NOTIFY_TARGET_ROOM then
            sendToDiscord(
                "📍 Dang farm room",
                string_format("Room %d/%d\nVi tri: (%.0f, %.0f, %.0f)",
                    idx, numRooms, entry.pos.X, entry.pos.Y, entry.pos.Z),
                65280, false
            )
        end
        
        -- Lấy corners cho mini chest
        local _, bzFinal = isChestOnCooldown(actualRoom)
        bz = bzFinal or bz
        local corners = getCorners(actualRoom, bz)
        local center = corners[1] or entry.pos
        local miniSpots = {corners[2], corners[3], corners[4], corners[5]}
        
        -- Mini chest system
        local pendingChests = {}
        local processing = false
        
        local function nearestSpotIndex(pos)
            local bestIdx, bestDist = nil, math_huge
            for i = 1, 4 do
                local spot = miniSpots[i]
                if spot then
                    local dist = (spot - pos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestIdx = i
                    end
                end
            end
            return bestIdx, bestDist
        end
        
        -- Listener mini chest spawn
        local listenerConn = breakablesContainer.ChildAdded:Connect(function(inst)
            task_defer(function()
                if not isBreakable(inst) then return end
                local part = getPart(inst)
                if not part then return end
                
                local spotIdx, dist = nearestSpotIndex(part.Position)
                if spotIdx and dist <= 15 then
                    table_insert(pendingChests, {pos = miniSpots[spotIdx], inst = inst})
                end
            end)
        end)
        
        farmingThisRoom = true
        
        -- Thread xử lý mini chest
        task_spawn(function()
            while farmingThisRoom and mainFarmEnabled do
                if #pendingChests > 0 and not processing then
                    processing = true
                    local chestEntry = table_remove(pendingChests, 1)
                    
                    safeTeleport(chestEntry.pos)
                    updateStatusUI(string_format("📦 Room %d/%d: Mini Chest!", idx, numRooms))
                    
                    local waitStart = tick()
                    while chestEntry.inst and chestEntry.inst.Parent and mainFarmEnabled do
                        if tick() - waitStart > 15 then break end
                        task_wait(0.2)
                    end
                    
                    processing = false
                else
                    task_wait(0.1)
                end
            end
        end)
        
        -- Main loop: đứng ở center đánh boss
        while mainFarmEnabled do
            local cooldown = isChestOnCooldown(actualRoom)
            if cooldown then
                updateStatusUI(string_format("✅ Room %d/%d: Da pha xong!", idx, numRooms))
                break
            end
            
            if #pendingChests == 0 and not processing then
                safeTeleport(center)
                updateStatusUI(string_format("⚔️ Room %d/%d: Dang danh Boss", idx, numRooms))
            end
            
            task_wait(0.5)
        end
        
        -- Cleanup
        farmingThisRoom = false
        listenerConn:Disconnect()
        
        if not mainFarmEnabled then break end
        
        idx = idx % numRooms + 1
        task_wait(0.5)
    end
end

-- ============================
-- FARM BUTTON HANDLER
-- ============================
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
        label.Text = "⏹️ Da tat Farm."
    end
end)

print("✅ Script da san sang!")
print("⏱️ Unlock timeout: " .. getgenv().UNLOCK_TIMEOUT .. "s")
