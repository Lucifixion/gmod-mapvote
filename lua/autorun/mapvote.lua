Vote = {}
Vote.Config = {}

MapVote = {}
GameVote = {}

--Default Config
MapVoteConfigDefault = {
    MapLimit = 24,
    ModeLimit = 24,
    TimeLimit = 28,
    AllowCurrentMap = false,
    AllowCurrentMode = false,
    AllowRandom = false,
    EnableCooldown = true,
    MapsBeforeRevote = 3,
    RTVPlayerCount = 3,
    MapPrefixes = {"ttt_"},
    AdditionalMaps = {
        murder = ""
    },
    Gamemodes = {
        murder = true
    },
    MapConfigs = {}
}
--Default Config

local enableGamemodeVote = CreateConVar("mapvote_enable_game_vote", "0", FCVAR_ARCHIVE)

hook.Add("Initialize", "MapVoteConfigSetup", function()
    if not file.Exists("mapvote", "DATA") then
        file.CreateDir("mapvote")
    end
    if not file.Exists("mapvote/config.txt", "DATA") then
        file.Write("mapvote/config.txt", util.TableToJSON(MapVoteConfigDefault, true))
    else
        Vote.Config = util.JSONToTable(file.Read("mapvote/config.txt", "DATA"))
        if not Vote.Config then
            ErrorNoHalt("Failed to read mapvote/config.txt! Using default settings...")
            Vote.Config = MapVoteConfigDefault
        end
    end

    
    local activeGamemode = engine.ActiveGamemode()
    if SERVER and activeGamemode == "prop_hunt" then // Prop Hunt Enhanced has its own copy of this map vote, fuck you.
        include("autoload/mapvote.lua")
    elseif activeGamemode == "thehiddenirisedition" then // Hidden iris edition is awful, fuck you also.
        function VOTING:StartMapVoting()
            MapVote.Start(nil, nil, nil, nil)
        end
    end
end)

MapVote.CurrentMaps = {}
MapVote.Votes = {}

MapVote.Allow = false

Vote.UPDATE_VOTE = 1
Vote.UPDATE_WIN = 3

function Vote.GetRandomWinningKey( tab )
    if true then return table.GetWinningKey(tab) end

	local highest = -math.huge
	local winners = {}

	for k, v in pairs( tab ) do
		if v > highest then
            winners = {}
			table.Add(winners, k)
			highest = v
        elseif v == highest then
            table.Add(winners, k)
		end
	end

	return winners[math.random(#winners)]
end

MapVote.RandomPlaceholder = "#MapVoteRandom#"

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("mapvote/cl_mapvote.lua")
    AddCSLuaFile("mapvote/cl_gamevote.lua")
    AddCSLuaFile("mapvote/cl_votemenu.lua")

    include("mapvote/sv_mapvote.lua")
    include("mapvote/sv_gamevote.lua")
    include("mapvote/rtv.lua")
else
    include("mapvote/cl_mapvote.lua")
    include("mapvote/cl_gamevote.lua")
    include("mapvote/cl_votemenu.lua")
end
