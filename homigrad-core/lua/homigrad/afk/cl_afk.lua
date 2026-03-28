-- "addons\\homigrad-core\\lua\\homigrad\\afk\\cl_afk.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local afkWarnUntil = 0
local afkWarnActive = false

net.Receive("HG_AFKPrompt", function()
    afkWarnUntil = net.ReadFloat()
    afkWarnActive = true
end)

net.Receive("HG_AFKPromptCancel", function()
    afkWarnActive = false
    afkWarnUntil = 0
end)

hook.Add("HUDPaint", "HG_AFK_WarnOverlay", function()
    if not afkWarnActive then return end
    if not IsValid(LocalPlayer()) then return end

    local left = math.max(0, math.ceil(afkWarnUntil - CurTime()))
    if left <= 0 then
        afkWarnActive = false
        return
    end

    local w, h = ScrW(), ScrH()
    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 210))

    draw.SimpleText("НАЖМИТЕ ЛЮБУЮ КЛАВИШУ", "Trebuchet24", w * 0.5, h * 0.42, Color(255, 70, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("В ТЕЧЕНИИ 10 СЕКУНД", "Trebuchet24", w * 0.5, h * 0.47, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Иначе вы будете переведены в наблюдатели", "Trebuchet18", w * 0.5, h * 0.53, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(left), "Trebuchet24", w * 0.5, h * 0.59, Color(255, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
