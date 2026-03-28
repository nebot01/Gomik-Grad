hg.Attachments = {
    ["holo1"] = {
        Name = "Barska (holo)",
        Model = "models/weapons/arccw_go/atts/barska.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 1,
        Placement = "sight",
        ViewPos = Vector(0,0,0.15),

        MountType = "picatinny",

        IsHolo = true,
        Reticle = "vgui/arc9_eft_shared/reticles/new/scope_all_aimpoint_micro_h1_high_marks.png",
        ReticleSize = 12,
        ReticleUp = 0,
        ReticleRight = 0
    },
    ["holo2"] = {
        Name = "Kobra (holo)",
        Model = "models/weapons/arccw_go/atts/kobra.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 1,
        Placement = "sight",
        ViewPos = Vector(0,0,-0.1),

        MountType = "picatinny",

        IsHolo = true,
        Reticle = "vgui/arc9_eft_shared/reticles/new/scope_all_vomz_pilad_p1x42_mark_mode_001",
        ReticleSize = 9,
        ReticleUp = 1.45,
        ReticleRight = 0
    },
    ["holo3"] = {
        Name = "Eotech553 (holo)",
        Model = "models/weapons/arc9_eft_shared/atts/optic/eft_optic_553.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 0.65,
        Placement = "sight",
        ViewPos = Vector(0,0,0),

        MountType = "picatinny",

        IsHolo = true,
        Reticle = "vgui/arc9_eft_shared/reticles/new/scope_all_eotech_xps3-4_marks.png",
        ReticleSize = 11,
        ReticleUp = 0,
        ReticleRight = 0
    },
    ["optic1"] = {
        Name = "SIG Bravo-4 (optic)",
        Model = "models/weapons/arc9/darsu_eft/mods/scope_sig_bravo4.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 0.7,
        Placement = "sight",

        ScopePos = Vector(3,0,0.83),
        ScopeAng = Angle(0,0,0),
        ViewPos = Vector(0,0,-0.25),

        IsOptic = true,
        Fov = 9,
        MaxFov = 3,
        MinFov = 9,
        Reticle = "vgui/arc9_eft_shared/reticles/scope_all_ncstar_advance_dual_optic_3_9x_42_mark.png",
        ReticleSize = 1,
        Mat = "effects/arc9/rt",

        BlackMat = "decals/scope.png",
        BlackSize = 2070,
        BlackScope = 400,

        MountType = "picatinny",

        Rotation = 0
    },
    ["optic2"] = {
        Name = "ELCAN SpecterDR (optic)",
        Model = "models/weapons/arc9/darsu_eft/mods/scope_elcan_specter.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 0.7,
        Placement = "sight",

        ScopePos = Vector(3,0,0.99),
        ScopeAng = Angle(0,0,0),
        ViewPos = Vector(0,0,-0.1),

        IsOptic = true,
        Fov = 20,
        MaxFov = 5,
        MinFov = 20,
        Reticle = "vgui/arc9_eft_shared/reticles/scope_34mm_s&b_pm_ii_3_12x50_lod0_mark_12.png",
        ReticleSize = 0.6,
        Mat = "effects/arc9/rt",

        BlackMat = "decals/scope.png",
        BlackSize = 2070,
        BlackScope = 400,

        MountType = "picatinny",

        Rotation = 0
    },
    ["grip1"] = {
        Name = "Ergo Grip (grip)",
        Model = "models/weapons/arccw_go/atts/foregrip_ergo.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 1,
        Placement = "grip",

        LHandAng = Angle(30,-140,90),
        LHand = Vector(1.2,3,-3),

        DrawFunction = function(self) 
            if !IsValid(self:GetOwner()) then
                return
            end
            //hg.bone.Set(self:GetOwner(),"r_finger0",Vector(0,0,0),Angle(0,0,0),1,0.1)
            //hg.bone.Set(self:GetOwner(),"r_finger1",Vector(0,0,0),Angle(0,0,0),1,0.1)
        end
    },
    ["supp1"] = {
        Name = "SilencerCo Hybrid (suppressor)",
        Model = "models/weapons/arc9_eft_shared/atts/muzzle/silencer_mount_silencerco_hybrid_46_multi.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 1,
        Placement = "barrel",
        IsSupp = true
    },
    ["supp2"] = {
        Name = "AWC Thor PSR (suppressor)",
        Model = "models/weapons/arc9/darsu_eft/mods/silencer_base_awc_thor_psr_xl_multi.mdl",
        WorldPos = Vector(0,0,0),
        WorldAng = Angle(0,0,0),
        CorrectSize = 1,
        Placement = "barrel",
        IsSupp = true
    },
}

if SERVER then
    function hg.force_attachment(self,att_name)
        local att = hg.Attachments[att_name]
        if !self.Attachments then
            self.Attachments = {}
        end
        self.Attachments[att.Placement][1] = att_name

        timer.Simple(0,function()
            net.Start("att sync")
            net.WriteTable(self.Attachments)
            net.WriteEntity(self)
            net.Broadcast()
        end)
    end


        concommand.Add("setattach", function(ply, _, args)
        if not ply:IsPlayer() then return end
        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then
            print("Нет оружия в руках.")
            return
        end

        if #args < 1 then
            print("Использование: setattach <название_прицела>")
            return
        end

        local att_name = args[1]
        local att = hg.Attachments[att_name]

        if not att then
            print("Прицел не найден: " .. att_name)
            return
        end

        hg.force_attachment(weapon, att_name)
        print("Прицел " .. att_name .. " установлен на " .. weapon:GetClass())
    end)


        concommand.Add("removeattach", function(ply, _, args)
    if not ply:IsPlayer() then return end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then
        print("Нет оружия в руках.")
        return
    end

    if not weapon.Attachments then
        print("У оружия нет вложений.")
        return
    end

    
    for k, v in pairs(weapon.Attachments) do
        if type(v) == "table" and v[1] then
            v[1] = nil  
        end
    end

    print("Все вложения удалены с оружия.")
    end)
    util.AddNetworkString("hg_remove_single_attachment")
    net.Receive("hg_remove_single_attachment", function(len, ply)
        local attName = net.ReadString()
        local wep = net.ReadEntity()
        if not IsValid(wep) or wep:GetOwner() ~= ply then return end
        for k, v in pairs(wep.Attachments or {}) do
            if v[1] == attName then
                v[1] = nil
            end
        end

        timer.Simple(0, function()
            net.Start("att sync")
            net.WriteTable(wep.Attachments)
            net.WriteEntity(wep)
            net.Broadcast()
        end)
    end)

    util.AddNetworkString("hg_toggle_attachment")
    net.Receive("hg_toggle_attachment", function(len, ply)
        local attName = net.ReadString()
        local wep = net.ReadEntity()
        if not IsValid(wep) or wep:GetOwner() ~= ply then return end
        local att = hg.Attachments[attName]
        if not att then return end

        if not wep.Attachments then wep.Attachments = {} end
        if not wep.Attachments[att.Placement] then wep.Attachments[att.Placement] = {} end

       if wep.Attachments[att.Placement] and wep.Attachments[att.Placement][1] == attName then
       wep.Attachments[att.Placement] = {}
       else
       wep.Attachments[att.Placement] = {attName}
       end

        timer.Simple(0, function()
            net.Start("att sync")
            net.WriteTable(wep.Attachments)
            net.WriteEntity(wep)
            net.Broadcast()
        end)
    end)
end

if CLIENT then
    local frame
    concommand.Add("hg_attachments_gui", function()
    if IsValid(frame) then frame:Close() end

    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(400, 500)
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("Модификация оружия", "DermaLarge", 20, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 40, 0, 0)

    for attName, attData in pairs(hg.Attachments or {}) do
        local btn = scroll:Add("DButton")
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 5)
        btn:SetText("")
        btn._label = attData.Name or attName

        btn.Paint = function(self, w, h)
            if self:IsDown() then
                surface.SetDrawColor(40, 40, 40, 230)
            elseif self:IsHovered() then
                surface.SetDrawColor(60, 60, 60, 230)
            else
                surface.SetDrawColor(25, 25, 25, 220)
            end
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(self._label, "DermaDefaultBold", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            local ply = LocalPlayer()
            local wep = ply:GetActiveWeapon()
            if not IsValid(wep) then return end

            net.Start("hg_toggle_attachment")
            net.WriteString(attName)
            net.WriteEntity(wep)
            net.SendToServer()
        end
    end
end)
end

