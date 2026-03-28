-- "addons\\solidmapvote\\lua\\core\\client\\cl_net.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local function ConvertVotesForUI(rawVotes)
    local converted = {}
    for steamId, map in pairs(rawVotes) do
        converted[map] = (converted[map] or 0) + 1
    end
    return converted
end

net.Receive( 'SolidMapVote.start', function( len )
    local maps = net.ReadTable()
    
    surface.PlaySound("homigrad/vgui/menu_accept.wav")

    if CLIENT then
        sound.PlayFile("sound/homigrad/golosovanie.wav", "noplay", function(station)
            if IsValid(station) then
                station:Play()
                station:SetVolume(0.5)
                SolidMapVote.RTVMusic = station
            end
        end)
    end
    

    local cfg = SolidMapVote['Config'] or SolidMapVote.Config or {}
    local voteLen = tonumber(cfg['Length']) or 25
    local endTime = CurTime() + voteLen
    SolidMapVote.OpenCustomUI(maps, {}, endTime)
    SolidMapVote.isOpen = true
end )

net.Receive( 'SolidMapVote.sendVotes', function( len )
    local rawVotes = net.ReadTable()
    if table.Count( rawVotes ) < 1 then return end
    
    local uiVotes = ConvertVotesForUI(rawVotes)
    
    SolidMapVote.UpdateCustomVotes(uiVotes)
    
    hook.Run( 'SolidMapVote.UpdateVotes', rawVotes )
end )

net.Receive( 'SolidMapVote.sendNominations', function( len )
    local nominations = net.ReadTable()
    if table.Count( nominations ) < 1 then return end

    hook.Run( 'SolidMapVote.UpdateNominations', nominations )
end )

net.Receive( 'SolidMapVote.sendMessage', function( len )
    local tblMsg = net.ReadTable()
    chat.AddText( unpack( tblMsg ) )
end )

net.Receive( 'SolidMapVote.end', function( len )
    local winningMaps = net.ReadTable()
    local realWinner = net.ReadString()
    local fixedWinner = net.ReadString()
    
    if SolidMapVote.RTVMusic then
        SolidMapVote.RTVMusic:Stop()
        SolidMapVote.RTVMusic = nil
    end
    
    SolidMapVote.winningMap = fixedWinner ~= "" and fixedWinner or realWinner
    SolidMapVote.realWinner = realWinner
    
    surface.PlaySound("homigrad/vgui/item_drop6_ancient.wav")
    
    local postVoteLength = SolidMapVote['Config']['Post Vote Length'] or 5
    timer.Simple(postVoteLength, function()
        SolidMapVote.CloseCustomUI()
    end)
    
    hook.Run( 'SolidMapVote.WinningMaps', winningMaps, realWinner, fixedWinner )
end )

net.Receive( 'SolidMapVote.sendPlayCounts', function( len )
    local playCounts = net.ReadTable()

    hook.Run( 'SolidMapVote.MapPlayCounts', playCounts )
end )

net.Receive( 'SolidMapVote.sendMapPool', function( len )
    local mapPool = net.ReadTable()

    hook.Run( 'SolidMapVote.UpdateMapPool', mapPool )
end )
