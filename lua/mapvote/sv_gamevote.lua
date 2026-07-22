util.AddNetworkString("RAM_GameVoteStart")
util.AddNetworkString("RAM_GameVoteUpdate")
util.AddNetworkString("RAM_GameVoteCancel")
util.AddNetworkString("RAM_GameVoteOpen")

net.Receive("RAM_GameVoteUpdate", function(len, ply)
    if GameVote.Allow and IsValid(ply) then
        local update_type = net.ReadUInt(3)

        if update_type == Vote.UPDATE_VOTE then
            local game_id = net.ReadUInt(32)

            if GameVote.CurrentModes[game_id] then
                GameVote.Votes[ply:SteamID()] = game_id

                net.Start("RAM_GameVoteUpdate")
                net.WriteUInt(Vote.UPDATE_VOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(game_id, 32)
                net.Broadcast()
            end
        end
    end
end)

function GameVote.Start(length, current, limit, callback)
    current = current or Vote.Config.AllowCurrentMode or false
    length = length or Vote.Config.TimeLimit or 28
    limit = limit or Vote.Config.ModeLimit or 24
    local cooldown = Vote.Config.EnableCooldown or Vote.Config.EnableCooldown == nil and true

    local vote_gamemodes = engine.GetGamemodes()
    local gamemode_count = #vote_gamemodes

    if Vote.Config.Gamemodes ~= nil then
        for k, v in pairs(Vote.Config.Gamemodes) do
            if table.HasValue(vote_gamemodes, k) and not v then
                table.RemoveByValue(vote_gamemodes, k)
            end
        end
    end

    if gamemode_count > 0 then
        net.Start("RAM_GameVoteStart")
        net.WriteUInt(gamemode_count, 32)

        for _, mode in pairs(vote_gamemodes) do
            net.WriteString(mode.name)
        end

        net.WriteUInt(length, 32)
        net.Broadcast()

        GameVote.Allow = true
        GameVote.CurrentModes = vote_gamemodes
        GameVote.Votes = {}

        timer.Create("RAM_GameVote", length, 1, function()
            GameVote.Allow = false
            local gamemode_results = {}

            if GAMEMODE_NAME == "terrortown" then
                timer.Stop("wait2prep")
                timer.Stop("prep2begin")
                timer.Stop("end2prep")
                timer.Stop("winchecker")
            end

            for k, v in pairs(GameVote.Votes) do
                if not gamemode_results[v] then
                    gamemode_results[v] = 0
                end

                for _, v2 in pairs(player.GetAll()) do
                    if v2:SteamID() == k then
                        gamemode_results[v] = gamemode_results[v] + 1
                    end
                end
            end

            local winner = Vote.GetRandomWinningKey(gamemode_results) or 1
            net.Start("RAM_GameVoteUpdate")
            net.WriteUInt(Vote.UPDATE_WIN, 3)
            net.WriteUInt(winner, 32)
            net.Broadcast()

            local mode = GameVote.CurrentModes[winner].name
            RunConsoleCommand("gamemode", mode)

            timer.Simple(4, function()
                if hook.Run("GameVoteChange", map) ~= false then
                    if callback then
                        callback(mode)
                    else
                        MapVote.Start(nil, nil, nil, nil)

                        net.Start("RAM_GameVoteCancel")
                        net.Broadcast()
                    end
                end
            end)
        end)
    end
end

function GameVote.Cancel()
    if GameVote.Allow then
        GameVote.Allow = false

        net.Start("RAM_GameVoteCancel")
        net.Broadcast()

        timer.Remove("RAM_GameVote")
    end
end

local chatCommands = {
    "!vote",
    "/vote",
    "vote",
    "!mapvote",
    "/mapvote",
    "mapvote",
    "!ballot",
    "/ballot",
    "ballot"
}

hook.Add("PlayerSay", "Map Vote Commands", function(ply, text)
    -- Don't use "!" for admin because they are already used elsewhere
    if string.StartWith(text, "!") and ply:IsAdmin() then return end

    if GAMEMODE_NAME ~= "stopitslender" then
        if table.HasValue(chatCommands, string.lower(text)) then
            net.Start("RAM_GameVoteOpen")
            net.Send(ply)
            return ""
        end
    end
end)