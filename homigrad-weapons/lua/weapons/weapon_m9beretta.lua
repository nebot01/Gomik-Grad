-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_m9beretta.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "weapon_glockp80"
SWEP.PrintName = "Berreta M9"
SWEP.Category = "Оружие: Пистолеты"
SWEP.Spawnable = true

SWEP.Bodygroups = {[1] = 0,[2] = 0,[3] = 0}

SWEP.WorldModel = "models/weapons/tfa_ins2/w_m9.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_ins2/c_beretta.mdl"
SWEP.ViewModel = "models/weapons/tfa_ins2/c_beretta.mdl"

SWEP.HoldType = "revolver"

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.Primary.ReloadTime = 1.85
SWEP.Primary.ClipSize = 17
SWEP.Primary.DefaultClip = 17
SWEP.Primary.Damage = 35
SWEP.Primary.Force = 25
SWEP.RecoilForce = 1
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Wait = 0.1
SWEP.Sound = "weapons/tfa_ins2/m9/fire_1.wav"
SWEP.SubSound = "hmcd/hndg_beretta92fs/beretta92_fire1.wav"
SWEP.SuppressedSound = "sounds_zcity/glock17/supressor.wav"

SWEP.WorldPos = Vector(-5,0.2,0)
SWEP.WorldAng = Angle(1,0,0)
SWEP.AttPos = Vector(22.5,2.33,-3)
SWEP.AttAng = Angle(-0.5,-0.1,0)
SWEP.HolsterAng = Angle(0,-90,0)
SWEP.HolsterPos = Vector(5,7,0)

SWEP.BoltBone = "Slide"
SWEP.BoltVec = Vector(0,1,0)

SWEP.IconPos = Vector(35,7.5,-4)
SWEP.IconAng = Angle(0,90,0)

SWEP.TwoHands = false

SWEP.ZoomPos = Vector(8,-2.21,-0.29)
SWEP.ZoomAng = Angle(-0.5,0,0)

SWEP.ReloadShake = 0.06

SWEP.holdtypes = {
    ["revolver_empty"] = {[1] = 0.3,[2] = 1,[3] = 1.4,[4] = 1.62},
    ["revolver"] = {[1] = 0.3,[2] = 1,[3] = 1.62,[4] = 0}
}

SWEP.Animations = {
	["idle"] = {
        Source = "base_idle",
    },
	["draw"] = {
        Source = "base_draw",
        MinProgress = 0.5,
        Time = 0.5
    },
    ["reload"] = {
        Source = "base_reload",
        MinProgress = 0.5,
        Time = 2
    },
    ["reload_empty"] = {
        Source = "base_reload_empty",
        MinProgress = 0.5,
        Time = 2.1
    }
}

SWEP.Reload1 = "zcitysnd/sound/weapons/makarov/handling/makarov_magout.wav"
SWEP.Reload2 = "weapons/tfa_ins2/m9/handling/m9_magin.wav"
SWEP.Reload3 = "weapons/tfa_ins2/m9/handling/m9_maghit.wav"
SWEP.Reload4 = "weapons/tfa_ins2/m9/handling/m9_boltrelease.wav"
