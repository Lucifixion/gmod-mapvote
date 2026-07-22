surface.CreateFont("RAM_VoteFont", {
    font = "Trebuchet MS",
    size = 19,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("RAM_VoteFontCountdown", {
    font = GAMEMODE_DEFAULT_UI_FONT or "Tahoma",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("RAM_VoteSysButton", {
    font = "Marlett",
    size = 13,
    weight = 0,
    symbol = true
})

MapVote.EndTime = 0
MapVote.Panel = false

local defaultMapThumbnail = "materials/vgui/mapvote/missing.png"
local randomMapThumbnail = "materials/vgui/mapvote/random.png"
local function GetMapThumbnail(name)
    if file.Exists("maps/thumb/" .. name .. ".png", "GAME") then
        return "maps/thumb/" .. name .. ".png"
    elseif file.Exists("maps/" .. name .. ".png", "GAME") then
        return "maps/" .. name .. ".png"
    elseif file.Exists("map_thumbnails/maps/thumb/" .. name .. ".png", "DATA") then
        return "data/map_thumbnails/maps/thumb/" .. name .. ".png"
    elseif name == MapVote.RandomPlaceholder then
        return randomMapThumbnail
    else
        return defaultMapThumbnail
    end
end

net.Receive("RAM_MapVoteStart", function()
    MapVote.CurrentMaps = {}
    MapVote.Allow = true
    MapVote.Votes = {}

    local amt = net.ReadUInt(32)
    for _ = 1, amt do
        local map = net.ReadString()

        MapVote.CurrentMaps[#MapVote.CurrentMaps + 1] = {name = map, material = GetMapThumbnail(map)}
    end

    if IsValid(MapVote.Panel) then
        MapVote.Panel:Remove()
    end

    MapVote.Panel = vgui.Create("RAM_VoteScreen")

    MapVote.Panel.voteType = "map"
    MapVote.Panel:SetVoteIcons(MapVote.CurrentMaps)

    MapVote.Panel.startTime = IsValid(GameVote.Panel) and GameVote.Panel.startTime or SysTime()
    MapVote.Panel.endTime = CurTime() + net.ReadUInt(32)
end)

net.Receive("RAM_MapVoteUpdate", function()
    local update_type = net.ReadUInt(3)
    if update_type == Vote.UPDATE_VOTE then
        local ply = net.ReadEntity()

        if IsValid(ply) then
            local map_id = net.ReadUInt(32)
            MapVote.Votes[ply:SteamID()] = map_id

            if IsValid(MapVote.Panel) then
                MapVote.Panel:AddVoter(ply)
            end
        end
    elseif update_type == Vote.UPDATE_WIN and IsValid(MapVote.Panel) then
        MapVote.Panel:Flash(net.ReadUInt(32))
    end
end)

net.Receive("RAM_MapVoteCancel", function()
    if IsValid(MapVote.Panel) then
        MapVote.Panel:Remove()
    end
end)

-- Map icon download logic adapted from PAM Automatic Map Icon Downloader
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2812947175

local mapAddons = {}
local function DownloadMapIcons(map_name)
    local foundMap = nil
    for index, map in ipairs(mapAddons) do
        if string.find(map.title, map_name, 1, true) or
            string.find(map.file, map_name, 1, true) or
            string.find(map_name, map.title, 1, true) then
            foundMap = map.wsid;
            break
        else
            local sanstring = string.match(map_name, "_(.*)")
            if sanstring == nil then
                continue
            end
            sanstring = string.sub(string.gsub(sanstring, "_", ""), 1, 5)
            if string.find(map.title, sanstring, 1, true) then
                foundMap = map.wsid;
                break
            end
        end
    end

    -- Sanity check
    if not foundMap then return end

    -- Download the preview image from the found map's workshop page
    steamworks.FileInfo(foundMap, function(result)
        -- Sanity check
        if not result or not result.previewid then return end

        steamworks.Download(result.previewid, true, function(name)
            -- Sanity check
            if not name then return end

            if not file.Exists("map_thumbnails/maps/thumb/" .. map_name .. ".png", "DATA") then
                local fileData = file.Read(name, "GAME");
                -- Sanity check
                if not fileData then return end

                file.Write("map_thumbnails/maps/thumb/" .. map_name .. ".png", fileData);
            end
        end)
    end)
end

local downloadMissingMapIcons = CreateClientConVar("mapvote_download_missing_icons",  "1", true, false, "Whether the addon should try to download missing map icons from the workshop", 0, 1)
hook.Add("Initialize", "MapVote_MissingIcons_Initialize", function()
    if not downloadMissingMapIcons:GetBool() then return end

    -- Use the same storage path that the source PAM icon downloader does so we don't duplicate
    if not file.IsDir("map_thumbnails/maps/thumb", "DATA") then
        file.CreateDir("map_thumbnails/maps/thumb")
    end

    -- Find all addons with "map" in the tags
    for index, value in ipairs(engine.GetAddons()) do
        if string.find(string.lower(value.tags), "map") then
            value.title = string.lower(value.title)
            value.file = string.lower(value.file)
            table.insert(mapAddons, value)
        end
    end

    -- Find all maps that don't have a thumbnail in any path we check and try to download one
    local allMaps = file.Find("maps/*.bsp", "GAME")
    for index, map_name in ipairs(allMaps) do
        map_name = string.StripExtension(map_name)

        if GetMapThumbnail(map_name) == defaultMapThumbnail then
            DownloadMapIcons(map_name)
        end
    end
end)

local function OpenPanel()
    if IsValid(MapVote.Panel) then
        MapVote.Panel:SetVisible(true)
    end
end

concommand.Add("mapvote_open", OpenPanel)
net.Receive("RAM_MapVoteOpen", function()
    OpenPanel()
end)