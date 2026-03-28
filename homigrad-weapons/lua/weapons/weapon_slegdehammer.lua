-- "addons\\homigrad-core\\lua\\weapons\\weapon_slegdehammer.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "weapon_melee"
SWEP.Category = "Ближний Бой" // HERE IS JOHNY
SWEP.Author = "Homigrad"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/tfa_nmrih/v_me_sledge.mdl"
SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_sledge.mdl"

SWEP.HoldAng = Angle(-1,200,0)
SWEP.HoldPos = Vector(2.3,1.4,-5)

SWEP.AnimAng = Angle(0,0,0)
SWEP.AnimPos = Vector(-13,0,3)

SWEP.IconAng = Angle(120,-90,180)
SWEP.IconPos = Vector(130,-3,0)

SWEP.ModelScale = 1

SWEP.ViewModelFlip = false

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.Rarity = 8

SWEP.AnimWait = 2
SWEP.AttackTime = 0.4
SWEP.AttackAng = Angle(0,-30,30)
SWEP.AttackWait = 0.25
SWEP.AttackDist = 100
SWEP.AttackDamage = 120
SWEP.AttackType = DMG_CLUB
SWEP.NoLHand = false
SWEP.LHand = true

SWEP.HoldType = "melee"

SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.AttackHit = "weapons/melee/rifle_swing_hit_world.wav"
SWEP.DeploySnd = "physics/metal/weapon_impact_soft1.wav"

SWEP.Animations = {
	["idle"] = {
        Source = "Idle",
    },
	["draw"] = {
        Source = "Draw",
        MinProgress = 0.5,
        Time = 0.5
    },
    ["attack"] = {
        Source = "Attack_Quick",
        MinProgress = 0.5,
        Time = 1.5
    },
}
