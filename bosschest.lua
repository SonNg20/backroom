repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstancingCmds = require(
    ReplicatedStorage.Library.Client.InstancingCmds
)

local FFlags = require(
    ReplicatedStorage.Library.Client.FFlags
)

repeat task.wait() until ReplicatedStorage:FindFirstChild("Library")

local target = FFlags.Get(FFlags.Keys.SideJoinEventTarget)

if target then
    print("Joining:", target)
    InstancingCmds.Enter(target, nil, true, "You are joining the minigame!")
else
    warn("Không tìm thấy SideJoinEventTarget")
end
wait(30)
local container = workspace.__THINGS.__INSTANCE_CONTAINER.Active.Backrooms.GeneratedBackrooms
local spawnRoom = container:FindFirstChild("SpawnRoom")
local player = game:GetService("Players").LocalPlayer
local vim = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera

if spawnRoom then
local origin = spawnRoom:FindFirstChildWhichIsA("BasePart", true)
if origin then

local originPos = origin.Position
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local STEP = 250
-- Pham vi quet tuyet doi (da xac dinh qua nhieu server, SpawnRoom luon o X-4747 Z-1707)
local MIN_X, MAX_X = -6000, -2500
local MIN_Z, MAX_Z = -2500, 800
local SCAN_Y = originPos.Y -- giu cung do cao voi SpawnRoom
local WAIT_TIME = 0.8

-- ============================
-- GUI
-- ============================
if game.CoreGui:FindFirstChild("FarmGUI") then game.CoreGui.FarmGUI:Destroy() end
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "FarmGUI"
sg.ResetOnSpawn = false

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 250, 0, 80)
label.Position = UDim2.new(0, 10, 0, 140)
label.BackgroundColor3 = Color3.fromRGB(20,20,20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0,255,100)
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

-- ============================
-- VUNG AUTO CLICK (hien thi tren man hinh)
-- ============================
local clickZone = Instance.new("Frame", sg)
clickZone.Name = "ClickZone"
clickZone.Size = UDim2.new(0, 60, 0, 60)
clickZone.Position = UDim2.new(0.5, -30, 0.5, -30) -- giua man hinh
clickZone.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
clickZone.BackgroundTransparency = 0.6
clickZone.BorderSizePixel = 0
Instance.new("UICorner", clickZone).CornerRadius = UDim.new(1, 0)

local clickLabel = Instance.new("TextLabel", clickZone)
clickLabel.Size = UDim2.new(1, 0, 1, 0)
clickLabel.BackgroundTransparency = 1
clickLabel.TextColor3 = Color3.new(1,1,1)
clickLabel.Font = Enum.Font.GothamBold
clickLabel.TextSize = 12
clickLabel.Text = "CLICK"

-- ============================
-- RESULT LIST (danh sach MiniBossRoom tim duoc)
-- ============================
local resultFrame = Instance.new("ScrollingFrame", sg)
resultFrame.Size = UDim2.new(0, 250, 0, 180)
resultFrame.Position = UDim2.new(0, 10, 0, 225)
resultFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
resultFrame.BackgroundTransparency = 0.3
resultFrame.BorderSizePixel = 0
resultFrame.ScrollBarThickness = 6
resultFrame.CanvasSize = UDim2.new(0,0,0,0)
Instance.new("UICorner", resultFrame).CornerRadius = UDim.new(0, 8)
local resultLayout = Instance.new("UIListLayout", resultFrame)
resultLayout.Padding = UDim.new(0, 4)

local function addResult(name, pos)
    local btn = Instance.new("TextButton", resultFrame)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(0,150,80)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = name .. "\n" .. string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
    btn.TextWrapped = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        pcall(function()
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        end)
    end)
    resultFrame.CanvasSize = UDim2.new(0, 0, 0, resultLayout.AbsoluteContentSize.Y + 10)
    return btn
end

-- ============================
-- NUT BAT/TAT AUTO CLICK
-- ============================
local autoClickEnabled = true

local toggleBtn = Instance.new("TextButton", sg)
toggleBtn.Size = UDim2.new(0, 100, 0, 28)
toggleBtn.Position = UDim2.new(0, 10, 0, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,180,80)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.Text = "AUTO CLICK: ON"
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

toggleBtn.MouseButton1Click:Connect(function()
    autoClickEnabled = not autoClickEnabled
    if autoClickEnabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0,180,80)
        toggleBtn.Text = "AUTO CLICK: ON"
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
        toggleBtn.Text = "AUTO CLICK: OFF"
    end
end)

-- ============================
-- NUT BAT/TAT QUA TRINH FARM (DANH BOSS)
-- ============================
local farmEnabled = true

local farmToggleBtn = Instance.new("TextButton", sg)
farmToggleBtn.Size = UDim2.new(0, 100, 0, 28)
farmToggleBtn.Position = UDim2.new(0, 120, 0, 50)
farmToggleBtn.BackgroundColor3 = Color3.fromRGB(0,180,80)
farmToggleBtn.TextColor3 = Color3.new(1,1,1)
farmToggleBtn.Font = Enum.Font.GothamBold
farmToggleBtn.TextSize = 11
farmToggleBtn.Text = "FARM: ON"
Instance.new("UICorner", farmToggleBtn).CornerRadius = UDim.new(0, 8)

farmToggleBtn.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        farmToggleBtn.BackgroundColor3 = Color3.fromRGB(0,180,80)
        farmToggleBtn.Text = "FARM: ON"
    else
        farmToggleBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
        farmToggleBtn.Text = "FARM: OFF"
    end
end)

-- ============================
-- ANCHOR HRP (khong roi trong luc quet/tele)
-- ============================
hrp.Anchored = true
local humanoid = char:FindFirstChildOfClass("Humanoid")
if humanoid then
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

-- ============================
-- AUTO CLICK (lien tuc, chay nen, nham vao ClickZone)
-- ============================
task.spawn(function()
    while true do
        if autoClickEnabled then
            local absPos = clickZone.AbsolutePosition
            local absSize = clickZone.AbsoluteSize
            local x = absPos.X + absSize.X / 2
            local y = absPos.Y + absSize.Y / 2
            vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end
        task.wait(1.67)
    end
end)

-- ============================
-- HAM CHECK CHEST TIMER
-- timer.Enabled = true  -> dang hoi (boss da bi danh bay)
-- timer.Enabled = false -> chest san sang de danh
-- ============================
local function isChestOnCooldown(room)
    local bz = room:FindFirstChild("BREAK_ZONE", true)
    if not bz then return false, nil end
    local timer = bz:FindFirstChild("ChestTimer")
    if not timer then return false, bz end
    return timer.Enabled, bz
end

-- ============================
-- HAM CHECK + MO KHOA ROOM (dung attribute + remote)
-- ============================
local function isLocked(room)
    return room:GetAttribute("LockedRoom") == true
end

local function unlockRoom(room)
    local roomUID = room:GetAttribute("RoomUID")
    if not roomUID then return end
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient"):FireServer(
            "Backrooms", "AbstractRoom_FireServer", roomUID, "UnlockDoors"
        )
    end)
end

-- ============================
-- HAM LAY VI TRI 4 MINI CHEST + GIUA (boss chest)
-- ============================
local function getCorners(room, bz, fallbackPos)
    local center = fallbackPos
    if bz then
        local mainPart = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
        if mainPart then
            center = mainPart.Position
        end
    end

    local positions = {center}

    local spawnPoints = room:FindFirstChild("MiniChestSpawnPoints")
    if spawnPoints then
        for _, v in ipairs(spawnPoints:GetChildren()) do
            if v:IsA("BasePart") then
                table.insert(positions, v.Position)
            end
        end
    end

    -- Neu thieu (khong tim thay spawn points), fallback ve center
    while #positions < 5 do
        table.insert(positions, center)
    end

    return positions
end
local bossRooms = {} -- list cac room { room = Model, pos = Vector3 }
local TARGET_ROOMS = 2 -- so phong can tim truoc khi dung quet

task.spawn(function()
    local totalPoints = 0
    for x = MIN_X, MAX_X, STEP do
        for z = MIN_Z, MAX_Z, STEP do
            totalPoints = totalPoints + 1
        end
    end

    local count = 0
    local scanDone = false
    for x = MIN_X, MAX_X, STEP do
        if scanDone then break end
        for z = MIN_Z, MAX_Z, STEP do
            if scanDone then break end
            count = count + 1
            local pos = Vector3.new(x, SCAN_Y, z)
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 50, 0))
            task.wait(WAIT_TIME)

            label.Text = string.format("Dang quet: %d / %d\nX: %.0f  Z: %.0f\nMiniBoss found: %d/%d",
                count, totalPoints, pos.X, pos.Z, #bossRooms, TARGET_ROOMS)

            for _, room in ipairs(container:GetChildren()) do
                if room.Name:lower():find("boss") then
                    local bz = room:FindFirstChild("BREAK_ZONE", true)
                    if bz then
                        local part = bz:IsA("BasePart") and bz or bz:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local already = false
                            for _, r in ipairs(bossRooms) do
                                if r.room == room then already = true break end
                            end
                            if not already then
                                local btn = addResult(room.Name, part.Position)
                                table.insert(bossRooms, {room = room, pos = part.Position, btn = btn})
                            end
                        end
                    end
                end
            end

            if #bossRooms >= TARGET_ROOMS then
                scanDone = true
            end
        end
    end

    if #bossRooms == 0 then
        hrp.Anchored = false
        label.Text = "Khong tim thay MiniBossRoom nao!"
        return
    end

    -- Sap xep theo khoang cach gan spawn nhat
    table.sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)

    label.Text = string.format("Quet xong! Tim thay %d MiniBossRoom\nBat dau farm...", #bossRooms)

    -- An vung CLICK (van giu chuc nang auto click)
    clickZone.BackgroundTransparency = 1
    clickLabel.TextTransparency = 1

    -- Unanchor de di chuyen binh thuong (farm loop van tele bang CFrame duoc)
    hrp.Anchored = false
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    task.wait(2)

    -- ============================
    -- BUOC 2: FARM LOOP (xoay vong qua tat ca room tim duoc)
    -- ============================
    local idx = 1

    while true do
        if not farmEnabled then
            label.Text = "FARM DA TAT\n(Bam FARM: ON de tiep tuc)"
            task.wait(0.5)
            continue
        end

        local entry = bossRooms[idx]
        local room = entry.room
        local onCooldown, bz = isChestOnCooldown(room)

        if onCooldown then
            -- chest dang hoi -> chuyen qua room ke tiep
            label.Text = string.format("Room %d/%d: DANG HOI -> chuyen tiep", idx, #bossRooms)
            idx = idx % #bossRooms + 1
            task.wait(0.5)
        else
            -- chest san sang -> tele toi va danh
            label.Text = string.format("Room %d/%d: TELE va DANH chest", idx, #bossRooms)
            if entry.btn then
                entry.btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            end
            for i = 1, 3 do
                hrp.CFrame = CFrame.new(entry.pos + Vector3.new(0, 5, 0))
                task.wait(1)
            end

            -- Lay lai bz sau khi room da load (bz truoc do co the la nil do streaming)
            local _, bzFresh = isChestOnCooldown(room)
            bz = bzFresh or bz

            -- ============================
            -- PHASE MO KHOA (neu room dang bi khoa)
            -- ============================
            if isLocked(room) then
                label.Text = string.format("Room %d/%d: DANG MO KHOA...", idx, #bossRooms)
                local unlockStart = tick()
                while isLocked(room) do
                    if not farmEnabled then
                        label.Text = "FARM DA TAT\n(Bam FARM: ON de tiep tuc)"
                        task.wait(0.5)
                        continue
                    end
                    unlockRoom(room)
                    task.wait(1)
                    if tick() - unlockStart > 30 then
                        label.Text = string.format("Room %d/%d: Mo khoa qua lau, bo qua", idx, #bossRooms)
                        break
                    end
                end
            end

            -- Danh cho den khi ChestTimer bat dau hoi (boss bi danh bay)
            -- KHONG CO TIMEOUT: chi chuyen room khi chest timer thuc su bat dau dem
            -- Lay lai bz lan cuoi (dam bao dung room dang xu ly, tranh tele nham)
            local _, bzFinal = isChestOnCooldown(room)
            bz = bzFinal or bz
            local corners = getCorners(room, bz, entry.pos)
            local center = corners[1]
            local miniSpots = {corners[2], corners[3], corners[4], corners[5]}
            local lastCornerCheck = tick()

            while true do
                if not farmEnabled then
                    label.Text = "FARM DA TAT\n(Bam FARM: ON de tiep tuc)"
                    task.wait(0.5)
                    continue
                end

                local cooldown, _ = isChestOnCooldown(room)
                if cooldown then
                    label.Text = string.format("Room %d/%d: Da pha! Chuyen room...", idx, #bossRooms)
                    if entry.btn then
                        entry.btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                    end
                    break
                end

                if tick() - lastCornerCheck >= 12 then
                    -- Ghe qua 4 goc de vot mini chest
                    label.Text = string.format("Room %d/%d: Kiem tra mini chest...", idx, #bossRooms)
                    for _, spot in ipairs(miniSpots) do
                        if spot then
                            pcall(function()
                                hrp.CFrame = CFrame.new(spot + Vector3.new(0, 5, 0))
                            end)
                            task.wait(8.5)
                        end
                    end
                    lastCornerCheck = tick()
                else
                    -- Dung giua danh boss
                    if center then
                        pcall(function()
                            hrp.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
                        end)
                    end
                    label.Text = string.format("Room %d/%d: Dang danh boss", idx, #bossRooms)
                    task.wait(1)
                end
            end

            idx = idx % #bossRooms + 1
            task.wait(0.5)
        end
    end
end)

end -- origin
end -- spawnRoom
