-- "addons\\homigrad-core\\lua\\homigrad\\sh_rolehide.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg = hg or {}
local NETMSG = "HG_ToggleHideUsergroup"

if SERVER then
    util.AddNetworkString(NETMSG)

    net.Receive(NETMSG, function(_, ply)
        if not IsValid(ply) then return end
        if not ply:IsSuperAdmin() then
            ply:SetNWBool("HidePlyName", false)
            return
        end

        local hide = net.ReadBool()
        ply:SetNWBool("HidePlyName", hide and true or false)
    end)
else
    hg._NextHideRoleSync = hg._NextHideRoleSync or 0
    hg._LastHideRoleValue = hg._LastHideRoleValue or nil

    hook.Add("Think", "HG_HideRoleSync", function()
        if (hg._NextHideRoleSync or 0) > CurTime() then return end
        hg._NextHideRoleSync = CurTime() + 1

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local hide = false
        if ply:IsSuperAdmin() and istable(GGrad_ConfigSettings) then
            hide = GGrad_ConfigSettings["hide_usergroup"] and true or false
        end

        if hg._LastHideRoleValue == hide then return end
        hg._LastHideRoleValue = hide

        net.Start(NETMSG)
        net.WriteBool(hide)
        net.SendToServer()
    end)
end
