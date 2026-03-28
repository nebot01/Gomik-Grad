-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_cat.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Cat"
SWEP.Category = "Оружие: Остальное"
SWEP.Spawnable = true

SWEP.WorldModel = "models/weapons/w_catgun.mdl"
SWEP.ViewModel = "models/weapons/v_catgun.mdl"
SWEP.WorldModelReal = "models/weapons/v_catgun.mdl"

SWEP.HoldType = "ar2"

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.Primary.Automatic = true
SWEP.Primary.ReloadTime = 1.85
SWEP.Primary.ClipSize = 500
SWEP.Primary.DefaultClip = 500
SWEP.Primary.Damage = 55
SWEP.Primary.Force = 50
SWEP.RecoilForce = 1
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Wait = 0.02
SWEP.Sound = "cat/meow.wav"
SWEP.SuppressedSound = "sounds_zcity/glock17/supressor.wav"

SWEP.WorldPos = Vector(-7,-0.5,2)
SWEP.WorldAng = Angle(-4,0,0)
SWEP.AttPos = Vector(22.5,2.33,-3)
SWEP.AttAng = Angle(-0.5,-0.1,0)
SWEP.HolsterAng = Angle(0,-90,0)
SWEP.HolsterPos = Vector(-16,4,2)


SWEP.IconPos = Vector(60,-15.75,-5)
SWEP.IconAng = Angle(0,90,0)

SWEP.TwoHands = true

SWEP.BoltBone = "weapon_tail1"
SWEP.BoltVec = Vector(0,2,0)

SWEP.ZoomPos = Vector(8,-2.31,-2.45)
SWEP.ZoomAng = Angle(-0.5,0,0)

SWEP.holdtypes = {
    ["ar2"] = {[1] = 0.3,[2] = 0,[3] = 0,[4] = 0},
}

SWEP.Animations = {
	["idle"] = {
        Source = "idle01",
    },
	["draw"] = {
        Source = "draw",
        MinProgress = 0.5,
        Time = 0.7
    },
    ["reload"] = {
        Source = "reload1",
        MinProgress = 0.5,
        Time = 1.5
    },
    ["reload_empty"] = {
        Source = "reload2",
        MinProgress = 0.5,
        Time = 1.9
    },
    ["fire"] = {
        Source = "fire01",
        MinProgress = 0.5,
        Time = 1.5
    },
}

SWEP.Reload1 = "cat/catsamloop.wav"
SWEP.Reload2 = false
SWEP.Reload3 = false
SWEP.Reload4 = false
