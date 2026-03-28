-- "addons\\homigrad-core\\lua\\homigrad\\cl_win.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg = hg or {}

hg.WinTime = hg.WinTime or 0
STOP_ROUND_GAME = STOP_ROUND_GAME or false

net.Receive("StopRoundGame",function()
    STOP_ROUND_GAME = net.ReadBool()
end)

function WinRound(color,text1,winside,text2,text3)
    if STOP_ROUND_GAME then return end
    --"homigrad/vgui/panorama/case_awarded_4_legendary_01.wav" - звук при выигрыше

    local StartTime = CurTime()
    local EndTime = StartTime + 7
    hg.WinTime = CurTime() + 5
    local TargetSize = 1
    local CurSize = 0

    local grad_l = Material("vgui/gradient-l")
    local traitorLine = text3
    if (not traitorLine or traitorLine == "") and ROUND_NAME == "hmcd" then
        local traitors = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:GetNWBool("HMCD_Traitor", false) then
                traitors[#traitors + 1] = ply:Name()
            end
        end
        if #traitors == 1 then
            traitorLine = "Предатель: " .. traitors[1]
        elseif #traitors > 1 then
            traitorLine = "Предатели: " .. table.concat(traitors, ", ")
        else
            traitorLine = "Предатели: неизвестно"
        end
    end

    surface.PlaySound("homigrad/vgui/panorama/case_awarded_4_legendary_01.wav")
    
    local WinGui = vgui.Create("hg_frame")
    WinGui:SetSize(612,120)
    WinGui:Center()
    local XPos = WinGui:GetX()
    WinGui:SetPos(WinGui:GetX(),ScrH() / 16)
    WinGui:ShowCloseButton(false)
    WinGui:SetTitle(" ")

    function WinGui:SubPaint(w,h)
        local TimeSpent = (EndTime - CurTime())

        //print(text2)

        local fix_w = w / 2 - ((w/2) * CurSize)

        CurSize = LerpFT(0.2,CurSize,TargetSize)
        self.CurSize = CurSize

        draw.RoundedBox(0,fix_w,0,w * CurSize,h,Color(24,24,24,230))

        draw.SimpleText(
            (string.format(hg.GetPhrase(text1), hg.GetPhrase(winside)) != string.format(text1, winside) and string.format(hg.GetPhrase(text1), hg.GetPhrase(winside)) or text1),
            "hg_HomicideMedium",
            w/2,
            h/2,
            Color(255, 255, 255, 255 * (CurSize - 0.1)),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        if text2 != nil then
            draw.SimpleText(
                (hg.GetPhrase(text2) != text2 and hg.GetPhrase(text2) or text2),
                "HS.25",
                w/2,
                h/1.35,
                Color(255, 255, 255, 255 * (CurSize - 0.1)),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        draw.SimpleText(
            (traitorLine and traitorLine != "" and traitorLine or "  "),
            "hg_HomicideSmalles",
            w/2,
            h/1.2,
            Color(255, 255, 255, 255 * math.Clamp(CurSize - 0.1, 0, 1)),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        //draw.RoundedBox(0,0,0,w,h,Color(255,255,255,100)) - дебаг

        surface.SetMaterial(grad_l)

        surface.SetDrawColor(color.r,color.g,color.b,55)

        surface.DrawTexturedRect(fix_w,0,(w / 1.3) * CurSize,h)
    end

    timer.Simple(6,function()
        TargetSize = 0
    end)

    timer.Simple(6.4,function()
        WinGui:Remove()
    end)
end

net.Receive("EndRound",function()
    local color = net.ReadColor()
    local text1 = net.ReadString()
    local winside = net.ReadString() or nil
    local text3 = net.ReadString() or nil
    WinRound(color,text1,winside,nil,text3)
    ROUND_ENDED = true
end)

concommand.Add("hg_win_test",function(ply,len,args)
    if ply:IsSuperAdmin() then
    WinRound(Color(255,0,0),args[1],args[2])
    end
end)
