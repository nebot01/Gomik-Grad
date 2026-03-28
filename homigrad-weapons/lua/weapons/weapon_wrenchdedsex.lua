-- "addons\\homigrad-core\\lua\\weapons\\weapon_wrenchdedsex.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "weapon_melee"
SWEP.Category = "Ближний Бой"
SWEP.Author = "Homigrad"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/tfa_nmrih/v_me_wrench.mdl"
SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_wrench.mdl"

SWEP.HoldAng = Angle(0,0,180)
SWEP.HoldPos = Vector(1,1.5,3)

SWEP.AnimAng = Angle(-10,0,0)
SWEP.AnimPos = Vector(-15,-2,-5)

SWEP.ModelScale = 1.2

SWEP.ViewModelFlip = false

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.Rarity = 4
SWEP.HoldType = "melee"
SWEP.AnimWait = 1.25
SWEP.AttackTime = 0.2
SWEP.AttackAng = Angle(0,-20,0)
SWEP.AttackWait = 0.4
SWEP.AttackDist = 40
SWEP.AttackDamage = 40
SWEP.AttackType = DMG_CLUB
SWEP.NoLHand = true

SWEP.IconAng = Angle(90,0,-90)
SWEP.IconPos = Vector(65,-5,4.25)

SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.AttackHit = {"physics/metal/metal_sheet_impact_hard2.wav","physics/metal/metal_sheet_impact_hard6.wav"}
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