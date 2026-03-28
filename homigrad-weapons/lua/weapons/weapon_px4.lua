-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_px4.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Beretta PX4"
SWEP.Category = "Оружие: Пистолеты"
SWEP.Spawnable = true


SWEP.WorldModel = "models/weapons/w_pist_px4.mdl"
SWEP.WorldModelReal = "models/weapons/salat/px4/c_px4.mdl"
SWEP.ViewModel = "models/weapons/salat/px4/c_px4.mdl"

SWEP.HoldType = "revolver"

SWEP.ViewModelFlip = true

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.Primary.ReloadTime = 1.85
SWEP.Primary.ClipSize = 17
SWEP.Primary.DefaultClip = 17
SWEP.Primary.Damage = 45
SWEP.Primary.Force = 30
SWEP.RecoilForce = 1
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Wait = 0.1
SWEP.Sound = "sounds_zcity/glock17/close.wav"
SWEP.SubSound = "weapons/aks74u/aks_tp.wav"

SWEP.WorldPos = Vector(-3,-1.5,1)
SWEP.WorldAng = Angle(1,0,0)
SWEP.AttPos = Vector(22.5,2.33,-3)
SWEP.AttAng = Angle(-0.5,-0.1,0)
SWEP.HolsterAng = Angle(0,-90,0)
SWEP.HolsterPos = Vector(-16,4,2)

SWEP.BoltBone = "slidey"
SWEP.BoltVec = Vector(-1,0,0)

SWEP.IconPos = Vector(40,-9.75,-7.5)
SWEP.IconAng = Angle(0,90,0)

SWEP.TwoHands = false

SWEP.ZoomPos = Vector(6,-3.5,-0.95)
SWEP.ZoomAng = Angle(-0.5,0,0)

SWEP.holdtypes = {
    ["revolver_empty"] = {[1] = 0.2,[2] = 1,[3] = 1.4,[4] = 0},
}

SWEP.Animations = {
	["idle"] = {
        Source = "idle",
    },
	["draw"] = {
        Source = "draw",
        MinProgress = 0.5,
        Time = 0.5
    },
    ["reload"] = {
        Source = "reload",
        MinProgress = 0.5,
        Time = 1.5
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        MinProgress = 0.5,
        Time = 1.9
    }
}

function SWEP:PostAnim()
    if self.BoltBone and self.BoltVec and CLIENT then
        local bone = self:GetWM():LookupBone(self.BoltBone)

        if bone then
            self:GetWM():ManipulateBonePosition(bone,self.BoltVec * self.animmul)
        end
    end

    if self:Clip1() == 0 and !self.reload then
        self.animmul = 1
    else 
        self.animmul = LerpFT(0.25,self.animmul,0)
    end
end

SWEP.Reload1 = "zcitysnd/sound/weapons/makarov/handling/makarov_magout.wav"
SWEP.Reload2 = "zcitysnd/sound/weapons/makarov/handling/makarov_maghit.wav"
SWEP.Reload3 = "zcitysnd/sound/weapons/m9/handling/m9_boltrelease.wav"
SWEP.Reload4 = false