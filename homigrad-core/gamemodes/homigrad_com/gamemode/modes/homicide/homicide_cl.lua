-- "addons\\homigrad-core\\gamemodes\\homigrad_com\\gamemode\\modes\\homicide\\homicide_cl.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hmcd = hmcd or {}

local sound_played = false

hmcd.TraitorList = hmcd.TraitorList or {}

function hmcd.IsKnownTraitor(ply)
    if not IsValid(ply) then return false end
    if ply == LocalPlayer() then return ply.IsTraitor == true end
    if not LocalPlayer().IsTraitor then return false end
    if ply:GetNWBool("HMCD_Traitor", false) then return true end
    local sid64 = ply:SteamID64()
    if sid64 and hmcd.TraitorList[sid64] then return true end
    local sid = ply:SteamID()
    if sid and hmcd.TraitorList[sid] then return true end
    return false
end

hmcd.StartSounds = {
    ["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gfz"] = "snd_jack_hmcd_panic.mp3" ,
    ["ww"] = "snd_jack_hmcd_wildwest.mp3"
}

function hmcd.GetTeamName(ply)
    if !ply then
        ply = LocalPlayer()
    end
    if !hmcd.Type then
        hmcd.Type = "soe"
    end

    if hmcd.IsKnownTraitor(ply) then
        return "hmcd_traitor",Color(230,0,0),hg.GetPhrase("hmcd_traitor_"..hmcd.Type)
    end

    if ply:Team() == 3 then
        return "hmcd_police", Color(0, 140, 255), hg.GetPhrase("hmcd_police_desc")
    end
    
    if ply.IsTraitor then
        return "hmcd_traitor",Color(230,0,0),hg.GetPhrase("hmcd_traitor_"..hmcd.Type)
    elseif ply.IsGunMan or ply.IsGunman then
        return "hmcd_gunman",Color(132,0,255),hg.GetPhrase("hmcd_gunman_"..hmcd.Type)
    else
        return "hmcd_bystander",Color(0,153,255),hg.GetPhrase("hmcd_bystander_"..hmcd.Type)
    end
end

function hmcd.DrawTraitorLabels()
    local localPly = LocalPlayer()
    if not localPly.IsTraitor then return end
    
    for _, ply in ipairs(player.GetAll()) do
        if ply == localPly then continue end
        if not IsValid(ply) then continue end
        if not ply:Alive() then continue end
        
        if not hmcd.IsKnownTraitor(ply) then continue end
        
        local pos = ply:GetPos() + Vector(0, 0, 75)
        local screenPos = pos:ToScreen()
        if not screenPos.visible then continue end
        
        local dist = localPly:GetPos():Distance(ply:GetPos())
        if dist > 1000 then continue end
        
        local alpha = math.Clamp(255 - (dist / 1000) * 200, 55, 255)
        
        local text = hg.GetPhrase("hmcd_traitor")
        local font = "HomigradFontBig"
        local fontName = "HomigradFont"

        local x = screenPos.x
        local y = screenPos.y

        draw.DrawText(text, font, x, y - -5, Color(255, 50, 50, alpha), TEXT_ALIGN_CENTER)

        local nick = ply:Name()
        draw.DrawText(nick, fontName, x, y + -15, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
    end
end

function hmcd.HUDPaint()
    if !hg.ROUND_START then
        hg.ROUND_START = CurTime()
    end

    local StartTime = ((hg.ROUND_START + 7) - CurTime())
    local w,h = ScrW(),ScrH()

    if (hmcd.TimeUntilCops or 0) > 0 then
        local policeLeft = (hg.ROUND_START + hmcd.TimeUntilCops) - CurTime()
        if policeLeft > 0 then
            local text = string.format(hg.GetPhrase("police_arrivein"), string.FormattedTime(policeLeft, "%02i:%02i"))
            draw.SimpleText(text, "ChatFont", w * 0.42, h * 0.98, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    if StartTime < 0 then
        return
    end

    if !sound_played then
        sound_played = true
        if !hmcd.Type then
            hmcd.Type = "standard"
        end
        local shit = hmcd.StartSounds[hmcd.Type]
        surface.PlaySound(istable(shit) and table.Random(shit) or shit)
    end

    local DarkMul = math.Clamp(StartTime,0,1)

    local Name,color,Desc = hmcd.GetTeamName()

    color.a = (255 * DarkMul)

    local PrintName = hg.GetPhrase(Name)

    surface.SetDrawColor(0,0,0,220 * DarkMul)
    surface.DrawRect(0,0,w,h)

    draw.DrawText(string.format(hg.GetPhrase("you_are"),PrintName),"H.25",w / 2,h / 2,color,TEXT_ALIGN_CENTER)
    draw.DrawText(hmcd.name .. " | ".. hg.GetPhrase("hmcd_"..hmcd.Type),"H.45",w / 2,h / 8,Color(0,140,255,255 * DarkMul),TEXT_ALIGN_CENTER)
    draw.DrawText(hg.GetPhrase(Desc),"H.25",w / 2,h / 1.2,color,TEXT_ALIGN_CENTER)

    hmcd.DrawTraitorLabels()
end

function hmcd.RenderScreenspaceEffects()

end

function hmcd.RoundStart()
    hg.ROUND_START = CurTime()
    sound_played = false
    hmcd.TraitorList = {} 
    hmcd.CopsArrive = false
end

net.Receive("hmcd_start",function()
    hmcd.Type = net.ReadString()
    local ist = net.ReadBool()
    local isg = net.ReadBool()
    hmcd.TimeUntilCops = net.ReadUInt(16)

    LocalPlayer().IsTraitor = ist
    LocalPlayer().IsGunman = isg
    LocalPlayer().IsGunMan = isg
    
    local count = net.ReadUInt(8)
    hmcd.TraitorList = {}
    for i = 1, count do
        local sid = net.ReadString()
        hmcd.TraitorList[sid] = true
    end
end)

net.Receive("hmcd_traitor_list", function()
    local count = net.ReadUInt(8)
    hmcd.TraitorList = {}
    for i = 1, count do
        local sid = net.ReadString()
        hmcd.TraitorList[sid] = true
    end
end)

hook.Add("HUDPaint", "HMCD_TraitorLabels", function()
    if not hg.ROUND_START then return end
    
    local StartTime = ((hg.ROUND_START + 7) - CurTime())
    if StartTime >= 0 then return end 
    
    hmcd.DrawTraitorLabels()
end)
