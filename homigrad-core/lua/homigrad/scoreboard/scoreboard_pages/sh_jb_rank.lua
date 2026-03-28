-- lua/autorun/sh_jb_ranks_fix.lua

-- 1. Создаем таблицу jb, если её нет (чтобы не было ошибок)
jb = jb or {}

-- 2. НАСТРОЙКА: Названия рангов и цвета (Shared часть)
local ranks_config = {
    [0] = { name = "No rank", color = Color(60, 60, 60) },
    [1] = { name = "Рядовой", color = Color(100, 100, 255) }, -- Cadet
    [2] = { name = "Сержант", color = Color(50, 50, 200) },   -- Sergeant
    [3] = { name = "Лейтенант", color = Color(0, 0, 150) },   -- Lieutenant
    [4] = { name = "Капитан", color = Color(255, 50, 50) }    -- Captain
}

-- Функция получения имени (используется в вашем скрипте)
function jb.GetPoliceRankName(rank)
    if ranks_config[rank] then
        return ranks_config[rank].name
    end
    return "Rank " .. rank
end

-- Функция получения цвета (используется в вашем скрипте)
function jb.GetPoliceRankColor(rank)
    if ranks_config[rank] then
        return ranks_config[rank].color
    end
    return Color(60, 60, 60)
end


-- 3. СЕРВЕРНАЯ ЧАСТЬ (Обработка и сохранение)
if SERVER then
    util.AddNetworkString("JB_PoliceRankSet")

    -- Когда игрок заходит на сервер, загружаем его ранг
    hook.Add("PlayerInitialSpawn", "JB_LoadPlayerRank", function(ply)
        local savedRank = ply:GetPData("jb_rank_save", 0) -- Загружаем из базы данных
        ply:SetNWInt("JBPoliceRank", tonumber(savedRank)) -- Ставим NWInt для scoreboard
    end)

    -- Обработка команды выдачи ранга из вашего меню
    net.Receive("JB_PoliceRankSet", function(len, ply)
        local target = net.ReadEntity()
        local rank = net.ReadUInt(3) -- 3 бита максимум значение 7, это покрывает ранги 0..4

        if not IsValid(ply) or not IsValid(target) then return end

        -- === ПРОВЕРКА ПРАВ ===
        -- Разрешаем повышать: супер-админы, админы, owner и игроки с рангом 4 (Капитан)
        local allowed = false

        if ply:IsSuperAdmin() or ply:IsAdmin() then allowed = true end
        if ply:GetUserGroup() == "owner" then allowed = true end
        if ply:GetNWInt("JBPoliceRank", 0) >= 4 then allowed = true end

        if not allowed then
            ply:ChatPrint("[JB] У вас нет прав менять ранги.")
            return
        end

        -- === ПОЛОТЁК РАНГА (только до 4) ===
        local maxRank = 4
        if rank > maxRank then
            ply:ChatPrint("[JB] Максимальный выдаваемый ранг: 4 (Капитан).")
            -- Отбрасываем попытку установить слишком высокий ранг
            return
        end

        -- Устанавливаем ранг для отображения (сразу видно всем)
        target:SetNWInt("JBPoliceRank", rank)
        
        -- Сохраняем ранг навсегда (чтобы не слетал при перезаходе)
        target:SetPData("jb_rank_save", rank)

        print(string.format("[JB Log] %s выдал ранг %d игроку %s", ply:Nick(), rank, target:Nick()))
    end)
end