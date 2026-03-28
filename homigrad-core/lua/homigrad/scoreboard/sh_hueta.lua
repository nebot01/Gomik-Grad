-- addons/homigrad-core/lua/homigrad/scoreboard/cl_custom_backgrounds.lua

local CustomBG = CustomBG or {}
hg.CustomBG = CustomBG

-- ============================================================================
-- Кэш и состояние
-- ============================================================================

CustomBG.VoicePanels = CustomBG.VoicePanels or {}
CustomBG.TabPanel = CustomBG.TabPanel or nil
CustomBG.VoiceURL = ""
CustomBG.TabURL = ""
CustomBG.LastVoiceURL = ""
CustomBG.LastTabURL = ""

-- ============================================================================
-- Загрузка URL из сохранённых настроек
-- ============================================================================

local function LoadVoiceURL()
    if hg.VoiceBG_GetURL then
        return hg.VoiceBG_GetURL() or ""
    end

    local path = "gomigrad_settings/voice_bg_url.txt"
    if file.Exists(path, "DATA") then
        local url = file.Read(path, "DATA")
        if url and url ~= "" then return url end
    end

    return ""
end

local function LoadTabURL()
    if hg.TabBG_GetURL then
        return hg.TabBG_GetURL() or ""
    end

    local path = "gomigrad_settings/tab_bg_url.txt"
    if file.Exists(path, "DATA") then
        local url = file.Read(path, "DATA")
        if url and url ~= "" then return url end
    end

    return ""
end

-- ============================================================================
-- Валидация URL
-- ============================================================================

local allowedExtensions = {
    ["png"] = true,
    ["jpg"] = true,
    ["jpeg"] = true,
    ["gif"] = true,
    ["webp"] = true,
    ["bmp"] = true,
    ["svg"] = true
}

local function IsValidImageURL(url)
    if not url or url == "" then return false end
    if #url > 2048 then return false end

    local lower = string.lower(url)
    if string.sub(lower, 1, 8) ~= "https://" and string.sub(lower, 1, 7) ~= "http://" then
        return false
    end

    -- Защита от javascript: и data: инъекций
    if string.find(lower, "javascript:", 1, true) then return false end
    if string.find(lower, "data:", 1, true) then return false end
    if string.find(lower, "<script", 1, true) then return false end

    return true
end

-- ============================================================================
-- Генерация HTML для DHTML панели
-- ============================================================================

local function BuildImageHTML(url, mode)
    -- mode: "cover" — заполнить целиком (для фона таба)
    --        "contain" — вписать с сохранением пропорций
    --        "voice" — специальный режим для войса

    local fitMode = "cover"
    if mode == "contain" then
        fitMode = "contain"
    elseif mode == "voice" then
        fitMode = "cover"
    end

    -- Экранируем URL для безопасной вставки в HTML
    local safeURL = string.gsub(url, "'", "\\'")
    safeURL = string.gsub(safeURL, '"', '\\"')
    safeURL = string.gsub(safeURL, "<", "&lt;")
    safeURL = string.gsub(safeURL, ">", "&gt;")

    local html = string.format([[
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    * {
        margin: 0;
        padding: 0;
        overflow: hidden;
    }

    body {
        width: 100vw;
        height: 100vh;
        background: transparent;
    }

    .bg-container {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%%;
        height: 100%%;
        background-image: url('%s');
        background-size: %s;
        background-position: center center;
        background-repeat: no-repeat;
    }

    .bg-container.error {
        background-image: none;
        background-color: rgba(255, 0, 0, 0.1);
    }

    .error-text {
        display: none;
        position: absolute;
        top: 50%%;
        left: 50%%;
        transform: translate(-50%%, -50%%);
        color: rgba(255, 100, 100, 0.8);
        font-family: Arial, sans-serif;
        font-size: 14px;
        text-align: center;
    }

    .bg-container.error .error-text {
        display: block;
    }
</style>
</head>
<body>
    <div class="bg-container" id="bgContainer">
        <div class="error-text">Image failed to load</div>
    </div>

    <script>
        var img = new Image();
        img.onload = function() {
            // Картинка загружена успешно
        };
        img.onerror = function() {
            document.getElementById('bgContainer').classList.add('error');
        };
        img.src = '%s';
    </script>
</body>
</html>
    ]], safeURL, fitMode, safeURL)

    return html
end

-- ============================================================================
-- Создание DHTML панели-контейнера
-- ============================================================================

local function CreateDHTMLPanel(parent, url, mode, w, h)
    if not IsValid(parent) then return nil end
    if not IsValidImageURL(url) then return nil end

    local container = vgui.Create("DPanel", parent)
    container:SetSize(w, h)
    container:SetPos(0, 0)
    container:SetMouseInputEnabled(false)
    container:SetKeyboardInputEnabled(false)
    container:SetPaintBackground(false)

    local dhtml = vgui.Create("DHTML", container)
    dhtml:SetSize(w, h)
    dhtml:SetPos(0, 0)
    dhtml:SetMouseInputEnabled(false)
    dhtml:SetKeyboardInputEnabled(false)
    dhtml:SetAllowLua(false)
    dhtml:SetScrollbars(false)
    dhtml:SetHTML(BuildImageHTML(url, mode))

    container.DHTML = dhtml
    container.URL = url
    container.Mode = mode

    -- Метод для обновления URL без пересоздания панели
    function container:SetImageURL(newURL)
        if not IsValidImageURL(newURL) then
            if IsValid(self.DHTML) then
                self.DHTML:SetHTML("")
            end
            self.URL = ""
            return
        end

        if newURL == self.URL then return end

        self.URL = newURL
        if IsValid(self.DHTML) then
            self.DHTML:SetHTML(BuildImageHTML(newURL, self.Mode))
        end
    end

    -- Метод для изменения размера
    function container:UpdateSize(newW, newH)
        self:SetSize(newW, newH)
        if IsValid(self.DHTML) then
            self.DHTML:SetSize(newW, newH)
        end
    end

    return container
end

-- ============================================================================
-- TAB BACKGROUND — Фон скорборда
-- ============================================================================

local function ApplyTabBackground()
    local url = LoadTabURL()
    CustomBG.TabURL = url

    -- Если URL не изменился и панель уже существует — ничего не делаем
    if url == CustomBG.LastTabURL and IsValid(CustomBG.TabPanel) then
        return
    end

    CustomBG.LastTabURL = url

    -- Удаляем старую панель
    if IsValid(CustomBG.TabPanel) then
        CustomBG.TabPanel:Remove()
        CustomBG.TabPanel = nil
    end

    -- Если URL пустой — просто убираем фон
    if url == "" then return end
    if not IsValid(ScoreBoardPanel) then return end

    -- Создаём DHTML панель поверх ScoreBoardPanel
    local bgPanel = CreateDHTMLPanel(
        ScoreBoardPanel,
        url,
        "cover",
        ScoreBoardPanel:GetWide(),
        ScoreBoardPanel:GetTall()
    )

    if not bgPanel then return end

    bgPanel:SetPos(0, 0)
    bgPanel:SetZPos(-999)  -- За всем контентом
    bgPanel:SetMouseInputEnabled(false)

    -- Полупрозрачный оверлей поверх картинки для читаемости
    local overlay = vgui.Create("DPanel", bgPanel)
    overlay:SetSize(bgPanel:GetWide(), bgPanel:GetTall())
    overlay:SetPos(0, 0)
    overlay:SetMouseInputEnabled(false)

    function overlay:Paint(w, h)
        local fade = open_fade or 1
        surface.SetDrawColor(0, 0, 0, 120 * fade)
        surface.DrawRect(0, 0, w, h)
    end

    bgPanel.Overlay = overlay

    -- Обновляем альфу контейнера вместе с open_fade
    function bgPanel:Think()
        if not IsValid(ScoreBoardPanel) then
            self:Remove()
            CustomBG.TabPanel = nil
            return
        end

        local fade = open_fade or 1
        self:SetAlpha(255 * fade)
        self:SetSize(ScoreBoardPanel:GetWide(), ScoreBoardPanel:GetTall())

        if IsValid(self.Overlay) then
            self.Overlay:SetSize(self:GetWide(), self:GetTall())
        end

        if IsValid(self.DHTML) then
            self.DHTML:SetSize(self:GetWide(), self:GetTall())
        end
    end

    CustomBG.TabPanel = bgPanel
end

-- ============================================================================
-- VOICE BACKGROUND — Фон войс-панелей
-- ============================================================================

-- Хук в систему voice chat. Перехватываем создание войс-панелей
-- и добавляем DHTML фон к каждой.

local function ApplyVoiceBackground(voicePanel)
    if not IsValid(voicePanel) then return end

    local url = LoadVoiceURL()
    CustomBG.VoiceURL = url

    if url == "" then
        -- Убираем DHTML фон если URL пустой
        if IsValid(voicePanel.CustomDHTMLBG) then
            voicePanel.CustomDHTMLBG:Remove()
            voicePanel.CustomDHTMLBG = nil
        end
        return
    end

    -- Если фон уже установлен с тем же URL — пропускаем
    if IsValid(voicePanel.CustomDHTMLBG) and voicePanel.CustomDHTMLBG.URL == url then
        return
    end

    -- Удаляем старый
    if IsValid(voicePanel.CustomDHTMLBG) then
        voicePanel.CustomDHTMLBG:Remove()
    end

    local w, h = voicePanel:GetSize()

    local bgPanel = CreateDHTMLPanel(
        voicePanel,
        url,
        "voice",
        w,
        h
    )

    if not bgPanel then return end

    bgPanel:SetPos(0, 0)
    bgPanel:SetZPos(-10)  -- За содержимым войс-панели, но внутри неё
    bgPanel:SetMouseInputEnabled(false)

    -- Оверлей для затемнения
    local overlay = vgui.Create("DPanel", bgPanel)
    overlay:SetSize(w, h)
    overlay:SetPos(0, 0)
    overlay:SetMouseInputEnabled(false)

    function overlay:Paint(pw, ph)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, pw, ph)
    end

    bgPanel.Overlay = overlay

    -- Следим за размером родительской панели
    function bgPanel:Think()
        if not IsValid(voicePanel) then
            self:Remove()
            return
        end

        local pw, ph = voicePanel:GetSize()
        self:SetSize(pw, ph)

        if IsValid(self.DHTML) then
            self.DHTML:SetSize(pw, ph)
        end

        if IsValid(self.Overlay) then
            self.Overlay:SetSize(pw, ph)
        end
    end

    voicePanel.CustomDHTMLBG = bgPanel
end

-- ============================================================================
-- Перехват создания войс-панелей
-- ============================================================================

-- Способ 1: Хук на PlayerStartVoice — ищем войс-панели после их создания
hook.Add("PlayerStartVoice", "CustomBG_VoiceStart", function(ply)
    -- Даём фрейм на создание панели движком
    timer.Simple(0, function()
        if not IsValid(ply) then return end

        local url = LoadVoiceURL()
        if url == "" then return end

        -- Ищем войс-панель для этого игрока
        -- Garry's Mod хранит их в g_VoicePanelList
        if g_VoicePanelList then
            for _, panelData in pairs(g_VoicePanelList) do
                if panelData and IsValid(panelData.Panel) and panelData.ply == ply then
                    ApplyVoiceBackground(panelData.Panel)
                end
            end
        end
    end)
end)

-- Способ 2: Если у Gomigrad своя система войса — хук на их кастомные панели
hook.Add("HG_VoicePanelCreated", "CustomBG_VoicePanel", function(panel, ply)
    if not IsValid(panel) then return end
    ApplyVoiceBackground(panel)
end)

-- ============================================================================
-- Основной Think — следим за изменениями URL и состоянием скорборда
-- ============================================================================

local nextCheck = 0
local CHECK_INTERVAL = 1  -- Проверяем раз в секунду, не каждый фрейм

hook.Add("Think", "CustomBG_URLWatcher", function()
    local now = RealTime()
    if now < nextCheck then return end
    nextCheck = now + CHECK_INTERVAL

    -- === TAB Background ===
    local newTabURL = LoadTabURL()
    if newTabURL ~= CustomBG.TabURL then
        CustomBG.TabURL = newTabURL

        if IsValid(ScoreBoardPanel) then
            ApplyTabBackground()
        end
    end

    -- Если скорборд открыт и панели нет — создаём
    if IsValid(ScoreBoardPanel) and not IsValid(CustomBG.TabPanel) and CustomBG.TabURL ~= "" then
        ApplyTabBackground()
    end

    -- Если скорборд закрыт — чистим
    if not IsValid(ScoreBoardPanel) and IsValid(CustomBG.TabPanel) then
        CustomBG.TabPanel:Remove()
        CustomBG.TabPanel = nil
        CustomBG.LastTabURL = ""
    end

    -- === Voice Background ===
    local newVoiceURL = LoadVoiceURL()
    if newVoiceURL ~= CustomBG.VoiceURL then
        CustomBG.VoiceURL = newVoiceURL

        -- Обновляем все существующие войс-панели
        if g_VoicePanelList then
            for _, panelData in pairs(g_VoicePanelList) do
                if panelData and IsValid(panelData.Panel) then
                    if newVoiceURL == "" then
                        -- Удаляем фон
                        if IsValid(panelData.Panel.CustomDHTMLBG) then
                            panelData.Panel.CustomDHTMLBG:Remove()
                            panelData.Panel.CustomDHTMLBG = nil
                        end
                    else
                        ApplyVoiceBackground(panelData.Panel)
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- Хук на открытие скорборда — применяем фон
-- ============================================================================

hook.Add("ScoreboardShow", "CustomBG_TabApply", function()
    -- Даём фрейм на создание ScoreBoardPanel
    timer.Simple(0, function()
        ApplyTabBackground()
    end)
end)

-- ============================================================================
-- Очистка при закрытии
-- ============================================================================

hook.Add("ScoreboardHide", "CustomBG_TabCleanup", function()
    -- Фон удалится вместе со ScoreBoardPanel как child,
    -- но на всякий случай чистим ссылку
    timer.Simple(0.3, function()
        if not IsValid(ScoreBoardPanel) then
            CustomBG.TabPanel = nil
            CustomBG.LastTabURL = ""
        end
    end)
end)

-- ============================================================================
-- Публичный API для других скриптов
-- ============================================================================

--- Принудительно обновить фон таба
function CustomBG.RefreshTab()
    CustomBG.LastTabURL = ""  -- Сбрасываем кэш чтобы пересоздать
    if IsValid(ScoreBoardPanel) then
        ApplyTabBackground()
    end
end

--- Принудительно обновить фон войса
function CustomBG.RefreshVoice()
    CustomBG.VoiceURL = ""  -- Сбрасываем кэш
    local newURL = LoadVoiceURL()
    CustomBG.VoiceURL = newURL

    if g_VoicePanelList then
        for _, panelData in pairs(g_VoicePanelList) do
            if panelData and IsValid(panelData.Panel) then
                ApplyVoiceBackground(panelData.Panel)
            end
        end
    end
end

--- Получить текущие URL
function CustomBG.GetVoiceURL()
    return CustomBG.VoiceURL
end

function CustomBG.GetTabURL()
    return CustomBG.TabURL
end

--- Проверить валидность URL
function CustomBG.ValidateURL(url)
    return IsValidImageURL(url)
end

-- ============================================================================
-- Интеграция с настройками — вызывается после сохранения в settings page
-- ============================================================================

-- Когда пользователь нажимает "OK" в настройках, вызываем обновление
hook.Add("HG_VoiceBG_Changed", "CustomBG_VoiceUpdate", function(newURL)
    CustomBG.VoiceURL = ""  -- Форсируем обновление
    CustomBG.RefreshVoice()
end)

hook.Add("HG_TabBG_Changed", "CustomBG_TabUpdate", function(newURL)
    CustomBG.LastTabURL = ""  -- Форсируем обновление
    CustomBG.RefreshTab()
end)

-- ============================================================================
-- Консольные команды для дебага
-- ============================================================================

concommand.Add("hg_bg_debug", function()
    print("=== CustomBG Debug ===")
    print("Voice URL: " .. tostring(CustomBG.VoiceURL))
    print("Tab URL: " .. tostring(CustomBG.TabURL))
    print("Tab Panel Valid: " .. tostring(IsValid(CustomBG.TabPanel)))
    print("ScoreBoardPanel Valid: " .. tostring(IsValid(ScoreBoardPanel)))

    local voiceCount = 0
    if g_VoicePanelList then
        for _, panelData in pairs(g_VoicePanelList) do
            if panelData and IsValid(panelData.Panel) then
                voiceCount = voiceCount + 1
                print("  Voice Panel: " .. tostring(panelData.ply) ..
                      " | Has BG: " .. tostring(IsValid(panelData.Panel.CustomDHTMLBG)))
            end
        end
    end
    print("Active Voice Panels: " .. voiceCount)
    print("======================")
end)

concommand.Add("hg_bg_refresh", function()
    CustomBG.RefreshTab()
    CustomBG.RefreshVoice()
    print("[CustomBG] Forced refresh of all backgrounds")
end)

print("[Gomigrad] Custom Backgrounds (DHTML) loaded")