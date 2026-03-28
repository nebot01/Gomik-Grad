-- "addons\\solidmapvote\\lua\\vgui\\solidmapvotenomination.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal

local PANEL = {}

function PANEL:Init()
    self.mapPool = {}
    self.nominations = {}

    self:SetPos( 0, 0 )
    self:SetSize( ScrW(), ScrH() )

    self:Hooks()
    RunConsoleCommand( 'solidmapvote_request_mappool' )
    RunConsoleCommand( 'solidmapvote_request_nominations' )

    self.menu = vgui.Create( 'SolidMapVoteNominationMenu', self )
end

function PANEL:PerformLayout( w, h )
    local wide, tall = w*0.3, h*0.6

    self.menu:SetSize( wide, tall )
    self.menu:SetPos( w*0.5 - wide*0.5, h*0.5 - tall*0.5 )
end

function PANEL:Hooks()
    hook.Add( 'SolidMapVote.UpdateNominations', 'SolidMapVote.NominationsMenu', function( nominations )
        self.nominations = nominations
        self.menu:SetNominations( self.nominations )
    end )

    hook.Add( 'SolidMapVote.UpdateMapPool', 'SolidMapVote.NominationsMapPool', function( mapPool )
        self.mapPool = mapPool
        self.menu:SetMapPool( self.mapPool )
    end )
end

function PANEL:OnRemove()
    hook.Remove( 'SolidMapVote.UpdateNominations', 'SolidMapVote.NominationsMenu' )
    hook.Remove( 'SolidMapVote.UpdateMapPool', 'SolidMapVote.NominationsMapPool' )
end

function PANEL:Paint( w, h )
    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
end

vgui.Register( 'SolidMapVoteNomination', PANEL )
