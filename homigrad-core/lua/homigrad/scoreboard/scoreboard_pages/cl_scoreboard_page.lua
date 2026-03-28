-- "addons\\homigrad-core\\lua\\homigrad\\scoreboard\\scoreboard_pages\\cl_scoreboard_page.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
include("cl_steamframes.lua")

local MutedPlayers = {}
local mute_death = false
local mute_all = false
local needSave = false
local open = false
local open_gavno = 1
local panelka = nil

local FrameCache = {}

if IsValid(HG_FrameSanctuary) then HG_FrameSanctuary:Remove() end
HG_FrameSanctuary = vgui.Create("DPanel")
HG_FrameSanctuary:SetSize(0, 0)
HG_FrameSanctuary:SetVisible(true)
HG_FrameSanctuary:SetMouseInputEnabled(false) 
HG_FrameSanctuary:SetKeyboardInputEnabled(false)
HG_FrameSanctuary:SetDrawBackground(false)

local ugc = {
    ["owner"] = Color(46,126,231),
    ["superadmin"] = Color(255,0,0),
    ["dsuperadmin"] = Color(46, 82, 10),
    ["intern"] = Color(51, 255, 0),
    ["admin"] = Color(41, 171, 24),
    ["dadmin"] = Color(41, 171, 24),
    ["piar_agent"] = Color(255,77,0),
    ["operator"] = Color(0,119,255),
    ["doperator"] = Color(0,119,255),
    ["megasponsor"] = Color(255, 170, 0)
}

local ug_names = {
    ["owner"] = "Владелец",
    ["superadmin"] = "SuperAdmin",
    ["dsuperadmin"] = "DSuperAdmin",
    ["intern"] = "Intern",
    ["admin"] = "Admin",
    ["dadmin"] = "DAdmin",
    ["piar_agent"] = "Пиар-Агент",
    ["operator"] = "Operator",
    ["doperator"] = "DOperator",
    ["megasponsor"] = "MegaSponsor"
} //такие название лучше!!! я ещьо сделаю чтобы у владелецев и мб суперамдинов был переливающиеся ники типо ргб // после этого тупикрупик стал фурри вроде

local playerIterator = player.Iterator
local AliveColor = Color(0,255,0,90)
local DeadColor = Color(255,0,0,90)
local SpecColor = Color(179,179,179,90)

function CheckPlyStatus(ply)
    if ply:Team() == 1002 then return SpecColor,hg.GetPhrase("spectating") end
    if TableRound and TableRound().CanSeeAlive then
        return (ply:Alive() and AliveColor or DeadColor),(ply:Alive() and hg.GetPhrase("alive") or hg.GetPhrase("unalive"))
    end
    if ply == LocalPlayer() then
        return (ply:Alive() and AliveColor or DeadColor),(ply:Alive() and hg.GetPhrase("alive") or hg.GetPhrase("unalive"))
    end
    if LocalPlayer():Team() == 1002 or not LocalPlayer():Alive() then
        return (ply:Alive() and AliveColor or DeadColor),(ply:Alive() and hg.GetPhrase("alive") or hg.GetPhrase("unalive"))
    else
        return SpecColor,hg.GetPhrase("unknown")
    end
end

local grayspec, redfs, greenfs = Color(200,200,200,255), Color(255,0,0), Color(0,255,0)
function CheckPlyTeam(ply)
    if ply:Team() == 1002 then return grayspec, hg.GetPhrase("spectator") end
    if TableRound and TableRound().GetTeamName then
        local name,clr,desc = TableRound().GetTeamName(ply)
        return clr,name
    end
    if TableRound and TableRound().TeamBased then
        if !TableRound().Teams[ply:Team()] then return redfs, "N/A" end
        local clr,name = TableRound().Teams[ply:Team()].Color,TableRound().Teams[ply:Team()].Name
        return clr,name
    elseif TableRound and !TableRound().TeamBased then
        return TableRound().Teams[1].Color,TableRound().Teams[1].Name
    end
end

local mutedicon = Material( "icon32icon/unmute_icon64.png", "noclamp smooth" )
local unmutedicon = Material( "icon32icon/mute_icon64.png", "noclamp smooth" )

local function MutePlayer(ply, mute)
    if not IsValid(ply) or ply == LocalPlayer() then return end
    local steamID = ply:SteamID()
    if not steamID then return end
    ply:SetMuted(mute)
end

local function SaveMutes() file.Write("hgr/muted.json", util.TableToJSON(MutedPlayers)) end

local function ApplyAllMutes()
    for steamID, isMuted in pairs(MutedPlayers) do
        if isMuted then
            for _, ply in playerIterator() do
                if ply:SteamID() == steamID then MutePlayer(ply, true) break end
            end
        end
    end
end

local function ApplyMuteAll()
    for _, player in playerIterator() do
        if player ~= LocalPlayer() then
            local steamID = player:SteamID()
            if steamID then MutePlayer(player, mute_all) MutedPlayers[steamID] = mute_all end
        end
    end
    SaveMutes()
end

local function ApplyMuteDead()
    for _, player in playerIterator() do
        if player ~= LocalPlayer() then
            local steamID = player:SteamID()
            if steamID then
                if mute_death and not player:Alive() then MutePlayer(player, true)
                else local shouldMute = MutedPlayers[steamID] or false MutePlayer(player, shouldMute) end
            end
        end
    end
end

hook.Add("Initialize", "LoadMutedPlayersOnInit", function()
    if file.Exists("hgr/muted.json", "DATA") then
        local jsonData = file.Read("hgr/muted.json", "DATA")
        if jsonData and jsonData ~= "" then
            local loaded = util.JSONToTable(jsonData)
            if loaded then MutedPlayers = loaded timer.Simple(2, ApplyAllMutes) end
        end
    end
end)

hook.Add("Think", "CheckMuteState", function()
    for _, ply in playerIterator() do
        if ply ~= LocalPlayer() then
            local steamID = ply:SteamID()
            if steamID then
                if mute_all then if not ply:IsMuted() then ply:SetMuted(true) end
                elseif mute_death and not ply:Alive() then if not ply:IsMuted() then ply:SetMuted(true) end
                else
                    local shouldMute = MutedPlayers[steamID] or false
                    if shouldMute and not ply:IsMuted() then ply:SetMuted(true)
                    elseif not shouldMute and ply:IsMuted() then ply:SetMuted(false) end
                end
            end
        end
    end
end)

hook.Add("Think", "AutoMuteDeadPlayers", function()
    if mute_death then
        for _, player in playerIterator() do
            if player ~= LocalPlayer() then
                local steamID = player:SteamID()
                if steamID and not player:Alive() and not player:IsMuted() then MutePlayer(player, true) end
            end
        end
    end
end)

local function CheckTPSCock(tps)
    if tps < 15 then return Color(255, 187, 0)
    elseif tps < 25 then return Color(179, 255, 0)
    elseif tps < 35 then return Color(0, 255, 0)
    elseif tps < 40 then return Color(255, 187, 0)
    elseif tps < 60 then return Color(179, 255, 0)
    else return Color(0, 255, 0) end
end

local vgui_gradientl = Material("vgui/gradient-l")
local vgui_gradientr = Material("vgui/gradient-r")
local white_ = Color(255,255,255)
local greenflchat = Color(107, 255, 186)
local blackfltps = Color(22, 22, 22, 200)

local function CanUseScreenGrabLocal()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    if group == "owner"
        or group == "superadmin"
        or group == "dsuperadmin"
        or group == "admin"
        or group == "dadmin"
        or group == "operator"
        or group == "doperator"
        or group == "piar_agent"
        or group == "piaragent"
        or group == "piar-agent" then
        return true
    end

    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
    if isfunction(ply.IsOwner) and ply:IsOwner() then return true end
    return false
end

local drawSimpleText = draw.SimpleText
local tbsort = table.sort
local surfaceGetTextSize = surface.GetTextSize
local surfaceDrawTexturedRect = surface.DrawTexturedRect
local surfaceSetDrawColor = surface.SetDrawColor
local surfaceSetMaterial = surface.SetMaterial
local vguiCreate = vgui.Create

local function GetCustomMaterial(ply)
    if not IsValid(ply) then return nil end
    local steamid = ply:SteamID()
    if not steamid then return nil end
    
    if _G.PlayerVoiceBackgrounds and _G.PlayerVoiceBackgrounds[steamid] then
        local data = string.Split(_G.PlayerVoiceBackgrounds[steamid], ";")
        local path = data[1]
        local offX = tonumber(data[2])
        local offY = tonumber(data[3])
        
        if path and path ~= "none" and path ~= "" then
            local mat = Material(path, "smooth")
            if mat and mat ~= Material("error") and not mat:IsError() then return mat, offX, offY end
        end
    end
    return nil
end


local function CreateFrameContainer(steamID64)
    if FrameCache[steamID64] and IsValid(FrameCache[steamID64].Container) then return FrameCache[steamID64] end
    local container = vgui.Create("DPanel", HG_FrameSanctuary)
    container:SetSize(128, 128)
    container:SetMouseInputEnabled(false)
    container:SetDrawBackground(false)
    container.Paint = function(self, w, h)
        local x, y = self:LocalToScreen(0, 0)
        render.SetScissorRect(x, y, x + w, y + h, true)
    end
    container.PaintOver = function(self, w, h) render.SetScissorRect(0, 0, 0, 0, false) end
    container:MakePopup()
    container:SetMouseInputEnabled(false)
    container:SetKeyboardInputEnabled(false)
    container:SetVisible(false)
    local html = vgui.Create("DHTML", container)    
    html:SetSize(128, 128)
    html:SetMouseInputEnabled(false)
    FrameCache[steamID64] = { Container = container, HTML = html, LastHTML = "", LastUpdate = 0, TargetAvatar = nil, ParentScroll = nil }
    return FrameCache[steamID64]
end

local function UpdateFramePosition(frameData, avatar, scrollPanel)
    if not frameData or not IsValid(frameData.Container) then return end
    if not IsValid(avatar) or not IsValid(scrollPanel) then frameData.Container:SetVisible(false) return end
    local screenX, screenY = avatar:LocalToScreen(0, 0)
    if screenX == 0 and screenY == 0 then frameData.Container:SetVisible(false) return end
    local finalX = screenX - 25
    local finalY = screenY - 25
    local frameSize = 128
    local scrollX, scrollY = scrollPanel:LocalToScreen(0, 0)
    local scrollW, scrollH = scrollPanel:GetSize()
    local scrollBottom = scrollY + scrollH
    local cutTop = math.max(0, scrollY - finalY)
    local cutBottom = math.max(0, (finalY + frameSize) - scrollBottom)
    if cutTop >= frameSize or cutBottom >= frameSize then
        frameData.Container:SetVisible(false)
    else
        frameData.Container:SetVisible(true)
        frameData.Container:SetPos(finalX, finalY + cutTop)
        frameData.Container:SetSize(frameSize, frameSize - cutTop - cutBottom)
        if IsValid(frameData.HTML) then frameData.HTML:SetPos(0, -cutTop) end
        frameData.Container:MoveToFront()
    end
end

local function UpdateAllFrames()
    for _, frameData in pairs(FrameCache) do
        if frameData.TargetAvatar and frameData.ParentScroll then UpdateFramePosition(frameData, frameData.TargetAvatar, frameData.ParentScroll) end
    end
end

hook.Add("HUDPaint", "ScoreBoardPage", function()
    if not hg.ScoreBoard then return end
    if not IsValid(ScoreBoardPanel) then 
        open = false 
        open_gavno = 1 
        for _, frameData in pairs(FrameCache) do if IsValid(frameData.Container) then frameData.Container:SetVisible(false) end end
        return 
    end
    
    if hg.ScoreBoard == 1 and !hg.score_closing then open_gavno = 0 else open_gavno = 1 end
    
    if hg.ScoreBoard == 1 and not open then
        open_target = 0
        open = true
        local MainPanel = vguiCreate("DFrame", ScoreBoardPanel)
        MainPanel:SetSize(ScrW() * ScrMul(), ScrH() / 1.15)
        MainPanel:Center()
        MainPanel:SetDraggable(false)
        MainPanel:SetTitle(" ")
        MainPanel:ShowCloseButton(false)
        local cx = MainPanel:GetX()
        function MainPanel:Paint(w, h) self:SetX(cx - (w * open_gavno)) end

        local ScrollShit = vguiCreate("hg_frame", MainPanel)
        ScrollShit:SetSize(ScrW() / 1.3, ScrH() / 1.28)
        ScrollShit:Center()
        ScrollShit:SetDraggable(false)
        ScrollShit:SetTitle(" ")
        ScrollShit:ShowCloseButton(false)
        ScrollShit.tps = greenfs
        ScrollShit.DefaultClr = blackfltps
        local size2 = surfaceGetTextSize(tostring(string.format(hg.GetPhrase("sc_tps"), 0)))

        function ScrollShit:SubPaint(w, h)
            self:Center()
            local tps = math.Round(1 / engine.ServerFrameTime())
            ScrollShit.tps:Lerp(CheckTPSCock(tps), 0.1)
            drawSimpleText(hg.GetPhrase("sc_status"), "HS.18", w - w / 1.16, h - h / 1.02, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            drawSimpleText(hg.GetPhrase("sc_ug"), "HS.18", w - w / 1.4, h - h / 1.02, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            drawSimpleText(hg.GetPhrase("sc_team"), "HS.18", w - w / 5.5, h - h / 1.02, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            drawSimpleText(string.format(hg.GetPhrase("sc_tps"), tps), "HS.18", w - size2 * 1.5, h - 20, ScrollShit.tps, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local ww, hh = ScrollShit:GetSize()
        local delitel = 6.5
        local MuteDead = vguiCreate("hg_button", ScrollShit)
        MuteDead:SetSize(ww / delitel, hh / 20)
        MuteDead:SetText(" ")
        MuteDead:Center()
        MuteDead:SetY(hh / 1.06)
        MuteDead:SetX(MuteDead:GetX() - ww / 11)
        function MuteDead:SubPaint(w, h) drawSimpleText(hg.GetPhrase("sc_mutedead"), "HS.18", w / 2, h / 2, not mute_death and greenfs or redfs, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        function MuteDead:DoClick() mute_death = not mute_death ApplyMuteDead() surface.PlaySound(mute_death and "homigrad/vgui/panorama/ping_alert_negative.wav" or "homigrad/vgui/panorama/ping_alert_01.wav") end

        local MuteAll = vguiCreate("hg_button", ScrollShit)
        MuteAll:SetSize(ww / delitel, hh / 20)
        MuteAll:SetText(" ")
        MuteAll:Center()
        MuteAll:SetY(hh / 1.06)
        MuteAll:SetX(MuteAll:GetX() + ww / 11)
        function MuteAll:SubPaint(w, h) drawSimpleText(hg.GetPhrase("sc_muteall"), "HS.18", w / 2, h / 2, not mute_all and greenfs or redfs, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        function MuteAll:DoClick() mute_all = not mute_all ApplyMuteAll() surface.PlaySound(mute_all and "homigrad/vgui/panorama/ping_alert_negative.wav" or "homigrad/vgui/panorama/ping_alert_01.wav") end

        local ScrollablePlayerList = vguiCreate("DScrollPanel", ScrollShit)
        ScrollablePlayerList:SetSize(ScrollShit:GetWide() / 1.00, ScrollShit:GetTall() / 1.25)
        ScrollablePlayerList:Center()
        ScrollablePlayerList:SetY(ScrollablePlayerList:GetY() - 35)
        local sbar = ScrollablePlayerList:GetVBar()
        function sbar:Paint(w, h) end
        function sbar.btnUp:Paint(w, h) end
        function sbar.btnDown:Paint(w, h) end
        function sbar.btnGrip:Paint(w, h) end

        local function SortBucket(ply)
            if not IsValid(ply) then return 999 end
            if ply:Team() == 1002 then return 3 end -- spectators at bottom
            if ply:Alive() then return 1 end
            return 2
        end

        local function SortPlayers(a, b)
            local aBucket = SortBucket(a)
            local bBucket = SortBucket(b)
            if aBucket ~= bBucket then return aBucket < bBucket end

            local aTeam = a:Team()
            local bTeam = b:Team()
            if aTeam ~= bTeam then return aTeam < bTeam end

            local aName = string.lower(a:Name() or "")
            local bName = string.lower(b:Name() or "")
            if aName ~= bName then return aName < bName end

            return (a:EntIndex() or 0) < (b:EntIndex() or 0)
        end

        local players = player.GetAll()
        tbsort(players, SortPlayers)

        for _, ply in ipairs(players) do
            local ply = ply -- фиксируем игрока для замыканий
            local steamID = ply:SteamID()
            if steamID and MutedPlayers[steamID] == nil then MutedPlayers[steamID] = false needSave = true end
            
            local PlayerButton = vguiCreate("hg_button", ScrollablePlayerList)

            PlayerButton:Dock(TOP)
            PlayerButton:DockMargin(30, 0, 0, 13)
            PlayerButton:SetText(" ")
            PlayerButton:SetTall(90)
            PlayerButton:SetWide(ScrollablePlayerList:GetWide() / 0.99)
            PlayerButton.Player = ply
            PlayerButton.SteamID = steamID
            PlayerButton.NoDrawDefault = true
            local PlayerAvatar = vguiCreate("AvatarImage",PlayerButton)
            PlayerAvatar:SetPlayer(ply,80)
            PlayerAvatar:SetSize(78,78)

            local steamID64 = ply:SteamID64()
            local frameData = nil
            if steamID64 and steamID64 ~= "0" then
                frameData = CreateFrameContainer(steamID64)
                if frameData then
                    local currentHTML = BuildPlayerScoreHTML(ply)
                    if IsValid(frameData.HTML) and currentHTML ~= frameData.LastHTML then frameData.HTML:SetHTML(currentHTML) frameData.LastHTML = currentHTML end
                    PlayerButton.FrameData = frameData
                    PlayerButton.PlayerAvatar = PlayerAvatar
                    frameData.TargetAvatar = PlayerAvatar
                    frameData.ParentScroll = ScrollablePlayerList
                end
            end

            local DefaultSizeX, DefaultSizeY = 512, 80

            if ply != LocalPlayer() then
                local MuteButton = vguiCreate("DImageButton", PlayerButton)
                MuteButton:SetSize(76, 76)
                MuteButton:SetPos(PlayerButton:GetWide() - 140, 7)
                MuteButton:SetMaterial(MutedPlayers[steamID] and mutedicon or unmutedicon)
                function MuteButton:DoClick()
                    if not IsValid(ply) then return end
                    local playerSteamID = ply:SteamID()
                    if not playerSteamID then return end
                    MutedPlayers[playerSteamID] = not MutedPlayers[playerSteamID]
                    MutePlayer(ply, MutedPlayers[playerSteamID])
                    self:SetMaterial(MutedPlayers[playerSteamID] and mutedicon or unmutedicon)
                    local buttonclicksound = (MutedPlayers[playerSteamID] and "homigrad/vgui/panorama/ping_alert_01.wav") or "homigrad/vgui/panorama/ping_alert_negative.wav"
                    surface.PlaySound(buttonclicksound)
                    SaveMutes()
                end
                PlayerButton.MuteButton = MuteButton
            end

            function PlayerButton:SubPaint(w, h)
                if not self.CurSizeMul then self.CurSizeMul = 1 self.CurPosMul = 0 self.WasHovered = false self.CurColor = 24 self.CurAlpha = 0 end
                if !self:IsHovered() then
                    self.CurSizeMul = LerpFT(0.1, self.CurSizeMul, 1)
                    self.CurPosMul = LerpFT(0.1, self.CurPosMul, 0)
                    self.CurColor = LerpFT(0.2, self.CurColor, 24)
                    self.CurAlpha = LerpFT(0.15, self.CurAlpha, 0)
                    self.WasHovered = false
                else
                    if !self.WasHovered then self.WasHovered = true surface.PlaySound("homigrad/vgui/csgo_ui_contract_type2.wav") end
                end
                if !IsValid(ply) then self:Remove() return end

                local plyColor, plyStatusText = CheckPlyStatus(ply)
                plyColor = Color(plyColor.r, plyColor.g, plyColor.b, 50)
                local teamColor, teamStatusText = CheckPlyTeam(ply)
                teamColor = teamColor and Color(teamColor.r, teamColor.g, teamColor.b, teamColor.a or 255) or Color(0, 0, 0)

                local rowBgUrl = ply:GetNWString("HGRowBG", "")
                local sid64 = ply:SteamID64()
                if rowBgUrl == "" and hg.ScoreboardRowBG and hg.ScoreboardRowBG.RemoteCache and sid64 and hg.ScoreboardRowBG.RemoteCache[sid64] then
                    rowBgUrl = hg.ScoreboardRowBG.RemoteCache[sid64]
                end
                if rowBgUrl == "" and hg.ScoreboardRowBG and hg.ScoreboardRowBG.LocalCache and sid64 and hg.ScoreboardRowBG.LocalCache[sid64] then
                    rowBgUrl = hg.ScoreboardRowBG.LocalCache[sid64]
                end
                if rowBgUrl ~= "" and hg.GetURLMaterial then
                    local rowMat = hg.GetURLMaterial(rowBgUrl, "gomigrad_scoreboard_row_bg", "png")
                    if rowMat then
                        surfaceSetMaterial(rowMat)
                        surfaceSetDrawColor(255, 255, 255, 200)
                        surfaceDrawTexturedRect(0, 0, w, h)
                        surfaceSetDrawColor(0, 0, 0, 120)
                        surface.DrawRect(0, 0, w, h)
                    end
                end
    
                local customMat, offX, offY = GetCustomMaterial(ply)
                if customMat then
                    surfaceSetMaterial(customMat)
                    surfaceSetDrawColor(255, 255, 255, 150)
                    
                    local matWidth, matHeight = 1360, 700
                    
                    local scaleW = w / matWidth
                    local scaleH = h / matHeight
                    local scale = math.max(scaleW, scaleH)
                    if scale < 1 then scale = 1 end
                    
                    local finalW, finalH = matWidth * scale, matHeight * scale
                    
                    offX = offX or 0.5
                    offY = offY or 0.5
                    
                    local x = (w / 2) - (finalW * offX)
                    local y = (h / 2) - (finalH * offY)
                    
                    x = math.Clamp(x, w - finalW, 0)
                    y = math.Clamp(y, h - finalH, 0)
                    
                    surfaceDrawTexturedRect(x, y, finalW, finalH)
                end

                self.DefaultColor = Color(self.CurColor, self.CurColor, self.CurColor)
                surfaceSetDrawColor(plyColor.r, plyColor.g, plyColor.b, 25)
                surfaceSetMaterial(vgui_gradientl)
                surfaceDrawTexturedRect(0, 0, DefaultSizeX * 2 * (self.CurSizeMul * 2), DefaultSizeY * self.CurSizeMul)
                surfaceSetDrawColor(teamColor.r, teamColor.g, teamColor.b, 75)
                surfaceSetMaterial(vgui_gradientr)
                surfaceDrawTexturedRect(w - DefaultSizeX * 3 * (self.CurSizeMul * 2), 0, DefaultSizeX * 3 * (self.CurSizeMul * 2), DefaultSizeY * self.CurSizeMul)
                self:SetSize(DefaultSizeX, DefaultSizeY * self.CurSizeMul)
                DefaultSizeX, DefaultSizeY = 80, 80
                if ply != LocalPlayer() and IsValid(self.MuteButton) then
                    self.MuteButton:SetSize(DefaultSizeX * self.CurSizeMul, DefaultSizeY * self.CurSizeMul)
                    self.MuteButton:SetPos(w - 95 - self.CurPosMul / 1.9, 0)
                    self.MuteButton:SetMaterial(MutedPlayers[self.SteamID] and mutedicon or unmutedicon)
                end
                PlayerAvatar:SetSize(78 * self.CurSizeMul, 78.3 * self.CurSizeMul)
                PlayerAvatar:SetPos(0 - self.CurPosMul, (78 - 78 * self.CurSizeMul) / 2)
                drawSimpleText(ply:Name(), "H.18", w / 2, h / 2, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                teamColor.a = 255
                drawSimpleText(plyStatusText, "H.18", w / 8.3, h / 2, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                local real_usergroup = ply:GetUserGroup()
                if ply:GetNWBool("HidePlyName", false) then real_usergroup = "user" end

                if real_usergroup ~= "user" then 
                    local groupName = ug_names[real_usergroup] or real_usergroup
                    drawSimpleText(groupName, "H.18", w / 3.65, h / 2, ugc[real_usergroup] or white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
                end
                
                drawSimpleText(hg.GetPhrase(teamStatusText), "H.18", w / 1.21, h / 2, teamColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local playtimeSeconds = ply:GetNWFloat("TimeGay", 0)
                local hours = math.floor(playtimeSeconds / 3600)
                local minutes = math.floor((playtimeSeconds % 3600) / 60)
                drawSimpleText(hours .. "h " .. minutes .. "m", "H.18", w / 1.5, h / 2, white_, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                local roleStripColor = ugc[real_usergroup]
                if real_usergroup ~= "user" and roleStripColor then
                    surfaceSetDrawColor(roleStripColor.r, roleStripColor.g, roleStripColor.b, 225)
                    surface.DrawRect(0, h - 3, w, 3)
                end
            end

            function PlayerButton:DoRightClick()
                local DM = vguiCreate("DMenu")
                DM:AddOption(hg.GetPhrase("sc_openprofile"), function()
                    if ply:IsBot() then chat.AddText(redfs, hg.GetPhrase("sc_unable_prof")) surface.PlaySound("homigrad/vgui/menu_invalid.wav") return end
                    ply:ShowProfile() surface.PlaySound("homigrad/vgui/csgo_ui_crate_open.wav")
                end)
                DM:AddOption(hg.GetPhrase("sc_copysteam"), function()
                    if ply:IsBot() then chat.AddText(redfl, hg.GetPhrase("sc_unable_steamid")) surface.PlaySound("homigrad/vgui/menu_invalid.wav") return end
                    chat.AddText(greenflchat, string.format(hg.GetPhrase("sc_success_copy"), ply:SteamID())) SetClipboardText(ply:SteamID()) surface.PlaySound("homigrad/vgui/lobby_notification_chat.wav")
                end)
                DM:AddOption(hg.GetPhrase("sc_copysteam64"), function()
                    if ply:IsBot() then chat.AddText(redfl, hg.GetPhrase("sc_unable_steamid64")) surface.PlaySound("homigrad/vgui/menu_invalid.wav") return end
                    chat.AddText(greenflchat, string.format(hg.GetPhrase("sc_success_copy64"), ply:SteamID())) SetClipboardText(ply:SteamID64()) surface.PlaySound("homigrad/vgui/lobby_notification_chat.wav")
                end)
                DM:AddOption(hg.GetPhrase("sc_copynick"), function()
                    if ply:IsBot() then surface.PlaySound("homigrad/vgui/menu_invalid.wav") return end
                    chat.AddText(greenflchat, string.format(hg.GetPhrase("sc_success_nick"), ply:SteamID())) SetClipboardText(ply:Nick()) surface.PlaySound("homigrad/vgui/lobby_notification_chat.wav")
                end)
                if CanUseScreenGrabLocal() and ply ~= LocalPlayer() then
                    DM:AddSpacer()
                    local grabOption = DM:AddOption("ScreenGrab", function()
                        if hg.ScreenGrabRequest then
                            hg.ScreenGrabRequest(ply)
                        else
                            surface.PlaySound("homigrad/vgui/menu_invalid.wav")
                        end
                    end)
                    if grabOption and grabOption.SetIcon then
                        grabOption:SetIcon("icon16/camera.png")
                    end
                end
                DM:SetPos(input.GetCursorPos())
                DM:MakePopup()
                surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
            end
        end

        if needSave then SaveMutes() needSave = false end
        panelka = MainPanel
        
    elseif hg.ScoreBoard != 1 then
        open = false
        if IsValid(panelka) and open_gavno >= 0.95 then
            for _, frameData in pairs(FrameCache) do if IsValid(frameData.Container) then frameData.Container:SetVisible(false) end end
            panelka:Remove()
        end
    end
    if open then UpdateAllFrames() end
end)

hook.Add("PlayerDisconnected", "CleanupMutedPlayers", function(disconnectedPlayer)
    timer.Simple(5, function() local steamID = disconnectedPlayer:SteamID() if steamID and MutedPlayers[steamID] then MutedPlayers[steamID] = nil SaveMutes() end end)
end)
hook.Add("PlayerConnect", "ApplyMutesToNewPlayer", function(ply)
    timer.Simple(3, function() if IsValid(ply) then local steamID = ply:SteamID() if steamID and MutedPlayers[steamID] then MutePlayer(ply, true) end end end)
end)
hook.Add("PlayerDisconnected", "CleanupFrameCache", function(disconnectedPlayer)
    local steamID64 = disconnectedPlayer:SteamID64()
    if steamID64 and FrameCache[steamID64] then if IsValid(FrameCache[steamID64].Container) then FrameCache[steamID64].Container:Remove() end FrameCache[steamID64] = nil end
end)
