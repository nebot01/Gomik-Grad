-- "addons\\homigrad-core\\lua\\homigrad\\scoreboard\\scoreboard_pages\\cl_jb_ranks_page.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local open = false
local panelka

local grad_r = Material("vgui/gradient-r")
local grad_l = Material("vgui/gradient-l")

local function T(key, fallback)
    if hg and hg.GetPhrase then
        local value = hg.GetPhrase(key)
        if value and value ~= "" then
            return value
        end
    end

    return fallback
end

local function SetupJBTextEntryFocus(entry)
    entry:SetEditable(true)
    entry:SetKeyboardInputEnabled(true)
    entry:SetMouseInputEnabled(true)

    entry.OnMousePressed = function(self, code)
        if IsValid(ScoreBoardPanel) then
            ScoreBoardPanel:SetMouseInputEnabled(true)
            ScoreBoardPanel:SetKeyBoardInputEnabled(true)
        end

        self:RequestFocus()
        DTextEntry.OnMousePressed(self, code)
    end

    entry.OnGetFocus = function(self)
        if IsValid(ScoreBoardPanel) then
            ScoreBoardPanel:SetMouseInputEnabled(true)
            ScoreBoardPanel:SetKeyBoardInputEnabled(true)
        end
    end

    entry.OnLoseFocus = function(self)
        if IsValid(ScoreBoardPanel) then
            ScoreBoardPanel:SetMouseInputEnabled(true)
            ScoreBoardPanel:SetKeyBoardInputEnabled(false)
        end
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end

    entry.OnEnter = function(self)
        self:FocusNext()
        self:OnLoseFocus()
    end
end

local function CanEditJBPoliceRanksLocal()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    if group == "owner"
        or group == "superadmin"
        or group == "dsuperadmin"
        or group == "admin"
        or group == "dadmin"
        or group == "operator"
        or group == "doperator" then
        return true
    end

    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
    if isfunction(ply.IsOwner) and ply:IsOwner() then return true end

    return string.lower(tostring(ROUND_NAME or "")) == "jb" and ply:Team() == 2 and ply:GetNWInt("JBPoliceRank", 0) >= 3
end

local function GetRankRows(filterValue)
    filterValue = string.lower(string.Trim(tostring(filterValue or "")))

    local rows = {}
    for _, ply in ipairs(player.GetAll()) do
        local rank = math.Clamp(math.floor(ply:GetNWInt("JBPoliceRank", 0)), 0, 4)
        local rankName = jb.GetPoliceRankName and jb.GetPoliceRankName(rank) or "No rank"
        local searchBlob = string.lower((ply:Nick() or "") .. " " .. rankName)

        if filterValue == "" or string.find(searchBlob, filterValue, 1, true) then
            rows[#rows + 1] = {
                ply = ply,
                rank = rank,
                rankName = rankName
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.rank ~= b.rank then
            return a.rank > b.rank
        end

        if a.ply:Team() ~= b.ply:Team() then
            return a.ply:Team() == 2
        end

        return string.lower(a.ply:Nick()) < string.lower(b.ply:Nick())
    end)

    return rows
end

local function OpenJBRowMenu(target)
    if not IsValid(target) or not CanEditJBPoliceRanksLocal() then return end

    local menu = DermaMenu()
    menu:AddOption(T("sc_jb_rank_remove", "Remove rank"), function()
        net.Start("JB_PoliceRankSet")
        net.WriteEntity(target)
        net.WriteUInt(0, 3)
        net.SendToServer()
    end)
    menu:AddSpacer()

    for rank = 1, 4 do
        local rankName = jb.GetPoliceRankName and jb.GetPoliceRankName(rank) or tostring(rank)
        menu:AddOption(rankName, function()
            net.Start("JB_PoliceRankSet")
            net.WriteEntity(target)
            net.WriteUInt(rank, 3)
            net.SendToServer()
        end)
    end

    menu:Open()
end

local function BuildJBRows(container, filterValue)
    if not IsValid(container) then return end

    container:Clear()

    if string.lower(tostring(ROUND_NAME or "")) ~= "jb" then
        local empty = vgui.Create("DPanel", container)
        empty:Dock(TOP)
        empty:SetTall(80)
        empty:DockMargin(0, 8, 0, 0)
        function empty:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 220 * (open_fade or 1)))
            draw.SimpleText(T("sc_jb_only", "This tab is available only in JailBreak"), "H.25", 20, h / 2, Color(255, 255, 255, 255 * (open_fade or 1)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return
    end

    for _, entry in ipairs(GetRankRows(filterValue)) do
        local row = vgui.Create("DButton", container)
        row:Dock(TOP)
        row:SetTall(54)
        row:DockMargin(0, 0, 0, 6)
        row:SetText("")

        local avatar = vgui.Create("AvatarImage", row)
        avatar:SetSize(40, 40)
        avatar:SetPos(8, 7)
        avatar:SetPlayer(entry.ply, 64)

        function row:Paint(w, h)
            local fade = open_fade or 1
            local rankColor = jb.GetPoliceRankColor and jb.GetPoliceRankColor(entry.rank) or Color(60, 60, 60)

            draw.RoundedBox(0, 0, 0, w, h, Color(28, 28, 28, 235 * fade))

            surface.SetMaterial(grad_r)
            surface.SetDrawColor(rankColor.r, rankColor.g, rankColor.b, 155 * fade)
            surface.DrawTexturedRect(w * 0.55, 0, w * 0.45, h)

            surface.SetMaterial(grad_l)
            surface.SetDrawColor(0, 0, 0, 180 * fade)
            surface.DrawTexturedRect(0, 0, w, h)

            draw.SimpleText(entry.ply:Nick(), "H.25", 58, h / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(entry.rankName, "H.25", w - 20, h / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 12 * fade)
                surface.DrawRect(0, 0, w, h)
            end

            surface.SetDrawColor(255, 255, 255, 25 * fade)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        function row:DoClick()
            OpenJBRowMenu(entry.ply)
        end

        function row:DoRightClick()
            OpenJBRowMenu(entry.ply)
        end
    end
end

concommand.Add("jb_ranks", function()
    hg.ScoreBoard = 5
    hg.score_closing = false

    if not IsValid(ScoreBoardPanel) and show_scoreboard then
        show_scoreboard()
    end
end)

hook.Add("HUDPaint", "JB_Ranks_Page", function()
    if not hg.ScoreBoard then return end

    if not IsValid(ScoreBoardPanel) then
        open = false
        if IsValid(panelka) then
            panelka:Remove()
        end
        return
    end

    if hg.ScoreBoard == 5 and not open then
        open = true

        local mainPanel = vgui.Create("DFrame", ScoreBoardPanel)
        mainPanel:SetDraggable(false)
        mainPanel:SetSize(ScrW() * ScrMul(), ScrH() / 1.15)
        mainPanel:Center()
        mainPanel:SetTitle(" ")
        mainPanel:ShowCloseButton(false)

        function mainPanel:Paint(w, h) end

        local content = vgui.Create("DPanel", mainPanel)
        content:SetSize(ScrW() / 1.3, ScrH() / 1.28)
        content:Center()

        function content:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 185 * (open_fade or 1)))
            draw.Frame(0, 0, w, h, Color(255, 255, 255, 15 * (open_fade or 1)), Color(0, 0, 0, 125 * (open_fade or 1)))
            surface.SetDrawColor(255, 255, 255, 18 * (open_fade or 1))
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
            draw.SimpleText(T("sc_jb_ranks_title", "Police ranks"), "H.45", 20, 24, Color(255, 255, 255, 255 * (open_fade or 1)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(CanEditJBPoliceRanksLocal() and T("sc_jb_ranks_manage_hint", "Right click a player to change rank") or T("sc_jb_ranks_view_hint", "Police ranks overview"), "H.18", 22, 56, Color(180, 180, 180, 255 * (open_fade or 1)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local search = vgui.Create("DTextEntry", content)
        search:SetPos(20, 76)
        search:SetSize(content:GetWide() - 40, 32)
        search:SetFont("H.18")
        search:SetUpdateOnType(true)
        search:SetTextColor(Color(235, 235, 235))
        search:SetHighlightColor(Color(90, 110, 140))
        search:SetCursorColor(Color(255, 255, 255))
        search:SetPaintBackground(false)
        search:SetPlaceholderText(T("sc_jb_ranks_search", "Enter player name..."))
        search:SetPlaceholderColor(Color(130, 130, 130))

        SetupJBTextEntryFocus(search)

        function search:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200 * fade))

            local col = self:GetTextColor()
            self:SetTextColor(Color(col.r, col.g, col.b, 255 * fade))

            self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        end

        local scroll = vgui.Create("DScrollPanel", content)
        scroll:SetPos(20, 120)
        scroll:SetSize(content:GetWide() - 40, content:GetTall() - 140)

        local sbar = scroll:GetVBar()
        function sbar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(35, 35, 35, 180 * (open_fade or 1))) end
        function sbar.btnUp:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 180 * (open_fade or 1))) end
        function sbar.btnDown:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 180 * (open_fade or 1))) end
        function sbar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(90, 90, 90, 200 * (open_fade or 1))) end

        function mainPanel:RefreshJBRows(force)
            local rowsSignature = {}
            for _, ply in ipairs(player.GetAll()) do
                rowsSignature[#rowsSignature + 1] = table.concat({ply:SteamID64() or ply:EntIndex(), ply:Nick(), ply:GetNWInt("JBPoliceRank", 0), ply:Team()}, ":")
            end

            table.sort(rowsSignature)
            local signature = table.concat(rowsSignature, "|") .. "#" .. search:GetValue() .. "#" .. tostring(ROUND_NAME or "")

            if not force and self.LastJBSignature == signature then
                return
            end

            self.LastJBSignature = signature
            BuildJBRows(scroll, search:GetValue())
        end

        function search:OnValueChange()
            if IsValid(mainPanel) then
                mainPanel:RefreshJBRows(true)
            end
        end

        function mainPanel:Think()
            if (self.NextRefresh or 0) > CurTime() then return end
            self.NextRefresh = CurTime() + 0.35
            self:RefreshJBRows(false)
        end

        mainPanel:RefreshJBRows(true)
        panelka = mainPanel
    elseif hg.ScoreBoard ~= 5 and open then
        open = false
        if IsValid(panelka) then
            panelka:Remove()
        end
    end
end)

