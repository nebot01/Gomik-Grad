-- "addons\\homigrad-core\\lua\\homigrad\\sh_comunication.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local function IsPlayerGagged(ply)
    if not IsValid(ply) then return false end
    if hg and hg.IsForcedGagged and hg.IsForcedGagged(ply) then return true end
    if ply.gagged or ply.ulx_gagged then return true end
    if ply.GetNWBool and (ply:GetNWBool("gagged", false) or ply:GetNWBool("ulx_gagged", false)) then return true end
    if ply.GetPData then
        if ply:GetPData("ulx_gagged", "0") == "1" or ply:GetPData("ulx_pgag", "0") == "1" then
            return true
        end
    end
    if hg and hg.GetTimeGagLeft and hg.GetTimeGagLeft(ply) > 0 then return true end
    return false
end

local function IsPlayerTimeGagged(ply)
    if not IsValid(ply) then return false end
    if hg and hg.GetTimeGagLeft and hg.GetTimeGagLeft(ply) > 0 then return true end
    return false
end

local function IsBlockedByULXVoice(listener, speaker)
    local hooks = hook.GetTable()
    if not hooks then return false end
    local voiceHooks = hooks.PlayerCanHearPlayersVoice
    if not istable(voiceHooks) then return false end

    local checkOrder = {
        "ULXGag",
        "ULXCC_PgagManager",
        "ulxcc_VoteGagged"
    }

    for _, hookName in ipairs(checkOrder) do
        local fn = voiceHooks[hookName]
        if isfunction(fn) then
            local ok, canHear = pcall(fn, listener, speaker)
            if ok and canHear == false then
                return true
            end
            ok, canHear = pcall(fn, speaker, listener)
            if ok and canHear == false then
                return true
            end
        end
    end

    return false
end

local function ChatLogic(output, input, isChat, teamonly, text)
    if not IsValid(output) or not IsValid(input) then return false end
    if not isChat and IsPlayerGagged(input) then return false, false end
    if IsPlayerTimeGagged(input) then return false, false end
    if not isChat and IsBlockedByULXVoice(output, input) then return false, false end
    
    local result, is3D = hook.Run("Player Can Lisen", output, input, isChat, teamonly, text)
    if result ~= nil then return result, is3D end

    if ROUND_ENDED or !ROUND_ACTIVE then
        return true
    end

    if output:Alive() and input:Alive() and !input:GetNWBool("otrub") then
        if teamonly then
            return output:Team() == input:Team()
        else
            return input:GetPos():DistToSqr(output:GetPos()) < 800000, true
        end
    elseif not output:Alive() and input:Alive() then
        return true, true
    elseif not output:Alive() and not input:Alive() or output:Team() == 1002 and not input:Alive() then
        return true
    else
        return false
    end
end

hook.Add("PlayerCanSeePlayersChat", "RealiticChar", function(text, teamOnly, listener, speaker)
    if not IsValid(speaker) then return false end
    local result = ChatLogic(listener, speaker, true, teamOnly, text)
    return result
end)

hook.Add("PlayerCanHearPlayersVoice", "RealisticVoice", function(listener, speaker)
    if not IsValid(speaker) then return false, false end
    
    local result, is3D = ChatLogic(listener, speaker, false, false)
    local speak = speaker:IsSpeaking()
    
    speaker.IsSpeak = speak
    if speaker.IsOldSpeak ~= speaker.IsSpeak then
        speaker.IsOldSpeak = speak
        if speak then 
            hook.Run("StartVoice", speaker, listener) 
        else 
            hook.Run("EndVoice", speaker, listener)  
        end
    end

    return result, is3D
end)
