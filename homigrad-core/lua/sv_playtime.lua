-- lua/autorun/server/sv_playtime_tracker.lua

-- Загрузка времени при входе
hook.Add("PlayerInitialSpawn", "HG_LoadPlayTime", function(ply)
    -- Читаем сохраненное время (или 0, если игрок новый)
    local savedTime = ply:GetPData("HG_TotalPlayTime", 0)
    ply.HG_SessionStart = CurTime()
    ply.HG_TotalTimeBase = tonumber(savedTime)
    
    -- Устанавливаем значение для скорборда
    ply:SetNWFloat("TimeGay", ply.HG_TotalTimeBase)
end)

-- Обновление времени каждую секунду (чтобы скорборд тикал в реальном времени)
timer.Create("HG_PlayTimeUpdate", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.HG_TotalTimeBase then
            local currentSession = CurTime() - (ply.HG_SessionStart or CurTime())
            local total = ply.HG_TotalTimeBase + currentSession
            
            -- Обновляем переменную, которую ищет ваш скорборд
            ply:SetNWFloat("TimeGay", total)
        end
    end
end)

-- Сохранение времени при выходе
hook.Add("PlayerDisconnected", "HG_SavePlayTime", function(ply)
    if ply.HG_TotalTimeBase then
        local currentSession = CurTime() - (ply.HG_SessionStart or CurTime())
        local total = ply.HG_TotalTimeBase + currentSession
        
        ply:SetPData("HG_TotalPlayTime", total)
    end
end)

-- Сохранение при выключении сервера (на всякий случай)
hook.Add("ShutDown", "HG_SaveAllTime", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.HG_TotalTimeBase then
            local currentSession = CurTime() - (ply.HG_SessionStart or CurTime())
            local total = ply.HG_TotalTimeBase + currentSession
            ply:SetPData("HG_TotalPlayTime", total)
        end
    end
end)