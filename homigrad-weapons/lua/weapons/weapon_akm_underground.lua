-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_akm_underground.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Underground AKM"
SWEP.Category = "Оружие: Винтовки"
SWEP.Spawnable = true

SWEP.WorldModel = "models/weapons/tfa_ins2/w_akm_bw.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_ins2/c_akm_bw.mdl"
SWEP.ViewModel = "models/weapons/tfa_ins2/c_akm_bw.mdl"


SWEP.AvaibleAtt = {
    ["sight"] = true,
    ["barrel"] = true,
    ["grip"] = false
}

SWEP.HoldType = "ar2"

SWEP.holdtypes = {
    ["ar2"] = {[1] = 0.46,[2] = 1.17,[3] = 2.1,[4] = 2.2},
}

SWEP.Primary.ReloadTime = 2.4
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Damage = 35
SWEP.Primary.Force = 12
SWEP.Primary.Ammo = "7.62x39 mm"
SWEP.Primary.Wait = 0.09
SWEP.Sound = "weapons/newakm/akmm_fp.wav"
SWEP.SubSound = "weapons/ak47/ak47_fp.wav"
SWEP.SuppressedSound = "weapons/newakm/akmm_suppressed_tp.wav"
SWEP.RecoilForce = 0.4

SWEP.WorldPos = Vector(-5,-0.5,0)
SWEP.WorldAng = Angle(0,0,0)
SWEP.AttPos = Vector(37,2.93,-2.4)
SWEP.AttAng = Angle(0.45,-0.25,0)
SWEP.HolsterAng = Angle(140,0,180)
SWEP.HolsterPos = Vector(-16,6,5.5)
SWEP.HolsterBone = "ValveBiped.Bip01_Spine2"

SWEP.Slot = 2
SWEP.SlotPos = 0

SWEP.BoltBone = "Bolt"
SWEP.BoltVec = Vector(0,2,0)

SWEP.ZoomPos = Vector(4,-2.9,-1)
SWEP.ZoomAng = Angle(-0.9,-0.26,0)

SWEP.Rarity = 4

SWEP.TwoHands = true

SWEP.MountType = "dovetail"
SWEP.MountModel = "models/weapons/arc9_eft_shared/atts/mounts/mount_dovetail_aksion_kobra.mdl"
SWEP.MountPos = Vector(0.71,6,-1,-1.5)
SWEP.MountAng = Angle(-90,180,0)
SWEP.MountScale = 0.75

SWEP.AttBone = "A_Modkit"

SWEP.AttachmentPos = {
    ['sight'] = Vector(-4,0,1),
    ['barrel'] = Vector(-32,1.5,0),
}

SWEP.AttachmentAng = {
    ['sight'] = Angle(90,0,-90),
    ['barrel'] = Angle(0,90,180),
}

SWEP.IconPos = Vector(130,-23.2,-1)
SWEP.IconAng = Angle(0,90,0)

SWEP.Animations = {
	["idle"] = {
        Source = "base_idle",
    },
	["draw"] = {
        Source = "base_draw",
        MinProgress = 0.5,
        Time = 0.6
    },
    ["reload"] = {
        Source = "base_reload",
        MinProgress = 1,
        Time = 2.7
    },
    ["reload_empty"] = {
        Source = "base_reloadempty",
        MinProgress = 1,
        Time = 3
    }
}

function SWEP:PostAnim()
    if self.BoltBone and self.BoltVec and CLIENT then
        local bone = self:GetWM():LookupBone(self.BoltBone)

        if bone then
            self:GetWM():ManipulateBonePosition(bone,self.BoltVec * self.animmul)
        end
    end

    if IsValid(self.worldModel) and self.worldModel:LookupBone("vm_mag2") then
        self.worldModel:ManipulateBoneScale(self.worldModel:LookupBone("vm_mag2"),Vector(1,1,1) * (self.reload != nil and 1 or 0))
        self.worldModel:ManipulateBoneScale(self.worldModel:LookupBone("tag_mag2"),Vector(1,1,1) * (self.reload != nil and 1 or 0))
    end

    self.animmul = LerpFT(0.12,self.animmul,0)
end

SWEP.Reload1 = "weapons/newakm/akmm_magout.wav"
SWEP.Reload2 = "zcitysnd/sound/weapons/aks74u/handling/aks_magin.wav"
SWEP.Reload3 = "weapons/newakm/akmm_boltback.wav"
SWEP.Reload4 = "weapons/newakm/akmm_boltrelease.wav"