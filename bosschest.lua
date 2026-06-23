-- ============================
-- CONFIG
-- ============================
getgenv().WebhookURL ="https://discord.com/api/webhooks/1516774421787054262/kpEu6j9Iz_Zi01XN_mRvQRY-pvIkygxAiZypxCcdIRfWqpEV12BDG6vtgddMB_Nr1_os"
getgenv().DiscordUserID ="989895037406044200"
getgenv().NOTIFY_TARGET_ROOM = false
getgenv().NOTIFY_HUGE_TITANIC = true 

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

-- Hàm dịch chuyển an toàn
local function safeTeleport(pos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if hrp and pos then
        hrp.CFrame = CFrame_new(Vector3_new(pos.X, pos.Y + 2.5, pos.Z))
        
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
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ============================
-- GUI
-- ============================
if game.CoreGui:FindFirstChild("ScanGUI") then game.CoreGui.ScanGUI:Destroy() end
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ScanGUI"
sg.ResetOnSpawn = false

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 280, 0, 160)
label.Position = UDim2.new(0, 10, 0, 140)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.Font = Enum.Font.Code
label.TextSize = 11
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
-- PHẦN QUÉT & KHỞI TẠO TOÀN BỘ BOSS TRÊN MAP
-- ============================
local bossRooms = {}

hrp.Anchored = true
label.Text = "Dang quet tim boss..."

task_spawn(function()
    local Breakables = thingsContainer:WaitForChild("Breakables")
    local bossesCount = 0
    
    task_wait(1)

    -- Quét toàn bộ vật thể đập phá đang có để lọc Boss
    for _, breakable in ipairs(Breakables:GetChildren()) do
        if breakable:IsA("Model") and breakable:GetAttribute("BreakableID") == "Daydream Mimic Boss2" then
            bossesCount = bossesCount + 1
            
            local part = breakable:IsA("BasePart") and breakable or breakable:FindFirstChildWhichIsA("BasePart", true)
            if part then
                -- Ánh xạ Boss thành Room mà không giới hạn số lượng target
                table_insert(bossRooms, {
                    room = breakable, 
                    pos = part.Position, 
                    unlocked = true, 
                    corners = {part.Position, part.Position, part.Position, part.Position, part.Position}
                })
            end
        end
    end

    if bossesCount >= 3 then
        print("3 or more bosses detected:", bossesCount)
    end

    if #bossRooms == 0 then
        hrp.Anchored = false
        label.Text = "Khong tim thay Daydream Mimic Boss2 nao!"
        return
    end

    -- Sắp xếp phòng chứa Boss theo khoảng cách từ gần đến xa
    table_sort(bossRooms, function(a, b)
        return (a.pos - originPos).Magnitude < (b.pos - originPos).Magnitude
    end)

    hrp.Anchored = false

    -- ============================
    -- HÀM KIỂM TRA TRẠNG THÁI BOSS
    -- ============================
    local function isChestOnCooldown(room)
        if not room or not room.Parent then 
            return true, nil 
        end
        return false, room
    end

    -- HÀM CẬP NHẬT TRẠNG THÁI UI TỰ ĐỘNG THEO TỔNG SỐ BOSS QUÉT ĐƯỢC
    local function updateStatusUI(currentAction)
        local str = string_format("Status: %s\n", currentAction)
        str = str .. "-----------------------------\n"
        for i, entry in ipairs(bossRooms) do
            local cooldown = isChestOnCooldown(entry.room)
            local statusText = cooldown and "Da Chet" or "San Sang"
            str = str .. string_format("room%d: (%.0f, %.0f, %.0f): %s\n", i, entry.pos.X, entry.pos.Y, entry.pos.Z, statusText)
        end
        label.Text = str
    end

    local function isLocked(room)
        return false
    end

    local function unlockRoom(room)
        return
    end

    local function getCorners(r, breakZone)
        local positions = {r:IsA("BasePart") and r.Position or r:FindFirstChildWhichIsA("BasePart", true).Position}
        return positions
    end

    local breakablesContainer = thingsContainer:WaitForChild("Breakables")
    local networkFolder = ReplicatedStorage:WaitForChild("Network", 15)
    local damageRemote = networkFolder:WaitForChild("Breakables_PlayerDealDamage")

    local function isBreakableInstance(inst)
        if inst:IsA("BasePart") or inst:IsA("Model") then
            return inst:GetAttribute("BreakableUID") ~= nil
        end
        return false
    end

    -- Vòng lặp Screen Clicker chạy nền
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

    -- Auto Clicker đập các vật thể xung quanh nhân vật trong bán kính 15 studs
    local farmingThisRoom = true
    task_spawn(function()
        while true do
            if farmingThisRoom then
                local bestInst, bestDist = nil, math.huge
                local breakables = breakablesContainer:GetChildren()
                for i = 1, #breakables do
                    local obj = breakables[i]
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
            end
            task_wait(0.1)
        end
    end)

    -- ============================
    -- VÒNG LẶP FARM CHẠY HẾT TOÀN BỘ BOSS QUÉT ĐƯỢC
    -- ============================
    local idx = 1
    local numRooms = #bossRooms 

    while true do
        local entry = bossRooms[idx]
        local room = entry.room
        local onCooldown, bz = isChestOnCooldown(room)

        if onCooldown then
            updateStatusUI(string_format("Room %d/%d: DA CHET -> chuyen tiep", idx, numRooms))
            idx = idx % numRooms + 1 
            task_wait(0.5)
            continue
        end

        updateStatusUI(string_format("Room %d/%d: TELE va DIET BOSS", idx, numRooms))

        for i = 1, 3 do
            safeTeleport(entry.pos)
            task_wait(0.5)
        end

        if getgenv().NOTIFY_TARGET_ROOM then
            sendToDiscord(
                "Dang farm Daydream Mimic Boss2",
                string_format("Room %d/%d\nVi tri: (%.0f, %.0f, %.0f)",
                    idx, numRooms, entry.pos.X, entry.pos.Y, entry.pos.Z),
                65280, false
            )
        end

        local center = entry.pos
        farmingThisRoom = true

        -- Vòng lặp liên tục đứng tại Boss để farm cho đến khi biến mất
        while true do
            local cooldown = isChestOnCooldown(room)
            if cooldown then
                updateStatusUI(string_format("Room %d/%d: Da tieu diet! Chuyen room...", idx, numRooms))
                break
            end

            safeTeleport(center)
            updateStatusUI(string_format("Room %d/%d: Dang danh Boss", idx, numRooms))
            task_wait(0.5)
        end

        farmingThisRoom = false

        idx = idx % numRooms + 1
        task_wait(0.5)
    end
end)
