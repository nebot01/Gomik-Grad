-- addons/hg/lua/hgamemode/z_roundsystem_1/dm/dm_sv.lua

dm = dm or {}
dm.Warmup = false

-- Регистрируем сетевые сообщения
util.AddNetworkString("DM_WarmupState")
util.AddNetworkString("DM_RoundEndScreen")

dm.Loadout = {
    primary = { "weapon_ar15", "weapon_ak74", "weapon_mp5", "weapon_m870", "weapon_m4a1", "weapon_spas12" },
    secondary = { "weapon_glockp80", "weapon_deagle", "weapon_usp" },
    other = { "weapon_sog", "weapon_bandage", "weapon_medkit_hg" }
}

dm.Models = {
    "models/player/group01/male_01.mdl", "models/player/group01/male_02.mdl",
    "models/player/group01/male_03.mdl", "models/player/group01/male_04.mdl",
    "models/player/group01/male_05.mdl", "models/player/group01/male_06.mdl"
}

function dm.GiveLoadout(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    ply:StripWeapons()
    ply:StripAmmo()

    if hg and hg.Equip_Armor then
        hg.Equip_Armor(ply, "vest6")
        hg.Equip_Armor(ply, "helmet1")
    else
        ply:SetArmor(100)
    end

    local prim = table.Random(dm.Loadout.primary)
    local sec = table.Random(dm.Loadout.secondary)
    
    local w1 = ply:Give(prim)
    if IsValid(w1) then ply:GiveAmmo(w1:GetMaxClip1() * 4, w1:GetPrimaryAmmoType(), true) end

    local w2 = ply:Give(sec)
    if IsValid(w2) then ply:GiveAmmo(w2:GetMaxClip1() * 2, w2:GetPrimaryAmmoType(), true) end

    for _, item in pairs(dm.Loadout.other) do ply:Give(item) end

    ply:SetModel(table.Random(dm.Models))
    ply:SetPlayerColor(Vector(math.random(), math.random(), math.random()))
    ply:SetupHands() 

    if IsValid(w1) then ply:SelectWeapon(w1:GetClass()) end
end

function dm.SpawnPlayer(ply)
    local SpawnList = ReadDataMap("tdm_red") 
    if not SpawnList or #SpawnList == 0 then SpawnList = ReadDataMap("tdm_blue") end

    ply:SetTeam(1)
    ply:Spawn()
    ply.AppearanceOverride = true

    if SpawnList and #SpawnList > 0 then ply:SetPos(table.Random(SpawnList)) end
    
    timer.Create("DM_GiveLoadout_" .. ply:EntIndex(), 0.1, 1, function()
        dm.GiveLoadout(ply)
    end)
end

function dm.StartRoundSV()
    team.DirectTeams(1) 

    dm.Warmup = true
    
    -- 1. Скрываем старое окно победы
    net.Start("DM_RoundEndScreen")
        net.WriteBool(false)
        net.WriteTable({})
    net.Broadcast()

    -- 2. Отправляем время конца разминки
    net.Start("DM_WarmupState")
        net.WriteFloat(CurTime() + 15)
    net.Broadcast()
    
    timer.Create("DM_Warmup_Timer", 15, 1, function()
        dm.Warmup = false
        PrintMessage(HUD_PRINTCENTER, "БОЙ НАЧАЛСЯ!")
        for _, ply in ipairs(player.GetAll()) do
            ply:EmitSound("homigrad/vgui/menu_accept.wav")
        end
    end)

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= 1002 then dm.SpawnPlayer(ply) end
    end
    
    game.CleanUpMap(false)
end

function dm.RoundThink()
    local PlayersAlive = 0
    local LastSurvivor = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:Team() ~= 1002 then
            PlayersAlive = PlayersAlive + 1
            LastSurvivor = ply
        end
    end

    if PlayersAlive <= 1 and not ROUND_ENDED then
        ROUND_ENDED = true
        ROUND_ENDSIN = CurTime() + 10 -- Время на просмотр таблицы
        
        dm.Warmup = false
        if timer.Exists("DM_Warmup_Timer") then timer.Remove("DM_Warmup_Timer") end
        
        -- Собираем данные
        local scoreboardData = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() ~= 1002 then
                table.insert(scoreboardData, {
                    name = ply:Name(),
                    frags = ply:Frags(),
                    is_winner = (ply == LastSurvivor)
                })
            end
        end

        -- Сортируем (Победитель первый, остальные по фрагам)
        table.sort(scoreboardData, function(a, b)
            if a.is_winner then return true end
            if b.is_winner then return false end
            return a.frags > b.frags
        end)

        -- Отправляем клиентам
        net.Start("DM_RoundEndScreen")
            net.WriteBool(true) -- Показать
            net.WriteTable(scoreboardData)
        net.Broadcast()

        hook.Run("EndRound", 1)
    end
end

function dm.CanStart(forced)
    local world = game.GetWorld()
    local min, max = world:GetModelBounds()
    local size = (max - min):Length()
    if size < 3000 and not forced then return false end
    return true 
end

function dm.LootSpawn() return true end

-- Блокировки действий
hook.Add("StartCommand", "DM_Warmup_NoAttack", function(ply, cmd)
    if ROUND_NAME == "dm" and dm.Warmup then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end
end)

hook.Add("PlayerSwitchWeapon", "DM_Warmup_NoSwitch", function(ply, oldWep, newWep)
    if ROUND_NAME == "dm" and dm.Warmup and IsValid(oldWep) then return false end
end)

local old_hg_kick = concommand.GetTable()["hg_kick"]
concommand.Add("hg_kick", function(ply, cmd, args, argStr)
    if ROUND_NAME == "dm" and dm.Warmup then
        if IsValid(ply) then ply:ChatPrint("[DM] Кик запрещен на разминке!") end
        return 
    end
    if old_hg_kick then old_hg_kick(ply, cmd, args, argStr) end
end)

hook.Add("PlayerSay", "DM_BlockVoteKickChat", function(ply, text)
    if ROUND_NAME == "dm" and dm.Warmup then
        local lowerText = string.lower(text)
        if string.find(lowerText, "!kick") or string.find(lowerText, "/kick") or string.find(lowerText, "hg_kick") then
            ply:ChatPrint("[DM] Кик запрещен на разминке!")
            return ""
        end
    end
end)

hook.Add("PlayerSpawn", "DM_PlayerRespawn", function(ply)
    if ROUND_NAME == "dm" and ply:Team() ~= 1002 then
        timer.Create("DM_GiveLoadout_" .. ply:EntIndex(), 0.1, 1, function() dm.GiveLoadout(ply) end)
    end
end)