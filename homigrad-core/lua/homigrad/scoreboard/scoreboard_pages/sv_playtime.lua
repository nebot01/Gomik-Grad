-- lua/autorun/server/sv_homigrad_playtime.lua

-- Имя переменной, которую ждет ваш скорборд (по коду это "TimeGay")
local NW_VAR_NAME = "TimeGay"
local SQL_KEY = "HG_TotalPlayTime"

-- Загрузка времени при входе игрока
hook.Add("PlayerInitialSpawn", "HG_PlayTime_Init", function(ply)
    -- Получаем сохраненное время из базы данных (PData)
    local savedTime = tonumber(ply:GetPData(SQL_KEY)) or 0
    
    -- Запоминаем время входа для расчетов
    ply.HG_SessionStart = CurTime()
    ply.HG_TotalSavedTime = savedTime

    -- Сразу отправляем клиентам текущее общее время
    ply:SetNWFloat(NW_VAR_NAME, savedTime)
end)

-- Регулярное обновление (каждую минуту, чтобы не спамить сеть каждую секунду)
-- Но для плавности в табе можно и чаще, но обычно 60 сек достаточно для базы.
-- Для таба мы обновляем NW переменную чаще.
timer.Create("HG_PlayTime_Think", 5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.HG_SessionStart then
            -- Считаем: Сохраненное время + (Текущее время - Время входа)
            local currentSessionTime = CurTime() - ply.HG_SessionStart
            local totalTime = ply.HG_TotalSavedTime + currentSessionTime
            
            -- Обновляем переменную для TAB меню
            ply:SetNWFloat(NW_VAR_NAME, totalTime)
        end
    end
end)

-- Сохранение при выходе игрока
hook.Add("PlayerDisconnected", "HG_PlayTime_Save", function(ply)
    if ply.HG_SessionStart then
        local currentSessionTime = CurTime() - ply.HG_SessionStart
        local totalTime = ply.HG_TotalSavedTime + currentSessionTime
        
        -- Сохраняем итоговое время в базу данных
        ply:SetPData(SQL_KEY, totalTime)
    end
end)

-- Сохранение всех при выключении сервера (на всякий случай)
hook.Add("ShutDown", "HG_PlayTime_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.HG_SessionStart then
            local currentSessionTime = CurTime() - ply.HG_SessionStart
            local totalTime = ply.HG_TotalSavedTime + currentSessionTime
            ply:SetPData(SQL_KEY, totalTime)
        end
    end
end)