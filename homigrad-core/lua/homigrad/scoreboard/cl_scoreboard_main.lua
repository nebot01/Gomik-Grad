if not open then open = false end
open_fade = 0

local toggle_tab = (ConVarExists("hg_toggle_score") and GetConVar("hg_toggle_score") or CreateClientConVar("hg_toggle_score","1",true,false,"Toggle tab",0,1))

-- Иконки
local panelIcons = {
    [1] = Material("icon32icon/scoreboard_icon.png"),
    [2] = Material("icon32icon/teams_icon.png"),
    [3] = Material("icon32icon/inventory_icon.png"),
    [4] = Material("icon32icon/settings_icon.png"),
    [5] = Material("icon32icon/teams_icon.png"),
    [6] = Material("icon32icon/shop_icon.png"),
    [7] = Material("icon32icon/settings_icon.png"),
    [8] = Material("icon32icon/inventory_icon.png"), -- Модели
    [9] = Material("icon32icon/shop_icon.png"),      -- Кейсы
    [10] = Material("icon32icon/shop_icon.png")      -- Казино
}

local panelNames = {
    [1] = hg.GetPhrase("sc_players") or "ИГРОКИ",
    [2] = hg.GetPhrase("sc_teams") or "КОМАНДЫ", 
    [3] = hg.GetPhrase("sc_invento") or "ИНВЕНТАРЬ",
    [4] = hg.GetPhrase("sc_settings") or "НАСТРОЙКИ",
    [5] = hg.GetPhrase("sc_jb_ranks") or "РАНГИ JB",
    [6] = hg.GetPhrase("sc_shop") or "МАГАЗИН",
    [7] = hg.GetPhrase("sc_event_menu") or "ИВЕНТЫ",
    [8] = "МОДЕЛИ",
    [9] = "Кейсы",
    [10] = "Казино"
}

local glowMaterial = Material("sprites/glow04_noz")
local jbTabIconURL = "https://i.postimg.cc/g2nhqnQk/icons8-handcuffs-64.png"
local eventTabIconURL = "https://i.postimg.cc/cJnysszC/icons8-megaphone-50.png"
local casinoTabIconURL = "https://i.postimg.cc/Hx8Pq11n/icons8-chips-64.png"

local remoteTabIcons = {
    [5] = jbTabIconURL,
    [7] = eventTabIconURL,
    [10] = casinoTabIconURL
}

function AddPanel(Parent, Text, NeedTo, ChangeTo, SizeXY, DockTo, CustomFunc)
    local ButtonShit = Parent:Add("hg_button")
    ButtonShit:SetSize(SizeXY.x, SizeXY.y)
    ButtonShit:SetText(" ")
    ButtonShit:Center()
    ButtonShit:Dock(DockTo)
    ButtonShit:DockMargin(0, 0, 0, 0)
    ButtonShit:SetPos(0, 0)
    ButtonShit.Text = Text
    
    ButtonShit.Icon = panelIcons[ChangeTo]
    Parent[ChangeTo] = ButtonShit
    
    if CustomFunc then ButtonShit.Shit = CustomFunc end
    
    ButtonShit.HoverProgress = 0
    ButtonShit.TextOffset = -100
    ButtonShit.GlowAlpha = 0
    ButtonShit.Name = panelNames[ChangeTo] or Text

    function ButtonShit:Think()
        local target = self:IsHovered() and 1 or 0
        self.HoverProgress = Lerp(FrameTime() * 12, self.HoverProgress, target)
        local targetOffset = self:IsHovered() and 0 or -100
        self.TextOffset = Lerp(FrameTime() * 15, self.TextOffset, targetOffset)
        local targetGlow = self:IsHovered() and 1 or 0
        self.GlowAlpha = Lerp(FrameTime() * 10, self.GlowAlpha, targetGlow)
    end
    
    function ButtonShit:Paint(w, h)
        local centerX, centerY = w/2, h/2
        if self.GlowAlpha > 0 then
            surface.SetMaterial(glowMaterial)
            surface.SetDrawColor(255, 255, 255, 80 * self.GlowAlpha * open_fade)
            local pulse = math.sin(CurTime() * 8) * 0.1 + 0.9
            local glowSize = w * 1.2 * pulse * self.GlowAlpha
            surface.DrawTexturedRect(centerX - glowSize/2, centerY - glowSize/2, glowSize, glowSize)
        end

        local iconMat = self.Icon
        if remoteTabIcons[ChangeTo] and hg.GetURLMaterial then
            iconMat = hg.GetURLMaterial(remoteTabIcons[ChangeTo], "gomigrad_tab_icons", "png") or iconMat
        end

        if iconMat then
            surface.SetDrawColor(255, 255, 255, 255 * open_fade)
            surface.SetMaterial(iconMat)
            local iconSize = math.min(w, h) * 0.7
            surface.DrawTexturedRect(centerX - iconSize/2, centerY - iconSize/2, iconSize, iconSize)
        end

        if ChangeTo == 1 then
            local playerCount = #player.GetAll()
            surface.SetFont("hg_HomicideSmalles")
            local text = tostring(playerCount)
            local _, textHeight = surface.GetTextSize(text)
            local circleSize = textHeight * 1.2
            local circleX = w - circleSize / 2 - 5
            local circleY = circleSize / 2 + 5
            draw.RoundedBox(circleSize / 2, circleX - circleSize / 2, circleY - circleSize / 2, circleSize, circleSize, Color(0, 0, 0, 200 * open_fade))
            draw.SimpleText(text, "hg_HomicideSmalles", circleX, circleY, Color(255, 255, 255, 255 * open_fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    function ButtonShit:DoClick()
        surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav")
        if hg[NeedTo] != ChangeTo then open_target = 1 end
        hg[NeedTo] = ChangeTo
    end
end

local function CreateTextPanel(parentPanel, itemsPanel)
    local TextDisplay = vgui.Create("DPanel", parentPanel)
    TextDisplay:SetSize(200, ScrH())
    TextDisplay:SetPos(ScrW() - itemsPanel:GetWide() - 200, 0)
    TextDisplay:SetZPos(999)
    
    TextDisplay.ActiveText = ""
    TextDisplay.TextAlpha = 0
    TextDisplay.TargetAlpha = 0
    TextDisplay.TextOffset = 50
    TextDisplay.TargetOffset = 0
    TextDisplay.LastHoveredButton = nil
    TextDisplay.LastButtonY = 0 

    function TextDisplay:Think()
        local hoveredButton = nil
        local buttonY = 0
        for i = 1, 10 do 
            if IsValid(itemsPanel[i]) and itemsPanel[i]:IsHovered() then
                hoveredButton = itemsPanel[i]
                local _, buttonRelativeY = itemsPanel[i]:GetPos()
                local _, itemsPanelY = itemsPanel:GetPos()
                buttonY = itemsPanelY + buttonRelativeY + itemsPanel[i]:GetTall() / 2
                break
            end
        end
        if hoveredButton ~= self.LastHoveredButton then
            if hoveredButton then
                self.ActiveText = hoveredButton.Name
                self.TargetAlpha = 255
                self.TextOffset = 50 
                self.TargetOffset = 0
                self.LastButtonY = buttonY
            else
                self.TargetAlpha = 0
                self.TargetOffset = 50
            end
            self.LastHoveredButton = hoveredButton
        else
            if hoveredButton then
                self.TargetAlpha = 255
                self.TargetOffset = 0
                self.LastButtonY = buttonY
            else
                self.TargetAlpha = 0
                self.TargetOffset = 50
            end
        end
        self.TextAlpha = Lerp(FrameTime() * 8, self.TextAlpha, self.TargetAlpha)
        self.TextOffset = Lerp(FrameTime() * 12, self.TextOffset, self.TargetOffset)
    end

    function TextDisplay:Paint(w, h)
        if self.TextAlpha > 0 and self.ActiveText ~= "" then
            local buttonY = self.LastButtonY
            local bgX = w - 120 + self.TextOffset
            local bgY = buttonY - 15
            surface.SetDrawColor(0, 0, 0, 150 * (self.TextAlpha / 255) * open_fade)
            surface.DrawRect(bgX, bgY, 115, 30)
            local textX = w - 10 + self.TextOffset
            draw.SimpleText(self.ActiveText, "H.25", textX, buttonY, Color(255, 255, 255, self.TextAlpha * open_fade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            if self.TextAlpha > 100 then
                local arrowSize = 8
                local arrowX = bgX + 115 + 5
                surface.SetDrawColor(255, 255, 255, self.TextAlpha * open_fade)
                surface.DrawLine(arrowX, buttonY - arrowSize, arrowX, buttonY + arrowSize)
                surface.DrawLine(arrowX, buttonY, arrowX + arrowSize, buttonY)
            end
        end
    end
    return TextDisplay
end

function show_scoreboard()
    if hg.ScoreBoard == 2 and !LocalPlayer():Alive() then hg.ScoreBoard = 1 end
    if hg.ScoreBoard == 5 and string.lower(tostring(ROUND_NAME or "")) != "jb" then hg.ScoreBoard = 1 end
    if hg.ScoreBoard == 7 and hg.EventMenuCanAccessLocal and not hg.EventMenuCanAccessLocal() then hg.ScoreBoard = 1 end
    if not hg.ScoreBoard then hg.ScoreBoard = 1 end
    
    ScoreBoardPanel = vgui.Create("DFrame")
    open_target = 0
    
    ScoreBoardPanel:SetSize(SW,SH)
    ScoreBoardPanel:Center()
    ScoreBoardPanel:ShowCloseButton(false)
    ScoreBoardPanel:SetTitle(" ")
    ScoreBoardPanel:MakePopup()
    ScoreBoardPanel:SetDraggable(false)
    ScoreBoardPanel:SetKeyBoardInputEnabled(false)
    
    function ScoreBoardPanel:Paint(w,h)
        local bgUrl = hg.TabBG_GetURL and hg.TabBG_GetURL() or ""
        if bgUrl ~= "" and hg.GetURLMaterial then
            local mat = hg.GetURLMaterial(bgUrl, "gomigrad_tab_bg")
            if mat then
                surface.SetMaterial(mat)
                surface.SetDrawColor(255,255,255,200 * open_fade)
                surface.DrawTexturedRect(0,0,w,h)
                surface.SetDrawColor(0,0,0,120 * open_fade)
                surface.DrawRect(0,0,w,h)
            else
                draw.RoundedBox(0,self:GetX(),self:GetY(),w,h,Color(0,0,0,129 * open_fade))
            end
        else
            draw.RoundedBox(0,self:GetX(),self:GetY(),w,h,Color(0,0,0,129 * open_fade))
        end
        draw.SimpleText("GOMIGRAD.COM","H.70",ScrW()/2,ScrH()/2,Color(255,255,255,30 * open_fade),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    
    ItemsPanel = vgui.Create("DScrollPanel",ScoreBoardPanel)
    ItemsPanel:SetSize(ScrW()/23,ScrH())
    local x,y = ItemsPanel:GetSize()
    ItemsPanel:SetPos(ScrW() - x,-ScrH())
    ItemsPanel:SetKeyBoardInputEnabled(false)
    ItemsPanel:SetHeight(ScrH() / 2)
    ItemsPanel:SetY(ScrH() / 4)
    ItemsPanel:SetZPos(1000)

    local TextPanel = CreateTextPanel(ScoreBoardPanel, ItemsPanel)

    ItemsPanelPaint = vgui.Create("DFrame",ScoreBoardPanel)
    ItemsPanelPaint:SetSize(ScrW()/256,ScrH())
    local x,y = ItemsPanel:GetSize()
    ItemsPanelPaint:SetPos(ScrW() - x - 10,-ScrH())
    ItemsPanelPaint:SetKeyBoardInputEnabled(false)
    ItemsPanelPaint:SetHeight(ScrH() / 2)
    ItemsPanelPaint:SetY(ScrH() / 4)
    ItemsPanelPaint:ShowCloseButton(false)
    ItemsPanelPaint:SetTitle(" ")
    ItemsPanelPaint:SetDraggable(false)
    ItemsPanelPaint.PosShit = (ItemsPanel:GetWide() * hg.ScoreBoard)

    function ItemsPanelPaint:Paint(w,h)
        cam.Start2D()
            local w = ScrW()
            local h = ScrH()
            surface.SetFont("hg_HomicideSmalles")
            
            if !TableRound then cam.End2D() return end
            
            local curRound = TableRound()
            if !curRound then cam.End2D() return end
            
            local nextRound = TableRound(ROUND_NEXT)
            if !nextRound then cam.End2D() return end
            
            local sizex,sizey = surface.GetTextSize(tostring(string.format(hg.GetPhrase("sc_curround"),(curRound and curRound.name or "N/A"))))
            local sizex2,sizey2 = surface.GetTextSize(tostring(string.format(hg.GetPhrase("sc_nextround"),(nextRound and nextRound.name or "N/A"))))
            surface.SetDrawColor(0,0,0,255 * open_fade)
            surface.SetMaterial(Material("homigrad/vgui/gradient_right.png"))
            surface.DrawTexturedRect(ScrW()-sizex*2,0,sizex * 2,(sizey*2) * 1.3)
            draw.SimpleText(string.format(hg.GetPhrase("sc_curround"),curRound.name), "hg_HomicideSmalles", ScrW() - sizex * 1.3 - sizex2 * 0.1, 8, Color(255, 255, 255, 255 * open_fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)          
            draw.SimpleText(string.format(hg.GetPhrase("sc_nextround"),nextRound.name), "hg_HomicideSmalles", ScrW() - sizex * 1.3 - sizex2 * 0.1, 8 + sizey, Color(255, 247, 173, 255 * open_fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        cam.End2D()
    end

    local mm_zalupa = vgui.Create("DFrame",ItemsPanelPaint)
    mm_zalupa:ShowCloseButton(false)
    mm_zalupa:SetTitle(" ")
    mm_zalupa:SetDraggable(false)
    mm_zalupa:SetSize(3,ItemsPanel:GetWide())
    mm_zalupa.ypos = 0

    function mm_zalupa:Paint(w,h)
        draw.RoundedBox(16,0,0,w,h,Color(255,255,255,100))
        local activeButton = IsValid(ItemsPanel[hg.ScoreBoard]) and ItemsPanel[hg.ScoreBoard] or ItemsPanel[1]
        if IsValid(activeButton) then
            self.ypos = LerpFT(0.2, self.ypos, activeButton:GetY())
            self:SetY(self.ypos)
        end
    end

    AddPanel(ItemsPanel,hg.GetPhrase("sc_players"),"ScoreBoard",1,{x = ItemsPanel:GetWide(),y = ItemsPanel:GetWide()},TOP,function(self) self.Amt = #player.GetAll() end)
    AddPanel(ItemsPanel,hg.GetPhrase("sc_teams"),"ScoreBoard",2,{x = ItemsPanel:GetWide(),y = ItemsPanel:GetWide()},TOP)    
    if LocalPlayer():Alive() then
        AddPanel(ItemsPanel,hg.GetPhrase("sc_invento"),"ScoreBoard",3,{x = ItemsPanel:GetWide(),y = ItemsPanel:GetWide()},TOP)
    end
    AddPanel(ItemsPanel,hg.GetPhrase("Настройки"),"ScoreBoard",4,{x = ItemsPanel:GetWide(),y = ItemsPanel:GetWide()},TOP)
    if string.lower(tostring(ROUND_NAME or "")) == "jb" then
        AddPanel(ItemsPanel, "JB Ranks", "ScoreBoard", 5, {x = ItemsPanel:GetWide(), y = ItemsPanel:GetWide()}, TOP)
    end
    if hg.EventMenuCanAccessLocal and hg.EventMenuCanAccessLocal() then
        AddPanel(ItemsPanel, "Ивенты", "ScoreBoard", 7, {x = ItemsPanel:GetWide(), y = ItemsPanel:GetWide()}, TOP)
    end

    -- Добавляем Модели, Кейсы и Казино
    local ply = LocalPlayer()
    local allowedGroups = {["microsponsor"]=true, ["sponsor"]=true, ["megasponsor"]=true, ["moderator"]=true, ["admin"]=true, ["superadmin"]=true, ["owner"]=true, ["doperator"]=true, ["dadmin"]=true, ["dsuperadmin"]=true, ["piar_agent"]=true}
    --AddPanel(ItemsPanel, "Модели", "ScoreBoard", 8, {x = ItemsPanel:GetWide(), y = ItemsPanel:GetWide()}, TOP)
    AddPanel(ItemsPanel, "Кейсы", "ScoreBoard", 9, {x = ItemsPanel:GetWide(),y = ItemsPanel:GetWide()}, TOP)
    AddPanel(ItemsPanel, "Казино", "ScoreBoard", 10, {x = ItemsPanel:GetWide(), y = ItemsPanel:GetWide()}, TOP)
end

hook.Add("ScoreboardShow","Homigrad_ScoreBoard",function()
    hg.score_closing = false
    if toggle_tab:GetBool() then return false end
    net.Start("HG_RequestInventory")
    net.SendToServer()
    if IsValid(ScoreBoardPanel) then
        if hg.islooting then
            surface.PlaySound("homigrad/vgui/item_drop.wav")
            hg.islooting = false
            if !hg.score_closing then
                hg.score_closing = true
                timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
            end
            hg.lootent = NULL
        else
            ScoreBoardPanel:Remove()
        end
    else
        show_scoreboard()
    end
    return false
end)

hook.Add("ScoreboardHide","Homigrad_ScoreBoard",function()
    if toggle_tab:GetBool() then return end
    if IsValid(ScoreBoardPanel) then
        hg.score_closing = true
        timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
        hg.islooting = false
        hg.lootent = NULL
    end
end)

local tabPressed = false
fastloot = false
hook.Add("HUDPaint", "HomigradScoreboardToggle", function()
    if !TableRound then return end
    if !IsValid(ScoreBoardPanel) then
        cam.Start2D()
            local w = ScrW()
            local h = ScrH()
            surface.SetFont("hg_HomicideSmalles")
            local curRound = TableRound()
            if !curRound then cam.End2D() return end
            local nextRound = TableRound(ROUND_NEXT)
            if !nextRound then cam.End2D() return end
            local sizex,sizey = surface.GetTextSize(tostring(string.format(hg.GetPhrase("sc_curround"),(curRound and curRound.name or "N/A"))))
            local sizex2,sizey2 = surface.GetTextSize(tostring(string.format(hg.GetPhrase("sc_nextround"),(nextRound and nextRound.name or "N/A"))))
            surface.SetDrawColor(0,0,0,255 * open_fade)
            surface.SetMaterial(Material("homigrad/vgui/gradient_right.png"))
            surface.DrawTexturedRect(ScrW()-sizex*2,0,sizex * 2,(sizey*2) * 1.3)
            draw.SimpleText(string.format(hg.GetPhrase("sc_curround"),curRound.name), "hg_HomicideSmalles", ScrW() - sizex * 1.3 - sizex2 * 0.1, 8, Color(255, 255, 255, 255 * open_fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)          
            draw.SimpleText(string.format(hg.GetPhrase("sc_nextround"),nextRound.name), "hg_HomicideSmalles", ScrW() - sizex * 1.3 - sizex2 * 0.1, 8 + sizey, Color(255, 247, 173, 255 * open_fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        cam.End2D()
    end
    if !hg.score_closing then open_fade = LerpFT(0.25,open_fade,1) else open_fade = LerpFT(0.25,open_fade,0) end
    if hg.islooting and IsValid(hg.lootent) and hg.lootent:GetPos():Distance(LocalPlayer():GetPos()) > 95 or !IsValid(hg.lootent) and hg.islooting or hg.islooting and !LocalPlayer():Alive() then
        if hg.islooting then
            surface.PlaySound("homigrad/vgui/item_drop.wav")
            hg.islooting = false
            hg.lootent = NULL
            if !hg.score_closing then
                hg.score_closing = true
                timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
            end
        else
            if IsValid(ScoreBoardPanel) then
                hg.islooting = false
                hg.score_closing = true
                timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
            end
        end
    end
    if (input.IsKeyDown(KEY_H) or input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) and !fastloot then fastloot = true
    elseif !input.IsKeyDown(KEY_H) and !input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT) then fastloot = false end

    if !toggle_tab:GetBool() then return end
    if input.IsKeyDown(KEY_TAB) and !tabPressed then
        if IsValid(ScoreBoardPanel) then
            if hg.islooting then
                surface.PlaySound("homigrad/vgui/item_drop.wav")
                hg.islooting = false
                hg.lootent = NULL
                if !hg.score_closing then
                    hg.score_closing = true
                    timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
                end
            else
                hg.score_closing = true
                timer.Simple(0.2,function() ScoreBoardPanel:Remove() end)
                hg.islooting = false
                hg.lootent = NULL
            end
        else
            show_scoreboard()
            hg.score_closing = false
        end
        tabPressed = true
    elseif !input.IsKeyDown(KEY_TAB) then
        tabPressed = false
    end
end)