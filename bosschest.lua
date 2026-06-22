repeat task.wait() until game:IsLoaded()

-- ============================
-- CONFIG (chinh o day)
-- ============================
getgenv().WebhookURL = getgenv().WebhookURL or "https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID = getgenv().DiscordUserID or "989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = true   
getgenv().NOTIFY_HUGE_TITANIC = true  
getgenv().FarmMultiChest = true       

-- ============================
-- TỐI ƯU HÓA ĐỒ HỌA CHỐNG CAO RAM (ANTI-LAG)
-- ============================
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    game:GetService("Lighting").GlobalShadows = false
    for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("BloomEffect") then
            v.Enabled = false
        end
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local vim = game:GetService("VirtualInputManager")

-- Đợi nhân vật load hoàn chỉnh
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ============================
-- KHỞI TẠO HỆ THỐNG CHỐNG RỚT (BỆ ĐỠ + TRIỆT TIÊU TRỌNG LỰC)
-- ============================
local platform = Instance.new("Part")
platform.Size = Vector3.new(15, 1, 15)
platform.Anchored = true
platform.Transparency = 1 
platform.CanCollide = true
platform.Parent = workspace

local attachment = Instance.new("Attachment", hrp)
local linearVelocity = Instance.new("LinearVelocity", hrp)
linearVelocity.Attachment0 = attachment
linearVelocity.MaxForce = math.huge
linearVelocity.VectorVelocity = Vector3.new(0, 0, 0) -- Triệt tiêu hoàn toàn trọng lực tác động lên player

local function safeTeleport(targetPos)
    platform.CFrame = CFrame.new(targetPos - Vector3.new(0, 3, 0)) -- Luôn đặt bệ đỡ ngay dưới chân khi tele
    hrp.CFrame = CFrame.new(targetPos)
end

-- ============================
-- AUTO JOIN SK CŨ + TELE PORTAL QUA DEEP BACKROOMS
-- ============================
local InstancingCmds = require(ReplicatedStorage.Library.Client.InstancingCmds)
local FFlags = require(ReplicatedStorage.Library.Client.FFlags)
repeat task.wait() until ReplicatedStorage:FindFirstChild("Library")
local joinTarget = FFlags.Get(FFlags.Keys.SideJoinEventTarget)
if joinTarget then
    InstancingCmds.Enter(joinTarget, nil, true, "You are joining the minigame!")
end

task.wait(10) 

local activeContainer = workspace:WaitForChild("__THINGS"):WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")
local backroomsFolder = activeContainer:WaitForChild("Backrooms")
local generatedBackrooms = backroomsFolder:WaitForChild("GeneratedBackrooms")

print("Dang tim kiem cong vao Deep Backrooms...")
local spawnRoomFolder = generatedBackrooms:WaitForChild("SpawnRoom", 30)
if spawnRoomFolder then
    local deepDoor = spawnRoomFolder:WaitForChild("DeepDoor", 15)
    if deepDoor and deepDoor:FindFirstChild("Interact") then
        local interactPart = deepDoor.Interact
        
        for i = 1, 5 do
            safeTeleport(interactPart.Position + Vector3.new(0, 2, 0))
            task.wait(0.3)
        end
        
        -- Chờ 2 giây rồi bấm cổng (Không nhảy Spacebar)
        task.wait(2)
        
        local prompt = interactPart:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            fireproximityprompt(prompt)
            print("Da kich hoat cong vao Deep Backrooms thanh cong!")
        else
            print("Khong tim thay ProximityPrompt, dang thu va cham truc tiep...")
            safeTeleport(interactPart.Position)
        end
    end
end

task.wait(12)

local spawnRoom = generatedBackrooms:WaitForChild("DeepSpawnRoom", 35)
if not spawnRoom then 
    print("Loi nghiem trong: Khong tim thay DeepSpawnRoom!")
    return 
end

local origin = spawnRoom:FindFirstChildWhichIsA("BasePart", true)
if not origin then return end
local originPos = origin.Position

-- ============================
-- GUI
-- ============================
if game.CoreGui:FindFirstChild("ScanGUI") then game.CoreGui.ScanGUI:Destroy() end
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ScanGUI"
sg.ResetOnSpawn = false

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 250, 0, 90)
label.Position = UDim2.new(0, 10, 0, 140)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Text = "Dang khoi tao..."
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

local screenClickEnabled = true
local toggleClickBtn = Instance.new("TextButton", sg)
toggleClickBtn.Size = UDim2.new(0, 160, 0, 30)
toggleClickBtn.Position = UDim2.new(0, 10, 0, 100)
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
            ["timestamp"] = os.date("!%Y-%m-%dT%M:%M:%SZ")
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
-- CAU HINH QUET MAP MỚI
-- ============================
local STEP = 350
local MIN_X, MAX_X = -7500, -2100
local MIN_Z, MAX_Z = -3600, 900
local SCAN_Y = 2055
local WAIT_TIME = 0.7

local STEPS_X = math.floor((MAX_X - MIN_X) / STEP) + 1
local STEPS_Z = math.floor((MAX_Z - MIN_Z) / STEP) + 1
local TOTAL_POINTS = STEPS_X * STEPS_Z

local TARGET_ROOMS = getgenv().FarmMultiChest and 2 or 1

-- ============================
-- BUOC 1: QUET MAP (LƯU LẠI PHÒNG - PHỤC VỤ UNLOCK/COOLDOWN)
-- ============================
local bossRooms = {} 
label.Text = "Dang quet map..."

task.spawn(function()
    local count = 0
    local scanDone = false
    local lastLabelUpdate = tick()

    for x = MIN_X, MAX_X, STEP do
        if scanDone then break end
        for z = MIN_Z, MAX_Z, STEP do
            if scanDone then break end
            count = count + 1

            -- Teleport an toàn có bệ đỡ và chống trọng lực đi theo ma trận
            safeTeleport(Vector3.new(x, SCAN_Y + 28, z))
            task.wait(WAIT_TIME)

            local now = tick()
            if now - lastLabelUpdate >= 0.5 then
                label.Text = string.format(
                    "Dang quet: %d / %d\nX: %.0f  Z: %.0f\nRoom: %d/%d",
                    count, TOTAL_POINTS, x, z, #bossRooms, TARGET_ROOMS)
                lastLabelUpdate = now
            end

            local children = generatedBackrooms:GetChildren()
            for i = 1, #children do
                local room = children[i]
                if room.Name == "GameMastersStage" and room.Parent == generatedBackrooms then
                    local bz = room:FindFirstChild("BREAK_ZONE", true)
                    if bz then
                        local part = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local found = false
                            for j = 1, #bossRooms do
                                if bossRooms[j].room == room then
                                    found = true 
                                    break
                                end
                            end
                            if not found then
                                table.insert(bossRooms, {room = room, pos = part.Position})
                            end
                        end
                    end
                end
            end

            if #bossRooms >= TARGET_ROOMS then
                scanDone = true
                break
            end
        end
    end

    -- Xóa sạch các phòng thừa lặt vặt xung quanh sau khi quét để tiết kiệm RAM tối đa
    print("Quet xong! Dang xoa cac object thua de nhe RAM...")
    pcall(function()
        for _, v in ipairs(generatedBackrooms:GetChildren()) do
            local isBossRoom = false
            for _, bRoom in ipairs(bossRooms) do
                if bRoom.room == v then isBossRoom = true break end
            end
            if not isBossRoom and v.Name ~= "DeepSpawnRoom" then
                v:Destroy()
            end
        end
    end)
    task.wait(1)

    if #bossRooms == 0 then
        platform:Destroy()
        linearVelocity:Destroy()
        attachment:Destroy()
        print("Khong tim thay GameMastersStage nao!")
        label.Text = "Khong tim thay GameMastersStage nao!"
        sendToDiscord("Quet xong", "Khong tim thay GameMastersStage nao!", 16711680, false)
        return
    end

    table.sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)

    label.Text = string.format("Tim thay %d room. Bat dau farm...", #bossRooms)
    
    local firstRoom = bossRooms[1]
    for i = 1, 3 do
        safeTeleport(firstRoom.pos + Vector3.new(0, 5, 0))
        task.wait(0.5)
    end

    -- ============================
    -- LOGIC CÁC HÀM GỐC NGUYÊN BẢN
    -- ============================
    local function isLocked(room) 
        return room:GetAttribute("LockedRoom") == true
    end
    
    local function unlockRoom(room)
        local roomUID = room:GetAttribute("RoomUID")
        if not roomUID then return end
        pcall(function()
            ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient"):FireServer(
                "Backrooms", "AbstractRoom_FireServer", roomUID, "UnlockDoors"
            )
        end)
    end

    local function isChestOnCooldown(r)
        local breakZone = r:FindFirstChild("BREAK_ZONE", true)
        if not breakZone then return false, nil end
        local chestTimer = breakZone:FindFirstChild("ChestTimer", true)
        if not chestTimer then return false, breakZone end
        local stroke = chestTimer:FindFirstChildWhichIsA("UIStroke")
        if not stroke then return false, breakZone end
        return stroke.Enabled, breakZone
    end

    local function getCorners(r, breakZone)
        local positions = {}
        local mainPart = breakZone:IsA("BasePart") and breakZone or breakZone:FindFirstChildWhichIsA("BasePart", true)
        if mainPart then table.insert(positions, mainPart.Position) end
        local spawnPoints = r:FindFirstChild("MiniChestSpawnPoints")
        if spawnPoints then
            for _, v in ipairs(spawnPoints:GetChildren()) do
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                if part then table.insert(positions, part.Position) end
            end
        end
        return positions
    end

    local breakablesContainer = workspace:WaitForChild("__THINGS"):WaitForChild("Breakables")
    local damageRemote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Breakables_PlayerDealDamage")

    local function isBreakableInstance(inst)
        if inst:IsA("BasePart") or inst:IsA("Model") then
            return inst:GetAttribute("BreakableUID") ~= nil
        end
        return false
    end

    task.spawn(function()
        while true do
            if screenClickEnabled then
                local vp = camera.ViewportSize
                vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
                vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
            end
            task.wait(1)
        end
    end)

    -- ============================
    -- HAM FARM ROOM GỐC KẾT HỢP SAFETELEPORT Chống Rớt
    -- ============================
    local function farmRoom(entry, idx, total)
        local room = entry.room
        local bz = room:FindFirstChild("BREAK_ZONE", true)
        if not bz then return false end
        if isLocked(room) then unlockRoom(room) end

        for i = 1, 3 do safeTeleport(entry.pos + Vector3.new(0, 5, 0)) task.wait(0.5) end
        
        label.Text = string.format("Room %d/%d: Dang danh...", idx, total)
        if getgenv().NOTIFY_TARGET_ROOM then
            sendToDiscord(
                "Dang farm GameMastersStage",
                string.format("Room %d/%d\nVi tri: (%.0f, %.0f, %.0f)", idx, total, entry.pos.X, entry.pos.Y, entry.pos.Z),
                65280, false
            )
        end

        local corners = getCorners(room, bz)
        local center = corners[1]
        local miniSpots = {corners[2], corners[3], corners[4], corners[5]}
        local pendingChests = {}
        local processing = false

        local function nearestSpotIndex(pos)
            local bestIdx, bestDist = nil, math.huge
            for i, spot in ipairs(miniSpots) do
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

        -- Lắng nghe rương nhỏ spawn dựa theo logic phòng nguyên bản
        local listenerConn = breakablesContainer.ChildAdded:Connect(function(inst)
            task.defer(function()
                if not isBreakableInstance(inst) then return end
                local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
                if not part then return end
                local idx2, dist = nearestSpotIndex(part.Position)
                if idx2 and dist <= 15 then
                    table.insert(pendingChests, {pos = miniSpots[idx2], inst = inst})
                end
            end)
        end)

        local farmingThisRoom = true
        task.spawn(function()
            while farmingThisRoom do
                local bestInst, bestDist = nil, math.huge
                for _, obj in ipairs(breakablesContainer:GetChildren()) do
                    local uid = obj:GetAttribute("BreakableUID")
                    if uid then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local d = (part.Position - hrp.Position).Magnitude
                            if d <= 15 and d < bestDist then
                                bestDist = d
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
                task.wait(0.1)
            end
        end)

        task.spawn(function()
            while farmingThisRoom do
                if #pendingChests > 0 and not processing then
                    processing = true
                    local chestEntry = table.remove(pendingChests, 1)

                    safeTeleport(chestEntry.pos + Vector3.new(0, 5, 0))
                    label.Text = string.format("Room %d/%d: Dang danh mini chest...", idx, total)

                    while chestEntry.inst and chestEntry.inst.Parent do
                        task.wait(0.2)
                    end

                    processing = false
                else
                    task.wait(0.1)
                end
            end
        end)

        while true do
            local cooldown, _ = isChestOnCooldown(room)
            if cooldown then
                label.Text = string.format("Room %d/%d: Da pha! Chuyen room...", idx, total)
                if getgenv().NOTIFY_TARGET_ROOM then
                    sendToDiscord("Boss da bi danh bay!", string.format("Room %d/%d dang trong thoi gian hoi.", idx, total), 65280, false)
                end
                break
            end

            if #pendingChests == 0 and not processing then 
                safeTeleport(center + Vector3.new(0, 5, 0)) 
                label.Text = string.format("Room %d/%d: Dang danh boss", idx, total)
            end
            task.wait(0.5)
        end
        
        farmingThisRoom = false
        listenerConn:Disconnect()
        return true
    end

    -- ============================
    -- MULTI FARM LOOP (VÒNG LẶP XOAY TUA PHÒNG GỐC)
    -- ============================
    local farmIdx = 1
    while true do
        local entry = bossRooms[farmIdx]
        local onCooldown = isChestOnCooldown(entry.room)

        if onCooldown then
            label.Text = string.format("Room %d/%d: DANG HOI -> chuyen tiep", farmIdx, #bossRooms)
            farmIdx = farmIdx % #bossRooms + 1
            task.wait(0.5)
        else
            farmRoom(entry, farmIdx, #bossRooms)
            farmIdx = farmIdx % #bossRooms + 1
            task.wait(0.5)
        end
    end
end)
