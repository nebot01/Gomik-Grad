-- "addons\\homigrad-core\\lua\\homigrad\\skins\\sh_skins.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
﻿hg = hg or {}
hg.ServerSkins = hg.ServerSkins or {}

local function CanUseSkins(ply)
    if not IsValid(ply) then return false end
    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    if group == "megasponsor"
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

hg.CanUseSkins = CanUseSkins

if SERVER then
    local dataFile = "gomigrad_datacontent/server_skins.json"
    local playerDataFile = "gomigrad_datacontent/server_player_skins.json"

    if not file.IsDir("gomigrad_datacontent", "DATA") then
        file.CreateDir("gomigrad_datacontent")
    end

    local function LoadJson(path)
        if not file.Exists(path, "DATA") then
            file.Write(path, util.TableToJSON({}))
        end
        local list = util.JSONToTable(file.Read(path, "DATA") or "") or {}
        if not istable(list) then
            list = {}
        end
        return list
    end

    local function SaveJson(path, tbl)
        file.Write(path, util.TableToJSON(tbl or {}))
    end

    local function SaveList()
        SaveJson(dataFile, hg.ServerSkins.List)
    end

    local function SavePlayerSkins()
        SaveJson(playerDataFile, hg.ServerSkins.PlayerNext)
    end

    hg.ServerSkins.List = LoadJson(dataFile)
    hg.ServerSkins.PlayerNext = LoadJson(playerDataFile)

    util.AddNetworkString("HG_ServerSkins_Request")
    util.AddNetworkString("HG_ServerSkins_List")
    util.AddNetworkString("HG_ServerSkins_Set")

    function hg.SendServerSkins(ply)
        local list = hg.ServerSkins.List or {}
        net.Start("HG_ServerSkins_List")
        net.WriteUInt(#list, 16)
        for _, item in ipairs(list) do
            net.WriteString(item.path or "")
            net.WriteString(item.name or item.path or "")
        end
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    function hg.AddServerSkin(path, name)
        if not path or path == "" then return false end
        local list = hg.ServerSkins.List or {}
        for _, item in ipairs(list) do
            if item.path == path then
                item.name = name or item.name or path
                SaveList()
                hg.SendServerSkins()
                return true
            end
        end
        list[#list + 1] = {path = path, name = name or path}
        hg.ServerSkins.List = list
        SaveList()
        hg.SendServerSkins()
        return true
    end

    function hg.RemoveServerSkin(path)
        if not path or path == "" then return false end
        local list = hg.ServerSkins.List or {}
        for i = #list, 1, -1 do
            if list[i].path == path then
                table.remove(list, i)
                hg.ServerSkins.List = list
                SaveList()
                hg.SendServerSkins()
                return true
            end
        end
        return false
    end

    net.Receive("HG_ServerSkins_Request", function(_, ply)
        if not CanUseSkins(ply) then return end
        hg.SendServerSkins(ply)
    end)

    net.Receive("HG_ServerSkins_Set", function(_, ply)
        if not CanUseSkins(ply) then return end
        local sid = ply:SteamID64()
        local path = net.ReadString()

        if path == "" then
            ply.HGNextSkin = ""
            ply:SetNWString("HGNextSkin", "")
            if sid and sid ~= "" then
                hg.ServerSkins.PlayerNext[sid] = ""
                SavePlayerSkins()
            end
            if PrintMessageChat then
                PrintMessageChat(ply, hg.GetPhrase and hg.GetPhrase("setting_skins_applied_next") or "Скин будет применен в следующем раунде.")
            else
                ply:ChatPrint(hg.GetPhrase and hg.GetPhrase("setting_skins_applied_next") or "Скин будет применен в следующем раунде.")
            end
            return
        end

        local list = hg.ServerSkins.List or {}
        local ok = false
        for _, item in ipairs(list) do
            if item.path == path then
                ok = true
                break
            end
        end
        if not ok then return end

        ply.HGNextSkin = path
        ply:SetNWString("HGNextSkin", path)
        if sid and sid ~= "" then
            hg.ServerSkins.PlayerNext[sid] = path
            SavePlayerSkins()
        end

        if PrintMessageChat then
            PrintMessageChat(ply, hg.GetPhrase and hg.GetPhrase("setting_skins_applied_next") or "Скин будет применен в следующем раунде.")
        else
            ply:ChatPrint(hg.GetPhrase and hg.GetPhrase("setting_skins_applied_next") or "Скин будет применен в следующем раунде.")
        end
    end)

    hook.Add("PlayerInitialSpawn", "HG_ServerSkins_Load", function(ply)
        local sid = ply:SteamID64()
        if not sid or sid == "" then return end
        local path = hg.ServerSkins.PlayerNext[sid] or ""
        ply.HGNextSkin = path
        ply:SetNWString("HGNextSkin", path)
    end)

    hook.Add("PlayerSpawn", "HG_ServerSkins_Apply", function(ply)
        if not CanUseSkins(ply) then return end
        if not ply.HGNextSkin or ply.HGNextSkin == "" then return end
        if ROUND_NAME and ROUND_NAME ~= "hmcd" then return end
        local path = ply.HGNextSkin
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            if not CanUseSkins(ply) then return end
            if ROUND_NAME and ROUND_NAME ~= "hmcd" then return end
            if ply.isZombie or ply.isCombine or ply.isCombineSuper then return end
            if ply.PlayerClassName and ply.PlayerClassName ~= "" then return end
            ply:SetModel(path)
        end)
    end)
end

if CLIENT then
    hg.ServerSkins.List = hg.ServerSkins.List or {}

    net.Receive("HG_ServerSkins_List", function()
        local count = net.ReadUInt(16)
        local list = {}
        for i = 1, count do
            local path = net.ReadString()
            local name = net.ReadString()
            if path ~= "" then
                list[#list + 1] = {path = path, name = name ~= "" and name or path}
            end
        end
        hg.ServerSkins.List = list
        hook.Run("HG_ServerSkins_Updated")
    end)
end