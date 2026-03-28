-- addons/hg/lua/hgamemode/z_roundsystem_1/dm/dm_cl.lua

dm = dm or {}
dm.WarmupEndTime = 0
dm.ShowEndScreen = false
dm.ScoreboardData = {}

-- Прием данных
net.Receive("DM_WarmupState", function()
    dm.WarmupEndTime = net.ReadFloat()
end)

net.Receive("DM_RoundEndScreen", function()
    local show = net.ReadBool()
    dm.ShowEndScreen = show
    if show then
        dm.ScoreboardData = net.ReadTable()
    else
        dm.ScoreboardData = {}
    end
end)

-- Глобальный хук для отрисовки
hook.Add("HUDPaint", "DM_GlobalHUD", function()
    -- Рисуем только если сейчас режим DM
    if (ROUND_NAME or "") ~= "dm" then return end

    local w, h = ScrW(), ScrH()

    -- 1. ТАЙМЕР РАЗМИНКИ
    if dm.WarmupEndTime > CurTime() then
        local timeLeft = math.ceil(dm.WarmupEndTime - CurTime())
        local text = "РАЗМИНКА: " .. timeLeft .. " СЕК"
        
        -- Используем стандартный шрифт GMod, если кастомного нет
        local font = "DermaLarge" 
        
        surface.SetFont(font)
        local tw, th = surface.GetTextSize(text)
        
        local x = w / 2 - tw / 2
        local y = h - 150 -- Чуть выше низа

        -- Тень
        draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 255))
        -- Текст (Ярко-красный)
        draw.SimpleText(text, font, x, y, Color(255, 0, 0, 255))
        
        draw.SimpleText("СТРЕЛЬБА ОТКЛЮЧЕНА", "DermaDefaultBold", w/2, y + 40, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    -- 2. ЭКРАН ПОБЕДЫ
    if dm.ShowEndScreen then
        -- Затемнение
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 220))
        
        draw.SimpleText("РАУНД ЗАВЕРШЕН", "DermaLarge", w/2, 100, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        
        local startY = 200
        local itemHeight = 50
        
        for i, data in ipairs(dm.ScoreboardData) do
            -- Рисуем только топ 10, чтобы не улетело за экран
            if i > 10 then break end

            local textColor = Color(255, 255, 255)
            local prefix = i .. ". "
            local name = data.name
            
            -- Отрисовка ПОБЕДИТЕЛЯ (1 место)
            if data.is_winner then
                -- Желтый фон для победителя
                draw.RoundedBox(8, w/2 - 300, startY - 5, 600, itemHeight, Color(255, 215, 0, 50))
                
                textColor = Color(255, 215, 0) -- Золотой текст
                prefix = "🏆 ПОБЕДИТЕЛЬ: "
            end
            
            local text = prefix .. name .. "  [ Фраги: " .. data.frags .. " ]"
            
            draw.SimpleText(text, "DermaLarge", w/2, startY, textColor, TEXT_ALIGN_CENTER)
            
            startY = startY + itemHeight + 10
        end
    end
end)

-- Стандартная функция режима (оставим её для совместимости)
function dm.HUDPaint()
    -- Она может быть пустой, так как мы используем глобальный хук выше
end

function dm.RenderScreenspaceEffects() end
function dm.RoundStart() hg.ROUND_START = CurTime() end