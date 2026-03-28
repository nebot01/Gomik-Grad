-- lua/homigrad/scoreboard/scoreboard_pages/sv_model_selector.lua

-- [[ ПОДКЛЮЧЕНИЕ КОНФИГА ]]
if file.Exists("homigrad/scoreboard/sh_cases_config.lua", "LUA") then
    AddCSLuaFile("homigrad/scoreboard/sh_cases_config.lua")
    include("homigrad/scoreboard/sh_cases_config.lua")
end

-- [[ СЕТЕВЫЕ СТРОКИ ]]
util.AddNetworkString("HG_Points_Notification")
util.AddNetworkString("HG_ModelSelector_Action")
util.AddNetworkString("HG_Case_Open")
util.AddNetworkString("HG_SendInventory")
util.AddNetworkString("HG_Casino_Spin")

-- ==========================================
-- СПИСОК ЗАПРЕЩЕННЫХ РЕЖИМОВ
-- ==========================================
-- В этих режимах кастомные скины надеваться НЕ БУДУТ.
-- Названия должны совпадать с глобальной переменной ROUND_NAME.
local RestrictedModes = {
    ["gw"] = true,       -- Gang Wars (важно для цветов банд)
    ["hl2dm"] = true,    -- Half-Life 2 DM (комбайны vs повстанцы)
    ["wick"] = true,     -- John Wick (костюмы)
    ["riot"] = true,     -- Riot (полиция vs зэки)
    ["tdm"] = true,      -- Team Deathmatch
    ["coop"] = true,
    ["construct"] = false, 
    ["sandbox"] = false,
}

-- ==========================================
-- СИСТЕМА ПОИНТОВ И НАГРАД ЗА ВРЕМЯ
-- ==========================================

local function GetPoints(ply)
    return tonumber(ply:GetPData("HG_Points", 0))
end

local function SetPoints(ply, amount)
    ply:SetPData("HG_Points", amount)
    ply:SetNWInt("HG_Points", amount) 
end

local function AddPoints(ply, amount)
    if not IsValid(ply) then return end
    
    local current = GetPoints(ply)
    SetPoints(ply, current + amount)
    
    net.Start("HG_Points_Notification")
    net.WriteInt(amount, 16)
    net.Send(ply)
end

-- [[ ФУНКЦИЯ ЗАПУСКА ТАЙМЕРА ]]
local function StartTimeReward(ply)
    if not IsValid(ply) then return end
    
    local timerID = "HG_TimeReward_" .. ply:SteamID64()
    
    timer.Remove(timerID) -- Удаляем старый, если есть

    -- 300 секунд = 5 минут
    timer.Create(timerID, 300, 0, function()
        if IsValid(ply) then
            AddPoints(ply, 5)
        else
            timer.Remove(timerID)
        end
    end)
end

-- 1. Инициализация при входе
hook.Add("PlayerInitialSpawn", "HG_Points_Init", function(ply)
    SetPoints(ply, GetPoints(ply))
    StartTimeReward(ply)
end)

-- 2. Удаление таймера при выходе
hook.Add("PlayerDisconnected", "HG_Points_Cleanup", function(ply)
    timer.Remove("HG_TimeReward_" .. ply:SteamID64())
end)

-- 3. Запуск для уже подключенных (при перезагрузке скрипта)
for _, ply in ipairs(player.GetAll()) do
    StartTimeReward(ply)
    SetPoints(ply, GetPoints(ply))
end


-- ==========================================
-- ИНВЕНТАРЬ
-- ==========================================

local function GetPlayerInventory(ply)
    local data = ply:GetPData("HG_Inventory_V2", "[]")
    return util.JSONToTable(data) or {}
end

local function AddItemToInventory(ply, modelPath)
    local inv = GetPlayerInventory(ply)
    if inv[modelPath] then return false end
    inv[modelPath] = true
    ply:SetPData("HG_Inventory_V2", util.TableToJSON(inv))
    return true
end

local function PickItemFromCase(caseID)
    local caseData = HG_CaseConfig.Cases[caseID]
    if not caseData then return nil end
    local totalChance = 0
    for _, item in pairs(caseData.Items) do totalChance = totalChance + (item.Chance or 10) end
    local randomNum = math.random(0, totalChance)
    local currentSum = 0
    for _, item in pairs(caseData.Items) do
        currentSum = currentSum + (item.Chance or 10)
        if randomNum <= currentSum then return item end
    end
    return caseData.Items[1]
end

-- ==========================================
-- ОБРАБОТЧИКИ (СЕТЬ)
-- ==========================================

net.Receive("HG_SendInventory", function(len, ply)
    local inv = GetPlayerInventory(ply)
    net.Start("HG_SendInventory")
    net.WriteTable(inv)
    net.Send(ply)
end)

net.Receive("HG_Case_Open", function(len, ply)
    local caseID = net.ReadString()
    local caseData = HG_CaseConfig.Cases[caseID]

    if not caseData then return end

    local points = GetPoints(ply)
    if points < caseData.Price then
        ply:ChatPrint("[HG] Недостаточно поинтов! Нужно: " .. caseData.Price)
        return
    end

    local winItem = PickItemFromCase(caseID)
    if not winItem then return end

    SetPoints(ply, points - caseData.Price)

    local isNew = AddItemToInventory(ply, winItem.Model)
    
    net.Start("HG_Case_Open")
        net.WriteString(winItem.Model)
        net.WriteString(winItem.Name)
        net.WriteString(caseID)
        net.WriteBool(isNew)
    net.Send(ply)
end)

net.Receive("HG_ModelSelector_Action", function(len, ply)
    local action = net.ReadString()
    if ply:GetPData("HG_CustomModel_Data") then ply:RemovePData("HG_CustomModel_Data") end

    if action == "reset" then
        ply:RemovePData("HG_EquippedModel_V2")
        ply:ChatPrint("[HG] Скин сброшен.")
        return
    end

    if action == "apply" then
        local path = net.ReadString()
        local skin = net.ReadUInt(8)
        local col = net.ReadVector()
        local bgroups = net.ReadTable()
        local inv = GetPlayerInventory(ply)
        
        if not inv[path] and not ply:IsAdmin() then return end

        local data = { model = path, skin = skin, col = col, bgroups = bgroups }
        ply:SetPData("HG_EquippedModel_V2", util.TableToJSON(data))
        ply:ChatPrint("[HG] Скин сохранен!")
    end
end)

-- [[ ХУКИ НАГРАД ]] --

-- Награда за убийство (+8)
hook.Add("PlayerDeath", "HG_Points_KillReward", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        AddPoints(attacker, 8)
        print("[HG POINTS] Игрок " .. attacker:Name() .. " убил " .. victim:Name() .. " и получил 8 pts.")
    end
end)

-- Награда за выживание (+5)
hook.Add("RoundEnd", "HG_Points_SurvivalReward", function(winnerTeam)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= 1002 and ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
            AddPoints(ply, 5)
        end
    end
end)

-- [[ ПРИМЕНЕНИЕ СКИНА С ПРОВЕРКОЙ РЕЖИМА ]] --
hook.Add("PlayerSpawn", "HG_ApplyCustomModel_Inventory_V2", function(ply)
    -- Задержка 1 секунда, чтобы режим успел выдать свою модель (например, в GW выдает бандита)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        
        -- 1. ПРОВЕРКА РЕЖИМА
        -- Если режим в списке RestrictedModes (gw, hl2dm и т.д.), мы выходим и НЕ меняем модель
        local currentMode = string.lower(tostring(ROUND_NAME or ""))
        if RestrictedModes[currentMode] then 
            -- print("[HG Skin] Режим " .. currentMode .. " запрещает кастомные скины.")
            return 
        end

        -- 2. ПРОВЕРКА СПЕКТАТОРОВ
        if ply:Team() == 1002 or ply:Team() == TEAM_SPECTATOR then return end

        local inv = GetPlayerInventory(ply)
        local dataStr = ply:GetPData("HG_EquippedModel_V2")
        
        if dataStr then
            local data = util.JSONToTable(dataStr)
            if data and data.model and util.IsValidModel(data.model) then
                if inv[data.model] or ply:IsAdmin() then
                    ply:SetModel(data.model)
                    if data.skin then ply:SetSkin(data.skin) end
                    if data.col then ply:SetPlayerColor(data.col) end
                    if data.bgroups then for id, val in pairs(data.bgroups) do ply:SetBodygroup(id, val) end end
                    ply:SetupHands()
                else
                    ply:RemovePData("HG_EquippedModel_V2")
                end
            end
        end
    end)
end)

-- ==========================================
-- КАЗИНО ЛОГИКА
-- ==========================================

net.Receive("HG_Casino_Spin", function(len, ply)
    local bet = net.ReadUInt(32)
    local currentPoints = GetPoints(ply)

    if bet < 10 or bet > currentPoints then
        ply:ChatPrint("[CASINO] Недостаточно средств или неверная ставка!")
        return
    end

    local newBalance = currentPoints - bet
    SetPoints(ply, newBalance)

    local s1 = math.random(1, 3)
    local s2 = math.random(1, 3)
    local s3 = math.random(1, 3)
    
    local winAmount = 0
    local winType = 0 

    if s1 == 3 and s2 == 3 and s3 == 3 then
        winAmount = bet * 5 
        winType = 3
    elseif s1 == 2 and s2 == 2 and s3 == 2 then
        winAmount = bet * 3 
        winType = 2
    elseif s1 == 1 and s2 == 1 and s3 == 1 then
        winAmount = bet * 2 
        winType = 1
    end

    if winAmount > 0 then
        SetPoints(ply, newBalance + winAmount)
    end

    net.Start("HG_Casino_Spin")
    net.WriteUInt(s1, 4)
    net.WriteUInt(s2, 4)
    net.WriteUInt(s3, 4)
    net.WriteUInt(winAmount, 32)
    net.WriteUInt(winType, 4)
    net.Send(ply)
end)