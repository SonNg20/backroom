local IGNORE_FILE = "ServerHop.txt"
local HOUR = 3600

local Module = {}

local HttpService, TeleportService = game:GetService"HttpService", game:GetService"TeleportService"

local function GET()
    if not isfile(IGNORE_FILE) then return {} end
    local list = {}
    local now = os.time()
    for _, line in next, readfile(IGNORE_FILE):split("\n") do
        local pmo, ts = line:match("([^|]+)|?(%d*)")
        ts = tonumber(ts) or 0
        if now - ts < HOUR then list[pmo] = ts end
    end
    return list
end

local function Update(List)
    local sybau = {}
    for ts, pmo in next, List do
        table.insert(sybau, ts .. "|" .. pmo)
    end
    writefile(IGNORE_FILE, table.concat(sybau, "\n"))
end

local IgnoredServers = GET()

function Module:GetServers(Sort)
    Sort = Sort or { ping = true, fps = false, asc = false }
    
    local cursor = ""
    while true do
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(`https://games.roblox.com/v1/games/{game.PlaceId}/servers/Public?limit=100&sortOrder={(Sort.asc and "Asc" or "Desc")}&excludeFullGames=true&cursor={cursor}`))
        end)
        
        if not success or not result or not result.data then error("server error (not success or no result or no data)") end

        local ServersList = result.data

        table.sort(ServersList, function(a, b)
            if Sort.ping and Sort.fps then
                return a.ping == b.ping and a.fps > b.fps or a.ping < b.ping
            elseif Sort.ping then
                return a.ping < b.ping
            elseif Sort.fps then
                return a.fps > b.fps
            end
        end)

        for _, Server in next, ServersList do
            if not IgnoredServers[Server.id] then
                IgnoredServers[Server.id] = os.time()
                Update(IgnoredServers)

                return TeleportService:TeleportToPlaceInstance(game.PlaceId, Server.id, game:GetService("Players").LocalPlayer)
            end
        end

        assert(result.nextPageCursor, "No server found.")

        cursor = result.nextPageCursor
    end
end

return Module
