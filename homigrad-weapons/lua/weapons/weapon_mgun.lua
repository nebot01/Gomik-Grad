-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_mgun.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Minigun"
SWEP.Category = "Оружие: Пулемёты"
SWEP.Spawnable = true

SWEP.WorldModel = "models/viper/mw/weapons/w_dblmg.mdl"
SWEP.WorldModelReal = "models/viper/mw/weapons/v_dblmg.mdl"
SWEP.ViewModel =  "models/viper/mw/weapons/v_dblmg.mdl"

SWEP.HoldType = "smg"

SWEP.Empty3 = false
SWEP.Empty4 = false

SWEP.holdtypes = {
    ["smg"] = {[1] = 1.63,[2] = 0,[3] = 0,[4] = 4.1},
}

SWEP.Primary.ReloadTime = 8
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 300
SWEP.Primary.DefaultClip = 300
SWEP.Primary.Damage = 120
SWEP.Primary.Force = 10
SWEP.Primary.Ammo = "7.62x39 mm"
SWEP.Primary.Wait = 0.05
SWEP.Sound = "weapons/m24sws/m24_shoot_default.wav"
SWEP.SubSound = "weapons/m249/m249_tp.wav"
SWEP.RecoilForce = 2.4

SWEP.WorldPos = Vector(-5.1,-2,-2)
SWEP.WorldAng = Angle(0,0,3)
SWEP.AttPos = Vector(37,4.95,-9.2)
SWEP.AttAng = Angle(0.6,-0.1,0)
SWEP.HolsterAng = Angle(0,-10,0)
SWEP.HolsterPos = Vector(-18,0,5.5)
SWEP.HolsterBone = "ValveBiped.Bip01_Spine4"

SWEP.IconPos = Vector(135,-21.25,-2)
SWEP.IconAng = Angle(0,90,0)

SWEP.TwoHands = true

SWEP.Rarity = 8

SWEP.BoltBone = "j_rotating_barrels"
SWEP.BoltVec = Vector(0,0,0)

SWEP.ZoomPos = Vector(11,-4.86,-1.6)
SWEP.ZoomAng = Angle(0,-0.05,0)

SWEP.Animations = {
	["idle"] = {
        Source = "idle",
    },
	["draw"] = {
        Source = "draw",
        MinProgress = 0.5,
        Time = 1.2
    },
    ["reload"] = {
        Source = "reload",
        MinProgress = 0.5,
        Time = 8
    },
    ["fire"] = {
        Source = "spin_end",
        MinProgress = 3.5,
        Time = 0.6
    },
}

SWEP.Reload1 = "viper/weapons/dblmg/wfoly_plr_lm_minigun_reload_belt_out.wav"
SWEP.Reload2 = false
SWEP.Reload3 = false
SWEP.Reload4 = "viper/weapons/dblmg/wfoly_plr_lm_minigun_reload_end.wav"
