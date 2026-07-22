GameVote.EndTime = 0
GameVote.Panel = false

local defaultMapThumbnail = "materials/vgui/mapvote/missing.png"
local function GetGamemodeThumbnail(name)
	if file.Exists("gamemodes/" .. name .. "/icon24.png", "GAME") then
		return "gamemodes/" .. name .. "/icon24.png"
    else
        return defaultMapThumbnail
	end
end

net.Receive("RAM_GameVoteStart", function()
    GameVote.CurrentModes = {}
    GameVote.Allow = true
    GameVote.Votes = {}

    local amt = net.ReadUInt(32)
    for _ = 1, amt do
        local mode = net.ReadString()

        GameVote.CurrentModes[#GameVote.CurrentModes + 1] = {name = mode, material = GetGamemodeThumbnail(mode)}
    end

    if IsValid(GameVote.Panel) then
        GameVote.Panel:Remove()
    end

    GameVote.Panel = vgui.Create("RAM_VoteScreen")

    GameVote.Panel.voteType = "gamemode"
    GameVote.Panel:SetVoteIcons(GameVote.CurrentModes)
    
    GameVote.Panel.startTime = IsValid(MapVote.Panel) and MapVote.Panel.startTime or SysTime()
    GameVote.Panel.endTime = CurTime() + net.ReadUInt(32)
end)

net.Receive("RAM_GameVoteUpdate", function()
    local update_type = net.ReadUInt(3)
    if update_type == Vote.UPDATE_VOTE then
        local ply = net.ReadEntity()

        if IsValid(ply) then
            local game_id = net.ReadUInt(32)
            GameVote.Votes[ply:SteamID()] = game_id

            if IsValid(GameVote.Panel) then
                GameVote.Panel:AddVoter(ply)
            end
        end
    elseif update_type == Vote.UPDATE_WIN and IsValid(GameVote.Panel) then
        GameVote.Panel:Flash(net.ReadUInt(32))
    end
end)

net.Receive("RAM_GameVoteCancel", function()
    if IsValid(GameVote.Panel) then
        GameVote.Panel:Remove()
    end
end)

local function OpenPanel()
    if IsValid(GameVote.Panel) then
        GameVote.Panel:SetVisible(true)
    end
end

concommand.Add("mapvote_open", OpenPanel)
net.Receive("RAM_GameVoteOpen", function()
    OpenPanel()
end)