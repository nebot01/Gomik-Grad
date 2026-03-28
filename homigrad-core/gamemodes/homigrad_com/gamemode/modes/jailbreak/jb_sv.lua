jb = jb or {}

jb.RoundEnds = 0

function jb.SpawnWarden(ply)
    local SpawnList = {}

    local weps_pri = {"weapon_m4a4"}
    local weps_sec = {"weapon_deagle_a"}
    local weps_oth = {"weapon_kknife","weapon_handcuffs","weapon_painkillers_hg","weapon_bandage","weapon_radio_event"}

    if #ReadDataMap("jb_warden") == 0 then
	    for i, ent in RandomPairs(ents.FindByClass("info_player_counterterrorist")) do
	    	table.insert(SpawnList,ent:GetPos())
	    end
    end

    ply:SetTeam(2)

    ply:Spawn()

    ply:SetMaxHealth(200)
    ply:SetHealth(200)

    if #ReadDataMap("jb_warden") != 0 then
        ply:SetPos(((table.Random(SpawnList) != nil and table.Random(SpawnList)[1] != nil) and table.Random(SpawnList)[1] or ply:GetPos()))
    else
        ply:SetPos(table.Random(SpawnList))
    end

    local wep_primary = ply:Give(table.Random(weps_pri))
    local wep_secondary = ply:Give(table.Random(weps_sec))
    for _, wep in pairs(weps_oth) do
        ply:Give(wep)
    end

    hg.Equip_Armor(ply,"helmet1")
    hg.Equip_Armor(ply,"vest6")

    wep_primary:SetClip1(wep_primary:GetMaxClip1())
    wep_secondary:SetClip1(wep_secondary:GetMaxClip1())

    ply:GiveAmmo(wep_primary:GetMaxClip1() * math.random(8,16), wep_primary:GetPrimaryAmmoType(), true)
    ply:GiveAmmo(wep_secondary:GetMaxClip1() * math.random(2,4), wep_secondary:GetPrimaryAmmoType(), true)

    timer.Simple(0,function()
        ply:SetPlayerColor(Color(0,17,255):ToVector())
        ply:SetSubMaterial()
    end)
end

function jb.SpawnPrisoner(ply)
    local weps_oth = {"weapon_knife_css"}

    local SpawnList = {}

    if #ReadDataMap("jb_prisoner") == 0 then
	    for i, ent in RandomPairs(ents.FindByClass("info_player_terrorist")) do
	    	table.insert(SpawnList,ent:GetPos())
	    end
    end

    ply:SetTeam(1)

    ply:Spawn()

    if #ReadDataMap("jb_prisoner") != 0 then
        ply:SetPos(((table.Random(SpawnList) != nil and table.Random(SpawnList)[1] != nil) and table.Random(SpawnList)[1] or ply:GetPos()))
    else
        ply:SetPos(table.Random(SpawnList))
    end

    local wep_other = ply:Give(table.Random(weps_oth))

    timer.Simple(0,function()
        ply:SetPlayerColor(Color(255,0,0):ToVector())
        ply:SetSubMaterial()
    end)
end

function jb.StartRoundSV()
    local plys = {}

    jb.RoundEnds = CurTime() + jb.TimeRoundEnds

    -- 1. Сначала всех переводим за заключенных
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == 1002 then -- Пропуск наблюдателей
            continue 
        end
        table.insert(plys, ply)
        ply:SetTeam(1)
        ply.AppearanceOverride = true
        jb.SpawnPrisoner(ply)
    end

    -- 2. Фильтруем список для поиска кандидатов в Охранники (Ранг >= 1)
    local wardenCandidates = {}
    for _, ply in ipairs(plys) do
        if ply:GetNWInt("JBPoliceRank", 0) >= 1 then
            table.insert(wardenCandidates, ply)
        end
    end

    -- 3. Выбираем первого охранника
    local htr1 = table.Random(wardenCandidates)
    
    if htr1 then
        -- Убираем его из списка заключенных и списка кандидатов
        table.RemoveByValue(plys, htr1)
        table.RemoveByValue(wardenCandidates, htr1)

        jb.SpawnWarden(htr1)

        -- 4. Если игроков больше 12, выбираем второго охранника из оставшихся кандидатов
        if #player.GetAll() > 12 and #wardenCandidates > 0 then
            local htr2 = table.Random(wardenCandidates)
            -- Убираем из списка заключенных (на всякий случай, хотя роль уже выдана)
            table.RemoveByValue(plys, htr2) 
            jb.SpawnWarden(htr2)
        end
    else
        -- (Опционально) Если ни у кого нет ранга, можно написать в чат
        PrintMessage(HUD_PRINTTALK, "[JB] Не удалось найти охранников с рангом 1+!")
    end
    
    game.CleanUpMap(false)
end

function jb.RoundThink()
    local T_ALIVE = team.GetCountLive(team.GetPlayers(2))
    local CT_ALIVE = team.GetCountLive(team.GetPlayers(1))

    if T_ALIVE == 0 and !ROUND_ENDED then
        ROUND_ENDED = true
        ROUND_ENDSIN = CurTime() + 8

        EndRound(1)
    end

    if CT_ALIVE == 0 and !ROUND_ENDED then
        ROUND_ENDED = true
        ROUND_ENDSIN = CurTime() + 8

        EndRound(2)
    end

    if jb.RoundEnds < CurTime() and !ROUND_ENDED then
        ROUND_ENDED = true
        ROUND_ENDSIN = CurTime() + 8

        EndRound(2)
    end
end

function jb.CanStart(forced)
    local mapname = string.lower(game.GetMap())

    -- 1. Проверка карты
    if !string.match(mapname,"jb_") then
        return false
    end

    -- 2. Проверка наличия охранников
    -- Если хотя бы у одного игрока (не наблюдателя) есть ранг >= 1, разрешаем старт
    local hasGuard = false
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() != 1002 and ply:GetNWInt("JBPoliceRank", 0) >= 1 then
            hasGuard = true
            break
        end
    end

    if not hasGuard then 
        return false -- Ни у кого нет ранга -> режим не начнется
    end

    return true
end

function jb.StartRoundSV()
    -- === ЭТАП 1: ПРОВЕРКА ПЕРЕД СТАРТОМ ===
    local wardenCandidates = {}
    
    -- Собираем список всех, кто МОЖЕТ быть охранником
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() != 1002 and ply:GetNWInt("JBPoliceRank", 0) >= 1 then
            table.insert(wardenCandidates, ply)
        end
    end

    -- Если кандидатов нет — ОТМЕНЯЕМ СТАРТ
    if #wardenCandidates == 0 then
        PrintMessage(HUD_PRINTCENTER, "Раунд не начался: Нет Охраны (Ранг 1+)")
        PrintMessage(HUD_PRINTTALK, "[JB] Раунд отменен. Для старта нужен хотя бы один игрок с рангом Рядовой (1) или выше.")
        return -- Выходим из функции, ничего не происходит
    end

    -- === ЭТАП 2: ЗАПУСК РАУНДА (если охрана есть) ===
    local plys = {}
    jb.RoundEnds = CurTime() + jb.TimeRoundEnds

    -- Сначала спавним ВСЕХ как заключенных
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == 1002 then 
            continue 
        end
        table.insert(plys, ply)
        ply:SetTeam(1)
        ply.AppearanceOverride = true
        jb.SpawnPrisoner(ply)
    end

    -- === ЭТАП 3: НАЗНАЧЕНИЕ ОХРАННИКОВ ===
    -- Выбираем случайного кандидата из тех, кого мы нашли в Этапе 1
    local htr1 = table.Random(wardenCandidates)

    if htr1 then
        -- Убираем его из списка заключенных
        table.RemoveByValue(plys, htr1)
        -- Убираем из списка кандидатов (чтобы не выбрать дважды)
        table.RemoveByValue(wardenCandidates, htr1)

        jb.SpawnWarden(htr1)

        -- Если игроков много (>12) и есть еще кандидаты, берем второго
        if #player.GetAll() > 12 and #wardenCandidates > 0 then
            local htr2 = table.Random(wardenCandidates)
            table.RemoveByValue(plys, htr2)
            jb.SpawnWarden(htr2)
        end
    end
    
    game.CleanUpMap(false)
end