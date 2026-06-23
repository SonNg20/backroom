-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL = "https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID = "989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true

if not getgenv().UnlockedRoomsCache then
    getgenv().UnlockedRoomsCache = {}
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================
-- OPTIMIZATION: CACHE
-- ============================
local Vector3_new, CFrame_new = Vector3.new, CFrame.new
local task_wait, task_spawn, task_defer = task.wait, task.spawn, task.defer
local string_format, pairs, ipairs = string.format, pairs, ipairs
local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort
local tostring, pcall, tick = tostring, pcall, tick

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local vim = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================
-- INIT
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

local function isBreakable(obj)
    return obj:GetAttribute("BreakableUID") ~= nil
end

local function getPart(obj)
    return obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
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
        for _ = 1, 5 do
            safeTeleport(deepDoor.Interact.Position)
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
            safeTeleport(deepDoor.Interact.Position)
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
local firstCheck = true

local function checkInventory()
    if not SaveModule or not getgenv().NOTIFY_HUGE_TITANIC then return end
    
    local ok, data = pcall(function() return SaveModule.Get() end)
    if not ok or not data or not data.Inventory or not data.Inventory.Pet then return end
    
    local current = {}
    for _, pet in pairs(data.Inventory.Pet) do
        if pet.id then
            current[pet.id] = (current[pet.id] or 0) + (pet._am or 1)
        end
    end
    
    if firstCheck then
        previousPetCounts = current
        firstCheck = false
        return
    end
    
    for name, count in pairs(current) do
        local prev = previousPetCounts[name] or 0
        if count > prev then
            local gained = count - prev
            local isTitanic = name:find("Titanic")
            local isHuge = not isTitanic and name:find("Huge")
            
            if isHuge or isTitanic then
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
    
    previousPetCounts = current
end

if getgenv().NOTIFY_HUGE_TITANIC then
    task_spawn(function()
        while true do
            pcall(checkInventory)
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
local function createButton(name, position, color, text)
    local btn = Instance.new("TextButton", sg)
    btn.Size = UDim2.new(0, 280, 0, 30)
    btn.Position = position
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
local toggleFarmBtn = createButton(
    "Farm", UDim2.new(0, 10, 0, 100),
    Color3.fromRGB(150, 30, 30), "FARM: OFF"
)

-- Screen Click Button
local screenClickEnabled = true
local toggleClickBtn = createButton(
    "ScreenClick", UDim2.new(0, 10, 0, 140),
    Color3.fromRGB(0, 150, 80), "CLICK: ON"
)

toggleClickBtn.MouseButton1Click:Connect(function()
    screenClickEnabled = not screenClickEnabled
    toggleClickBtn.Text = screenClickEnabled and "CLICK: ON" or "CLICK: OFF"
    toggleClickBtn.BackgroundColor3 = screenClickEnabled 
        and Color3.fromRGB(0, 150, 80) 
        or Color3.fromRGB(150, 30, 30)
end)

-- ============================
-- ROOM SYSTEM
-- ============================
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
    local uid = room:GetAttribute("RoomUID")
    if not uid then return end
    pcall(function()
        ReplicatedStorage.Network.Instancing_FireCustomFromClient
            :FireServer("Backrooms", "AbstractRoom_FireServer", uid, "UnlockDoors")
    end)
end

local function getCorners(room, breakZone)
    local positions = {}
    
    -- Vị trí break zone (center)
    if breakZone then
        local mainPart = getPart(breakZone)
        if mainPart then
            positions[1] = mainPart.Position
        end
    end
    
    -- Mini chest spawn points
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

-- ============================
-- AUTO CLICK
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

-- ============================
-- FARM LOGIC
-- ============================
local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
local damageRemote = networkFolder:WaitForChild("Breakables_PlayerDealDamage")
local farmingThisRoom = false

-- Auto farm breakables khi ở gần (cả boss và mini chest)
task_spawn(function()
    while true do
        if mainFarmEnabled and farmingThisRoom then
            local hrp = getHRP()
            if hrp then
                local best, bestDist = nil, 15
                
                for _, obj in ipairs(breakablesContainer:GetChildren()) do
                    if isBreakable(obj) then
                        local part = getPart(obj)
                        if part then
                            local dist = (part.Position - hrp.Position).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                best = obj
                            end
                        end
                    end
                end
                
                if best then
                    pcall(function()
                        damageRemote:FireServer(tostring(best:GetAttribute("BreakableUID")))
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
local bossRooms = {}

local function updateUI(action)
    local str = string_format("Status: %s\n", action)
    str = str .. "-----------------------------\n"
    
    for i, entry in ipairs(bossRooms) do
        local status = entry.unlockStatus
        if entry.room and status ~= "🔒 Dang khoa" then
            local onCD = isChestOnCooldown(entry.room)
            status = onCD and "⏳ Dang hoi" or "✅ San sang"
        end
        str = str .. string_format("Room %d: %s\n", i, status)
    end
    
    label.Text = str
end

local function scanBosses()
    bossRooms = {}
    
    for _, obj in ipairs(breakablesContainer:GetChildren()) do
        if obj:IsA("Model") and obj:GetAttribute("BreakableID") == "Daydream Mimic Boss2" then
            local part = getPart(obj)
            if part then
                table_insert(bossRooms, {
                    bossModel = obj,
                    pos = part.Position,
                    unlocked = false,
                    unlockStatus = "🔍 Cho quet",
                    room = nil
                })
            end
        end
    end
    
    if #bossRooms == 0 then return false end
    
    table_sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)
    
    return true
end

local function teleportToBoss(pos)
    for _ = 1, 3 do
        if not mainFarmEnabled then return false end
        safeTeleport(pos)
        task_wait(0.5)
    end
    return mainFarmEnabled
end

-- Hàm tìm mini chest gần nhất
local function findNearestSpot(pos, spots)
    local bestIdx, bestDist = nil, math.huge
    
    for i = 1, #spots do
        if spots[i] then
            local dist = (spots[i] - pos).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestIdx = i
            end
        end
    end
    
    return bestIdx, bestDist
end

local function processRoom(entry, idx, total)
    -- Teleport đến boss
    if not teleportToBoss(entry.pos) then return false end
    
    -- Detect room
    local room, bz = detectSpawnedRoom(entry.pos)
    entry.room = room
    
    if not room then
        updateUI(string_format("⏳ Room %d/%d: Chua spawn...", idx, total))
        return true
    end
    
    local roomUID = room:GetAttribute("RoomUID") or tostring(entry.pos)
    
    -- Unlock nếu cần
    if not getgenv().UnlockedRoomsCache[roomUID] and isLocked(room) then
        updateUI(string_format("🔓 Room %d/%d: Dang mo khoa...", idx, total))
        
        local startTime = tick()
        while isLocked(room) and mainFarmEnabled do
            unlockRoom(room)
            task_wait(1)
            if tick() - startTime > 30 then
                entry.unlockStatus = "🔒 Dang khoa"
                updateUI(string_format("❌ Room %d/%d: Mo khoa that bai!", idx, total))
                return true
            end
        end
        
        if not mainFarmEnabled then return false end
        getgenv().UnlockedRoomsCache[roomUID] = true
    end
    
    entry.unlockStatus = "✅ Da mo"
    
    -- Check cooldown
    local onCD = isChestOnCooldown(room)
    if onCD then
        updateUI(string_format("⏳ Room %d/%d: Dang hoi...", idx, total))
        return true
    end
    
    -- Notify
    if getgenv().NOTIFY_TARGET_ROOM then
        sendToDiscord(
            "📍 Dang farm room",
            string_format("Room %d/%d\nVi tri: %.0f, %.0f, %.0f",
                idx, total, entry.pos.X, entry.pos.Y, entry.pos.Z),
            65280, false
        )
    end
    
    -- Lấy vị trí center và mini spots
    local corners = getCorners(room, bz)
    local centerPos = corners[1] or entry.pos
    
    -- Mini spots (index 2-5, bỏ index 1 là center)
    local miniSpots = {}
    for i = 2, math.min(5, #corners) do
        miniSpots[i-1] = corners[i]
    end
    
    -- === BẮT ĐẦU FARM TRONG ROOM ===
    farmingThisRoom = true
    updateUI(string_format("⚔️ Room %d/%d: Dang farm!", idx, total))
    
    -- Queue mini chest
    local pendingChests = {}
    local processing = false
    
    -- Listener phát hiện mini chest mới spawn
    local listenerConn
    listenerConn = breakablesContainer.ChildAdded:Connect(function(inst)
        task_defer(function()
            if not farmingThisRoom then return end
            if not isBreakable(inst) then return end
            
            local part = getPart(inst)
            if not part then return end
            
            -- Kiểm tra xem có phải mini chest trong room này không
            local spotIdx, dist = findNearestSpot(part.Position, miniSpots)
            if spotIdx and dist <= 15 then
                table_insert(pendingChests, {
                    pos = miniSpots[spotIdx],
                    inst = inst
                })
            end
        end)
    end)
    
    -- Thread xử lý mini chest queue
    task_spawn(function()
        while farmingThisRoom and mainFarmEnabled do
            if #pendingChests > 0 and not processing then
                processing = true
                local chest = table_remove(pendingChests, 1)
                
                updateUI(string_format("📦 Room %d/%d: Mini chest!", idx, total))
                safeTeleport(chest.pos)
                
                -- Đợi đến khi mini chest bị phá
                local waitStart = tick()
                while chest.inst and chest.inst.Parent and farmingThisRoom and mainFarmEnabled do
                    if tick() - waitStart > 15 then break end
                    task_wait(0.2)
                end
                
                -- Quay về center
                safeTeleport(centerPos)
                processing = false
            else
                task_wait(0.1)
            end
        end
    end)
    
    -- Ở center đánh boss
    while mainFarmEnabled and farmingThisRoom do
        -- Kiểm tra cooldown (đã phá xong)
        if isChestOnCooldown(room) then
            updateUI(string_format("✅ Room %d/%d: Da pha xong!", idx, total))
            break
        end
        
        -- Nếu không có mini chest pending thì đứng ở center
        if #pendingChests == 0 and not processing then
            safeTeleport(centerPos)
        end
        
        task_wait(0.5)
    end
    
    -- Cleanup
    farmingThisRoom = false
    if listenerConn then
        listenerConn:Disconnect()
    end
    
    return mainFarmEnabled
end

local function startFarmLoop()
    if not scanBosses() then
        label.Text = "❌ Khong tim thay boss nao!"
        mainFarmEnabled = false
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        return
    end
    
    label.Text = string_format("✅ Tim thay %d boss!", #bossRooms)
    updateUI("🚀 Bat dau farm...")
    
    local idx = 1
    local total = #bossRooms
    
    while mainFarmEnabled do
        local entry = bossRooms[idx]
        if not entry then
            idx = 1
            task_wait(0.5)
            continue
        end
        
        local shouldContinue = processRoom(entry, idx, total)
        if not shouldContinue then break end
        
        idx = idx % total + 1
        task_wait(0.5)
    end
    
    if not mainFarmEnabled then
        label.Text = "⏹️ Da dung farm."
    end
end

-- ============================
-- BUTTON HANDLER
-- ============================
toggleFarmBtn.MouseButton1Click:Connect(function()
    mainFarmEnabled = not mainFarmEnabled
    
    if mainFarmEnabled then
        toggleFarmBtn.Text = "FARM: ON"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        task_spawn(startFarmLoop)
    else
        toggleFarmBtn.Text = "FARM: OFF"
        toggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        farmingThisRoom = false
        label.Text = "⏹️ Dang dung..."
    end
end)

print("✅ Script da san sang!")
print("📌 Bam nut FARM de bat dau")
print("📦 Ho tro auto farm Boss + Mini Chest!")
