-- "addons\\homigrad-core\\lua\\homigrad\\scoreboard\\scoreboard_pages\\cl_settings_page.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local open = false
local panelka
local SetDrawColor,DrawRect = surface.SetDrawColor,surface.DrawRect
hintImage = nil
hintDesc = nil

local function SetupTextEntryFocus(entry)
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

local DefaultSettingsValues = {
    ["show_notify"] = true,
    ["show_historyweapon"] = true,
    ["show_afkscreen"] = true,
    ["hide_usergroup"] = false,
    ["show_group_hmcd"] = true,
    ["mat_filtertextures"] = false,
    ["pp_ssao_plus"] = false,
    ["gmod_mcore_test"] = true,
    ["gg_armor"] = false,
    ["gg_holster"] = false,
    ["hg_fov"] = 100,
    ["hg_cshs_fake"] = false,
    ["hg_casual"] = true,
    ["r_3dsky"] = true,
}

if not file.Exists("gomigrad_datacontent/settings.xml", "DATA") then
    file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(DefaultSettingsValues))
end

GGrad_ConfigSettings = util.JSONToTable(file.Read("gomigrad_datacontent/settings.xml", "DATA"), true)

local function ConfigSettingSync()
    file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(GGrad_ConfigSettings))
end

timer.Create("FixConfigSettings", 5, 0, function()
    local cfg = file.Read("gomigrad_datacontent/settings.xml", "DATA")
    local tbl = util.JSONToTable(cfg)
    for k, v in pairs(DefaultSettingsValues) do
        if tbl[k] == nil then
            tbl[k] = v
            file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(tbl))
        end
    end
end)


local function LoadVoiceBackground()
    if hg.VoiceBG_GetURL then
        return hg.VoiceBG_GetURL()
    end
    return ""
end

local function SaveVoiceBackground(path)
    if hg.VoiceBG_SetURL then
        hg.VoiceBG_SetURL(path or "")
    end
end

local function LoadTabBackground()
    if hg.TabBG_GetURL then
        return hg.TabBG_GetURL()
    end
    return ""
end

local function SaveTabBackground(path)
    if hg.TabBG_SetURL then
        hg.TabBG_SetURL(path or "")
    end
end

local function LoadScoreboardRowBackground()
    if hg.ScoreboardRowBG_GetURL then
        return hg.ScoreboardRowBG_GetURL()
    end
    if not file.IsDir("gomigrad_settings", "DATA") then
        file.CreateDir("gomigrad_settings")
    end
    local path = "gomigrad_settings/scoreboard_row_bg_url.txt"
    if file.Exists(path, "DATA") then
        local url = file.Read(path, "DATA")
        if url and url ~= "" then
            return url
        end
    end
    return ""
end

local function SaveScoreboardRowBackground(path)
    if hg.ScoreboardRowBG_SetURL then
        hg.ScoreboardRowBG_SetURL(path or "")
        return
    end
    if not file.IsDir("gomigrad_settings", "DATA") then
        file.CreateDir("gomigrad_settings")
    end
    file.Write("gomigrad_settings/scoreboard_row_bg_url.txt", path or "")
end

local function GetCustomMaterialForSettings(path, folder, defaultExt)
    if path and path ~= "" then
        if hg.GetURLMaterial and (string.sub(path, 1, 7) == "http://" or string.sub(path, 1, 8) == "https://") then
            return hg.GetURLMaterial(path, folder or "gomigrad_url", defaultExt)
        end
        local mat = Material(path, "smooth")
        if mat and mat ~= Material("error") and not mat:IsError() then
            return mat
        end
    end
    return nil
end

local function NormalizeHttpURL(url)
    url = (url or ""):Trim()
    if url == "" then return "" end
    local lower = string.lower(url)
    if string.sub(lower, 1, 7) == "http://" or string.sub(lower, 1, 8) == "https://" then
        return url
    end
    if string.find(lower, "://", 1, true) then
        return url
    end
    if string.sub(lower, 1, 9) == "materials" or string.sub(lower, 1, 5) == "vgui/" or string.sub(lower, 1, 7) == "models/" or string.sub(lower, 1, 5) == "data/" then
        return url
    end
    return "https://" .. url
end

local lagaen = CreateClientConVar("cl_superduperoptimization", "0", true)
local SettingHints = {
    ["show_notify"] = {
        on = "icon_settings/on_notification.png",
        off = "icon_settings/off_notification.png",
        desc = hg.CurLoc.setting_hint_notify
    },
    ["gmod_mcore_test"] = {
        on = "icon_settings/on_gmodcore.png",
        off = "icon_settings/off_gmodcore.png",
        desc = hg.CurLoc.setting_hint_multicore
    },
    ["mat_filtertextures"] = {
        on = "icon_settings/on_pixels.png",
        off = "icon_settings/off_pixels.png",
        desc = hg.CurLoc.setting_hint_pixels
    },
}

local SettingsList = {
    {
        name = hg.CurLoc.setting_fov,
        var = "hg_fov",
        type = "slider",
        min = 75,
        max = 120,
        desc = hg.CurLoc.setting_fov_desc
    },
    /*{
        name = hg.CurLoc.setting_notify,
        var = "show_notify",
        desc = hg.CurLoc.setting_notify_desc
    },*/ //эта нужна
    {
        name = hg.CurLoc.setting_cshs_camera,
        var = "hg_cshs_fake",
        desc = hg.CurLoc.setting_cshs_camera_desc
    },
    {
        name = "Скрыть роль в табе",
        var = "hide_usergroup",
        desc = "Скрывает вашу админ-роль для других игроков."
    },
    /*{
        name = hg.CurLoc.setting_casual,
        var = "hg_casual",
        desc = hg.CurLoc.setting_casual_desc
    },*/ //не работает пидарас
}

local OptimizationSettings = {
    {
        name = hg.CurLoc.setting_multicore,
        var = "gmod_mcore_test",
        command = "gmod_mcore_test",
        disable_value = "1",
        enable_value = "0",
        desc = hg.CurLoc.setting_multicore_desc
    },
    {
        name = hg.CurLoc.setting_pixels,
        var = "mat_filtertextures",
        command = "mat_filtertextures",
        disable_value = "0",
        enable_value = "1",
        desc = hg.CurLoc.setting_pixels_desc
    },
    {
        name = hg.CurLoc.setting_ssao,
        var = "pp_ssao_plus",
        command = "pp_ssao_plus",
        disable_value = "1",
        enable_value = "0",
        desc = hg.CurLoc.setting_ssao_desc
    },
    {
        name = hg.CurLoc.setting_3dskybox,
        var = "r_3dsky",
        command = "r_3dsky",
        disable_value = "1",
        enable_value = "0",
        desc = hg.CurLoc.setting_3dskybox_desc
    },
}

local KeyBinds = {
    {
        name = hg.CurLoc.setting_ragdoll,
        command = "fake",
        var = "bind_fake",
        desc = hg.CurLoc.setting_ragdoll_desc
    },
    {
        name = hg.CurLoc.setting_suicide,
        command = "suicide",
        var = "bind_suicide",
        desc = hg.CurLoc.setting_suicide_desc
    },
    {
        name = hg.CurLoc.setting_kick,
        command = "hg_kick",
        var = "bind_hg_kick",
        desc = hg.CurLoc.setting_kick_desc
    },
}

local skinsContentScroll

local function CanToggleHideUsergroup()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    if isfunction(ply.IsOwner) and ply:IsOwner() then return true end
    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    return group == "owner"
end

local function CanUseSkinsLocal()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    if hg.CanUseSkins then return hg.CanUseSkins(ply) end
    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    if group == "megasponsor"
        or group == "moderator"
        or group == "intern"
        or group == "operator"
        or group == "doperator"
        or group == "admin"
        or group == "dadmin"
        or group == "superadmin"
        or group == "dsuperadmin"
        or group == "owner"
        or group == "piar_agent"
        or group == "piaragent"
        or group == "piar-agent" then
        return true
    end
    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
    if isfunction(ply.IsOwner) and ply:IsOwner() then return true end
    return false
end

local function CreateSkinsHeader(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(70)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 6)
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 148 * fade))
        draw.SimpleText(hg.CurLoc.setting_skins_title or "Скины", "H.25", 10, h/2 - 10, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hg.CurLoc.setting_skins_desc or "Скины будут применены в следующем раунде.", "H.18", 10, h/2 + 10, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    return panel
end

local function CreateSkinPanel(parent, skin)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(60)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 148 * fade))
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
        draw.SimpleText(skin.name or skin.path, "H.25", 10, h/2 - 8, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local button = vgui.Create("DButton", panel)
    button:SetText("")
    button:SetSize(140, 34)
    
    function button:Paint(w, h)
        local fade = open_fade or 1
        local selected = LocalPlayer():GetNWString("HGNextSkin", "") == skin.path
        local baseColor = selected and Color(0, 200, 60, 200 * fade) or Color(41, 41, 41, 200 * fade)
        draw.RoundedBox(4, 0, 0, w, h, baseColor)
        local text = selected and (hg.CurLoc.setting_skins_unset or "Убрать") or (hg.CurLoc.setting_skins_set or "Set")
        draw.SimpleText(text, "H.18", w/2, h/2, Color(240, 240, 245, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function button:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        net.Start("HG_ServerSkins_Set")
        if LocalPlayer():GetNWString("HGNextSkin", "") == skin.path then
            net.WriteString("")
        else
            net.WriteString(skin.path or "")
        end
        net.SendToServer()
    end
    
    function panel:PerformLayout(w, h)
        button:SetPos(w - 140, h/2 - 16)
    end
    
    return panel
end

local function BuildSkinsTab(parent)
    if parent.GetCanvas then
        local canvas = parent:GetCanvas()
        if IsValid(canvas) then
            for _, child in ipairs(canvas:GetChildren()) do
                child:Remove()
            end
        end
    else
        for _, child in ipairs(parent:GetChildren()) do
            child:Remove()
        end
    end
    CreateSkinsHeader(parent)
    local list = hg.ServerSkins and hg.ServerSkins.List or {}
    if #list == 0 then
        local empty = vgui.Create("DPanel", parent)
        empty:SetTall(50)
        empty:Dock(TOP)
        empty:DockMargin(2, 2, 2, 2)
        function empty:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 148 * fade))
            draw.SimpleText(hg.CurLoc.setting_skins_empty or "Нету скинов.", "H.25", 10, h/2, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return
    end
    for _, skin in ipairs(list) do
        CreateSkinPanel(parent, skin)
    end
end

local function CreateVoicePanelPreview(parent, x, y, w, h, bgMaterial, isTalking)
    local panel = vgui.Create("hg_frame", parent)
    panel:SetDraggable(false)
    panel:ShowCloseButton(false)
    panel:SetTitle("")

    panel:SetPos(x, y)
    panel:SetSize(w, h)
    
    local Avatar = vgui.Create("AvatarImage", panel)
    Avatar:SetPlayer(LocalPlayer(), 64)
    
    local talkAmt = isTalking and 1 or 0.3
    
    function panel:Paint(pw, ph)
        local fade = open_fade or 1
        if IsValid(Avatar) then Avatar:SetAlpha(255 * fade) end

        if bgMaterial then
            surface.SetMaterial(bgMaterial)
            if not LocalPlayer():Alive() then
                surface.SetDrawColor(255, 100, 100, 180 * talkAmt * fade)
            else
                surface.SetDrawColor(255, 255, 255, 180 * talkAmt * fade)
            end
            surface.DrawTexturedRect(0, 0, pw, ph)
        else
            draw.RoundedBox(6, 0, 0, pw, ph, Color(0, 0, 0, 200 * talkAmt * fade))
        end
        
        if TableRound and TableRound().TeamBased and LocalPlayer():Alive() then
            if LocalPlayer():Team() != 1002 then
                local clr = TableRound().Teams[LocalPlayer():Team()].Color
                local clr_mul = 0.7
                surface.SetDrawColor(clr.r, clr.g, clr.b, 250 * talkAmt * fade)
                surface.SetMaterial(Material("vgui/gradient-r"))
                surface.DrawTexturedRect(pw - pw/2 * (clr_mul + 0.3), 0, pw/2 * (clr_mul + 0.3), ph)
            end
        end
        
        local avatarSize = ph - 4
        local nameX = avatarSize + 140
        draw.SimpleText(LocalPlayer():Name(), "HO.18", nameX, ph/2, Color(255, 255, 255, 255 * talkAmt * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        local voiceVolume = isTalking and 0.8 or 0.3
        local circleSize = voiceVolume * 25
        
        local circleX, circleY = avatarSize/2, avatarSize/2
        
        surface.SetMaterial(Material("materials/voice_hud/vgui/models/circle.png"))
        surface.SetDrawColor(255 * voiceVolume * 2, 255 * voiceVolume * 2, 255 * voiceVolume * 2, 255 * talkAmt * fade)
        surface.DrawTexturedRect(circleX - circleSize/2, circleY - circleSize/2, circleSize, circleSize)
    end
    
    function panel:UpdateAvatarPosition()
        if IsValid(Avatar) then
            Avatar:SetPos(2, 2)
            Avatar:SetSize(self:GetTall() - 4, self:GetTall() - 4)
        end
    end
    
    panel:UpdateAvatarPosition()
    
    return panel
end

local function CreateVoiceBGSetting(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(230)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local currentBG = LoadVoiceBackground()
    local previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_voicebg_cache") or nil
    local isTalking = false
    local previewPanel
    
    local animationTimer = "VoicePreviewAnimation_" .. tostring(panel)
    timer.Create(animationTimer, 2, 0, function()
        if IsValid(panel) then
            isTalking = not isTalking
            if IsValid(previewPanel) then
                previewPanel:InvalidateLayout()
            end
        else
            timer.Remove(animationTimer)
        end
    end)
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(6, 0, 0, w, h, Color(56, 56, 56, 148 * fade))
        if self:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_voice_bg or "Фон голосового чата", "H.25", 15, 25, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hg.CurLoc.setting_voice_bg_select or "Укажи ссылку на картинку", "H.18", 15, 45, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local previewContainer = vgui.Create("DPanel", panel)
    previewContainer:SetSize(400, 50)
    previewContainer:SetPos(15, 70)
    
    function previewContainer:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 150 * fade))
    end
    
    previewPanel = CreateVoicePanelPreview(previewContainer, 0, 0, 400, 50, previewMat, isTalking)
    
    local urlEntry = vgui.Create("DTextEntry", panel)
    urlEntry:SetSize(520, 28)
    urlEntry:SetPos(15, 135)
    urlEntry:SetText(currentBG or "")
    urlEntry:SetTextColor(Color(235, 235, 235))
    urlEntry:SetHighlightColor(Color(90, 110, 140))
    urlEntry:SetCursorColor(Color(255, 255, 255))
    urlEntry:SetPaintBackground(false)
    urlEntry:SetPlaceholderText("https://")
    urlEntry:SetPlaceholderColor(Color(130, 130, 130))

    SetupTextEntryFocus(urlEntry)

    function urlEntry:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200 * fade))
        
        local col = self:GetTextColor()
        self:SetTextColor(Color(col.r, col.g, col.b, 255 * fade))
        
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end
    
    local applyBtn = vgui.Create("DButton", panel)
    applyBtn:SetSize(120, 30)
    applyBtn:SetPos(540, 132)
    applyBtn:SetText("")
    
    function applyBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 80, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(90, 90, 100, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_apply or "OK", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function applyBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        local url = NormalizeHttpURL(urlEntry:GetText() or "")
        urlEntry:SetText(url)
        SaveVoiceBackground(url)
        currentBG = url

        hook.Run("HG_VoiceBG_Changed", url)

    end
    
    local resetBtn = vgui.Create("DButton", panel)
    resetBtn:SetSize(120, 30)
    resetBtn:SetPos(670, 132)
    resetBtn:SetText("")
    
    function resetBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 70, 70, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(140, 90, 90, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_reset or "Сброс", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function resetBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        urlEntry:SetText("")
        SaveVoiceBackground("")
        currentBG = ""
    end
    
    function panel:UpdatePreview()
        currentBG = LoadVoiceBackground()
        previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_voicebg_cache") or nil
        if IsValid(previewPanel) then
            previewPanel:Remove()
            previewPanel = CreateVoicePanelPreview(previewContainer, 0, 0, 400, 50, previewMat, isTalking)
        end
    end
    
    local updateTimer = "VoiceBGPreviewUpdate_" .. tostring(panel)
    timer.Create(updateTimer, 1, 0, function()
        if IsValid(panel) then
            panel:UpdatePreview()
        else
            timer.Remove(updateTimer)
        end
    end)
    
    function panel:OnRemove()
        timer.Remove(animationTimer)
        timer.Remove(updateTimer)
    end
    
    return panel
end

local function CreateTabBGSetting(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(170)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local currentBG = LoadTabBackground()
    local previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_tab_bg") or nil
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(6, 0, 0, w, h, Color(56, 56, 56, 148 * fade))
        if self:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_tab_bg_title or "Фон TAB", "H.25", 15, 25, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hg.CurLoc.setting_tab_bg_desc or "Укажи ссылку на картинку", "H.18", 15, 45, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if previewMat then
            surface.SetMaterial(previewMat)
            surface.SetDrawColor(255,255,255,180 * fade)
            surface.DrawTexturedRect(w - 160, 20, 140, 80)
            surface.SetDrawColor(0,0,0,80 * fade)
            surface.DrawRect(w - 160, 20, 140, 80)
        end
    end
    
    local urlEntry = vgui.Create("DTextEntry", panel)
    urlEntry:SetSize(520, 28)
    urlEntry:SetPos(15, 95)
    urlEntry:SetText(currentBG or "")
    urlEntry:SetTextColor(Color(235, 235, 235))
    urlEntry:SetHighlightColor(Color(90, 110, 140))
    urlEntry:SetCursorColor(Color(255, 255, 255))
    urlEntry:SetPaintBackground(false)
    urlEntry:SetPlaceholderText("https://")
    urlEntry:SetPlaceholderColor(Color(130, 130, 130))

    SetupTextEntryFocus(urlEntry)

    function urlEntry:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200 * fade))
        
        local col = self:GetTextColor()
        self:SetTextColor(Color(col.r, col.g, col.b, 255 * fade))
        
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end
    
    local applyBtn = vgui.Create("DButton", panel)
    applyBtn:SetSize(120, 30)
    applyBtn:SetPos(540, 92)
    applyBtn:SetText("")
    
    function applyBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 80, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(90, 90, 100, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_apply or "OK", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function applyBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        local url = NormalizeHttpURL(urlEntry:GetText() or "")
        urlEntry:SetText(url)
        SaveTabBackground(url)
        currentBG = url
        previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_tab_bg") or nil

        hook.Run("HG_TabBG_Changed", url)
    end
    
    local resetBtn = vgui.Create("DButton", panel)
    resetBtn:SetSize(120, 30)
    resetBtn:SetPos(670, 92)
    resetBtn:SetText("")
    
    function resetBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 70, 70, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(140, 90, 90, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_reset or "Сброс", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function resetBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        urlEntry:SetText("")
        SaveTabBackground("")
        currentBG = ""
        previewMat = nil
    end
    
    return panel
end

local function CreateScoreboardRowPreview(parent, x, y, w, h, bgMaterial)
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(x, y)
    panel:SetSize(w, h)
    
    local avatar = vgui.Create("AvatarImage", panel)
    avatar:SetPlayer(LocalPlayer(), 64)
    avatar:SetPos(4, 4)
    avatar:SetSize(h - 8, h - 8)
    
    function panel:Paint(pw, ph)
        local fade = open_fade or 1
        if IsValid(avatar) then avatar:SetAlpha(255 * fade) end
        
        if bgMaterial then
            surface.SetMaterial(bgMaterial)
            surface.SetDrawColor(255, 255, 255, 200 * fade)
            surface.DrawTexturedRect(0, 0, pw, ph)
            surface.SetDrawColor(0, 0, 0, 120 * fade)
            surface.DrawRect(0, 0, pw, ph)
        else
            draw.RoundedBox(4, 0, 0, pw, ph, Color(24, 24, 24, 200 * fade))
        end
        
        draw.SimpleText("Мёртв", "H.18", 120, ph / 2, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("superadmin", "H.18", 260, ph / 2, Color(255, 0, 0, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(LocalPlayer():Name(), "H.18", 430, ph / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("1h 27m", "H.18", 620, ph / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Невиновные", "H.18", 760, ph / 2, Color(0, 140, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    function panel:UpdateAvatar()
        if IsValid(avatar) then
            avatar:SetPos(4, 4)
            avatar:SetSize(self:GetTall() - 8, self:GetTall() - 8)
        end
    end
    
    panel:UpdateAvatar()
    return panel
end

local function CreateScoreboardRowBGSetting(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(230)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)

    local currentBG = LoadScoreboardRowBackground()
    local previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_scoreboard_row_bg", "png") or nil
    local previewPanel

    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(6, 0, 0, w, h, Color(56, 56, 56, 148 * fade))
        if self:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_row_bg_title or "Фон строки TAB", "H.25", 15, 25, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(hg.CurLoc.setting_row_bg_desc or "Укажи ссылку на картинку", "H.18", 15, 45, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local previewContainer = vgui.Create("DPanel", panel)
    previewContainer:SetSize(860, 50)
    previewContainer:SetPos(15, 70)
    function previewContainer:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 150 * fade))
    end
    previewPanel = CreateScoreboardRowPreview(previewContainer, 0, 0, 860, 50, previewMat)

    local urlEntry = vgui.Create("DTextEntry", panel)
    urlEntry:SetSize(520, 28)
    urlEntry:SetPos(15, 135)
    urlEntry:SetText(currentBG or "")
    urlEntry:SetTextColor(Color(235, 235, 235))
    urlEntry:SetHighlightColor(Color(90, 110, 140))
    urlEntry:SetCursorColor(Color(255, 255, 255))
    urlEntry:SetPaintBackground(false)
    urlEntry:SetPlaceholderText("https://")
    urlEntry:SetPlaceholderColor(Color(130, 130, 130))

    SetupTextEntryFocus(urlEntry)

    function urlEntry:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200 * fade))
        
        local col = self:GetTextColor()
        self:SetTextColor(Color(col.r, col.g, col.b, 255 * fade))
        
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end

    local applyBtn = vgui.Create("DButton", panel)
    applyBtn:SetSize(120, 30)
    applyBtn:SetPos(540, 132)
    applyBtn:SetText("")

    function applyBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 80, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(90, 90, 100, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_apply or "ОК", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function applyBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        local url = NormalizeHttpURL(urlEntry:GetText() or "")
        urlEntry:SetText(url)
        SaveScoreboardRowBackground(url)
        currentBG = url
        previewMat = currentBG ~= "" and GetCustomMaterialForSettings(currentBG, "gomigrad_scoreboard_row_bg", "png") or nil
        if IsValid(previewPanel) then
            previewPanel:Remove()
            previewPanel = CreateScoreboardRowPreview(previewContainer, 0, 0, 860, 50, previewMat)
        end
    end

    local resetBtn = vgui.Create("DButton", panel)
    resetBtn:SetSize(120, 30)
    resetBtn:SetPos(670, 132)
    resetBtn:SetText("")

    function resetBtn:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 70, 70, 200 * fade))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(140, 90, 90, 200 * fade))
        end
        draw.SimpleText(hg.CurLoc.setting_reset or "Сброс", "H.18", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function resetBtn:DoClick()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        urlEntry:SetText("")
        SaveScoreboardRowBackground("")
        currentBG = ""
        previewMat = nil
        if IsValid(previewPanel) then
            previewPanel:Remove()
            previewPanel = CreateScoreboardRowPreview(previewContainer, 0, 0, 860, 50, nil)
        end
    end

    return panel
end

local function BuildAccountTab(parent)
    if not CanUseSkinsLocal() then
        SaveVoiceBackground("")
        SaveScoreboardRowBackground("")
        SaveTabBackground("")

        local blocked = vgui.Create("DPanel", parent)
        blocked:SetTall(70)
        blocked:Dock(TOP)
        blocked:DockMargin(2, 2, 2, 2)
        function blocked:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(6, 0, 0, w, h, Color(56, 56, 56, 148 * fade))
            draw.SimpleText("Фоны доступны только с ролью.", "H.25", 15, h / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return
    end

    local voice = CreateVoiceBGSetting(parent)
    if voice then
        voice:Dock(TOP)
        voice:DockMargin(2, 2, 2, 2)
    end
    local rowbg = CreateScoreboardRowBGSetting(parent)
    if rowbg then
        rowbg:Dock(TOP)
        rowbg:DockMargin(2, 2, 2, 2)
    end
end



local function CreateFOVSlider(parent, setting)
    local panel = vgui.Create("hg_frame", parent)
    panel:SetDraggable(false)
    panel:SetTitle("")
    panel:ShowCloseButton(false)
    panel:SetTall(70)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local currentValue = GGrad_ConfigSettings[setting.var] or setting.min
    local isDragging = false
    local lastSoundTime = 0
    local sliderWidth = 250
    local sliderHeight = 12
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        local mul_daun = (self.CurSize or 1)

        SetDrawColor(self.DefaultClr.r,self.DefaultClr.g,self.DefaultClr.b,190 * fade)
        DrawRect(w/2 * (1-mul_daun),0,w * mul_daun,h)
        
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
        
        draw.SimpleText(setting.name, "H.25", 10, 20, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if setting.desc then
            draw.SimpleText(setting.desc, "H.18", 10, 40, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        draw.SimpleText(currentValue, "H.25", w - 30, 20, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        local sliderX = 10
        local sliderY = 53
        
        draw.RoundedBox(6, sliderX, sliderY, sliderWidth, sliderHeight, Color(80, 80, 80, 200 * fade))
        
        local fraction = (currentValue - setting.min) / (setting.max - setting.min)
        local filledWidth = sliderWidth * fraction
        draw.RoundedBox(6, sliderX, sliderY, filledWidth, sliderHeight, Color(102, 102, 102, 255 * fade))
        
        local knobPos = sliderX + filledWidth
        local knobSize = 20
        draw.RoundedBox(knobSize/2, knobPos - knobSize/2, sliderY - (knobSize - sliderHeight)/2, knobSize, knobSize, Color(240, 240, 245, 255 * fade))
        
        if isDragging or (self:IsHovered() and gui.MouseX() >= sliderX and gui.MouseX() <= sliderX + sliderWidth and 
           gui.MouseY() >= sliderY - 10 and gui.MouseY() <= sliderY + sliderHeight + 10) then
            draw.RoundedBox((knobSize + 4)/2, knobPos - (knobSize + 4)/2, sliderY - (knobSize + 4 - sliderHeight)/2, knobSize + 4, knobSize + 4, Color(255, 255, 255, 30 * fade))
        end
    end
    
    function panel:OnMousePressed(mouseCode)
        if mouseCode == MOUSE_LEFT then
            local mouseX, mouseY = gui.MousePos()
            local panelX, panelY = self:LocalToScreen(0, 0)
            local sliderX = panelX + 10
            local sliderY = panelY + 50
            
            if mouseX >= sliderX and mouseX <= sliderX + sliderWidth and 
               mouseY >= sliderY - 10 and mouseY <= sliderY + sliderHeight + 10 then
                isDragging = true
                self:MouseCapture(true)
                surface.PlaySound("homigrad/vgui/csgo_ui_contract_type10.wav")
                
                local fraction = (mouseX - sliderX) / sliderWidth
                fraction = math.Clamp(fraction, 0, 1)
                local newValue = math.Round(setting.min + fraction * (setting.max - setting.min))
                
                if newValue != currentValue then
                    currentValue = newValue
                    GGrad_ConfigSettings[setting.var] = currentValue
                    RunConsoleCommand("hg_fov", currentValue)
                    surface.PlaySound("homigrad/vgui/csgo_ui_contract_type10.wav")
                end
                
                return true
            end
        end
    end
    
    function panel:OnMouseReleased(mouseCode)
        if isDragging and mouseCode == MOUSE_LEFT then
            isDragging = false
            self:MouseCapture(false)
            ConfigSettingSync()
            surface.PlaySound("homigrad/vgui/csgo_ui_contract_type10.wav")
        end
    end
    
    function panel:OnCursorMoved(x, y)
        if isDragging then
            local mouseX = gui.MousePos()
            local panelX = self:LocalToScreen(0, 0)
            local sliderX = panelX + 10
            
            local fraction = (mouseX - sliderX) / sliderWidth
            fraction = math.Clamp(fraction, 0, 1)
            local newValue = math.Round(setting.min + fraction * (setting.max - setting.min))
            
            if newValue != currentValue then
                currentValue = newValue
                GGrad_ConfigSettings[setting.var] = currentValue
                RunConsoleCommand("hg_fov", currentValue)
                
                if CurTime() - lastSoundTime > 0.1 then
                    surface.PlaySound("homigrad/vgui/csgo_ui_contract_type10.wav")
                    lastSoundTime = CurTime()
                end
            end
        end
    end
    
    return panel
end

local function CreateSettingPanel(parent, setting)
    if setting.type == "slider" then
        return CreateFOVSlider(parent, setting)
    end
    
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(60)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local isHovered = false
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 148 * fade))
        
        if isHovered then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
    end
    
    local button = vgui.Create("DButton", panel)
    button:SetText("")
    button:Dock(FILL)
    button:DockMargin(0, 0, 0, 0)
    
    function button:Paint(w, h)
        local fade = open_fade or 1
        draw.SimpleText(setting.name, "H.25", 10, h/2 - 8, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if setting.desc then
            draw.SimpleText(setting.desc, "H.18", 10, h/2 + 8, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    local switch = vgui.Create("DCheckBox", panel)
    switch:SetSize(80, 30)
    
    function switch:Paint(w, h)
        local fade = open_fade or 1
        local checked = self:GetChecked()
        local color = checked and Color(0, 255, 42, 255 * fade) or Color(255, 0, 0, 255 * fade)
        
        draw.RoundedBox(30, 0, 0, w, h, color)
        
        local circlePos = checked and (w * 0.8) or (w * 0.15)
        draw.RoundedBox(30, circlePos - h * 0.3, h * 0.1, h * 0.8, h * 0.8, Color(240, 240, 245, 255 * fade))
        
        if self:IsHovered() then
            draw.RoundedBox(30, 0, 0, w, h, Color(148, 148, 148, 30 * fade))
        end
    end
    
    local currentValue = GGrad_ConfigSettings[setting.var]
    switch:SetChecked(currentValue)
    
    function switch:OnChange(val)
        GGrad_ConfigSettings[setting.var] = val
        ConfigSettingSync()
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        
        if isHovered then
            local hintData = SettingHints[setting.var]
            if hintData and hintImage and hintDesc then
                local matPath = val and hintData.on or hintData.off
                local mat = Material(matPath)
                if mat and not mat:IsError() then
                    hintImage:SetMaterial(mat)
                    hintImage:SetVisible(true)
                    hintDesc:SetText(hintData.desc)
                end
            end
        end
    end
    
    function button:DoClick()
        switch:Toggle()
    end
    
    function button:OnCursorEntered()
        isHovered = true
        local hintData = SettingHints[setting.var]
        if hintData and hintImage and hintDesc then
            local currentState = GGrad_ConfigSettings[setting.var]
            local matPath = currentState and hintData.on or hintData.off
            local mat = Material(matPath)
            
            if mat and not mat:IsError() then
                hintImage:SetMaterial(mat)
                hintImage:SetVisible(true)
                hintDesc:SetText(hintData.desc)
            end
        end
    end
    
    function button:OnCursorExited()
        isHovered = false
        if hintImage then
            hintImage:SetVisible(false)
        end
        if hintDesc then
            hintDesc:SetText("")
        end
    end
    
    function panel:PerformLayout(w, h)
        switch:SetPos(w - 90, 15)
    end
    
    return panel
end

local function CreateOptimizationPanel(parent, setting)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(50)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local isHovered = false
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 148 * fade))
        
        if isHovered then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
    end
    
    local button = vgui.Create("DButton", panel)
    button:SetText("")
    button:Dock(FILL)
    button:DockMargin(0, 0, 0, 0)
    
    function button:Paint(w, h)
        local fade = open_fade or 1
        draw.SimpleText(setting.name, "H.25", 10, h/2 - 8, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if setting.desc then
            draw.SimpleText(setting.desc, "H.18", 10, h/2 + 8, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    local switch = vgui.Create("DCheckBox", panel)
    switch:SetSize(80, 30)
    
    function switch:Paint(w, h)
        local fade = open_fade or 1
        local checked = self:GetChecked()
        local color = checked and Color(0, 255, 42, 255 * fade) or Color(255, 0, 0, 255 * fade)
        
        draw.RoundedBox(30, 0, 0, w, h, color)
        
        local circlePos = checked and (w * 0.8) or (w * 0.15)
        draw.RoundedBox(30, circlePos - h * 0.3, h * 0.1, h * 0.8, h * 0.8, Color(240, 240, 245, 255 * fade))
        
        if self:IsHovered() then
            draw.RoundedBox(30, 0, 0, w, h, Color(148, 148, 148, 30 * fade))
        end
    end
    
    local currentState
    if setting.command then
        currentState = GetConVar(setting.command):GetString() == setting.disable_value
    else
        currentState = GGrad_ConfigSettings[setting.var]
    end
    
    switch:SetChecked(currentState)
    
    function switch:OnChange(val)
        if setting.command then
            local param = val and setting.disable_value or setting.enable_value
            RunConsoleCommand(setting.command, param)
        else
            GGrad_ConfigSettings[setting.var] = val
            ConfigSettingSync()
        end
        
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        
        if isHovered then
            local hintData = SettingHints[setting.var]
            if hintData and hintImage and hintDesc then
                local matPath = val and hintData.on or hintData.off
                local mat = Material(matPath)
                if mat and not mat:IsError() then
                    hintImage:SetMaterial(mat)
                    hintImage:SetVisible(true)
                    hintDesc:SetText(hintData.desc)
                end
            end
        end
    end
    
    function button:DoClick()
        switch:Toggle()
    end
    
    function button:OnCursorEntered()
        isHovered = true
        local hintData = SettingHints[setting.var]
        if hintData and hintImage and hintDesc then
            local currentState
            if setting.command then
                currentState = GetConVar(setting.command):GetString() == setting.disable_value
            else
                currentState = GGrad_ConfigSettings[setting.var]
            end
            
            local matPath = currentState and hintData.on or hintData.off
            local mat = Material(matPath)
            
            if mat and not mat:IsError() then
                hintImage:SetMaterial(mat)
                hintImage:SetVisible(true)
                hintDesc:SetText(hintData.desc)
            end
        end
    end
    
    function button:OnCursorExited()
        isHovered = false
        if hintImage then
            hintImage:SetVisible(false)
        end
        if hintDesc then
            hintDesc:SetText("")
        end
    end
    
    function panel:PerformLayout(w, h)
        switch:SetPos(w - 90, 15)
    end
    
    return panel
end

local function CreateEffectsPanel(parent, setting)
    if not setting then return end
    
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(50)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    local isHovered = false
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 148 * fade))
        
        if isHovered then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
    end
    
    local button = vgui.Create("DButton", panel)
    button:SetText("")
    button:Dock(FILL)
    button:DockMargin(0, 0, 0, 0)
    
    function button:Paint(w, h)
        local fade = open_fade or 1
        draw.SimpleText(setting.name, "H.25", 10, h/2 - 8, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if setting.desc then
            draw.SimpleText(setting.desc, "H.18", 10, h/2 + 8, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    local switch = vgui.Create("DCheckBox", panel)
    switch:SetSize(80, 30)
    
    function switch:Paint(w, h)
        local fade = open_fade or 1
        local checked = self:GetChecked()
        local color = checked and Color(0, 255, 42, 255 * fade) or Color(255, 0, 0, 255 * fade)
        
        draw.RoundedBox(30, 0, 0, w, h, color)
        
        local circlePos = checked and (w * 0.8) or (w * 0.15)
        draw.RoundedBox(30, circlePos - h * 0.3, h * 0.1, h * 0.8, h * 0.8, Color(240, 240, 245, 255 * fade))
        
        if self:IsHovered() then
            draw.RoundedBox(30, 0, 0, w, h, Color(148, 148, 148, 30 * fade))
        end
    end
    
    local currentState
    if setting and setting.command then
        currentState = GetConVar(setting.command):GetString() == (setting.disable_value or "0")
    elseif setting then
        currentState = GGrad_ConfigSettings[setting.var]
    else
        currentState = false
    end
    
    switch:SetChecked(currentState)
    
    function switch:OnChange(val)
        if setting and setting.command then
            local param = val and (setting.disable_value or "0") or (setting.enable_value or "1")
            RunConsoleCommand(setting.command, param)
        elseif setting then
            GGrad_ConfigSettings[setting.var] = val
            ConfigSettingSync()
        end
        
        surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        
        if isHovered and setting then
            local hintData = SettingHints[setting.var]
            if hintData and hintImage and hintDesc then
                local matPath = val and hintData.on or hintData.off
                local mat = Material(matPath)
                if mat and not mat:IsError() then
                    hintImage:SetMaterial(mat)
                    hintImage:SetVisible(true)
                    hintDesc:SetText(hintData.desc)
                end
            end
        end
    end
    
    function button:DoClick()
        switch:Toggle()
    end
    
    function button:OnCursorEntered()
        isHovered = true
        if not setting then return end
        local hintData = SettingHints[setting.var]
        if hintData and hintImage and hintDesc then
            local currentState
            if setting and setting.command then
                currentState = GetConVar(setting.command):GetString() == (setting.disable_value or "0")
            elseif setting then
                currentState = GGrad_ConfigSettings[setting.var]
            else
                currentState = false
            end
            
            local matPath = currentState and hintData.on or hintData.off
            local mat = Material(matPath)
            
            if mat and not mat:IsError() then
                hintImage:SetMaterial(mat)
                hintImage:SetVisible(true)
                hintDesc:SetText(hintData.desc)
            end
        end
    end
    
    function button:OnCursorExited()
        isHovered = false
        if hintImage then
            hintImage:SetVisible(false)
        end
        if hintDesc then
            hintDesc:SetText("")
        end
    end
    
    function panel:PerformLayout(w, h)
        switch:SetPos(w - 90, 15)
    end
    
    return panel
end

local function CreateKeybindPanel(parent, bind)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(50)
    panel:Dock(TOP)
    panel:DockMargin(2, 2, 2, 2)
    
    function panel:Paint(w, h)
        local fade = open_fade or 1
        draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 148 * fade))
        
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(70, 70, 70, 180 * fade))
        end
    end
    
    local button = vgui.Create("DButton", panel)
    button:SetText("")
    button:Dock(FILL)
    button:DockMargin(0, 0, 0, 0)
    
    function button:Paint(w, h)
        local fade = open_fade or 1
        draw.SimpleText(bind.name, "H.25", 10, h/2 - 8, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if bind.desc then
            draw.SimpleText(bind.desc, "H.18", 10, h/2 + 8, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    local binder = vgui.Create("DBinder", panel)
    binder:SetSize(80, 40)

    
    function binder:Paint(w, h)
        local fade = open_fade or 1
        binder:SetText("")
        draw.RoundedBox(4, 0, 0, w, h, Color(41, 41, 41, 200 * fade))
        
        local keyText = hg.CurLoc.setting_key_none
        if binder:GetSelectedNumber() > 0 then
            keyText = input.GetKeyName(binder:GetSelectedNumber())
        end
        
        draw.SimpleText(keyText, "H.25", w/2, h/2, Color(240, 240, 245, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local savedKey = file.Read("gomigrad_settings/" .. bind.var .. ".txt", "DATA")
    if savedKey and savedKey != "" then
        local keyCode = tonumber(savedKey)
        if keyCode and keyCode > 0 then
            binder:SetSelectedNumber(keyCode)
            
            hook.Add("PlayerButtonDown", "KeyBind_" .. bind.var, function(ply, button)
                if ply == LocalPlayer() and button == keyCode then
                    RunConsoleCommand(bind.command)
                end
            end)
        end
    end
    
    function binder:OnChange(keyCode)
        if keyCode and keyCode > 0 then
            file.Write("gomigrad_settings/" .. bind.var .. ".txt", tostring(keyCode))
            
            hook.Remove("PlayerButtonDown", "KeyBind_" .. bind.var)
            hook.Add("PlayerButtonDown", "KeyBind_" .. bind.var, function(ply, button)
                if ply == LocalPlayer() and button == keyCode then
                    RunConsoleCommand(bind.command)
                end
            end)
            
            surface.PlaySound("homigrad/vgui/csgo_ui_page_scroll.wav")
        end
    end
    
    function panel:PerformLayout(w, h)
        binder:SetPos(w - 90, 6)
    end
    
    return panel
end

hook.Add("HG_ServerSkins_Updated", "SettingsPage_Skins", function()
    if IsValid(skinsContentScroll) then
        BuildSkinsTab(skinsContentScroll)
    end
end)

file.CreateDir("gomigrad_settings")

hook.Add("HUDPaint","Settings_Page",function()
    if not hg.ScoreBoard then return end
    if not IsValid(ScoreBoardPanel) then 
        open = false 
        if IsValid(panelka) then panelka:Remove() end
        return 
    end
    
    if hg.ScoreBoard == 4 and not open then
        open = true
        
        local MainPanel = vgui.Create("hg_frame", ScoreBoardPanel)
        MainPanel:SetDraggable(false)
        MainPanel:SetSize(ScrW(), ScrH())
        MainPanel:Center()
        MainPanel:SetDraggable(false)
        MainPanel:SetTitle(" ")
        MainPanel:ShowCloseButton(false)
        
        function MainPanel:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 170 * fade))
        end
        
        local LeftPanel = vgui.Create("DPanel", MainPanel)
        LeftPanel:SetSize(ScrW()/5, ScrH())
        LeftPanel:SetPos(-ScrW()/5, 0)

        function LeftPanel:Paint(w , h )
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 50 * fade))
        end
        
        
        
        local header = vgui.Create("hg_frame", LeftPanel)
        header:SetDraggable(false)
        header:SetTitle("")
        header:ShowCloseButton(false)
        header:SetTall(60)
        header:Dock(TOP)

        function header:Paint(w, h)
            local fade = open_fade or 1
            draw.SimpleText(hg.CurLoc.setting_header, "H.25", w/2, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        local RightPanel = vgui.Create("DPanel", MainPanel)
        RightPanel:SetSize(ScrW() - ScrW()/5, ScrH())
        RightPanel:SetPos(ScrW(), 0)
        
        function RightPanel:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 1 * fade))
        end
        
        local ContentPanel = vgui.Create("DPanel", RightPanel)
        ContentPanel:SetSize(RightPanel:GetWide() * 0.6, RightPanel:GetTall())
        ContentPanel:SetPos(0, 0)
        
        function ContentPanel:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 35, 1 * fade))
        end
        
        local HintPanel = vgui.Create("hg_frame", RightPanel)
        HintPanel:SetDraggable(false)
        HintPanel:SetTitle("")
        HintPanel:ShowCloseButton(false)
        HintPanel:SetSize(RightPanel:GetWide() * 0.3, RightPanel:GetTall())
        HintPanel:SetPos(RightPanel:GetWide() * 0.7, 0)

        function HintPanel:Paint(w, h)
        end
        
        
        hintImage = vgui.Create("DImage", HintPanel)
        hintImage:SetSize(HintPanel:GetWide() - 40, HintPanel:GetTall() * 0.5)
        hintImage:SetPos(20, 60)
        hintImage:SetVisible(false)
        function hintImage:Think()
            local fade = open_fade or 1
            self:SetAlpha(255 * fade)
        end
        
        hintDesc = vgui.Create("DLabel", HintPanel)
        hintDesc:SetSize(HintPanel:GetWide() - 40, HintPanel:GetTall() * 0.3)
        hintDesc:SetPos(20, HintPanel:GetTall() * 0.5 + 70)
        hintDesc:SetFont("ChatFont")
        hintDesc:SetTextColor(Color(200, 200, 200))
        hintDesc:SetText("")
        hintDesc:SetWrap(true)
        function hintDesc:Think()
            local fade = open_fade or 1
            local col = self:GetTextColor()
            self:SetTextColor(Color(col.r, col.g, col.b, 255 * fade))
        end
        
        local currentTab = 1
        local contentScroll
        local tabButtons = {}

        local function CreateLeftHeader(parent, text)
            local header = vgui.Create("DPanel", parent)
            header:SetTall(30)
            header:Dock(TOP)
            header:DockMargin(10, 15, 10, 0)
            function header:Paint(w, h)
                local fade = open_fade or 1
                draw.SimpleText(text, "H.25", 5, h/2, Color(180, 180, 180, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return header
        end
        
        local function CreateLeftButton(parent, text, isActive, onClick)
            local button = vgui.Create("hg_button", parent)
            button:SetTall(30)
            button:Dock(TOP)
            button:DockMargin(10, 5, 10, 0)
            button:SetText("")
            
            button.isActive = isActive
            
            function button:Paint(w,h)
                local fade = open_fade or 1
                
                if self.Shit then
                    self:Shit()
                end

                self:Draw(w,h)

                SetDrawColor(25,25,25, 255 * fade)
                DrawRect(0,0,w,h)

                if self:IsDown() then
                    SetDrawColor(20,20,20,255 * fade)
                    DrawRect(0,0,w,h)
                elseif self:IsHovered() then
                    SetDrawColor(255,255,255,5 * fade)
                    DrawRect(0,0,w,h)
                    if !self.ishovered then
                        self.ishovered = true
                    end
                else
                    self.ishovered = false
                end

                if cframe1 and cframe2 then
                end

                if self.SubPaint then
                    self:SubPaint(w,h)
                end

                if self.GradColor then
                    local clr = self.GradColor
                    surface.SetDrawColor(clr.r,clr.g,clr.b,15 * fade)
                    surface.SetMaterial(Material("vgui/gradient_up"))
                    surface.DrawTexturedRect(0,h-h/2,w,h/2)
                end
                draw.SimpleText(text, "H.25", 15, h/2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                draw.SimpleText(self.Text, (self.TextFont or "HS.18"), w / 2, h / 2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(self.LowerText, (self.LowerFont or "HS.18"), w / 2, h / 1.2, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                if self.Amt then
                    draw.SimpleText(self.Amt, "HS.12", w / 2, h / 1.5, Color(255, 255, 255, 100 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            
            function button:DoClick()
                surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav")
                onClick()
            end
            
            return button
        end
        
        local function SwitchTab(tabIndex, tabData)
            currentTab = tabIndex
            
            for i, button in ipairs(tabButtons) do
                button.isActive = (i == tabIndex)
            end
            
            if IsValid(contentScroll) then
                contentScroll:Remove()
            end
            
            contentScroll = vgui.Create("DScrollPanel", ContentPanel)
            contentScroll:Dock(FILL)
            contentScroll:DockMargin(10, 10, 10, 10)
            
            function contentScroll:Paint(w, h)
                local fade = open_fade or 1
                draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 35, 1 * fade))
            end
            
            local contentSbar = contentScroll:GetVBar()
            function contentSbar:Paint(w, h) 
                local fade = open_fade or 1
                draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 200 * fade))
            end
            function contentSbar.btnUp:Paint(w, h)
                local fade = open_fade or 1
                draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60, 200 * fade))
            end
            function contentSbar.btnDown:Paint(w, h)
                local fade = open_fade or 1
                draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60, 200 * fade))
            end
            function contentSbar.btnGrip:Paint(w, h)
                local fade = open_fade or 1
                draw.RoundedBox(0, 0, 0, w, h, Color(80, 80, 80, 200 * fade))
            end
            
            if hintImage then
                hintImage:SetVisible(false)
            end
            if tabData.id == "skins" then
                skinsContentScroll = contentScroll
                BuildSkinsTab(contentScroll)
                net.Start("HG_ServerSkins_Request")
                net.SendToServer()
            elseif tabData.build then
                skinsContentScroll = nil
                tabData.build(contentScroll)
            else
                skinsContentScroll = nil
                for _, setting in ipairs(tabData.list) do
                    if setting.var == "hide_usergroup" and not CanToggleHideUsergroup() then
                        if istable(GGrad_ConfigSettings) then
                            GGrad_ConfigSettings["hide_usergroup"] = false
                        end
                        continue
                    end
                    tabData.create(contentScroll, setting)
                end
            end
        end

        local tabs = {
            {id = "general", name = hg.CurLoc.setting_tab_general or "General", list = SettingsList, create = CreateSettingPanel},
            {id = "graphics", name = hg.CurLoc.setting_tab_graphics or "Graphics", list = OptimizationSettings, create = CreateOptimizationPanel},
            {id = "keyboard", name = hg.CurLoc.setting_tab_keyboard or "Keyboard", list = KeyBinds, create = CreateKeybindPanel},
            -- {id = "account", name = hg.CurLoc.setting_tab_account or "Account", build = BuildAccountTab} -- УБРАНО
        }
        
        /* -- УБРАНО (Скины)
        if CanUseSkinsLocal() then
            table.insert(tabs, {id = "skins", name = hg.CurLoc.setting_tab_skins or "Skins", build = function(p) BuildSkinsTab(p) end})
        end
        */
        
        local navItems = {
            {type = "header", text = hg.CurLoc.setting_section_settings or "SETTINGS"},
            {type = "tab", index = 1}, -- General
            {type = "tab", index = 2}, -- Graphics
            {type = "tab", index = 3}, -- Keyboard
            -- {type = "header", text = hg.CurLoc.setting_section_personalization or "PERSONALIZATION"}, -- УБРАНО
            -- {type = "tab", index = 4}, -- Account -- УБРАНО
            -- {type = "header", text = 'FORTNITE BALLS' or "FORTNITE BALLS"}, -- УБРАНО
        }

        /* -- УБРАНО (Скины)
        if CanUseSkinsLocal() then
            table.insert(navItems, {type = "tab", index = #tabs})
        end
        */
        
        for _, item in ipairs(navItems) do
            if item.type == "header" then
                CreateLeftHeader(LeftPanel, item.text)
            elseif item.type == "tab" then
                local tabData = tabs[item.index]
                if tabData then
                    local button = CreateLeftButton(LeftPanel, tabData.name or "Skins", currentTab == item.index, function()
                        SwitchTab(item.index, tabData)
                    end)
                    tabButtons[item.index] = button
                end
            end
        end
        
        local divider2 = vgui.Create("DPanel", LeftPanel)
        divider2:SetTall(1)
        divider2:Dock(TOP)
        divider2:DockMargin(10, 15, 10, 15)
        
        function divider2:Paint(w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(100, 100, 110, 100 * fade))
        end
        
        SwitchTab(1, tabs[1])
        
        function LeftPanel:Think()
            local targetX = 0
            self:SetPos(targetX, 0)
        end

        function RightPanel:Think()
            local targetX = ScrW()/5
            self:SetPos(targetX, 0)
        end

        
        panelka = MainPanel
        
    elseif hg.ScoreBoard != 4 and open then
        open = false
        if IsValid(panelka) then
            panelka:Remove()
            hintImage = nil
            hintDesc = nil
        end
        if IsValid(ScoreBoardPanel) then
            ScoreBoardPanel:SetKeyBoardInputEnabled(false)
        end
    end
end)
