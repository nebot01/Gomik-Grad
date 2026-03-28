-- 1. Регистрируем сетевое сообщение
util.AddNetworkString("DeathScreen")

-- Таблица для перевода групп попаданий в строки (для клиента)
local hitgroupTranslate = {
    [HITGROUP_GENERIC]  = "generic",
    [HITGROUP_HEAD]     = "head",
    [HITGROUP_CHEST]    = "chest",
    [HITGROUP_STOMACH]  = "stomach",
    [HITGROUP_LEFTARM]  = "leftarm",
    [HITGROUP_RIGHTARM] = "rightarm",
    [HITGROUP_LEFTLEG]  = "leftleg",
    [HITGROUP_RIGHTLEG] = "rightleg",
    [HITGROUP_GEAR]     = "gear"
}

-- 2. Отслеживаем попадания, чтобы знать, в какую часть тела прилетел последний урон
hook.Add("ScalePlayerDamage", "HG_DeathScreen_TrackHit", function(ply, hitgroup, dmginfo)
    -- Запоминаем последнюю группу попаданий в переменную игрока
    ply.LastHitGroupStored = hitgroup
end)

-- 3. Главный хук смерти
hook.Add("PlayerDeath", "HG_DeathScreen_Send", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end

    -- Определяем часть тела
    local hitGroup = victim.LastHitGroupStored or HITGROUP_GENERIC
    local hitString = hitgroupTranslate[hitGroup] or "generic"
    
    -- Сбрасываем сохраненную группу попадания
    victim.LastHitGroupStored = nil

    -- Определяем причину (Reason)
    local reason = "dead_unknown"
    
    if attacker == victim then
        reason = "dead_kys" -- Самоубийство
    elseif attacker:IsPlayer() then
        reason = "dead_gun" -- Убит игроком (можно расширить логику)
    elseif attacker:IsWorld() then
        reason = "dead_world" -- Разбился / мир
    elseif attacker:IsNPC() then
        reason = "dead_npc" -- НПС
    end

    if victim:IsOnFire() then 
        -- reason = "dead_burn" 
    end
    
    victim:SetNWString("KillReason", reason)
    victim:SetNWEntity("LastInflictor", inflictor)
    victim:SetNWEntity("LastAttacker", attacker)
    victim:SetNWString("LastHitBone", hitString)

    net.Start("DeathScreen")
    net.Send(victim)
end)