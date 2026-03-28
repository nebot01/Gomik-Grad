-- "addons\\homigrad-core\\lua\\homigrad\\sh_spawnmenu.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local validUserGroup = {
    owner = true,
    doperator = true,
    piar_agent = true,
    piaragent = true,
    ["piar-agent"] = true,
    dadmin = true,
    dsuperadmin = true,
    admin = true,
    superadmin = true
}

local function HasGroupAccess(ply)
    if not IsValid(ply) then return false end
    local group = string.lower(tostring(ply:GetUserGroup() or ""))
    if validUserGroup[group] then return true end
    group = string.Replace(group, "_", "")
    group = string.Replace(group, "-", "")
    return validUserGroup[group] == true
end

if SERVER then
    local function HasSpawnAccess(ply)
        if not IsValid(ply) then return false end
        return HasGroupAccess(ply) or ply:IsAdmin() or GetGlobalBool("AccessSpawn")
    end

    hook.Add("Think","HG_SpawnAccessSync",function()
        if (HG_NextSpawnAccessSync or 0) > CurTime() then return end
        HG_NextSpawnAccessSync = CurTime() + 1
        for _, ply in ipairs(player.GetAll()) do
            local can = HasSpawnAccess(ply) and true or false
            if ply:GetNWBool("HG_CanOpenSpawnMenu", false) ~= can then
                ply:SetNWBool("HG_CanOpenSpawnMenu", can)
            end
        end
    end)

    local function CanUseSpawnMenu(ply,class)
        if !TableRound then
            return true
        end
        local func = TableRound().CanUseSpawnMenu
        func = func and func(ply,class)
        if func != nil then return func end

        if HasSpawnAccess(ply) then return true end

        if not ply:IsAdmin() then ply:Kick("xd)00)0") return false end
    end

    hook.Add("PlayerSpawnVehicle","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"vehicle") end)
    hook.Add("PlayerSpawnRagdoll","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"ragdoll") end)
    hook.Add("PlayerSpawnEffect","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"effect") end)
    hook.Add("PlayerSpawnProp","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"prop") end)
    hook.Add("PlayerSpawnSENT","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"sent") end)
    hook.Add("PlayerSpawnNPC","Cantspawnbullshit",function(ply) return CanUseSpawnMenu(ply,"npc") end)

    hook.Add("PlayerSpawnSWEP","SpawnBlockSWEP",function(ply) return CanUseSpawnMenu(ply,"swep") end)
    hook.Add("PlayerGiveSWEP","SpawnBlockSWEP",function(ply) return CanUseSpawnMenu(ply,"swep") end)

    local function spawn(ply,class,ent)
        if !TableRound then
            return true
        end
        local func = TableRound().CanUseSpawnMenu
        func = func and func(ply,class,ent)
    end

    hook.Add("PlayerSpawnedVehicle","sv_round",function(ply,model,ent) spawn(ply,"vehicle",ent) end)
    hook.Add("PlayerSpawnedRagdoll","sv_round",function(ply,model,ent) spawn(ply,"ragdoll",ent) end)
    hook.Add("PlayerSpawnedEffect","sv_round",function(ply,model,ent) spawn(ply,"effect",ent) end)
    hook.Add("PlayerSpawnedProp","sv_round",function(ply,model,ent) spawn(ply,"prop",ent) end)
    hook.Add("PlayerSpawnedSENT","sv_round",function(ply,model,ent) spawn(ply,"sent",ent) end)
    hook.Add("PlayerSpawnedNPC","sv_round",function(ply,model,ent) spawn(ply,"npc",ent) end)
else
    local function CanUseSpawnMenu()
        if !TableRound then
            return true
        end
        local ply = LocalPlayer()
        if ply:GetNWBool("HG_CanOpenSpawnMenu", false) or HasGroupAccess(ply) or GetGlobalBool("AccessSpawn") then return true end

        if not ply:IsAdmin() then return false end
    end

    hook.Add("ContextMenuOpen", "hide_spawnmenu",CanUseSpawnMenu)
    hook.Add("SpawnMenuOpen", "hide_spawnmenu",CanUseSpawnMenu)
end
