-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_36mr.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.Base = "homigrad_base"
SWEP.PrintName = "Manurhin MR-96"
SWEP.Category = "Оружие: Пистолеты"
SWEP.Spawnable = true

SWEP.WorldModel = "models/weapons/w_mr96.mdl"
SWEP.WorldModelReal = "models/weapons/c_pist_mr96.mdl"
SWEP.ViewModel = "models/weapons/c_pist_mr96.mdl"

SWEP.HoldType = "revolver"

SWEP.holdtypes = {
    ["revolver"] = {[1] = 0.25,[2] = 0.77,[3] = 2,[4] = 2.5},
}

SWEP.Bodygroups = {[1] = 2}

SWEP.Primary.ReloadTime = 3.5
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Damage = 85
SWEP.Primary.Force = 15
SWEP.Primary.Ammo = ".44 Magnum"
SWEP.Primary.Wait = 0.8
SWEP.Sound = "zcitysnd/sound/weapons/revolver/revolver_fp.wav"
SWEP.RecoilForce = 2
SWEP.Empty3 = false
SWEP.Empty4 = false

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.IsRevolver = true

SWEP.WorldPos = Vector(-2,0,0)
SWEP.WorldAng = Angle(1,0,-1)
SWEP.AttPos = Vector(24,2.77,-1.25)
SWEP.AttAng = Angle(0.4,-0.15,0)
SWEP.HolsterAng = Angle(0,-90,0)
SWEP.HolsterPos = Vector(-10,4,4)
SWEP.HolsterBone = "ValveBiped.Bip01_Pelvis"

SWEP.BoltBone = "speedloader"
SWEP.BoltVec = Vector(0,0,0)

SWEP.ZoomPos = Vector(5,-2.16,-0.32)
SWEP.ZoomAng = Angle(0,-0.1,0)

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

SWEP.IconPos = Vector(50,-17,1)
SWEP.IconAng = Angle(0,90,0)

SWEP.Animations = {
	["idle"] = {
        Source = "idle1",
    },
	["draw"] = {
        Source = "draw",
        MinProgress = 0.5,
        Time = 0.7
    },
    ["reload"] = {
        Source = "reload",
        MinProgress = 0.5,
        Time = 3.5
    },
    ["fire"] = {
        Source = "shoot2",
        MinProgress = 0.5,
        Time = 0.45
    },
}

SWEP.Reload1 = "weapons/tfa_ins2/swmodel10/revolver_open_chamber.wav"
SWEP.Reload2 = "weapons/tfa_ins2/thanez_cobra/revolver_dump_rounds_01.wav"
SWEP.Reload3 = "weapons/tfa_ins2/thanez_cobra/revolver_speed_loader_insert_01.wav"
SWEP.Reload4 = "weapons/tfa_ins2/thanez_cobra/revolver_close_chamber.wav"