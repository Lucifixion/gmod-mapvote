local CATEGORY_NAME = "GameVote"
------------------------------ VoteMap ------------------------------
function AMB_gamevote( calling_ply, votetime, should_cancel )
    if not should_cancel then
        GameVote.Start(votetime, nil, nil)
        ulx.fancyLogAdmin( calling_ply, "#A called a game vote!" )
    else
        GameVote.Cancel()
        ulx.fancyLogAdmin( calling_ply, "#A canceled the game vote" )
    end
end

local gamevotecmd = ulx.command( CATEGORY_NAME, "ulx gamevote", AMB_gamevote, "!gamevote" )
gamevotecmd:addParam{ type=ULib.cmds.NumArg, min=15, default=25, hint="time", ULib.cmds.optional, ULib.cmds.round }
gamevotecmd:addParam{ type=ULib.cmds.BoolArg, invisible=true }
gamevotecmd:defaultAccess( ULib.ACCESS_ADMIN )
gamevotecmd:help( "Invokes the game vote logic" )
gamevotecmd:setOpposite( "ulx ungamevote", {_, _, true}, "!ungamevote" )