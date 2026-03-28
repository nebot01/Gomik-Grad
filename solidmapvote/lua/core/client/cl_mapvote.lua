-- "addons\\solidmapvote\\lua\\core\\client\\cl_mapvote.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal

SolidMapVote.isOpen = SolidMapVote.isOpen or false
SolidMapVote.isNominating = SolidMapVote.isNominating or false

-- Override open function to use custom UI
local originalOpen = SolidMapVote.open
function SolidMapVote.open( maps )
    -- Don't use default UI, custom UI will be opened via network
    -- This is kept for backwards compatibility
end

function SolidMapVote.openCustom( maps )
    SolidMapVote.isOpen = true
    gui.EnableScreenClicker( SolidMapVote.isOpen )

    SolidMapVote.Menu = vgui.Create( 'SolidMapVote' )
    SolidMapVote.Menu:SetMaps( maps )
end

function SolidMapVote.close()
    SolidMapVote.CloseCustomUI()
end

function SolidMapVote.GetMapConfigInfo( map )
    for _, mapData in pairs( SolidMapVote[ 'Config' ][ 'Specific Maps' ] ) do
        if map == mapData.filename then
            return mapData
        end
    end

    local fallbackImage = SolidMapVote[ 'Config' ][ 'Missing Image' ]
    local localMapMaterial = "maps/" .. map
    local mapMat = Material(localMapMaterial)
    if mapMat and not mapMat:IsError() then
        fallbackImage = localMapMaterial
    end

    return {
        filename = map,
        displayname = string.Replace( map, '_', ' ' ),
        image = fallbackImage,
        width = SolidMapVote[ 'Config' ][ 'Missing Image Size' ].width,
        height = SolidMapVote[ 'Config' ][ 'Missing Image Size' ].height
    }
end

hook.Add( 'PlayerBindPress', 'SolidMapVote.StopMovement', function( ply, bind )
    if ValidPanel( SolidMapVote.Menu ) and
       SolidMapVote.Menu:IsVisible() and
       bind != 'solidmapvote_test' and
       (bind != 'messagemode' and SolidMapVote[ 'Config' ][ 'Enable Chat' ]) and
       (bind != 'messagemode2' and SolidMapVote[ 'Config' ][ 'Enable Chat' ]) and
       (bind != '+voicerecord' and SolidMapVote[ 'Config' ][ 'Enable Voice' ])
    then
        return true
    end
end )

concommand.Add( 'solidmapvote_nomination_menu', function()
    if SolidMapVote.isOpen then return end
    if SolidMapVote.isNominating then
        if ValidPanel( SolidMapVote.Nominate ) then
            SolidMapVote.Nominate:Remove()
            SolidMapVote.isNominating = false
            gui.EnableScreenClicker( SolidMapVote.isNominating )
        end

        return
    end

    SolidMapVote.isNominating = true
    gui.EnableScreenClicker( SolidMapVote.isNominating )
    SolidMapVote.Nominate = vgui.Create( 'SolidMapVoteNomination' )
end )

concommand.Add( 'solidmapvote_close_ui', function()
    SolidMapVote.close()
end )
