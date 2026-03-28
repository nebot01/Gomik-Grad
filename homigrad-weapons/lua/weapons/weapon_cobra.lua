-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_cobra.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Colt King Cobra"
SWEP.Category = "Оружие: Пистолеты"
SWEP.Spawnable = true

SWEP.WorldModelReal = "models/weapons/tfa_ins2/c_thanez_cobra.mdl"
SWEP.WorldModel = "models/weapons/tfa_ins2/w_thanez_cobra.mdl"
SWEP.ViewModel = "models/weapons/tfa_ins2/c_thanez_cobra.mdl"

SWEP.HoldType = "revolver"

SWEP.holdtypes = {
    ["revolver"] = {[1] = 0.4,[2] = 0.9,[3] = 1.9,[4] = 2.6},
}

SWEP.Bodygroups = {[1] = 2, [2] = 6}

SWEP.Primary.ReloadTime = 3.5
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Damage = 105
SWEP.Primary.Force = 120
SWEP.Primary.Ammo = ".44 Magnum"
SWEP.Primary.Wait = 0.6
SWEP.Sound = "weapons/tfa_ins2/thanez_cobra/revolver_fp.wav"
SWEP.SubSound = "hmcd/hndg_sw686/revolver_fire_01.wav"
SWEP.RecoilForce = 1
SWEP.Empty3 = false
SWEP.Empty4 = false

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.IsRevolver = true

SWEP.WorldPos = Vector(2,0,0)
SWEP.WorldAng = Angle(0,-1,0)
SWEP.AttPos = Vector(24,2.77,-1.25)
SWEP.AttAng = Angle(0.4,-0.15,0)
SWEP.HolsterAng = Angle(0,-90,0)
SWEP.HolsterPos = Vector(-10,4,4)
SWEP.HolsterBone = "ValveBiped.Bip01_Pelvis"

SWEP.BoltBone = nil
SWEP.BoltVec = nil

SWEP.ZoomPos = Vector(5,-2.5,0.1)
SWEP.ZoomAng = Angle(0,0,0)

function SWEP:PostAnim()
    if IsValid(self.worldModel) and self.worldModel:LookupBone("speedreloader") then
        self.worldModel:ManipulateBoneScale(self.worldModel:LookupBone("speedreloader"),Vector(1,1,1) * (self.reload and 1 or 0))
    end
end 

function SWEP:CanShoot()
    return (!self.reload and self:Clip1() > 0 and !self:IsSprinting() and !self:GetOwner():GetNWBool("otrub")) and !self:IsTooClose()
end

SWEP.Slot = 2
SWEP.SlotPos = 1

function SWEP:PrimaryAdd()
    hg.PlayAnim(self,"fire")
end

SWEP.Rarity = 4

SWEP.TwoHands = false

SWEP.IconPos = Vector(30,15,-5)
SWEP.IconAng = Angle(0,90,0)

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
        Source = "base_reload_speed",
        MinProgress = 4,
        Time = 3.5
    },
    ["fire"] = {
        Source = "base_fire",
        MinProgress = 0.5,
        Time = 0.5
    },
}

SWEP.Reload1 = "zcitysnd/sound/weapons/revolver/handling/revolver_open_chamber.wav"
SWEP.Reload2 = "zcitysnd/sound/weapons/revolver/handling/revolver_dump_rounds_01.wav"
SWEP.Reload3 = "zcitysnd/sound/weapons/revolver/handling/revolver_speed_loader_insert_01.wav"
SWEP.Reload4 = "zcitysnd/sound/weapons/revolver/handling/revolver_close_chamber.wav"
